---
title: "Graded Agent Guardrails"
created: 2026-08-05
tags: [agents, verification, policy, hooks, supply-chain]
last_verified: 2026-08-05
---

# Graded Agent Guardrails

A guardrail should label the strength of its evidence and match enforcement to that strength:

- **Certain:** deterministic, reproducible fact (for example, a parsed manifest dependency or failed test). It may block a change if the host can enforce it.
- **Likely:** structural signal with context-dependent meaning (for example, a thin wrapper or duplicate normalized symbol). It should ask for justification, not declare the code wrong.
- **Heuristic:** shape match or smell. It belongs in advisory feedback only.

[[Ratchet]] makes this distinction at the edit boundary; [[OpenLoop (thu-nmrc/openloop)]] applies the stronger form to task completion via independent verification; [[FlowForge]] routes process decisions but relies on external checks for hard claims.

## Design rule

**The strength of an automated intervention must not exceed the strength of its evidence.** A regex cannot support a hard correctness claim, while a deterministic test or parsed policy can. This avoids both blind trust in prompt-only norms and alert fatigue from overconfident lint-like agents.

## Trust boundary

A useful control mechanism is not automatically a safe dependency. Before installing a hook, plugin, or packaged binary, inspect its distribution and activation path—not just its detector logic. The [[Ratchet]] study found a current 80.5 MB Windows UI archive that the installer expands and launches automatically, alongside unresolved public supply-chain allegations. That makes it a design reference, not an adoptable tool.

## Applies when

Use this model when adding agent hooks, review bots, policy gates, or autonomous remediation. Keep heuristic feedback reversible and visible; reserve blocking for independently verifiable conditions; treat automatic binary launchers as a separate supply-chain review.
