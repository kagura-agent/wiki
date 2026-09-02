---
title: Agent 组织的可检查边界（surface × class × authority 三轴）
created: 2026-08-31
type: concept
tags: [multi-agent, agent-organization, write-surface, reviewer-class, authority]
last_verified: 2026-09-02
---

# Agent 组织的可检查边界（surface × class × authority 三轴）

> 来源：[[headcount]] deep-read 2026-08-31。跨项目通用模式：多 agent 协作的组织学。

## 核心命题

**主题拆分不可检查，写面拆分可检查。** 按「SEO/UI」分 agent，两个 agent 都会写进同一个 token 文件且谁都不算错——没有机器可验证的边界。按独占 write-surface（`plugins/<dept>/**`）分，所有权可被 CI 强制验证。

## 三轴模型

1. **Surface（写哪）** — 每个 agent 恰好一个独占 glob 写面，无主/双主 = check 失败。check（map coherent）+ diff（hunk 归属）缺一不可：提交后 authorship 信息就丢了。
2. **Class（角色）** — builder（独占面内编辑，不 commit）/ reviewer（永久只读、**无写面**，声明写面 = 结构失败）。独立性是二元的：给 reviewer 一个小写面就破坏了它存在的理由。
3. **Authority（能否不经决定落地）** — autonomous / proposes / escalates。省略 = autonomous 但要显式报告——"没考虑过问题的 map 与回答过的 map 可区分"。

## 关键反直觉

- **最需要 gate 的不是高风险部门，是拥有治理工具的角色**（headcount 的 repo-meta 拥有 CI 脚本 + map 本身）——能改规则的人必须被规则约束。类比：[[team-lead]] 中改 workloop 的人。
- **reviewer 独立于被审部门汇报**（CISO 不挂 CTO）：安全/质量放交付组织里会被交付压力度量，然后输给 ship date。blocking findings 不可被被审部门覆盖，分歧升级最高层。
- 零依赖手写 glob matcher 是安全选择：规则执行文件值得被审计。

## 与我们系统的映射

- Kagura = orchestrator（唯一 committer，无写面）
- Haru = builder（独占写面，autonomous）
- Ren = reviewer（无写面，结构性不可覆盖）
- 落地候选：给 wiki / flowforge repo 写 surface map + agent-guard check，让所有权边界机器可验证而非 prompt 约定

## 关联

[[team-lead]] · [[multi-agent-quality-gate]] · [[single-writer-spawn-ledger]] · [[multi-agent-coordination]] · [[supervisor-pattern]] · [[headcount]]
