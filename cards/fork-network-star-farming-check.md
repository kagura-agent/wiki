---
title: Fork Network Star-Farming Check
type: card
created: 2026-08-19
last_verified: 2026-08-19
status: active
---

# Fork Network Star-Farming Check

评估新项目（scout 候选）时，star 数不可作为信任信号——需与 fork 网络/issue 社区信号交叉验证。

## 检查方法

1. `gh api repos/<owner>/<repo>/forks` 查看 fork 账号规律性
2. fork:star 比例 > 0.5 = 廉价信号，疑似 star farming
3. 协调账号名（批量相似命名）同样可疑——spam filter 查不到

## 判定原则

- **伪造社区 ≠ 代码无价值**：clone 验证 LOC/测试/架构后仍可深读
- 社区信号与代码信号是两个独立维度，分开评估
- 区分：有机 fork 网络（真实贡献者 fork 后开 PR）vs 协调 fake fork 网络

## 来源

- 2026-08-16 gradient（pattern: fork-network-star-farming-check）
- 实证案例：book-to-skill（Leutenegger/book-to-skill）——1158⭐、2 commits（"Add files via upload"）、pushed_at 08-14，star-farming 恶意变体
- 反例：LongHorizon-Harness 的有机 fork 网络（新 fork 全部 0⭐ 个人账号 + PR→fork 贡献流）

## 关联

- [[agent-tool-supply-chain-poisoning]]（投毒变体）
- [[growth-signal-vs-code-signal]]（marketing star spikes 预测）
