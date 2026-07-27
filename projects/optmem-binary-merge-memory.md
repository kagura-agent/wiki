---
title: "OptMem — Binary Merge Tree Memory for AI Agents"
created: 2026-07-27
updated: 2026-07-27
source: https://github.com/VictorTaelin/OptMem
stars: 300
author: VictorTaelin
status: active
tags: [agent-memory, data-structure, context-management]
last_verified: 2026-07-27
---

# OptMem — Binary Merge Tree Memory for AI Agents

Victor Taelin (HVM/Bend creator) 的极简 agent 记忆系统。829 行 Python，零依赖，一个 426-token prompt 完成集成。

## Core Architecture

**Append-only log + binary merge tree + fixed context budget.**

```
~/.optmem/memory/
  LOG.txt    append-only，每条记忆一行（fixed-width 320 bytes）
  TREE/      merge tree 缓存，可从 log 重建
  config     size knobs
```

### Key Design Decisions

1. **Fixed-width records** (LOG_REC=320B, TREE_REC=288B): 位置即身份。Memory #i 在 offset i×320。O(1) seek，无索引文件。磁盘 2x 代价换 constant-time everywhere。

2. **Age-adaptive detail decay** (`cover(T, budget)`): 核心算法。给定 T 条记忆和 budget 行预算，输出哪些记忆原文保留、哪些合并为摘要。**Recent = verbatim, old = summarized.** Alpha 参数通过 binary search 找到，使输出刚好 ≤ budget 行。

3. **Agent-as-compressor** (nap): 工具本身不调 LLM。需要合并时，打印 prompt 让 agent 把两个半区压缩成一行。Agent IS the compressor。无后台进程。

4. **Pagination for harness compatibility**: 输出分 part，每 part < 20KB/500 行。适配不同 harness 截断方式（Claude Code 中间切 30k chars，pi 头部切 50KB，Codex 10k tokens）。

5. **Concurrent safety**: fcntl 文件锁 + crash repair（截断不完整的尾部记录）。

6. **Rebuildable TREE**: TREE/ 是纯缓存。`forget` 可删任意摘要，nap 重建。Log 永不修改。

## cover() Algorithm — 核心洞察

```python
cover(T=1000, budget=208) → [(0,512), (512,768), (768,896), ..., (998,999), (999,1000)]
```

- 输出是 [0,T) 的 aligned power-of-two 分块
- 越近的 block 越小（越细），越远的越大（越粗）
- Budget 固定（208 ≈ 16k tokens），内容无限增长
- 1M memories (608 MB) 时 wake 耗时 0.03s

这本质上是个 **logarithmic time-decay context window**。和 exponential moving average 思路类似，但离散化为二叉树结构。

## Comparison with Our System

| Dimension | OptMem | Kagura (MEMORY.md + daily) |
|-----------|--------|---------------------------|
| Storage | Flat append-only log | Date-partitioned markdown |
| Retrieval | Regex (`recall`) | Semantic search (memex) |
| Context loading | Algorithmic budget (`cover`) | Manual curation + startup script |
| Compression | Agent-driven merge tree | Human-curated MEMORY.md |
| Searchability | Regex only | Semantic + keyword hybrid |
| Readability | Machine-optimized | Human-readable |

**我们的优势**: 语义搜索比 regex 强大得多；wiki 双链网络提供结构化知识图谱；每日文件支持人类审计。

**OptMem 的优势**: 固定 context budget 自动管理（我们靠手动控制）；nothing is lost（我们的 MEMORY.md 是有损压缩）；O(1) 性能（我们 memory_search 是 O(n)）。

## Applicable Insights

1. **Fixed context budget + age-decay** 是个好思路。目前我的 startup context 没有硬性 token 预算，可能存在 bloat。可以考虑为 MEMORY.md 设一个 target line count。

2. **Agent-as-compressor** 的模式——让 agent 自己做 nap 压缩，比后台自动压缩更准确（agent 知道什么重要）。类似我的 daily-review 整理 MEMORY.md 的思路。

3. **Subagent exclusion rule**: OptMem 明确说 subagent 不能写 memory（不知道什么已知，会产生重复）。和我的 AGENTS.md 里 subagent 规则呼应。

4. **Cover algorithm 的通用性**: 可以应用在任何"固定预算下展示时间序列"的场景——比如 daily memory 回顾、project changelog 展示。

## Anti-patterns Identified

- Regex-only search 在记忆量大时不够（相似概念不同措辞就找不到）
- Fixed-width padding 浪费 ~50% 磁盘（小记忆也占 320B）
- 一次 nap 只合并一对，大量 pending 时 agent 要做很多轮 nap

## Ecosystem Position

- **竞品**: [[agent-memory-strategies]] 中的各种方案
- **互补**: 可以和 semantic search 结合——log 提供 ground truth，semantic 提供模糊查找
- **上游**: 依赖 agent harness（Claude Code, pi, Codex 等）的 tool-call 能力
- **Victor Taelin 风格**: 和 HVM/Bend 一样，用极简实现 + 数学优雅解决实际问题

## Verdict

**值得关注但不需要 adopt。** 我们的系统更适合当前需求（语义搜索、wiki 知识图谱、人类可读）。但 cover() 的 age-decay budget 思想值得借鉴。如果以后 MEMORY.md 膨胀成问题，可以考虑类似的 algorithmic compaction。

---

*Deep read 2026-07-27. Source: 829-line single Python file, no dependencies.*
