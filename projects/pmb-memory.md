---
title: PMB — Local-First Persistent Memory for AI Coding Agents
slug: pmb-memory
tags: [agent-memory, mcp, sqlite, vector-search, local-first]
created: 2026-06-26
updated: 2026-06-26
status: deep-read
last_verified: 2026-06-26
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

## Weaknesses

1. **Issue #1**: `record_keyed_fact` uses fragile `LIKE` on raw JSON instead of `json_extract` — basic data integrity flaw
2. **The hard problem is punted**: What SHOULD become memory is left to the agent/user (Issue #2 feedback confirms this)
3. **Solo dev, minimal community**: 87⭐ but only 2 issues, 0 PRs from community
4. **Heavy deps**: numpy, scipy, sentence-transformers, LanceDB, rank-bm25, fastembed — non-trivial install
5. **Dashboard is visualization, not curation**: Shows everything captured but no mechanism for memory quality control or pruning

## Verdict

Well-engineered SQLite+vector memory system. Exploration memo cache and PPR graph retrieval are genuinely novel. Lesson follow-through tracking is a concrete feature we could adopt. But our file-based approach trades performance for simplicity, readability, and git-native versioning — different tradeoff, not worse.

**Revisit**: 07-10 (want to see community growth + whether exploration memos get adopted elsewhere)

Links: [[git-backed-agent-memory]], [[agent-memory-landscape-202603]], [[brain-md]], [[ai-memory]], [[krusch-context-mcp]], [[beliefs-candidates]]
