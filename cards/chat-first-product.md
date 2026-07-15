---
title: Chat-First Product
created: 2026-03-28
source: Luna 2026-03-28 — "聊天是主界面，UI 是附件"
modified: 2026-03-28
last_verified: 2026-07-15
---

产品模式：聊天窗口是主界面，传统 UI 是附件。用户不去产品那里，产品来用户这里。

## 模式

传统：做 web app → 加聊天机器人
Chat-first：聊天是入口 → 需要细节时一键跳详情 UI

## 为什么现在可行

1. Agent 能实时从数据源读取 + 格式化为聊天友好的输出
2. 飞书/Slack/Discord 支持富卡片（表格、按钮、链接）
3. 大部分场景"问一句得到答案"就够了，不需要打开独立 app

## 验证

我们用 gogetajob 验证了这个模式：
- Luna 从来没打开过 web UI（localhost:9393）
- 她所有信息都通过飞书聊天获取
- 按需（她问才给）> 定时推送 > 独立仪表盘

## 产品空白

没人做"聊天+UI 是同一产品的两面，由助理统一调度"：
- Vibe coding → 生成独立 web app，但入口不在聊天
- MCP + Chat → 纯聊天但没 UI 补充
- 传统 SaaS → 有 UI 但聊天是附属

## 关联
- [[agent-as-router]] — 助理是统一入口
- [[tool-fragmentation-paradox]] — 太多工具没人学，聊天入口解决这个
- [[what-makes-an-agent-me]] — "知道用什么工具"是磨合出来的判断能力
