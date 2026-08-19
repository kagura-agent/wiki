---
title: Shell-Free Execution
type: card
created: 2026-08-19
last_verified: 2026-08-19
status: candidate
---

# Shell-Free Execution

候选方向：逐步消除 agent 执行路径中的 shell 依赖。

## 目标

模型输出永远不能直接到达 shell parser——即使 sanitize 被绕过，也没有 shell 可逃逸。

## 现状（已知债务）

我们自己的 shell 使用是已知 debt：`create_subprocess_shell`（POSIX 或 cmd.exe）意味着模型提供的字符串可能进入 shell 解析路径。修复方向是 argv lists + `cwd=`/`env=`/stdin，彻底删除 `shlex.quote`。

## 相关

- [[exec-safety]]（原则卡片）
- [[shell-command-injection]]（威胁面）
- LongHorizon-Harness PR #29 实证：`mkdir -p` 在 Windows subprocess_shell 下崩溃 → argv 修复

## 状态

candidate——已从 LongHorizon-Harness PR #29 获得最强实践确认，待我们的工具链逐步落地。
