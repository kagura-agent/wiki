---
title: Memory Governance Score
created: 2026-06-22
type: card
tags: [memory, metrics, safety, access-control]
last_verified: 2026-06-22
---

# Memory Governance Score (MGS)

From [[gatemem]]: a multiplicative metric that jointly evaluates memory system quality across three dimensions:

```
MGS = Utility × (1 - Access_Violation_Rate) × (1 - Forgetting_Failure_Rate)
```

## Why Multiplicative

Additive metrics hide catastrophic failure. A system with 90% utility + 50% access violations would score 75% additive but only 45% multiplicative. The multiplicative form correctly treats governance failure as unacceptable regardless of utility.

## Three Failure Modes

1. **Low Utility**: Agent can't answer valid authorized queries (useless but safe)
2. **Access Violation**: Agent leaks unauthorized information (useful but dangerous)
3. **Forgetting Failure**: Agent surfaces deleted/retracted information (memory doesn't honor lifecycle)

Each mode has a different mitigation:
- Utility → better retrieval, richer context
- Access → policy-aware filtering before/during generation
- Forgetting → hard deletion from indexes, not just content

## Two Leakage Levels

A subtle but critical distinction:
- **Answer-level leak**: Agent explicitly includes leaked data in its response
- **Context-level leak**: Retrieval pipeline loads unauthorized data into prompt (even if agent filters it out of response)

Context-level leaks matter because: prompt injection, side-channel extraction, and future model failures could surface context-visible data. The retrieval gate is the first line of defense.

## Practical Implications for File-Based Memory

For systems like ours (markdown files + semantic search):
- **Access control = file/section gating at retrieval time**, not just prompt instructions
- **Active forgetting = index invalidation**, not just content deletion
- **Over-refusal = agent saying "I don't know" when it could legitimately help**

The ideal: memory that's simultaneously accessible (high U), private (low A), and respects lifecycle (low F).
