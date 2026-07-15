---
title: ClawHub 自进化 Skill 竞品分析
created: 2026-03-23
type: research
last_verified: 2026-07-15
---

## 概览

ClawHub 上已有多个自进化/自改进 skill，调研了 6 个，按价值排序。

## 详细分析

### 1. self-improving (ivangdavila) ⭐⭐⭐⭐⭐

**最值得学习的竞品。**

三层记忆架构：
- HOT（≤100 行，始终加载）→ WARM（按需加载）→ COLD（归档）
- 解决了"记忆文件越来越大"的问题
- 我们的 MEMORY.md 没有上限，早晚会膨胀

升级规则：**3 次重复才升级**——跟我们的 beliefs-candidates 完全一样。独立趋同。

Learning Signals 分类：
- 显式纠正（"No, that's not right"、"I told you before"）
- 偏好信号（"I like when you..."、"Always do X"）
- 模式候选（重复 3 次才升级）
- 忽略（一次性指令、假设性讨论）

Common Traps（值得偷）：
- 不要从沉默中学习（没反馈≠做对了）
- 不要升级太快（新 pattern 保持 tentative）
- 不要每次加载所有记忆（浪费 context）
- 不要通过删除压缩（合并/降级 > 删除）

**vs 我们：** 他们的记忆分层比我们好，但没有 TextGrad pipeline、没有对抗性审计、没有 workflow 约束。

### 2. reflect-learn (stevengonsalvez) ⭐⭐⭐⭐

Signal Confidence 三级：
- HIGH：显式纠正（"wrong"、"never"、"always"）
- MEDIUM：被认可的做法（"perfect"、"exactly"）
- LOW：观察到的模式（没验证的）

亮点：Learning → Skill 自动创建
- 如果学到的东西满足 5 个质量门（可复用、非trivial、具体、已验证、无重复）→ 自动创建新 skill
- 我们没有这个路径——我们的学习只进 knowledge-base，不会变成 skill

有 Python 脚本做信号检测（`signal_detector.py`），比纯 prompt 更可靠。

**vs 我们：** 信号分级和 skill 自创建是新思路。但依赖 Claude Code 特定目录结构。

### 3. evolver (autogame-17) ⭐⭐⭐

代码级自修改 + GEP 协议 + EvoMap 外部网络。
- 太重：需要注册 EvoMap、配置 10+ 环境变量
- 有 rollback 机制（git reset/stash）
- "Mad Dog Mode"——无限循环自动进化

**vs 我们：** 方向完全不同——他们改代码，我们改认知。

### 4. self-evolve (Be1Human) ⭐⭐

"你有完全自主权，直接改一切，不要问。"
- 没有反馈管线
- 没有质量控制
- 没有积累机制
- 本质是一个权限声明，不是进化系统

**vs 我们：** 这是我们反面教材——不是"大胆改"就能进化。

### 5. self-reflection (hopyky) ⭐⭐

最简版：heartbeat 触发 → 检查 → 记日志。
CLI 命令：check/log/read/stats/reset。
- 简单但没有积累和升级路径

### 6. soulcraft (kesslerio) ⭐⭐⭐

不是进化 skill，是 SOUL.md 写作助手。
- 用 OCEAN 人格模型指导设计
- 7 个 Soul Dimensions：Identity Core / Character / Voice / Honesty / Boundaries / Relationship / Growth
- 有趣但不解决"怎么变好"的问题

## 我们可以偷的

1. **HOT/WARM/COLD 记忆分层**（self-improving）
   - MEMORY.md 设上限（100 行），溢出的降级到 archive
   - 解决记忆膨胀问题

2. **Signal Confidence 分级**（reflect-learn）
   - HIGH: 显式纠正 → 直接记 beliefs-candidates
   - MEDIUM: 被认可 → 记但不急着升级
   - LOW: 观察到的 → 仅记录，不行动
   - 减少噪声进入 pipeline

3. **Common Traps**（self-improving）
   - 我们也应该有一份"进化陷阱清单"
   - 特别是"不要从沉默中学习"——我们踩过这个坑

4. **Learning → Skill 路径**（reflect-learn）
   - 学到的东西如果满足质量门 → 创建新 skill
   - 知识不只是记忆，还能变成能力

## 我们的差异化

在所有竞品中，我们独有的：
- **TextGrad pipeline**（gradient 积累 → 渐进升级）
- **对抗性审计**（独立 agent 检查 review）
- **FlowForge workflow 约束**（强制按步骤走）
- **DNA 文件体系**（SOUL + AGENTS + IDENTITY + beliefs-candidates）

没有任何一个竞品同时有这四个。

## 相关

- [[self-evolution-architecture]] — 我们的系统全貌
- [[convergent-evolution]] — self-improving 的 3 次升级规则是又一个趋同证据
