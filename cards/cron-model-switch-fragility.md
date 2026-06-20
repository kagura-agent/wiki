---
title: Cron Model Switch Fragility
created: 2026-06-17
last_verified: 2026-06-20
tags: [cron, model-routing, failure-mode, runtime-stability]
status: observed
depth: reference
---
# cron-model-switch-fragility

> 当 LLM gateway 切换 model 版本（如 opus-4.6 → 4.7）时，in-flight 和邻近时间窗的 cron 运行会以多种形式失败。切换不是 hot-swap。

## 观察（2026-06-17 memory-eval cron）

在 ~19:00-22:40 的 model 切换窗口（claude-opus-4.6 → 4.7）内：

| 时间 | 状态 | 失败模式 |
|---|---|---|
| 18:40 | error | Edit failed (298s timeout) — agent 已开始 turn，最后写文件时挂了 |
| 19:00 | error | "⚠️ ⏰ Cron failed" 空 diagnostic |
| 19:40 | error | LLM request failed: provider rejected the request schema or tool payload |
| 22:40 | error | cron: job interrupted by gateway restart |
| 21:40 (4.7) | ok 但 delivered=false | fallback path 走通了但消息没投递 |

期间 model 字段在 cron run history 中体现为 4.6 → 4.7 的硬切换。consecutive errors 累计到 4。

## 失败模式分类

1. **Schema rejection** — 新 model 不接受旧版本的 tool/schema 编码
2. **In-flight kill** — gateway restart 中断正在执行的 turn
3. **Timeout amplification** — 切换后第一次调用响应慢，叠加 in-prompt 的工具 turns，达到 cron 整体 timeout
4. **Silent fallback** — 走通了但投递路径异常（fallbackUsed=true, delivered=false）

## 影响

- 看似稳定的 cron job 在 model 切换窗口集体失效
- consecutive errors 飙升触发 failure alert（如果有）
- 失败的 cron 没有自动 reschedule — 下一次 fire 还是按原 cron expr 等
- 用户/agent 误以为 cron 本身坏了，开始调试 cron expr/逻辑（实际是 model 问题）

## 处置建议

1. **Cron health monitor**：consecutive errors ≥ 3 → 飞书一次性 alert（避免飞书刷屏）
2. **Auto-reschedule on schema/restart errors**：识别"非业务错误"，5min 后重试一次
3. **Model 切换 announce**：gateway 提供 model swap 事件，cron 系统跳过/延后切换窗口的运行
4. **In-flight tolerance**：cron run record 应区分 "model error" / "business error" / "infra error"，便于 audit 不混淆

## 相关

- [[cron-observability-metrics]] — 失败原因维度需要分类标签
- [[cron-runaway-safety]] — restart 中断也是 runaway 的一种形式（资源没收回）

## 后续

填一个 openclaw upstream issue 描述这个 pattern，建议 gateway 提供 model-swap event hook。
