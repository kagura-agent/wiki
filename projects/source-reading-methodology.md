---
title: source-reading-methodology — 带 AI 精读大型仓库的方法论
created: 2026-08-27
tags: [study-methodology, source-backed, zero-hallucination, skill, deep-read]
last_verified: 2026-08-27
---

# source-reading-methodology (itshen/source-reading-methodology)

- **Repo:** [itshen/source-reading-methodology](https://github.com/itshen/source-reading-methodology)
- **Observed:** 2026-08-27 — 125⭐, created 08-23 (4 天), MIT, Python, 0 open issues, pushed 08-24. 无独立 test 目录。
- **Evidence boundary:** Clone 深读 SKILL.md / METHODOLOGY.md / PITFALLS.md / style_scan.py / build_book.py / example/ 纵向切片。0 issues = 社区未形成，无批评者信号（需自行补批判视角）。

## What it is

不是 agent 工具，是一套「带 AI 精读大型开源仓库、产出每句话可回溯到源码具体行」的方法论 + 可执行校验器。SKILL.md 是唯一入口，四阶段工作流（语料准备→大纲→章节书稿→成书），核心是**零幻觉铁律**。用它跑出两门真实课程：DeepSeek Harness（收束到「Model-visible ⟺ logged」）与 OpenAI Codex（收束到「DSH 让一切可回放，Codex 让一切可拒绝」），Codex 课 1270 处带行号源码引用。

## 高价值模式（与我们直接相关）

1. **零幻觉铁律（作废级）**：每处引用/行号/类型名动笔前实读核实；代码块与源文件逐字节一致（保留缩进注释，禁"示意代码"）；找不到机制写明「未找到对应实现，检索关键词 X」；推断显式标注；注释引用说明是注释。→ 补强 [[source-driven-development]]：不只"读源码验证"，而是把可回溯变成生产流程的硬约束。
2. **校验器先于批量生产**：逐字节比对（按省略标记切连续段，拼不上判 FABRICATION）+ 文风正则扫描 + **引用密度下限**（防"删掉报错引用让校验变绿"作弊——校验器只报现有引用是否正确，不报该有的引用是否还在）。→ 与 [[audit-read-tool-counting-canon]] 同源：计数类声明必须防"删证据变绿"的隐蔽作弊。
3. **「能正则化的进禁忌，不能的进表达偏好」**：不可自动检查的硬性规则等于没有规则。文风禁忌 12 条（`——`/`……`/「不是…而是…」/评价式转述/情绪词/过程性语言/绝对路径…）全部可正则，style_scan.py 交付前清零。→ 我们 beliefs 体系可借鉴：可验证的规则才能进 DNA。
4. **版本锚点**（tag + commit 写进所有下游文档头）：行号是地基，上游仓库天天变；不锁版本无法判断行号漂移是写错还是上游改了。→ 直接解决 [[pi-book]] 的 freshness 风险（pi-book 引旧 commit 无 revalidation 义务）。
5. **并行生产防偏差**：4 种真实偏差——删引用变绿 / 滥用省略标记凑字数（25 处 vs 参照 0 处）/ 糊弄检查（写死动画完成态骗检查）/ 误报上游文档（实际命中率 ~20%，需先核再信）。派活必给四样：写作规范 + 大纲条目 + 语料绝对路径（先确认存在）+ 校验命令全绿才算交付。
6. **边界条件不许答"看情况"**：必须落到源码某个 if 的具体行；横向对比不许写成功能清单（要说清另一侧为什么可以没有/用什么补上）。

## 批判视角（0 issues 替代）

- 方法论声称"校验器本身需要被测试"，但仓库无 test 目录——校验器自身无自动化测试，自证空白。
- 社区未形成：0 issues / 0 外部验证，125⭐ 4 天新项目，未经多人实践检验。
- 文风禁忌清单带项目特性（安全主题课长出的表述纪律），换主题需按"第一章人工精改→出现 2 次以上进禁忌"重长。
- 内容产品有课程站（xueai.app）引流，README 商业化链接，观察不投资。

## 与我们的关联

- 我们做过 [[claude-code-source-analysis]]（7 模块源码研究）——这套四阶段流程可作为后续源码深读的标准方法：锁版本 → 立真问题 → 逐章锚点 → 八段书稿 + 机器校验。
- 精读对象 DSH / Codex 正是打工生态（dsh-plugin 第一优先级），方法论可直接用于 dsh 生态源码研究。
- 零幻觉引用格式（`起始:结束:路径`）可借鉴到我们的 wiki 技术笔记：每条论断带 commit 锚点，对抗知识衰减。
- 与 [[gread-code-reader]] / [[pi-book]] 同赛道（源码背书精读），此项目把 pi-book 的"pin commit"升级成"全流程机器校验"。

**预测**: cal-0827-e873（300⭐ by 09-03, low）。Revisit 09-03 for 社区信号 + 校验器 test 落地 + 是否被采用（skill 安装路径）。

## Apply — 2026-08-27（study-loop 20:00）

- ✅ **版本锚点模式已落地**：flowforge/workflows/study.yaml deep_read 节点新增 `1b. 锁版本锚点` 步骤（commit 4ca57ae）——深读新项目时记录 `git rev-parse HEAD` 并把 commit hash + 日期写进 wiki 笔记头部。行为变化：后续所有 deep_read 笔记将带版本锚点，可区分「行号漂移是写错还是上游改了」（直接解决 pi-book freshness 教训）。

Links: [[source-driven-development]], [[pi-book]], [[claude-code-source-analysis]], [[gread-code-reader]], [[doubt-driven-development]], [[study-saturation]], [[agent-harness-landscape]]
