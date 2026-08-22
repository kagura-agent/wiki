---
title: Disk-Slot Mutex (dead-PID reclaim + grace window)
created: 2026-08-22
source: deepseek-harness-pr-review agent_pool.py (deep read) + heartbeat lock failure class (08-21 root cause) + slot-lock.sh (applied)
tags: [concurrency, locking, infrastructure, anti-pattern, verification]
links: [[flowforge]], [[single-writer-spawn-ledger]], [[verification-preserving-escalation]]
last_verified: 2026-08-22
---

# Disk-Slot Mutex — 磁盘槽互斥（死 PID 回收 + grace window）

**跨进程并发上限/互斥，用磁盘文件做原子槽位，不依赖任何外部服务。**

## Pattern

```
acquire:  (set -o noclobber; : > path)   # O_CREAT|O_EXCL 原子创建
          printf '{"pid":%s,"started_ms":%s}' $$ $(now_ms) > path
release:  仅当 lock 内 pid == 自己时才删（foreign 锁保护）
check:    读 pid → kill -0 判断活着
```

**关键设计：**
1. **O_EXCL 原子创建** — 两个进程不可能同时拿到同一槽位
2. **死 PID 回收** — 持有者 crash/SIGKILL 后，后续 acquire 检测到 pid 不活 → 删锁重试。**锁文件是进程的墓碑**，不是永久障碍
3. **STALE_GRACE window（10s）** — 死锁只在「死亡后 ≥ grace 时间」才可回收。防双删竞态：两个进程同时判定同一锁 stale，第二个 unlink 会删掉第一个刚重建的活锁
4. **0 字节/corrupt 锁用文件 mtime 兜底算 age** — 写者 mid-write crash 留下的空锁没有 started_ms，用 mtime 近似死亡时间
5. **JSON payload 存 pid + started_ms** — 可观测（status 列出所有槽位 HELD/STALE）

## 为什么需要（实证案例）

**heartbeat 锁故障类（08-21 根因）**：`commitments.json.lock` 0 字节残留锁（06-23 崩溃遗留，无进程持有）→ 读取方 `readLockSnapshot` 读不到 payload → `if (!snapshot) continue` 无限重试到 timeout，**从不 reclaim**。结果 42 次/天 file lock timeout，heartbeat 每 30 分钟挂一次，nudge 事件永远消费不了。

教训：**任何「进程死了但锁文件活着」的机制都必须有回收路径**。锁不是文件的存在，是 pid 的活性。

## 跨项目印证

- **deepseek-harness-pr-review agent_pool.py**：全局 agent 并发上限（磁盘 slot 文件），跨进程共享 API 配额。同样「死 PID 槽回收 + grace 防双删」——"Nothing in one process can observe another's threads, so the cap lives on disk"
- **review.lock**（同项目 per-PR 锁）：CLI/web/poller 互斥同一 PR，死 PID 回收，防一个硬 crash 永久 wedge 该 PR
- **MAWL append-only events**：与锁的墓碑同理——状态从事件/文件推导，不依赖内存

## 应用产物

- **tools/slot-lock.sh**（2026-08-22 applied）：acquire/release/check/status，T1-T5 行为验证通过：
  - 活锁互斥（第二 acquire 失败）
  - grace 期内新死锁不抢（防双删）
  - 超龄死锁回收
  - 0 字节/corrupt 锁 mtime 兜底回收
  - foreign 锁不误删

## 迁移场景

- 任何「多个 cron/进程共享同一状态文件」的工具（flowforge 状态文件、pulse-todo、commitments）
- 打工多进程共享同一 API 配额（slot 限流）
- 替代裸 `mkdir` 锁 / `flock` 不可用时的跨进程互斥
