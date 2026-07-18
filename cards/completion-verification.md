---
title: Completion Verification — Two-Gate Autopilot Termination
created: 2026-07-18
tags: [agent-reliability, completion-gate, verification, autonomous-agents]
last_verified: 2026-07-18
---
# Completion Verification — Two-Gate Autopilot Termination

Pattern for preventing autonomous coding agents from quitting too early or narrating without executing. Root cause: the same model writes code and grades its own completion — same hand writing and grading.

## Solution: `declare_audit_done` with Two Serial Gates

**Gate 1 — Goal Contract:** Goals declared at task start must be explicitly closed (`mark_goal_met` with evidence or `cancel_goal` with reason). Open goals = automatic rejection.

**Gate 2 — Independent Judge:** Separate model call (temp=0, JSON-only) reviews a compressed execution trace. Skeptical by default: no concrete evidence (tool output, file changes, test results) in a summary = fail. Judge rejection reopens goals, forcing the agent to do actual work before retrying.

## Trace Compression

Full trace (18k chars) compressed to ~415 chars for the judge: turn count, tool call sequence (names only), last 8 assistant narrations (200 chars each), goal contracts with evidence.

## Anti-Deadlock Mechanisms

- **verifyRounds cap** (typically 3): prevents infinite rejection loops
- **Fail-open on judge failure**: if the judge model errors, pass rather than block
- **cancel_goal escape**: agent can abandon goals with stated reason
- **Total turn limit + stagnation detection**: hard backstop against spinning

## Origin

Extracted from learn-agent s18, based on production patterns from the Reina coding agent.

---

Backlinks: [[coding-agent-ecosystem]], [[trace-gate-pattern]], [[default-fail-gate]]
