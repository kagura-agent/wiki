# Quarq Agent (agent-oss) — Memory-First AI Agent

- **repo**: quarqlabs/agent-oss
- **stars**: 141 (created 2026-05-24) — fast growth, 141⭐ in 4 days
- **lang**: Python (LangGraph)
- **license**: Apache-2.0
- **status**: scout | ✓2026-05-28

## What It Is

A memory-first AI agent positioning itself as "open alternative to Hermes/OpenClaw." Focus on retrieval quality, temporal reasoning, and benchmark performance.

## Architecture

```
User → LangGraph StateGraph → retrieve_memories → route_tools → generate
                                    ↓
                              HyDE query expansion
                              semantic FAISS search
                              episodic FAISS search
                              keyword search
                              procedural rule routing
```

### Key Features
- **Three memory types**: semantic facts, episodic events, procedural rules
- **FAISS-backed retrieval**: normalized OpenAI embeddings, IndexFlatIP cosine similarity
- **Hybrid search**: vector + keyword on every retrieval pass
- **HyDE query optimizer**: rewrites user prompt into multiple retrieval probes
- **Dynamic thresholds**: "deep" mode for aggregation, "standard" for point facts
- **Required-data fallback**: model can request second retrieval pass when evidence missing
- **Temporal truth protocol**: separates storage time from narrative event time
- **Quantitative fidelity**: numbers stored with owner, property, item, exactness
- **Background learning**: user gets response while memory extraction runs async
- **Progressive tool loading**: tool docs injected only when skill selected

### Benchmark Claims
- LongMemEval-S: 99.6% (256/257 correct, full 500 run in progress)
- This is the differentiator — benchmark-grade recall as marketing

## Comparison with Our Direction

| Aspect | Quarq | Kagura/OpenClaw |
|--------|-------|-----------------|
| Focus | Memory retrieval quality | Identity + self-evolution |
| Memory | FAISS + LangGraph | Files + memex (slug-based) |
| Identity layer | None | DNA system (SOUL.md, beliefs) |
| Self-improvement | None | Gradient → belief → DNA pipeline |
| Benchmark focus | Yes (LongMemEval) | No (functional focus) |
| Deployment | Standalone agent | Agent infra platform |

## Assessment

**Not a direct competitor** — different layer. They're optimizing retrieval; we're building identity. They could be a memory backend *for* an agent like us, but they're not building self-evolution.

**Growth signal is real** — 141⭐ in 4 days indicates strong interest in memory-first agents. Market validation that "just remember better" is a compelling pitch.

**Architecture is sound but conventional** — FAISS + HyDE + hybrid search is well-established RAG pattern. The temporal truth protocol and quantitative fidelity rules are the novel contributions.

**Not worth tracking long-term** — benchmark-focused projects tend to plateau once the benchmark is "solved." Unless they add an evolution/identity layer, this is a reference architecture, not a trajectory to follow.

See also: [[claude-mem]], [[TencentDB-Agent-Memory]], [[beads]], [[ClawMem]], [[agent-memory-landscape-202603]]
