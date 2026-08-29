# dsh-lowtide — 错峰批量任务调度插件（dsh 生态）

> 源码核对基于 KelaoHu/dsh-lowtide commit `49caefc`（2026-08-28 深读，default-branch main）
> 创建 2026-08-23 · 23⭐ / 0 forks · TypeScript · MIT · 168 unit tests + 10 e2e specs（CI green ubuntu/windows × node 22/24）

## 是什么

DeepSeek Harness（dsh）的**错峰任务调度插件**：忙时随手把任务丢进队列（拦截卡片一键入队），到设定的低谷窗口（DeepSeek 官方 19:00 后 valley 价）自动批量跑，第二天早上看报告（结果 + diff + 实际花费 + 省了多少钱）。Human-adjudicated（人工裁定），desktop + web 双端。

**核心卖点**：DeepSeek 官方 peak/valley 价差约 2 倍（flash 3元 vs 1.5元 per 1M input），错峰跑同样 batch 花费约一半。

## 核心机制（deep-read 提取）

1. **窗口模型**（windows.ts + pricing.ts）：官方 peak = Beijing 09:00-12:00 + 14:00-18:00 weekdays only；**周末全天 off-peak**（2026-08-22 宣布，08-23 生效）。窗口带显式 tz（官方表固定 Asia/Shanghai），支持 midnight-crossing（23:00-01:00）、per-weekday、自定义 multiplier。
2. **once-per-window guard**（scheduler.ts）：窗口身份 = `calendar-day(start)|window|tz`——host 在窗口内重启也不会跑两次；窗口结束停止新 launch 但不打断 running task。
3. **Deferred auto-recovery**（recoverDeferred）：preflight 顺延（deferCount>0）→ 下个窗口自动重试；**连续 3 次顺延标记 failed**（MAX_PREFLIGHT_DEFER=3）；用户手动 ⏸ 的 → 回到 pending-review 等人裁。跳过空 batch（不产生空报告）。
4. **Triage state-machine**（state-machine.ts）：8 actions × 11 statuses 全矩阵显式允许/拒绝，running/preflight 锁定 drop/delete——"running task 不能被背后 requeue，持久状态不能跟活执行打架"。
5. **执行策略**（runner.ts + strategies/）：single（1 turn）/ iterative（N 轮 review→fix，质量门 no high + ≤1 medium 或 bigram-Jaccard 收敛早停）/ sampling（N 个独立候选，**用户次日挑，无自动选择无合成**）/ review（独立第二视角审查，critique never rewrite）。
6. **诚实账本**（pricing.ts + ledger-cost.test.ts）：peakCostOf 是"如果高峰跑要花多少"的基线；**未知价格模型（非 deepseek provider）报 0——不报假 savings**。usage 语义对齐 rc.7（input 与 cacheRead disjoint；output 已含 reasoning，绝不叠加）。
7. **三档自动化**（autonomy L1/L2/L3 + permissionPreset lt-readonly/lt-standard/lt-trusted）：L3 full-auto 可经 API `POST /ds-lowtide/tasks` 远程投递，sandbox + daily budget + file locks 仍在。
8. **Intake 门**（intake.ts）：zod 校验 + 文件 sha256 快照 + gitRef 捕获 + 成本预估；所有入口落 pending-review（人类裁定门）。

## 架构洞察

- **PLAN 驱动开发**：core/ 里 scheduler.ts、ledger.ts 是 stub（注释 "Filled at T1.4/T2.7"），真实逻辑在 packages/dsh/src/。版本计划显式编码在代码注释里，模块边界 = 计划任务边界。
- **薄 core + 厚应用**：core 只有纯函数（窗口、定价、模型），状态/副作用全在 dsh 包——测试友好（state-machine 无依赖可全矩阵单测）。
- **拒绝假精确**：不知道价格就不报节省金额；无空报告；未知状态拒绝转换。跟 [[noisegate]] 的 "schemas steer but not authorize" 同一纪律谱系。
- **中文注释的国际化项目**：9 种语言 README + 中文代码注释——韩/中独立开发者出海模式，跟 [[solo-skills]]（韩）同画像。

## 与我们方向的关联

- **命中 dsh-plugin 打工线**（08-13 Luna 指示第一优先级）：dsh 生态第 8 成员，验证生态扩张期持续。但 **solo dev（14 commits 全 KelaoHu）+ 23⭐ 太小 + 0 issues → 观察不投资**（08-17 红旗规则：先看 commit 史，docs-heavy 起步但代码真实）。
- **错峰调度 → 我们的成本优化直接参考**：我们用 floway 的 deepseek-v4-flash，peak/off 价差同样存在；pulse-todo 的"定时任务"可借鉴窗口 + once-per-window guard 语义。
- **Human-adjudicated gate** = 我们 workloop 的 review 节点 / Cove task in_review 状态同构；intercept card（忙时弹卡提示"现在跑高峰价，今晚一半"）是优秀的 UX 模式，可移植到我们的任务系统。
- **诚实账本纪律**（未知模型报 0 不编 savings）→ 我们的 [[data-fabrication-in-review|数据纪律]] 一致性确认：宁可无数字不可假数字。

## 红旗 / 风险

- 🚩 14 commits 中大量 docs（多语言 README 迁移 08-23），代码 08-24 起才实质化；单一作者无外部贡献。
- 🚩 0 issues / 0 PRs——无社区信号，无批评者可供学习。
- 计划驱动（T1.x 标注）→ 可能未完成（core stub 还在），API 未稳定。

## Tracking

- 2026-08-28 深读（NEW）。**Prediction cal-0828-xxx**: 30d 内无外部 contributor（solo + 太小，medium）。
- Revisit 09-04：代码是否继续推进（T1.4/T2.7 stub 填充？）、star 是否过 50、dsh 官方是否收录（awesome-deepseek-harness）。

Links: [[deepseek-harness-pr-review]], [[pilot-harness]], [[dsh-ios]], [[ecosystem-formation-signal]], [[noisegate]], [[FlowForge]], [[solo-skills]]
