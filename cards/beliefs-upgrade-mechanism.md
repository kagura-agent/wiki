---
title: Beliefs Upgrade Mechanism
created: 2026-03-25
source: 实践观察 + MemSkill designer 模式类比
last_verified: 2026-07-15
---

## 定义
beliefs-candidates.md 中积累到重复 3 次以上的 gradient，升级到对应 DNA 文件（SOUL.md / AGENTS.md / NUDGE.md）的过程。

## 机制
1. Luna 反馈 → beliefs-candidates.md（text gradient）
2. 计数重复次数
3. ≥ 3 次 → 考虑升级到 DNA
4. 升级后飞书通知 Luna

## 与 MemSkill designer 的类比
| 维度 | MemSkill designer | Kagura beliefs upgrade |
|------|-------------------|----------------------|
| 输入 | hard cases (QA 失败) | Luna 的 text gradient |
| 频率 | 每个 epoch | daily-review (凌晨 3:00) |
| 输出 | 改进/新增 skills | 升级 DNA 文件 |
| 自动化 | 完全自动 | 半自动（需手动判断） |

## 关键教训（2026-03-25）
- **不区分类型**：信息类和信念类 gradient 走同样的 3 次验证，不开例外
- **已有规则不算完成**：数据纪律写进 AGENTS.md 后仍重复 7 次，说明规则不够具体或位置不对
- **隐私泄露达到升级阈值**：3 次，待下次 session 升级

[[self-evolving-agent-landscape]] [[mechanism-vs-evolution]]
