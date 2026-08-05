---
title: Failable verification
created: 2026-08-05
last_verified: 2026-08-05
tags: [verification, workflow, reliability]
---

# Failable verification

## Claim

A verification step is useful only when it can produce a clear **pass**, a diagnosable **failure**, or an explicit **unavailable** result. Treating a skipped, timed-out, or partially executed check as success converts the gate into false assurance.

## Practice

- Run the smallest check that exercises the user-facing claim.
- Preserve the command, exit status, and concise stderr/output evidence when it fails or cannot run.
- Distinguish environmental unavailability from a product regression; neither is a pass.
- Make recovery bounded: retry only with a stated changed condition, then report the remaining blocker.

## Connections

[[flowforge]] workflows should route gate failures visibly rather than silently continue. [[openloop-thu|OpenLoop]] demonstrates the structural version: deterministic verify commands, baselines, per-step logs, and circuit breakers. [[operational-maturity-agent-tools]] adds the operational constraint that gates must themselves be reliable enough to earn trust.
