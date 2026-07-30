---
title: Agent Memory Strategies
created: 2026-07-16
source: inferred from waku-agent and memraw project context
last_verified: 2026-07-30
---

> Comparative framework for agent memory retrieval approaches — from always-retrieve (RAG) to retrieval-gated to no-retrieval (compiled skills).

## Spectrum

| Strategy | Example | Tradeoff |
|----------|---------|----------|
| Always-retrieve (RAG) | Traditional vector-store lookup every turn | Token-heavy, high recall |
| Retrieval-gated | [[waku-agent]] SQL gate — only retrieve when turn needs personal context | Saves tokens on non-personal turns |
| Compiled / no-retrieval | [[memraw]] — bake memory into harness at build time | Zero retrieval latency, stale until recompile |
| Temporal KG | [[synapse-memory]] — bio-inspired knowledge graph with decay | Mimics human forgetting, complex infra |

## Key Insight

The "right" strategy depends on memory update frequency vs. query frequency. High-churn personal facts benefit from retrieval; stable skill knowledge benefits from compilation.

## See Also

- [[agent-memory-taxonomy]] — academic framework (forms/functions/dynamics)
- [[memraw]] — no-retrieval data point
- [[waku-agent]] — retrieval gate + SQL approach
- [[synapse-memory]] — temporal KG, opposite end of spectrum
- [[optmem-binary-merge-memory]] — binary-merge compaction approach
