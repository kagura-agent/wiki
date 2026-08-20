---
title: Pushed-at Misleading
created: 2026-08-20
source: beliefs-candidates.md (2026-08-16, pattern 第3次) + ProofRun study (2026-08-19)
tags: [verification, data-discipline, anti-pattern, study]
links: [[verify-claims]], [[verify-before-researching]]
last_verified: 2026-08-20
---

# Pushed-at Misleading

**不要信任"时间戳"类信号判断事物当前状态——时间戳可以被无关操作刷新，状态应该基于当前事实重算。**

## Pattern

GitHub 的 `pushed_at` 字段是典型陷阱：**任意分支或引用的推送都会刷新它**。一个核心代码 2 年没动过的 repo，可能因为一次 README 修改或一个 stale 分支的 push 而显示"最近活跃"，导致误判项目健康度。

类似地，任何"上次 X 时间"的断言（断言 vs 推导）都可能被缓存/陈旧数据误导——这正是 ProofRun 的 STALE 设计要解决的：**staleness 是关于当下的事实，不是关于上次运行时的事实**（"Only an observed execution can produce a stored result, but staleness is a fact about the present"）。

## Fix

判断 repo 活跃度时：
1. **查 default branch commits since 上次验证日期** — 核心开发是否真的在推进
2. **`branches?sort=committer_date` 一次到位** — 看真正有提交的分支
3. `pushed_at` 只作辅助信号，不作主判据

一般化：**freshness should be derived from state, not asserted**（新鲜度应从状态推导，而非断言）。

## Related

- [[verify-claims]] — 不验证就不下结论
- [[verify-before-researching]] — 动手前先确认前提
