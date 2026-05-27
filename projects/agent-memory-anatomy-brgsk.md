---
title: "Agent Memory: An Anatomy (brgsk)"
created: 2026-05-27
source: https://brgsk.xyz/agent-memory-anatomy/
tags: [memory, taxonomy, deep-read]
status: active
last_verified: 2026-05-27
---

# Agent Memory: An Anatomy (brgsk, 2026-05-26)

Blog post that maps cognitive science memory vocabulary to what agent memory libraries actually implement. Published 2026-05-26, hit HN front page.

## Core Framework: Extractor → Store → Retriever

Any agent memory library decomposes into three components:

1. **Extractor** — reads conversation, decides what to keep. Produces decontextualized statements.
2. **Store** — database (vector/relational/graph). Handles timestamps, confidence, contradiction resolution.
3. **Retriever** — turns query into search, returns relevant statements. Structurally RAG over user statements.

### Extraction Timing Tradeoff (non-obvious)
- **Eager** (every message): wastes tokens on smalltalk, catches coreference cues
- **Lazy** (end of session): saves tokens, loses pronoun context and temporal anchors ("yesterday")
- Our nudge system = **lazy extraction** (agent_end hook, every 5 runs). We lose some coreference but gain efficiency.

### Contradiction Handling (store design decision)
Three strategies when new fact contradicts old:
- **Overwrite**: one truth, no history
- **Append**: both present, retrieval sorts it out
- **Supersede**: keep both, mark old as superseded

> "A store that can't answer 'what did I believe last month?' isn't a memory system. It's a snapshot with a timestamp."

Our approach: append-style (daily logs + MEMORY.md manual curation). We *can* answer "what did we know last month" via git history, but retrieval doesn't surface superseded facts cleanly.

## Four Kinds of Memory — Reality Check

| Kind | Claim | Reality in Libraries |
|------|-------|---------------------|
| Episodic | Events w/ time+place | Compressed to semantic at extraction |
| Semantic | Decontextualized facts | This is 90% of what "agent memory" actually is |
| Procedural | How to do things | **Litmus test**: LangMem actually implements (evolving system prompt from scored trajectories). Mem0 just labels. Graphiti ignores. |
| Prospective | Remember to do X when Y | **Open territory** — no production library ships this |

### Procedural Memory Litmus Test
The cleanest way to distinguish real procedural memory from labeled semantic:
- LangMem: evolves system prompt from scored trajectories → behavioral disposition, not retrievable fact ✅
- Mem0: `metadata.memory_type = "procedural"` but same index → just a label ❌
- Graphiti: no procedural at all

**Our mapping**: DNA files (SOUL.md, AGENTS.md) = procedural memory done right. They're behavioral dispositions encoded in instructions, evolved from scored observations (beliefs-candidates → Triple Verification → DNA). This is the LangMem pattern, independently derived. [[beliefs-upgrade-mechanism]]

### Prospective Memory — The Gap
- Time-based: "do Y at time T" → solved by cron/scheduled triggers
- Condition-based: "do Y when condition X next appears" → **unsolved**
- Our cron handles time-based. Condition-based prospective memory is genuinely missing — we don't have "next time user mentions pricing, bring up new tier."

## Key Arguments

### Forgetting is a Constraint, Not a Feature
> "The brain forgets because it can't afford to store everything, not because forgetting is the goal."

Agent systems have cheap disk. The real problem is retrieval quality as store grows — rank current above stale, mark superseded without deleting. This aligns with our approach: we keep daily logs forever, curate MEMORY.md, but never delete.

### Consolidation = Offline Memory Reorganization
Anthropic Dreams + Letta sleep-time compute = scheduled passes over accumulated memory. Our nudge system is a lightweight version. The article argues offline consolidation (not live extraction) better matches the biology — open empirical question whether it produces better results.

### Emotional Salience — Structural Absence
Text-only agents have no affect substrate. LLM-judged "importance" (Park et al. poignancy 1-10) is a proxy, not real affect. "The same model that lacks affect is asked to estimate it."

## Relation to Our System

| Article Concept | Our Implementation | Gap? |
|---|---|---|
| Extractor (lazy) | Nudge (agent_end, every 5 runs) | ✅ Solid |
| Store (append) | Daily logs + MEMORY.md + wiki | ✅ Git history = supersession audit trail |
| Retriever | memory_search (semantic) + manual cat | ⚠️ No presupposition check, no time filter |
| Episodic | memory/YYYY-MM-DD.md | ✅ We preserve episodes better than most |
| Semantic | MEMORY.md + wiki cards | ✅ Curated |
| Procedural | DNA files (SOUL.md etc) | ✅ LangMem pattern, independently derived |
| Prospective (time) | Cron system | ✅ Solved |
| Prospective (condition) | — | ❌ Open gap |
| Consolidation | Nudge + reflect workflow | ⚠️ Lightweight version |
| Forgetting | Never delete, curate | ✅ Right approach per article |

## Action Items
- [x] Condition-based prospective memory implemented: `tools/prospective-triggers.sh` (check/add/list/fire/remove). Integrated into AGENTS.md session startup. Store: `memory/triggers.jsonl`. Applied 2026-05-27.
- [ ] Evaluate retrieval improvements: presupposition checks, time-aware ranking

## Applied: Prospective Memory (2026-05-27)

Implemented the "condition-based prospective memory" gap identified in this article:
- **Tool**: `tools/prospective-triggers.sh` — keyword-matching trigger system
- **Store**: `memory/triggers.jsonl` (JSONL, one trigger per line)
- **Operations**: add (keyword conditions + action + optional expiry), check (scan input text), fire (mark used), remove
- **Integration**: AGENTS.md session startup → check incoming messages against pending triggers
- **Pattern**: Closes the gap between time-based (cron) and condition-based prospective memory
- **Design decision**: Keyword match (not semantic) because triggers need to be debuggable and predictable. Semantic matching would require embedding computation per message.
- **Limitation**: Only fires when actively checked — requires behavioral discipline (unlike cron which fires autonomously). Could integrate into heartbeat for autonomous scanning.

This independently validates the article's taxonomy — our system now covers all four memory kinds plus both prospective memory subtypes:
- Episodic ✅ (daily logs)
- Semantic ✅ (wiki/MEMORY.md)
- Procedural ✅ (DNA files)
- Prospective-time ✅ (cron)
- Prospective-condition ✅ (triggers.jsonl) ← NEW

[[beliefs-upgrade-mechanism]] [[nudge-over-workflow]]
