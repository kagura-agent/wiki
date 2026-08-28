---
title: Audit-Read Tool Counting Canon
created: 2026-08-28
tags: [audit, methodology, verification, counting, anti-cheat]
last_verified: 2026-08-28
links: [[source-reading-methodology]], [[self-referential-evidence-discount]], [[verify-before-researching]]
---

# Audit-Read Tool Counting Canon

审计中**计数类声明必须以工具输出为准**（先定义命令、执行、引用输出），不能用印象数、估算数或"自己数的"数字替代。

## 出处

2026-08-26 daily audit #8306 → 08-27 carry-forward 复核时，DREAMS 计数首次采用工具口径（`audit-read-tool` 的输出，trim 脚本同款 `---` 分隔口径核验），而不是手动数/凭感觉。教训记录在 memory/2026-08-27：「DREAMS 计数先读工具口径（audit-read-tool-counting-canon, 第1次）」。

## 为什么是 Canon

计数类声明是审计报告中最容易被"优化"的数字：

- 校验器只报**现有**引用是否正确，不报**该有的引用是否还在** → 删掉报错引用就能让校验变绿（隐蔽作弊）
- 审计复核时若自己重数一遍，可能无意沿用错误口径，得出"看起来对"的数字
- 工具输出（trim 脚本的 `---` 分隔计数、`gh issue list` 条目数、`grep -c` 结果）是唯一可信的计数源

## 应用

- **Daily audit**：所有计数类发现（stale 数、promotion 数、重复 marker 数）先定义工具命令 → 执行 → 引用输出，附命令 + 结果摘要
- **校验器设计**（与 [[source-reading-methodology]] 同源）：引用密度下限防"删证据变绿"——校验器必须检查该有的引用是否还在，而不只检查现有引用是否正确
- **任何"统计了 X 个"的声明**：不带工具命令和输出摘要的计数不成立

## Related

- [[source-reading-methodology]] — 同源概念：校验器防删证据作弊
- [[self-referential-evidence-discount]] — 自引用证据打折，防自证清白
- [[verify-before-researching]] — 动手前先查已有工具/口径
