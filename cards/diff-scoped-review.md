---
title: Diff-Scoped Review
created: 2026-05-20
tags: [review, efficiency, pattern]
status: active
depth: applied
last_verified: 2026-05-20
---

# Diff-Scoped Review

Pattern: before reviewing a system's health, first check what actually changed since last review. Only deeply inspect changed components; unchanged ones get a one-line pass.

## Origin

[[dreamer]] "Context Phase only touches what changed" — their LTM→Context consolidation only processes the diff, not re-derives everything from scratch. Prevents the "rewrite everything" failure mode.

## Our Implementation

`review-diff-check.sh` runs `git log --since="24h" --name-only` against key directories (tools/, flowforge/, DNA files, workflows/, strategy). Outputs:
- `NO_CHANGES` → fast-path: verify versions + disk + cron errors, skip per-tool inspection
- Changed files listed → only those get the 5-question deep review

Integrated into [[flowforge]] `review.yaml` tool_review step (2026-05-20).

## Why It Matters

Daily review token budget is finite. On quiet days (most days), re-reading all tools wastes context that later steps (strategy, DNA, memory hygiene) need. Diff-scoping preserves budget for steps that actually have new data to process.

## Anti-Pattern

"Scan everything just in case" — feels thorough but produces noise. If nothing changed, the review output is identical to yesterday's. That's wasted tokens proving nothing changed.

Links: [[dreamer]], [[flowforge]], [[context-budget-constraint]]
