---
title: PMB — Local-First Persistent Memory for AI Coding Agents
slug: pmb-memory
tags: [agent-memory, mcp, sqlite, vector-search, local-first]
created: 2026-06-26
updated: 2026-07-20
status: deep-read
last_verified: 2026-07-20
---

# PMB — Local-First Persistent Memory for AI Coding Agents

> oleksiijko/pmb | 87⭐ | Apache-2.0 | Python | Created 2026-05-25

Local-first persistent memory for AI coding agents (Claude Code, Cursor, Codex) over MCP. SQLite as durable source of truth, LanceDB for vectors, BM25+vector hybrid search with cross-encoder reranking and entity graph PPR. No cloud, no API keys, no LLM on read path.

## Architecture

```
Agent → MCP stdio → PMB Daemon (shared warm process)
                      ├── Engine
                      │   ├── SQLite (durable events)
                      │   ├── LanceDB (vector embeddings)
                      │   ├── BM25 (rank-bm25, in-memory rebuild)
                      │   └── Entity Graph + PPR
                      └── Embed Queue (async, write-decoupled)
```

### Key Design Decisions

1. **SQLite-first, vectors-second**: Writes hit SQLite immediately (sub-ms), embeddings computed asynchronously in background queue. Writes never block on embedding.
2. **Shared daemon**: One warm process (model + LanceDB + BM25) serves N connected agents. Avoids ~1-2s cold start per recall.
3. **Hybrid search**: BM25 + dense vector (sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2, 384-dim) + optional cross-encoder reranking (ms-marco-MiniLM-L-6-v2).
4. **Entity graph + Personalized PageRank**: Co-occurrence graph built from events, PPR diffuses probability for multi-hop retrieval (HippoRAG trick, NeurIPS 2024). Pure CPU, ~5-20ms. Solves "what did Alice do after meeting Bob?" without LLM at read time.
5. **Lessons as first-class**: Auto-surfaced with every `recall()` call, each with `surface_id` for follow-through confirmation via `mark_lesson_followed()`.

### Memory Types

- **Events**: decisions, lessons, facts, completed tasks, goals — typed with metadata
- **Keyed facts**: key-value with time-travel (old values archived, never lost)
- **Project structure**: file purposes, symbol counts, git commit intents (LLM-summarized via Haiku)
- **PDFs**: indexed and searchable
- **Exploration memos**: cached analysis with content-hash freshness checking

## Novel Patterns

### 1. Exploration Memo Cache ⭐
`record_exploration(intent, conclusion, files)` + `recall_exploration(intent)`. Agent reads 5 files → reaches conclusion → memoizes keyed to content hashes. Next session: if files unchanged → `fresh` (skip re-reading). If files changed → `stale_files` lists what changed. **Token savings without quality loss.** This is the most interesting pattern for us — we re-read the same wiki/project files repeatedly. See [[git-backed-agent-memory]], [[brain-md]].

### 2. Lesson Follow-Through Tracking
Every surfaced lesson gets a `surface_id`. Agent calls `mark_lesson_followed(surface_id)` to confirm compliance. Creates a closed loop: lesson stored → lesson surfaced → lesson followed → follow-through recorded. Our [[beliefs-candidates]] lacks the "surfaced + confirmed" loop — we surface in DNA preflight but don't track whether the rule was actually followed in that session.

### 3. Async Embed Queue with Circuit Breaker
Write → SQLite (immediate) → embed queue (background) → LanceDB. Circuit breaker (`circuit_breaker.py`) handles embedding failures gracefully. Our gateway embedding can block the write path.

### 4. PPR for Multi-Hop Agent Memory
Build co-occurrence graph from events → Personalized PageRank with seed entities from query → score candidates by PPR mass of their entities. O(E) build, ~20 iterations to converge. Novel application of HippoRAG to agent memory — most agent memory systems stop at vector+BM25.

## Comparison to Our Approach

