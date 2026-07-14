---
title: "Clodex IDE — Zero-Trust Agentic IDE"
created: 2026-07-14
updated: 2026-07-14
status: scout
depth: deep-dive
stars: 696
repo: mereyabdenbekuly-ctrl/clodex-ide
last_verified: 2026-07-14
---

# Clodex IDE

Electron-based agentic development environment. Local-first, zero-trust architecture for verifiable autonomous software development. TypeScript monorepo, AGPL-3.0, 2354 files.

**Core thesis**: "Model output is untrusted input. Authority comes from explicit policy, isolated runtimes, and user-controlled review."

## Architecture Patterns

### Guardian Service (most novel)
Content-free policy assessor **isolated from execution**. Has no shell, network, MCP, sandbox, model-provider or credential dependencies. Cannot execute what it reviews or expand its own permissions.

Compare: [[clawpatrol]] enforces at the network level (MITM proxy). Clodex enforces at the process level. OpenClaw trusts agents to respect policy. Three enforcement points, three tradeoffs:
- Network-level (Claw Patrol): catches everything but heavyweight, can't understand intent
- Process-level (Clodex Guardian): understands intent but requires IDE integration
- Trust-based (OpenClaw): lightest weight but dependent on model compliance

### Shadow Classifier
LLM runs in **parallel** with deterministic risk rules for calibration:
- Deterministic rules make the actual decision (fast, reliable)
- LLM classifier runs in shadow mode (slower, potentially more nuanced)
- Agreement/disagreement tracked with latency metrics
- Deterministic always wins; shadow provides drift detection

This is a practical implementation of the [[predict-then-verify-calibration]] pattern at the policy layer. Could improve OpenClaw's approval system — shadow-run an LLM assessment alongside the fixed rule engine, calibrate over time.

### Risk × Authorization Matrix
Deterministic decision table:
```
risk: low|medium|high|critical
userAuth: unknown|low|medium|high
scope: narrowly_scoped | broad
→ decision: approve|escalate|deny
```
- Critical → always deny (no override)
- High + narrow scope + medium+ auth → approve
- High + broad scope → escalate regardless
- Low/medium → approve by default

### Evidence Memory
Append-only evidence records with provenance. Atomic ledger with chaos testing and recovery policy. Memory synchronized across local/cloud execution contexts.

### Execution Fabric
Local/SSH/Docker/cloud execution with:
- Portable snapshots and leases
- Digest-pinned Docker images
- Resource policies (CPU, memory, PID, FD, time bounds)
- Signed receipts for remote execution

### Egress Control Gateway
Deny-by-default network policy:
- Exact protocol/hostname/port grants
- DNS validation and pinned sockets
- Private/loopback/link-local protection
- Fail-closed when policy unavailable
- Content-free audit export

## Community Health: 🔴

| Signal | Value |
|--------|-------|
| Stars | 696 (2 days!) |
| Contributors | 1 (solo dev) |
| Commits | 7 (all 07-13) |
| Issues | 0 |
| External PRs | 0 |
| Subscribers | 1 |

**Suspicious growth pattern**: 696⭐ in 2 days, zero community engagement. 2354 files bulk-uploaded in 7 squashed commits. Either star-farmed or announced to a large audience with no follow-through yet.

## Relevance to Us

- **Shadow classifier**: Most directly applicable. Could add shadow LLM assessment to OpenClaw's approval system for calibration.
- **Guardian isolation**: Good security principle — the component that decides whether to approve an action should have no ability to execute it.
- **Evidence memory**: Append-only audit trail with provenance — more structured than our memory/YYYY-MM-DD.md logs.

## Tracking Decision

**Monthly check** — architecture is genuinely sophisticated despite star concerns. If community develops organically, worth deeper engagement. If stars grow but community stays at 0, confirms star farming.

Revisit: 2026-08-14
