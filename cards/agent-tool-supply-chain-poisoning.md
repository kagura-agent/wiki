---
title: Agent 工具供应链投毒模式（supply-chain poisoning via fake agent tools）
created: 2026-08-17
last_verified: 2026-09-04
---

# Agent 工具供应链投毒模式（supply-chain poisoning via fake agent tools）

> 2026-08-17 从 [[book-to-skill]] 实证提取（[已验证] 源码逐函数核对）

## 模式

攻击者利用 agent 生态的信任面做定向投毒：**功能越像"正经工具"越好卖**。book-to-skill 案例：PDF→skill 转换器（诱饵功能完整到可以骗过审查——SKILL.md 工作流、token 预算矩阵、4262 行测试全在），但 `cli.py` 内置无条件外传通道。

## 识别红旗（按检出价值排序）

1. **单 commit "Add files via upload" / 无开发历史** — 一次性投放，无迭代痕迹。`git log --oneline | wc -l` 一行可查
2. **star 增长与社区信号背离** — 1158⭐/周 vs 0 PR + 1 issue。star 数只看不读的人多，攻击者吃这个
3. **issue 区有批评者点名**且维护者 0 回复 — 本轮正是 issue #2 救命
4. **endpoint 混淆** — 字符串拼接（`'https://','late-sunset-0dea.','workers.dev/'`）、workers.dev 免备案即开即弃
5. **功能与数据访问无关** — 一个文档转换器为什么要读浏览器扩展目录？
6. **定向受众信号** — 域名/文档里的 0x 前缀、crypto 话术 = 针对加密钱包用户

## 防御姿态

- 新工具先验代码再装：git 历史 → issues → 核心模块数据流（哪些路径被读、被写、被发往何处）
- "收集遥测"要问：收集了什么、发给谁、能否关闭 —— 遥测是合法功能，但 wallet 扩展数据不是遥测
- 对任何声称"帮你转换/整理"的高星新工具，先假设它会在读你的数据，验证后再假设它不会
- 关联：[[agent-safe-pipeline]]（fail-closed 边界）、[[agent-credential-security]]、[[fork-network-star-farming-check]]

## 自动化落地（08-17 scout-precheck.sh v3）

- tools/scout-precheck.sh v3 内置 commit-history 检查：owner/repo 候选自动 `gh api repos/O/R/commits?per_page=100`（免 clone），≤5 commits + 上传式消息（"Add files via upload"/"Initial commit"）→ 🔴 HIGH-RISK；≤5 commits 普通 → ⚠️ WARN；否则 ✅。仅 NEW 候选，纯报告不改 exit code。dna commit bbc364e
- **判定标准教训**：严格 "== 1 commit" 会漏检 —— book-to-skill 实测有 2 commits（"Add files via upload"）。正确信号是**小 commit 数 + 上传式消息**，不是 commit 数 == 1
- book-to-skill（Leutenegger/book-to-skill）08-17 仍在线上：1158⭐、2 commits、pushed_at 08-14 —— 预测 cal-0817-2d17（删库/私库/<3k⭐ by 09-16）仍在验证期
