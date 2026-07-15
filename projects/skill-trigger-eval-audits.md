---
title: "Skill Trigger Eval Audits"
created: 2026-04-12
tags: [skills, eval, audit]
links: [skill-trigger-eval, skill-trajectory-tracking]
last_verified: 2026-07-15
---

# Skill Trigger Eval Audits

实际审计记录，使用 [[skill-trigger-eval]] 方法论。

last_verified: 2026-07-15
---

## Audit #1: agent-memes (2026-04-12)

**Description**: "Send meme reaction images in chat. One command to pick & send. Multi-platform (Discord, Feishu, Telegram, etc). Use when the conversation calls for a visual reaction — humor, celebration, frustration, facepalm, or any moment where a meme hits harder than words. Also use proactively when YOU feel something."

### 正例测试（Should Trigger）
| Prompt | Covered? | Notes |
|---|---|---|
| "发个表情包" | ✅ | "meme reaction images" |
| "send a meme" | ✅ | direct match |
| "react with a facepalm" | ✅ | "facepalm" explicit |
| "庆祝一下" (celebrate) | ⚠️ | "celebration" in desc, but 庆祝 not listed as trigger |
| "哈哈太搞笑了" (spontaneous humor) | ❌ | no Chinese humor triggers; "humor" is in desc but only as category |

### 反例测试（Should NOT Trigger）
| Prompt | Correct non-trigger? | Notes |
|---|---|---|
| "what memes are popular today" | ✅ | knowledge Q, not sending |
| "design a meme template" | ✅ | creation, not reaction |
| "add emoji reaction to message" | ⚠️ | Platform reactions ≠ meme images, but could be confused |

### 边界测试
| Prompt | Expected | Notes |
|---|---|---|
| "用 GIF 回复" | should trigger | GIF ≈ meme in this context |
| agent feels frustrated internally | should trigger (proactive) | "Also use proactively when YOU feel something" covers this |
| "给这个消息加个反应" | should NOT trigger | emoji reaction, not meme |

### 竞争测试
| Prompt | agent-memes vs | Expected winner |
|---|---|---|
| "发表情包到 Discord" | discord-ops | agent-memes (sending meme content, not managing Discord infra) |
| "创建 meme channel" | discord-ops | discord-ops (channel management) |

### 诊断总结
- **Precision**: 高 — description 明确限定了"visual reaction"场景
- **Recall 缺陷**: 中文触发词缺失。用户说"发个表情包"/"搞笑"/"哈哈"时，description 里无中文对应。依赖 available_skills 列表里的中文补充
- **改进建议**:
  1. description 加中文触发词: "发表情包, 表情, GIF, 搞笑, 哈哈"
  2. "Also use proactively" 是独特的设计——大多数 skill 是被动触发的，这个要求主动判断。这意味着 trigger eval 的正例不完全是用户说的话，还包括 agent 自己的状态判断。传统 trigger eval 方法在此有局限
  3. 与 emoji reaction 的边界需要更明确（"This is for sending IMAGE memes, not platform emoji reactions"）

last_verified: 2026-07-15
---

## Audit #2: discord-ops (2026-04-12)

**Description**: "Discord server management. Use when: creating channels, managing pins, updating allowlists, configuring cron delivery targets, or any Discord infrastructure task. Triggers on: create channel, discord channel, pin message, discord管理, 建channel, discord ops."

### 正例测试
| Prompt | Covered? | Notes |
|---|---|---|
| "create a new Discord channel" | ✅ | "create channel" explicit |
| "pin this message" | ✅ | "pin message" explicit |
| "update the cron delivery target" | ✅ | "configuring cron delivery targets" |
| "discord管理" | ✅ | Chinese trigger explicit |
| "change the channel allowlist" | ✅ | "updating allowlists" |

### 反例测试
| Prompt | Correct non-trigger? | Notes |
|---|---|---|
| "send a message in Discord" | ✅ | messaging ≠ management |
| "check Discord notifications" | ⚠️ | not infrastructure, but could be confused as "Discord task" |
| "set up a Discord bot" | ⚠️ | "infrastructure task" is broad — bot setup might match |

### 边界测试
| Prompt | Expected | Notes |
|---|---|---|
| "archive a Discord thread" | should trigger | thread lifecycle is infra management |
| "move messages between channels" | should trigger | channel management |
| "read channel pins" | should trigger | pin management |

### 竞争测试
| Prompt | discord-ops vs | Expected winner |
|---|---|---|
| "发表情包到 Discord" | agent-memes | agent-memes (content, not infra) |
| "在 Discord 创建 meme channel" | agent-memes | discord-ops (channel creation) |
| "check PR status in Discord" | github | github (PR is github domain) |

### 诊断总结
- **Precision**: 高 — "infrastructure task" + explicit trigger words
- **Recall**: 好 — 覆盖了主要管理操作
- **改进建议**:
  1. "any Discord infrastructure task" 太宽泛 — "check Discord notifications" 技术上算 Discord 任务但不需要这个 skill
  2. 建议加 NOT for 声明: "NOT for: sending messages, checking notifications, or content actions in Discord"
  3. 缺少 "thread" 相关触发词（thread lifecycle 是 Luna 重构的核心部分）
