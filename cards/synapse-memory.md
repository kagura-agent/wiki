---
title: Synapse Memory
created: 2026-07-16
source: inferred from memraw project context
last_verified: 2026-07-16
---

> Bio-inspired temporal knowledge graph for agent memory — models memory as synaptic connections with strength decay over time.

## Core Idea

Synapse Memory treats agent memory as a graph where nodes are facts/events and edges represent associations. Edge weights decay temporally (like biological synapses), so frequently reinforced memories stay strong while unused ones fade. Opposite end of the spectrum from [[memraw]]'s compiled no-retrieval approach.

## Characteristics

- **Temporal decay**: Memories weaken without reinforcement, mimicking biological forgetting
- **Associative retrieval**: Graph traversal finds related memories via connection strength
- **Dynamic consolidation**: Frequently co-activated nodes merge into stronger representations

## Position in the Landscape

Sits at the high-complexity, high-fidelity end of [[agent-memory-strategies]]:
- More infrastructure than flat file memory (MEMORY.md)
- More biologically plausible than vector-store RAG
- Contrasts with [[memraw]] (no retrieval) and [[waku-agent]] (SQL-gated retrieval)

## See Also

- [[agent-memory-strategies]] — comparative framework
- [[agent-memory-taxonomy]] — academic forms/functions/dynamics
- [[memraw]] — opposite approach (compile, don't retrieve)
