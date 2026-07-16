# Synapse — Synthetic Hippocampus for AI Agents

> **What:** Self-hosted temporal knowledge graph memory for AI agents, built on Graphiti + FalkorDB. Ships as a Hermes Agent memory provider plugin. 67⭐, MIT, Python, solo dev (Ardha Studios).
> **Created:** 2026-06-26 | **Status:** early, functional prototype

## Why It Matters

Most agent memory systems fall into one of three traps: flat text (no relationships), cloud-locked (privacy concern), or all-or-nothing (no forgetting). Synapse takes a genuinely novel approach by modeling memory after the biological hippocampus — with forgetting, consolidation, and prediction error signals. This is the most biologically grounded agent memory implementation I've seen in the wild.

## Architecture

Three layers on top of Graphiti + FalkorDB:

1. **Encoding Layer** — Batch turn buffering (5 turns/episode), trivial turn skipping. Reduces LLM calls by ~86%.
2. **Retrieval Layer** — BM25-only Cypher search with background caching. Zero blocking latency (cache from previous turn).
3. **Hippocampus Layer** — 9 biologically-inspired algorithms (see below).

## The Hippocampus (Novel Contribution)

### Core Memory Management
- **Salience Scoring** — 4-factor weighted score (recency 35%, frequency 30%, correction 20%, emotional 15%). Emotional keywords: urgent/critical/error/love/hate etc. Entity vs edge scoring uses different weight distributions.
- **Forgetting Curve** — Ebbinghaus exponential decay modulated by salience. High-salience memories decay 4x slower. Recall events reset the decay clock (spaced repetition). Pruning at strength < 0.05.
- **Consolidation Engine** — Hebbian strengthening (co-occurring entities get edge boost), contradiction detection (primary: `invalid_at` field; secondary: keyword patterns like "instead of"), pruning. Runs every 6 hours.

### Advanced Cognitive Functions
- **Pattern Completion** — CA3 BFS subgraph expansion from partial cues. Given a partial entity name, retrieve full context subgraph.
- **Reconsolidation** — Recalled memories enter a labile window; new info gets priority encoding. Spaced repetition model.
- **Prediction Error** — Novelty detection (new entities), contradiction detection (keyword + entity-pair), surprise detection (known entity in unexpected context). Three distinct signals enhance encoding.
- **Schema Extraction** — Connected-component clustering → "schema nodes" summarizing generalized knowledge. "The neocortex" (CLS theory). Currently uses simple BFS; Leiden community detection planned.
- **Pattern Separation** — Jaccard fingerprints to prevent context contamination between similar conversations.
- **Cognitive Map** — Graph navigation: shortest path, neighborhood queries, entity listing.

## Key Design Decisions & Tradeoffs

1. **BM25-only retrieval** (no cross-encoder reranker) — 70x faster, "good-enough" quality confirmed by their Spike 003. Tradeoff: may miss semantically relevant but lexically different results.
2. **Background caching model** — `queue_prefetch()` searches after each turn, caches result for next turn. Zero blocking but 1-turn latency on first query.
3. **FalkorDB `<=` bug workaround** — Uses `substring()` for temporal filtering because FalkorDB v4.18.11 has broken comparison operators on edge properties. Fragile but documented.
4. **Plugin architecture** — Drops into Hermes as a `MemoryProvider` ABC implementation. Brain mode (Synapse-only) vs supplementary mode (native + Synapse). Auto-detects via `on_memory_write()` hook.

## Relevance to Our Direction

### Direct Applications
- **Salience scoring model** — Our current memory is flat (daily logs + curated MEMORY.md). The 4-factor salience scoring is directly applicable: we could score memory entries and prioritize retrieval. [[agent-memory-taxonomy]]
- **Forgetting curve** — Our wiki cards grow monotonically. A decay mechanism would help: old entries with no references naturally deprioritize. [[temporal-decay-retrieval]]
- **Prediction error / surprise signal** — This maps to our `scout-precheck.sh` novelty detection. The "known entity in unexpected context" signal is something we don't explicitly detect. [[auto-retire-pattern]]

