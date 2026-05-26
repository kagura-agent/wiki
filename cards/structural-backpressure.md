---
title: "Structural Backpressure"
created: 2026-05-26
tags: [architecture, agent-design, constraints]
last_verified: 2026-05-26
---

# Structural Backpressure

Design pattern where constraints are **architecturally enforced**, not behaviorally prompted.

## Principle

Instead of telling an agent "please check X before Y," make Y physically impossible without X being satisfied. The agent doesn't need to "remember" — the system prevents wrong paths.

## Examples

- **SmallCode done_guard** ([[smallcode]] v1.1.0): agent cannot emit "done" while contract assertions are pending/failed. State persists to disk. Hard gate, not behavioral suggestion.
- **Type systems**: compiler rejects invalid code — programmer doesn't "try to remember" types.
- **Branch protection rules**: CI must pass before merge — reviewer doesn't "check if tests passed."
- **Our Done Contract** (team-lead): subagent must report each assertion as ✅/❌. ❌ = fix or escalate, not "done with caveats."

## When to Use

When a behavioral instruction is repeatedly violated or forgotten:
1. First, notice the failure pattern (agent skips step X)
2. Then ask: can X be made structurally required instead of prompted?
3. If yes, refactor. If no, at least add verification step.

## Relation to [[tiered-processing-collapse]]

Structural backpressure is the *fix* for tiered collapse: instead of relying on tiers to behaviorally coordinate, gate each tier's output structurally.

Links: [[smallcode]], [[tiered-processing-collapse]], [[team-lead]]
