# memraw (TetiAI)

**Discovered:** 2026-07-16 (scout)
**Repo:** https://github.com/TetiAI/memraw
**Stars:** 46⭐ (6d old, 0 forks)
**License:** Apache 2.0
**Language:** TypeScript
**Status:** v0.0.1 — experiment, not production

## What It Is

A radical anti-retrieval memory system for AI agents. The thesis: context windows keep growing, prompt caching keeps getting cheaper — so skip embeddings/vector DBs/retrieval entirely and put the **whole memory in the prompt, always**. Conversations get distilled into dense, importance-scored fact lines (~30 tokens each).

## Core Design

### The Format

```
<memory v="7" u="2026-07-09T16:40">
9 2026-07-05T16:40 name Alice, CTO at Acme
8 2026-07-05T16:40 celiac, Swedish origin
5 2026-07-08T09:05 set the launch for 2026-09-15
1 2026-07-09T14:20 the office coffee is nice
</memory>
```

Each line: importance (1-9), timestamp, fact in plain language. That's it. No embeddings, no metadata schema, no database.

### Key Operations

1. **add()**: Distill input (text or whole conversation) into fact lines via LLM. Dedup against existing. **APPEND only** — never reorders, preserving prompt cache byte-prefix stability.
2. **consolidate()**: Valley reorder (manual, deliberate) — invalidates cache, so you choose when.
3. **narrate()**: Prose view at 50% token budget — a compressed render, never stored back. Facts are the source of truth.
4. **forget()**: Explicit deletion by substring/regex or `"*"` to wipe.
5. **evict()**: When over budget, remove least-important facts (oldest first on ties). "Forget by importance, not by age."

### The Valley — Lost-in-the-Middle Mitigation

LLMs read start and end of context best, middle worst (Liu et al. 2023). `consolidate()` arranges facts as a valley: most important at edges, trivia in middle. Pure code, no LLM call. **Manual by design** — reordering breaks prompt cache.

### Supersede Vetting

When distilling, the LLM can claim a new fact supersedes an old identity fact. But the engine **vets** this: at least 50% of the old fact's significant words must appear in the new lines. If not, both are kept. "A supersede can never lose a memory." This is a smart safety mechanism.

## Benchmark Results (Honest)

One LOCOMO conversation → 11,076 token memory. 58 balanced questions, 6 reader models:

| Model | Facts accuracy | Prose accuracy |
|---|---|---|
| gemini-2.5-flash-lite | 56.9% | 55.2% |
| gpt-5 | **75.9%** | **69.0%** |

Key insight: **the same memory scores 56.9% → 75.9% just by swapping the reader model**. No retrieval pipeline to bottleneck — every model generation lift is free.

## Relevance to Us

**We're already doing a manual version of memraw.** Our MEMORY.md is plain text loaded into the system prompt — whole memory, always in context. The differences:

1. **We lack importance scoring.** Everything in MEMORY.md has equal weight. memraw's 1-9 scoring enables smart eviction and valley ordering.
2. **We lack automatic distillation.** We manually curate MEMORY.md. memraw uses LLM to extract facts from conversations.
3. **We lack valley ordering.** Our memory is chronologically organized, not attention-curve optimized.
4. **We already have the key advantage:** no retrieval failures. Multi-hop queries "just work" because everything is in context.

**Should we adopt?** Not directly — our memory is small enough (<5k tokens) that the engineering overhead isn't justified yet. But the importance-scoring concept could apply: putting high-importance facts at the top/bottom of MEMORY.md is a zero-cost improvement.

## The Bet

memraw is betting on two curves: bigger windows (128k → 1M → 10M) and cheaper prompt caching. At 1M window with 10-20% budget, you get 3,300-6,700 hot facts — "far past what a single user accumulates in years." The question is whether these curves continue.

**Counter-argument:** retrieval systems get better too, and they don't pay the prompt-cache cost for the full memory on every turn. For agents with large knowledge bases (not just personal facts), retrieval still wins.

## Position in Ecosystem

Anti-retrieval camp alongside the "compiling agent skills" approach (see [[compiled-harness-pattern]]). Contrasts with [[synapse-memory]] (temporal KG), [[waku-agent]] (retrieval gate + SQL), and traditional RAG. Part of the broader "memory is the moat" trend in 2026 agent development.

## Predictions

- If context windows hit 10M tokens with cheap caching: memraw's approach becomes mainstream for personal agents
- If caching costs don't drop enough: memraw stays niche for small-memory use cases

## Links

- [[waku-agent]] — contrasting approach (retrieval gate + structured memory)
- [[agent-memory-strategies]] — memraw adds the "no-retrieval" data point
- [[synapse-memory]] — bio-inspired temporal KG, opposite end of the spectrum
