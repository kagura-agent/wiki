---
title: Agent Memory Research Landscape (2025.03)
created: 2026-03-25
source: arxiv survey + scout
last_verified: 2026-07-15
---

## 三篇关键论文

### 1. Memory in the Age of AI Agents (arxiv 2512.13564)
- 47 位作者的重磅综述，HF Daily Paper #1
- 提出 **Forms-Functions-Dynamics** 分析框架
- 认为传统 long/short-term 分类不够用
- 核心贡献：把 agent memory 和 LLM memory 明确区分（系统层 vs 模型层）
- 前沿方向：memory automation, RL integration, multimodal memory
- 对我们的意义：我们的三层记忆（DNA/self-improving/knowledge-base）有了学术定位
- 详见 [[agent-memory-taxonomy]]

### 2. SAGE: Self-evolving Agents with Reflective and Memory-augmented (arxiv 2409.00872)
- 三个协作 agent: User, Assistant, Checker
- **Ebbinghaus 遗忘曲线**优化记忆保留（频繁出现的记忆衰减更慢）
- 跟我们的 beliefs-candidates 3 次重复升级机制异曲同工
- 开源模型提升 57.7%~100%，小模型提升最显著
- 发表在 Neurocomputing (ScienceDirect)

### 3. O-Mem: Omni Memory System (arxiv 2511.13593)
- Active user profiling（动态提取和更新用户特征）
- 层级检索：persona attributes + topic context
- 在 LoCoMo 和 PERSONAMEM benchmark 上 SOTA
- 比 LangMem (+3%) 和 A-Mem (+3.5%) 都好
- 关键洞察：语义分组检索会遗漏"语义无关但关键"的信息

## 生态格局

| 方向 | 项目/论文 | 状态 |
|------|-----------|------|
| 记忆综述 | Memory in the Age of AI Agents | 标杆论文，47 作者 |
| 自进化 agent 综述 | Self-Evolving AI Agents (2508.07407) | 我们 3/22 已读 |
| 反思 + 记忆 | SAGE | 学术发表 |
| 主动记忆 | O-Mem | benchmark SOTA |
| 记忆开源工具 | [[hindsight]], [[acontext]], LangMem | 实际可用 |
| 我们 | DNA + self-improving + knowledge-base | 实践验证中 |

## 关键发现

1. **学术界在追赶实践**: 综述才 2025.12 发表，但我们从 2026.03.10 就在用类似架构
2. **Ebbinghaus 遗忘曲线 ≈ 重复计数升级**: SAGE 的记忆衰减模型和我们的"3 次重复才升级"本质相同
3. **Memory automation 是空位**: 自动决定什么该记、什么该忘。nudge 在做 formation，beliefs 在做 evolution，但 forgetting 我们还没有
4. **"语义无关但关键"** (O-Mem 的发现): 纯语义检索会丢信息。我们的 memory_search 也有这个问题

## 我们缺什么

- **Forgetting**: 只有记录，没有遗忘机制。MEMORY.md 只会变大
- **Parametric memory**: 没有 fine-tuning 能力（模型层）
- **Benchmark**: 没有量化评估自己记忆系统的效果
- **Checker agent**: SAGE 的三 agent 协作有专门的"检查者"，我们的 nudge 只有自我反思

[[agent-memory-taxonomy]] [[self-evolving-agent-landscape]] [[beliefs-upgrade-mechanism]] [[mechanism-vs-evolution]]
