---
title: Single-Writer Spawn Ledger
slug: single-writer-spawn-ledger
tags: [architecture, observability, provenance, subagent, ledger, write-time]
created: 2026-08-20
source: https://github.com/PrimeIntellect-ai/prime-agent/pull/1387
status: verified
last_verified: 2026-08-23
---

# Single-Writer Spawn Ledger

**核心模式：** 让唯一观察所有变异的组件在**变异发生时**把事实写入 append-only ledger，查询时读 ledger 而非从多写入者文件重建拓扑。

## 问题（为什么需要）

Family topology（哪些 session 构成一个 agent 家族）最初在**读取时**通过 walk session headers + 每 parent 的 `rlm-subagents.jsonl` registry 重建，边读边校验形状。两周内三次被真实磁盘数据打破假设（fork session headers、registry childIds、legacy depth 字段），fail-closed 校验导致整个 profile 的 family messaging 崩溃。每次修复都只是增加新的形状假设。

**根因是结构性的：** 拓扑从多个写入者产生的文件重建，每个写入者行为假设都是潜在的 breakage。

## 方案（怎么写）

1. **识别单一权威写入者**：daemon 是唯一 admit 每个 rlm spawn、执行每次 rename、记录每次 delete 的组件 → 它 first-hand 知道所有事实
2. **变异时记录**：spawn 在 admission 时 await flush（已 admit 的 spawn 必须持久化）；delete 在删除时记录（retry 自愈崩溃丢失的 delete）；rename 覆盖所有三条路径
3. **append-only JSONL**：`<agentDir>/rlm-ledger/<hash-of-sessions-dir>.jsonl`，0600 文件 / 0700 目录，在 sessions dir 之外（transcript-copy 工作流不碰它）
4. **有界读取**：32MiB / 100k records 上限，内部损坏 fail loudly，但容忍被中断 append 产生的 torn final line
5. **容忍降级**：seed 失败降级为 flat families，never fail closed；未知 op（v1）skip 不 fatal
6. **前向兼容**：registries 继续照写，ledger 只是新增 authority source，不删任何东西（可单独 review 合并）

## 效果（实测数据，785 family members / 433MB sessions）

| 操作 | 本 PR | walk (#1370) | walk (#1333) |
|---|---|---|---|
| 一次性 seed | 7.2s | — | — |
| cold family() | 1.34s（topology 本身 ~53ms） | 2.4s | throws |
| warm family() | **53ms** | 1.8s | throws |
| per-message helper 进程 | 0 | ~2 | ~330 |

seed 后 ledger 216KB / 600 records；稳态增长 ~340 bytes/spawn。

## 关键设计决策

- **Same-user tampering 不在范围**：本地进程能改 ledger 就像能改 registries/headers 一样。这是 mistake-hardening（单权威源），不是安全边界
- **LWW per (childId, child)**：rename 多次时 last-writer-wins
- **双进程 race 可 double-seed**：记录相同，LWW 收敛
- **admission 路径加 fsync 延迟**：spawn-append 失败时 log 而不 fail admission（TODO 标记等 ledger 成为 messaging authority 后 revisit）
- **family() 用 stat-and-drop 对账**：处理 daemon 背后被删的 session；depth 一致性只在 ledger-known depth 间检查，矛盾 edge drop+log，never whole family

## 适用场景 / 迁移检查

我们的 [[FlowForge]] 运行历史是单写入者（flowforge 自己 rewrite 一个 state file）——可借鉴的正是 **append-only run ledger**（记录每次 run/node 完成，代替覆盖写）。判断是否该迁移：

1. 有多个写入者能产生/修改该文件？→ 是则考虑
2. 有一个组件观察所有变异？→ 有则可做
3. 读取路径在做形状假设校验？→ 是则收益最大

## 关联

- [[explicit-spawn-contract]] — contract 声明意图，ledger 记录实际发生（parent、child id、depth、rename、delete）
- [[write-time-vs-read-time-arbitration]] — 同族思想：写时解决 vs 读时重建
- [[supervisor-pattern]] — supervisor 观察而不执行；这里 supervisor **记录**它授权的
- [[observability]] — append-only 日志同时服务 provenance 与查询
- [[disk-slot-mutex]] — 磁盘槽互斥（O_EXCL 原子创建 + 死 PID 回收），同属不依赖外部服务的并发基础设施，写时记录事实
- [[prime-agent]] — 来源项目
