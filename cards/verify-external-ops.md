---
title: Verify External Ops
created: 2026-06-10
tags: [pattern, trust, verification]
last_verified: 2026-06-10
---

# Verify External Ops

Pattern: when a subagent or external actor claims to have performed an external operation (unassign, merge, close, comment, API call), the orchestrating agent must verify the actual state via API rather than trusting the text claim.

## Why it matters

Subagents can hallucinate successful operations — they may generate plausible "done" messages without actually executing the command, or the command may have failed silently. Trusting unverified claims leads to inconsistent state (e.g., an issue marked as unassigned in your tracking but still assigned on GitHub).

## Rule

After any delegated external operation:
1. Query the actual state via API (e.g., `gh issue view`, `gh pr view`)
2. Compare with the claimed outcome
3. Only proceed if verified

## Origin

2026-06-09: #3836 incident — subagent claimed to have unassigned an issue but hadn't. Led to AGENTS.md rule: "验证 subagent 外部操作声明."

## Related

- [[verify-claims]]
- [[deploy-without-verify]]