| Aspect | PMB | OpenClaw (us) |
|--------|-----|---------------|
| Storage | SQLite + LanceDB | Markdown files + git |
| Search | BM25 + vector + PPR + rerank | Hybrid semantic + keyword (gateway) |
| Write latency | Sub-ms (SQLite) → async embed | Direct file write |
| Read latency | ~35ms warm | Variable (index-dependent) |
| Schema | Typed events (decision/lesson/fact/goal) | Free-form markdown |
| Portability | Export to Markdown/JSON | Already markdown, git-native |
| Human readability | Requires CLI/dashboard | Natively readable files |
| Git integration | `track changes` (LLM-summarized) | Manual notes, native git |
| Graph retrieval | PPR on entity co-occurrence | None |
| Multi-agent sharing | Shared daemon, workspace-scoped | Session + MEMORY.md |

**Our advantages**: human readability, zero dependencies, git-native versioning, no daemon to manage, trivially portable.
**PMB advantages**: faster read path, structured types, graph retrieval, exploration caching, lesson follow-through.

## Update 2026-07-20: Community Transformation + Auto-Decay

**Stars**: 87 → 313 (+259%). Community: THRIVING 5/6 (25 merged PRs/30d, 4 unique PR authors, 6 external PRs/30d).

### New Architectural Additions

**1. Auto-Decay (PR#62)**: `apply_daily_decay` runs in daemon maintenance tick before archiving cold memories. Memories fade over time without explicit agent intervention. `w/(1+w)` saturation formula for graph-boost prevents runaway scores. This addresses the "no mechanism for memory quality control" weakness noted below — PMB now has autonomous memory curation.

**2. Read-Guard Removal (PR#62)**: Philosophical shift to "PMB informs, never blocks" — removed the mechanism that could gate reads. Permissive access philosophy.

**3. OpenAI Backend (PR#68, external contributor @jbendotnet)**: Multi-provider support via auto fallback (claude → anthropic → openai → ollama). No SDK dependency (stdlib urllib). Includes benchmark verification (LoCoMo accuracy + write-path latency). Notable: PR was created using OpenCode/GPT — agent-generated PR to an agent memory system.

**4. Dashboard + Live-QA Stability Fixes (PR#59, PR#64)**: Visualization layer + stability fixes from real-world QA testing.

### What Changed vs Original Assessment

| Original (06-26) | Now (07-20) |
|---|---|
| Solo dev, 87⭐, 0 PRs | THRIVING 5/6, 313⭐, 25 merged PRs/30d |
| No memory pruning | Auto-decay + graph-boost saturation |
| Claude/Ollama only | Multi-provider (Claude/Anthropic/OpenAI/Ollama) |
| No dashboard | Dashboard with port fallback |
| Fragile read-guard | Removed (informs, never blocks) |

## Weaknesses (Revised)

1. ~~**Solo dev, minimal community**~~: RESOLVED — now THRIVING 5/6
2. **The hard problem is partially addressed**: Auto-decay handles staleness but "what SHOULD become memory" still left to agent/user
3. **Heavy deps**: numpy, scipy, sentence-transformers, LanceDB, rank-bm25, fastembed — non-trivial install (unchanged)
4. ~~**No mechanism for memory quality control**~~: RESOLVED by auto-decay + graph-boost saturation
5. **v1.2.0 release pending**: PR#63 bump to 1.2.0 still open (23 days), suggesting release process lag

## Verdict (Updated)

Matured from clever solo project into a legitimate agent memory system with healthy community. Auto-decay pattern is the key new insight — autonomous memory curation via time-based decay + reinforcement is something we could adopt for our wiki/memory files (stale entries losing prominence over time). The community validation (external PRs, QA fixes, multi-provider support) confirms the architecture is sound.

**Relevance to us**: Auto-decay + lesson follow-through remain the two patterns worth considering. Our file-based approach still wins on simplicity/readability but lacks autonomous freshness management.

**Revisit**: 08-03 (monthly check, mature project)

Links: [[git-backed-agent-memory]], [[agent-memory-landscape-202603]], [[brain-md]], [[ai-memory]], [[krusch-context-mcp]], [[beliefs-candidates]]
