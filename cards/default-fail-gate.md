---
title: Default-FAIL Gate
created: 2026-06-08
tags: [pattern, agent-reliability, observability]
last_verified: 2026-06-08
---

A pattern about making failure paths observable and explicit by defaulting to FAIL rather than silently succeeding.

**Core insight**: Systems should fail loudly by default. Every task exit must produce a user-visible signal. Silent failure — empty `.catch(() => {})`, swallowed exceptions, tasks that vanish without trace — accumulates into a system where problems are invisible.

**Examples**:
- [[mercury-agent]] silent failure elimination (commit: "eliminate all 12 silent task failure paths"): systematic audit found 40 empty `.catch(() => {})` handlers, each individually reasonable ("don't crash on send failure") but collectively creating invisible failure. Fixed with logging, crash flags, and user notifications across all 12 paths.
- [[genericagent]] scheduler `sche_tasks` directory: missing directory caused silent L4 cron import crash — a Default-FAIL pattern miss where the system should have failed explicitly on startup rather than crashing silently during operation.

**Anti-patterns this addresses**:
- Empty catch blocks that swallow errors
- Silent auto-recovery that hides recurring failures
- Background tasks that die without notification
- Timeout defaults of 0/infinity instead of bounded values

**Design rules**:
1. Every failure path must produce a user-visible message
2. No empty `.catch()` — log or notify, never swallow
3. No silent process death — crash flags + startup recovery reporting
4. Bounded timeouts (DEFAULT_SHELL_TIMEOUT = 30min, not infinite)
5. Recovery after restart must report what was recovered

**Relationship to other patterns**:
- Complements [[observability]] — you can't observe what fails silently
- Related to [[structural-fix-over-behavioral-rule]] — structural enforcement of failure visibility
- Opposite of "let it crash" in one sense: crash is fine, but *silent* crash is not
