---
title: Convergence Engine
created: 2026-08-09
last_verified: 2026-08-09
tags: [agent-evaluation, convergence, cost-control, loop-detection, observability]
---

# Convergence Engine

A convergence engine assesses whether an agent loop is still making useful progress, rather than treating repeated activity or elapsed time as evidence of progress. [[wattage]] combines five per-iteration signals into a progress score:

- **Evidence gain**: novelty of tool or retrieval results relative to cumulative history.
- **State delta**: behavioral change relative to the preceding iteration.
- **Goal proximity**: progress toward an explicit goal, neutral when no trustworthy goal signal exists.
- **Oscillation**: recurring action cycles, detected from normalized action symbols.
- **Growth penalty**: tokens spent relative to information gained.

## Current-state classification

The key operational choice is to classify the *trailing* below-threshold streak rather than historical dips that later recovered. That separates a loop which is currently productive from one that is thrashing, oscillating, or stalled without penalizing a recovered investigation.

This differs from exact-repeat guards such as [[loop-detection-comparison]]: a loop can make superficially different calls while gaining no evidence, or can vary its actions while cycling between strategies. Progress evaluation should therefore combine behavior, results, and cost rather than rely on a single repetition signature.

## Boundary

A score is a diagnostic and a stop/review signal, not proof of task success. It should trigger an explicit decision—continue, change strategy, ask for a missing goal, or stop—while preserving the evidence that produced the classification.

## Evidence

The signal definitions, weights, and trailing-streak classifier were documented from [[wattage]]'s `convergence/` implementation on 2026-07-29. Its goal-proximity signal was explicitly a neutral placeholder absent an explicit goal signal; do not interpret it as a reliable measure of task completion.

## Related

- [[wattage]]
- [[loop-detection-comparison]]
- [[cron-observability-metrics]]
- [[durable-agent-runs]]
