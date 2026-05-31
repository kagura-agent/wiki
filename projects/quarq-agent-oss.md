# Quarq Agent OSS — Evidence-Gated Memory Agent

**Repo**: [quarqlabs/agent-oss](https://github.com/quarqlabs/agent-oss) | 182⭐ (2026-05-31, created 05-24) | Python | MIT
**Status**: new | deep-read | ✓2026-05-31

## What It Is

A memory-first AI agent positioning itself as an "open, inspectable alternative to Hermes or OpenClaw." Core claim: 99.6% recall on LongMemEval-S benchmark. Built on LangGraph + FAISS + OpenAI.

## Architecture

Simple 3-node LangGraph: `retrieve_memories → route_tools → generate_response`

### Memory System (3 tiers)
- **Semantic**: durable facts (identity, preferences, relationships)
- **Episodic**: time-stamped events with temporal metadata
- **Procedural**: behavioral rules extracted from patterns

### Retrieval Pipeline
- HyDE query expansion (rewrites prompt into multiple retrieval probes)
- Hybrid: FAISS vector (text-embedding-3-large, 1536d) + keyword matching
- Dynamic thresholds: "deep" mode for aggregation, "standard" for point facts
- REQUIRED_DATA fallback: model can request second retrieval pass
- Temporal truth protocol: separates storage time from event time
- Quantitative fidelity: numbers tracked with owner/property/item/exactness

### Key Design Decisions
1. **Background learning**: memory extraction runs async after user response returns (fast UX)
2. **Progressive tool loading**: tool docs injected only when a skill is selected (context efficiency)
3. **Persistent retry for background tasks**: infinite retry loop — never drops a learning task
4. **Single-file agent**: entire agent logic in one 150+ line `agent.py` — no real modular separation

## Honest Assessment

### Strengths
- Clear problem framing: "4 failure modes of standard RAG" is well-articulated
- Benchmark-first approach (LongMemEval-S) — rare for agent projects to lead with evaluation
- Background learning pattern is smart (don't block user on memory writes)

### Weaknesses
- **Hardcoded to OpenAI**: gpt-4.1 for generation, gpt-4o-mini for retrieval, text-embedding-3-large. No provider abstraction
- **Single-file architecture**: `agent.py` is a monolith with globals. Compare to ai-memory's clean crate separation
- **No external issues/discussions**: 0 issues, 1 merged PR (just the OSS release), 1 open PR (tests). Very early community
- **Only 2 contributors**: both appear to be the founding team
- **182⭐ in 7 days but shallow engagement**: stars without issues = curiosity, not usage
- **"Alternative to Hermes or OpenClaw"** — positioning claim, not demonstrated. Different problem space (personal memory agent vs agent runtime)

## Comparison to ai-memory (akitaonrails)

| Aspect | Quarq | ai-memory |
|---|---|---|
| Stars/age | 182⭐ / 7d | 430⭐ / 10d |
| Language | Python (LangGraph) | Rust |
| Memory tiers | 3 (semantic/episodic/procedural) | 4 (working/episodic/semantic/procedural) |
| Vector store | FAISS (in-process) | FAISS or sqlite-vec |
| Provider lock | OpenAI only | 6 providers |
| Architecture | Single-file monolith | 9 crates, clean separation |
| Community | 2 contributors, 0 issues | 36+ PRs, active issues |
| Benchmark | LongMemEval-S 99.6% | LongMemEval-S (in progress) |
| Cross-agent | No | Yes (handoff protocol) |

**Verdict**: ai-memory is significantly more mature architecturally and community-wise. Quarq's main contribution is the benchmark-first evaluation approach and the explicit "4 failure modes" framing.

## Relevance to Us

**Medium.** The 4 failure modes framing is useful for evaluating our own memory retrieval:
1. Wrong memory retrieved → our memex semantic search sometimes hits this
2. Right memory, wrong entity → less relevant for us (single user)
3. Storage time ≠ event time → our daily memory files handle this naturally
4. Wrong numbers from nearby context → relevant for any data-heavy queries

The REQUIRED_DATA fallback pattern (model requests a second retrieval pass) is interesting — our current search is single-pass.

## Not Tracking

Low community signal, OpenAI-locked, monolithic. Will not add to portfolio.

---
*First read: 2026-05-31*
