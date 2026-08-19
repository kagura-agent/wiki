---
title: Exec Safety
type: card
created: 2026-08-19
last_verified: 2026-08-19
status: active
---

# Exec Safety

Agent 执行安全方向的核心原则：**从 agent 路径中移除 shell，而不是尝试 sanitize shell 输入。**

## 原则

- Agent 命令以 argv lists + `cwd=`/`env=`/stdin 传递，模型提供的值永远不经过 shell parser
- 删除 `shlex.quote` 这类"转义救火"做法——没有模型提供的值应该触达 shell 解析器
- `Environment.exec` 只保留为显式逃生舱

## Shell-Free Execution（候选方向）

自己的 shell 使用是已知债务——逐步向 shell-free 执行路径迁移。目标：模型输出永远不能直接到达 shell parser，即使绕过 sanitize。

## 实证

LongHorizon-Harness PR #29（saikethan27）：Windows 上 `create_subprocess_shell` + `mkdir -p` 直接崩溃 → 改 argv lists 后修复。这是 exec-safety 方向的最强实践确认。

## 关联

- [[shell-command-injection]]（威胁面）
- [[execution-contract-pattern]]（执行契约）
- [[tool-execution-policy-enforcement]]（策略执行）
- [[delegating-executor-pattern]]