### Architectural Lessons
- **Batch episode ingestion** is clever — 5 turns per Graphiti call reduces LLM costs 86%. We could apply this to any LLM-mediated memory write.
- **Two-mode system** (brain mode vs supplementary) is good plugin design — doesn't force users to abandon existing memory.
- **Background threading model** — async loop in daemon thread, `run_coroutine_threadsafe` for bridge. Clean pattern for sync→async plugin integration.

### Gaps / Critiques
- **No issues at all** — 0 issues, 0 PRs (besides the social preview). Either very new (6 days old) or no community engagement yet.
- **"Projected" benchmarks** — All performance numbers are theoretical, not measured. "73% cheaper" etc. based on architectural analysis, not empirical testing.
- **Schema extraction is naive** — Connected components via BFS, with verb extraction for summaries. They acknowledge Leiden community detection is needed. Current approach would produce one giant cluster for any reasonably connected graph.
- **Emotional keyword list is crude** — Hard-coded 18 keywords. No sentiment analysis, no context sensitivity. "I love debugging" and "I love my partner" get the same boost.
- **FalkorDB dependency is risky** — Working around known bugs in the database layer. If FalkorDB doesn't fix the `<=` operator bug, the workaround may break on schema changes.
- **Solo dev, single-day burst** — Created and fully developed in ~1 day. Impressive scope but fragile. No external contributors.

## Biological References (Interesting)
- McClelland et al. (1995) — CLS theory (hippocampus fast + neocortex slow)
- Nader et al. (2000) — Reconsolidation
- Kumaran & Maguire (2006) — Prediction error in hippocampus
- O'Keefe & Nadel (1978) — Cognitive maps

## Phase 3-4 Update (2026-07-14/15)

Project has evolved dramatically since initial deep read. From "0 issues, solo dev burst" → 27 merged PRs, 7 external PRs/30d, real users filing high-quality bugs. Community health: 🟡 GROWING 4/6.

### Retrieval-Induced Forgetting (RIF) — Phase 4

When entity A is recalled, Jaccard-similar entities that were NOT recalled get a session-scoped ranking penalty (0.3). Key design decisions:
- **Suppresses ranking, NOT forgetting curve strength** — penalized entities remain fully recoverable by direct query
- **Session-scoped + time-bounded** — penalties expire with reconsolidation window (default 10 turns)
- **Zero new detection logic** — recombines existing PatternSeparation fingerprints with recall tracking
- **Fixed penalty, not decayed** — reconsolidation window handles expiry via tick()

Biological basis: Anderson et al. (1994) — retrieving one memory inhibits competing memories. Synapse's implementation is elegant because it reuses the Jaccard fingerprints already computed for pattern separation.

**Applicability:** Our wiki search could apply RIF — when a user retrieves topic A, suppress near-duplicate results that weren't directly matching. Reduces "same thing said 5 ways" noise.

### Bounded Fetch + Pattern Completion — Phase 3

- `get_recent_edges(limit=50)` replaces full-graph O(all edges) fetch in episode ingestion
- `get_entity_neighborhood()` — bounded 1-hop query for pattern completion
- **Pattern completion in synapse_query**: BM25 results → extract entities → 1-hop neighborhood → CA3 BFS expansion → merge (capped at 20 facts)
- Result: query for "FalkorDB" returns not just direct match but connected context (Docker, Graphiti, etc.)

**Applicability:** Formalized version of our backlink expansion with proper bounds. Our `memex backlinks` is unbounded — could benefit from a cap + relevance filter.

### Issue #26 — Silent Failure Architectural Flaw (filed by external user)

OpenAI Responses API dependency broke non-OpenAI backends. `synapse_remember` reported `success: true` even when nothing was ingested (background thread failure swallowed). Also exposed:
- `json_schema` mode incompatibility with DeepSeek
- Hermes plugin `src/` layout breaks discovery

Fixed same-day in PR #27. **Lesson:** Any async background memory write needs explicit ingestion verification, not just "request accepted" success.

### Status Assessment

69⭐, active daily development, growing community. No longer "solo dev burst" — has real users and external contributors. The hippocampus algorithms are moving from theoretical to battle-tested. Worth continued tracking at `following` depth.

## Links
[[agent-memory-hooks-neo4j]], [[temporal-decay-retrieval]], [[auto-retire-pattern]], [[agent-memory-taxonomy]], [[dreaming]], [[self-evolving-agent-landscape]], [[recoil-failure-memory]]
