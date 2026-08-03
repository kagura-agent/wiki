---
title: "Idempotent Operations for Agent Infrastructure"
created: 2026-08-03
tags: [pattern, agent-infrastructure, crash-recovery, idempotency, reliability]
last_verified: 2026-08-03
---

# Idempotent Operations for Agent Infrastructure

## The Problem

Agent infrastructure CLIs manage stateful resources (containers, sandboxes, worktrees, sessions). Agents interact with these CLIs and may:
1. **Crash mid-operation** (timeout, OOM, model limit)
2. **Retry the same command** (automatically or via human)
3. **Run concurrent instances** that interact with the same resources

Without idempotency guarantees, retries create duplicate resources, partial states, or conflicts.

## The Pattern: Operation Journal

Every mutation follows a journal-based protocol:

```
Request → Begin Operation (check journal)
           ├── Same key + same fingerprint → Cached (return previous result)
           ├── Same key + different fingerprint → Error (conflict)
           ├── Same op + running PID alive → InProgress (wait/skip)
           ├── Same op + dead PID → Recover (per-action reconciliation)
           └── New → Execute → Finish (record result)
```

**Components:**
1. **Idempotency key**: Client-provided, dedups retries
2. **Fingerprint**: Hash of request shape, prevents key reuse for different operations
3. **PID liveness check**: Distinguishes "still running" from "crashed"
4. **Per-action reconciliation**: Action-specific crash recovery logic
5. **State vs reality reconciliation**: Separate "reconcile" command checks journal against actual resource state

## Origin

First seen in [[gensee-crate-runtime-safety]] `managed.rs` (1095 LOC, 07-29). File-lock journaling with JSON state file, 300s staleness detection.

## Where This Applies

- Agent sandbox/session lifecycle management
- Subagent spawn and cleanup
- Cron job execution tracking
- Any tool that creates/destroys resources on behalf of agents

## Key Insight

This is essentially a **Write-Ahead Log (WAL) for agent tool operations**. The same principle databases use for crash recovery applies to agent infrastructure: record intent before action, verify completion after.

## See Also

- [[gensee-crate-runtime-safety]] — origin project
- [[sigbound]] — related agent safety tooling (file-system level)
- [[clawpatrol]] — network-level agent safety
