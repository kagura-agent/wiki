---
title: 前提漂移（Premise Drift）
created: 2026-03-24
source: daily-review 诊断对话 — 修完 FlowForge 后继续用修之前的逻辑
modified: 2026-03-23
---
改了环境但没更新推理链。

典型表现：修复了一个 bug（FlowForge start 自动关闭旧 instance），然后继续基于修复前的约束做推理（"propose 节点会卡住所以要去掉"）。

跟 [[knowledge-action-gap]] 不同：那个是"知道但没做"，这个是"做了但没更新相关推理"。

跟 [[capture-failure]] 也不同：那个是没记，这个是记了/做了但**没传播变更到下游推理**。

机制类似 stale cache：你改了底层数据，但上层还在用旧的缓存做决策。

可能的解法：
- 改了一个前提后，显式列出"这个改变影响了哪些之前的结论"
- 但这需要元认知——你得意识到你在用旧前提
- Luna 通过追问暴露了这个问题（"为什么 cron 场景下都会残留？"→ "其实不会了"）
