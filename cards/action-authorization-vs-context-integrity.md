---
created: 2026-04-09
last_verified: 2026-06-03
---
# Action Authorization vs Context Integrity

> Agent 安全的两个正交维度

## 核心区分

Agent 安全经常被笼统讨论，但实际上是两个独立问题：

**Action Authorization（行动授权）**: Agent 是否有权限代表用户执行某操作？
- 防御目标：防止 agent 越权
- 实现：权限模型、approval 机制、sandbox
- OpenClaw: exec preflight, approval cards

**Context Integrity（上下文完整性）**: Agent 依据的信息是否准确、未被篡改？
- 防御目标：防止 prompt injection、数据投毒
- 实现：输入标记、来源验证、信任边界
- OpenClaw: EXTERNAL_UNTRUSTED_CONTENT 标记

## 为什么区分重要

两者需要完全不同的防御策略。混为一谈会导致：
- 只做了授权控制，忽略了上下文污染（McKinsey Lilli 案例）
- 只做了输入过滤，忽略了权限升级

## 关联

- [[agent-security]] — 完整项目笔记
- 来源：HN 社区对 NIST AI Agent Security 的讨论（2026-04）
