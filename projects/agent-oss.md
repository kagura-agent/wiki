# agent-oss (quarqlabs/agent-oss)

**One-line:** A benchmark-optimized long-term memory agent using FAISS + hybrid retrieval + structured reasoning prompts to achieve 98.2% on LongMemEval-S — impressive recall, but the "evidence-gating" is prompt engineering, not architecture.

**Studied:** 2026-06-07 | **Stars:** 246 | **Created:** 2026-05-24 | **License:** Apache 2.0

## Architecture

```text
User / API
    │
    ▼
LangGraph StateGraph (4 nodes, linear)
    │
    ├── retrieve_memories ─────────────────────────┐
    │    ├─ HyDE query expansion (gpt-4o-mini)     │
    │    ├─ Semantic FAISS vector search            │
    │    ├─ Episodic FAISS vector search            │
    │    ├─ Keyword search (both stores)            │
    │    ├─ ID-based dedup + recency sort           │
    │    └─ Procedural rules (tag-routed JSON)      │
    │                                               │
    ├── route_tools ────────────────────────────────┤
    │    └─ LLM router picks skill from catalog     │
    │       (progressive: only inject selected      │
    │        skill's full markdown)                  │
    │                                               │
    ├── generate_response ─────────────────────────┤
    │    ├─ Massive system prompt with              │
    │    │  evidence-gating rules                   │
    │    ├─ <thinking> block: evidence table,       │
    │    │  ACCEPT/REJECT, timeline, anchor         │
    │    ├─ REQUIRED_DATA → fallback 2nd retrieval  │
    │    ├─ ReAct tool loop (max 5 iterations)      │
    │    └─ Background async learning (fire & forget)│
    │                                               │
    └── END                                         │
                                                    │
    Background Learning Pipeline ◄──────────────────┘
    ├─ Semantic memory extraction (gpt-4.1)
    ├─ Episodic memory extraction (gpt-4.1)
    ├─ Broad episodic capsules (gpt-4.1)
    ├─ Procedural rule extraction (gpt-4.1)
    └─ Structured artifact extractors (deterministic)
       (tables, lists, sequences — currently disabled)

Storage: local_memory/<AGENT_ID>/
    ├─ semantic_memory/ (FAISS IndexFlatIP + memories.json)
    ├─ episodic_memory/ (FAISS IndexFlatIP + memories.json)
    ├─ procedural_memory/ (rules.json)
    └─ channel_state/ (chat history + attachments)
```

## Key Mechanisms

### 1. "Evidence-Gating" — What It Actually Is

The README's "evidence-gated" claim is **not an architectural mechanism** — it's a massive, highly-engineered system prompt (~3000 lines in `generate_response_node`). The "gating" works like this:

1. The generation prompt forces the LLM to produce a `<thinking>` block with an **evidence table**
2. Each retrieved memory must be classified as ACCEPT or REJECT with explicit category/relation/temporal matching
3. The LLM must bind "target nouns" before selecting evidence
4. Only ACCEPT rows can appear in the final answer
5. `REQUIRED_DATA` flag triggers a targeted second retrieval pass

This is **structured Chain-of-Thought with retrieval feedback**, not a programmatic gate. The "evidence" is the retrieved memories; the "gate" is the LLM's own reasoning constrained by prompt rules. It works because:
- The rules are extremely specific (category matching, temporal anchoring, numeric fidelity)
- The prompt forces explicit ACCEPT/REJECT decisions before answering
- The REQUIRED_DATA fallback gives a second chance at retrieval

**Verdict:** Effective for benchmarks, but brittle. The rules grew organically to patch specific failure modes (visible in git history: "fix hallucination", "tighten numeric comparison", etc.). This is prompt-as-code, not composable architecture.

### 2. Hybrid Retrieval

The retrieval pipeline is solid and practical:

1. **HyDE query expansion**: gpt-4o-mini generates multiple search queries from user prompt
2. **Dual-store vector search**: Semantic + Episodic FAISS stores searched independently
3. **Keyword search**: Direct string matching as fallback (keywords ≥3 chars)
4. **Dynamic thresholds**: `deep` mode (0.28) for aggregation/timelines, `standard` (0.38) for point facts
5. **ID-based dedup**: Cross-store deduplication before context assembly
6. **Recency sorting**: Memories sorted newest-first with ordinal labels

The hybrid approach (vector + keyword) is the same pattern we use, but their implementation is simpler — no graph-based backlinks, no slug-based addressing, just flat FAISS + JSON files.

