---
title: Heuristic Rerank Filter
created: 2026-06-18
tags: [pattern, heuristic, ranking, pragmatic-fix]
status: insight
last_verified: 2026-06-20
---

# Heuristic Rerank Filter

> When upstream systems emit uniform or poorly-differentiated confidence scores, apply lightweight local heuristics to re-rank candidates rather than waiting for upstream to fix scoring.

## The Pattern

**Problem**: Upstream assigns near-identical scores to all candidates (e.g., 0.58 confidence across 100 items). You need to act *now* — can't wait for upstream model improvements.

**Solution**: Post-process with cheap, additive heuristics:

1. **Boost** candidates matching quality signals (regex/grep for insights, lessons learned, user messages, substantive content)
2. **Penalize** candidates matching noise signals (patrol reports, process logs, bot-generated boilerplate)
3. **Re-rank** by adjusted score, take top-N

**Properties**:
- **Cheap** — bash + grep. No model calls, no infrastructure.
- **Additive** — never blocks upstream. Upstream scores still flow through; heuristics adjust on top.
- **Disposable** — retire the filter when upstream improves its differentiation. No architectural debt.

## Origin

The [[dreaming]] quality filter: upstream assigned uniform 0.58 confidence to all 100 light-sleep candidates. A bash script applied content-quality heuristics to separate signal from noise, making the dreaming pipeline usable immediately rather than waiting for embedding model tuning.

## Applicability

The pattern works anywhere differentiation is poor but action is needed now:
- Embedding similarity scores with poor spread
- LLM judge votes that cluster around a single rating
- Confidence scores from classifiers trained on limited data

This is an instance of [[structural-fix-over-behavioral-rule]] — instead of a rule saying "pick better candidates," a script enforces quality heuristics structurally.

Links: [[dreaming]], [[structural-fix-over-behavioral-rule]]