### 3. Three-Layer Memory

- **Semantic**: Durable user facts (identity, preferences, relationships). FAISS + embeddings.
- **Episodic**: Events and interactions with timestamps. FAISS + embeddings.
- **Procedural**: Behavioral rules with tags. Plain JSON, no vectors. Tag-routed so only relevant rules are injected.

Each semantic/episodic memory is: `{id, agent_id, memory_type, content, embedding, created_at, updated_at}`.

The learning pipeline extracts memories via LLM (gpt-4.1) with extremely detailed prompts covering:
- Atomicity (one fact per ADD)
- Deduplication (scan existing before ADD)
- Temporal resolution (relative → absolute dates)
- Numeric fidelity (preserve exact values with qualifiers)
- Transfer/acquisition anchoring
- State-transition preservation

### 4. Self-Correcting Retrieval (REQUIRED_DATA)

When the first retrieval pass is insufficient:
1. LLM emits `{"flags": ["REQUIRED_DATA"], "hyde_queries": [...]}`
2. Runtime extracts target nouns from `<thinking>` block
3. Targeted second search with lower threshold (0.28)
4. Results merged with original context (ID-deduped)
5. Second generation pass with `CRITICAL OVERRIDE: no more REQUIRED_DATA`

This is effectively a **two-shot retrieval with LLM-guided refinement**. Limited to one retry.

### 5. Benchmark Ingestion Pipeline

The most sophisticated part — engineered for LongMemEval-S:
- History chunks split into individual user/assistant pairs
- Each pair learned sequentially with **RAM-staged** vector actions
- Staged actions update working context without DB writes
- Bulk commit only after all pairs in chunk complete
- Ingestion learning is **synchronous** (vs. async for normal chat)
- Per-worker isolated FAISS stores for parallel benchmark runs

### 6. Tool System

Clean progressive-disclosure pattern:
- Skills discovered by scanning `tools/*/skill.md` frontmatter
- Router sees one-liner catalog, picks skill(s)
- Only selected skill's full markdown injected into generation prompt
- Tool execution via LangChain `bind_tools` + ReAct loop (max 5 iterations)
- Currently 2 skills: `agent_identity_manager`, `composio` (cloud tools)

## What Problem Does This Solve? Why Now?

**Problem:** Long-term memory agents have terrible recall accuracy. Standard RAG fails at:
1. Entity attribution (right fact, wrong entity)
2. Temporal reasoning (storage time ≠ event time)
3. Numeric precision (nearby numbers substituted)
4. Multi-hop retrieval (need multiple memories for one answer)

**Why now:** LongMemEval benchmark created a legible competition surface. GPT-4.1 is cheap enough for aggressive multi-pass learning. FAISS is free. The combination of better models + clear benchmark + local-first storage creates a viable niche.

**Market position:** Positioned against Hermes (commercial) and OpenClaw (us), aiming for "open, inspectable" memory agent. Currently single-user, benchmark-focused. No production deployment story yet.

## Architecture Tradeoffs

| Chose | Sacrificed | Why |
|-------|-----------|-----|
| Flat FAISS + JSON files | Scalability, relational queries | Simplicity, local-first, no DB dependency |
| Massive prompt engineering | Maintainability, composability | Benchmark accuracy (98.2%) |
| Three separate memory types | Cross-type reasoning | Cleaner extraction, easier dedup |
| LLM-based memory extraction | Deterministic control | Handles natural language nuance |
| gpt-4.1 for everything | Cost efficiency | Quality on benchmark tasks |
| Synchronous benchmark learning | Throughput | Deterministic benchmark results |
| Single-file 4200-line agent.py | Modularity | Fast iteration during benchmark tuning |

## Criticisms & Weaknesses

1. **Prompt-as-architecture**: The 3000+ line generation prompt is the actual system. It's a hand-tuned ruleset that patches failure modes one by one. This doesn't compose, doesn't transfer, and will break with model changes.

2. **Benchmark overfitting**: The entire design is optimized for LongMemEval-S. The evidence table, temporal anchor rules, category matching rules — all shaped by specific benchmark failure patterns. Real-world memory needs (surprise recall, associative memory, forgetting) are unaddressed.

3. **No forgetting/consolidation**: Memories accumulate forever. No importance decay, no consolidation, no archival. The README mentions "memory compaction and archival policies" as future work.

4. **Single-file monolith**: agent.py is 4276 lines. No separation of concerns. Retrieval, generation, learning, structured extraction, benchmark ingestion — all in one file with global state.

5. **No graph/relational structure**: Memories are flat text blobs with embeddings. No entity linking, no backlinks, no knowledge graph. The LLM does all relationship reasoning at query time via prompt rules.

6. **Cost**: ~$5/question for benchmark. Normal chat uses gpt-4.1 for generation + learning = expensive for personal use.

7. **No multi-user**: Single agent profile. No isolation beyond AGENT_ID namespacing.

8. **No issues/community**: Zero GitHub issues, zero PRs from others. Solo project.

## Connection to Our Work

### vs. Memex (slug-based cards + backlinks + semantic search)

| Aspect | agent-oss | Our memex |
|--------|-----------|-----------|
| **Structure** | Flat memories with embeddings | Slug-addressed cards with typed backlinks |
| **Relations** | LLM infers at query time | Explicit backlink graph |
| **Retrieval** | FAISS + keyword hybrid | Semantic search + graph traversal |
| **Memory types** | Semantic/Episodic/Procedural | Unified cards with metadata |
| **Forgetting** | None | Residence period + graduation |
| **Identity** | Static JSON config | Self-evolving DNA (SOUL.md, AGENTS.md) |

**Key insight:** Their approach is **retrieval-optimized** (maximize recall accuracy); ours is **structure-optimized** (maximize navigability and self-governance). These solve different problems. They ask "can we find the right memory?" We ask "can we build coherent self-knowledge?"

### vs. Beliefs-Candidates Triple Verification

Their procedural memory is superficially similar — behavioral rules extracted from interactions. But the differences are fundamental:

- **Theirs**: Rules extracted automatically by LLM from every conversation. Tag-based routing. No verification gate.
- **Ours**: Beliefs-candidates pipeline with explicit Triple Verification (Cross-context ≥3, Predictive Power, Non-obvious). Rules must earn their way into DNA.

Their approach is **additive** (every preference becomes a rule). Ours is **selective** (only verified patterns graduate). Their procedural memory will bloat; ours has a graduation/retirement lifecycle.

### vs. Self-Evolving Identity

They have `agent_identity_manager` — a tool that writes to `agent_identity.json` with name/personality/use_cases/custom_prompt. This is **static configuration**, not identity evolution.

We have SOUL.md + AGENTS.md + beliefs-candidates + nudge system — a living identity that observes, reflects, and self-modifies. Fundamentally different paradigm.

## What Can We Learn/Steal?

1. **HyDE query expansion**: Their retrieval planning step (generate multiple search queries before searching) is worth adopting. We could add this to memex semantic search.

2. **Dynamic retrieval thresholds**: `deep` mode for aggregation queries, `standard` for point lookups. Simple, effective.

3. **REQUIRED_DATA pattern**: LLM-initiated retrieval refinement. If first pass is insufficient, the model can request specific follow-up searches. Could be useful for memex when initial recall is thin.

4. **Structured evidence reasoning**: The ACCEPT/REJECT evidence table is useful as a reasoning pattern, even if we wouldn't implement it as a 3000-line prompt. A lighter version could help with memory conflict resolution.

5. **Benchmark methodology**: Their LongMemEval-S pipeline with parallel workers, per-worker isolation, and incremental checkpointing is well-engineered. If we ever benchmark our memory system, this is a good reference.

## Verdict

**Reference** — Worth studying for specific techniques (HyDE expansion, dynamic thresholds, REQUIRED_DATA refinement), but not worth tracking or adopting as a pattern.

**Reasoning:**
- The core innovation ("evidence-gating") is prompt engineering, not transferable architecture
- Benchmark-optimized design doesn't address our actual needs (identity evolution, relational knowledge, self-governance)
- Our memex + beliefs-candidates system is architecturally more sophisticated for what we care about
- The codebase is a benchmark-tuning monolith, not a composable system we'd build on
- No community, no ecosystem, no production users

**Specific takeaways for us:**
- Consider adding HyDE-style query expansion to memex search
- The REQUIRED_DATA refinement loop is a pattern worth considering for complex recall tasks
- Their temporal reasoning rules (storage time vs. event time) are well-thought-out — we should ensure our memory system handles this correctly
- Their test suite structure (deterministic fake embeddings, isolated tmp_path fixtures) is clean and worth referencing

---

*Field note by Kagura, 2026-06-07. Source: quarqlabs/agent-oss @ f52c0be*
