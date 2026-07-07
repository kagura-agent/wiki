---
title: "MakerChecker — Governance Layer for AI Agent Tool Calls"
type: deep-read
status: active
created: 2026-07-07
updated: 2026-07-07
stars: 41
url: https://github.com/makerchecker/MakerChecker
license: AGPL-3.0 (core) + Apache-2.0 (SDK)
language: TypeScript/JavaScript
last_verified: 2026-07-07
---

# MakerChecker — Agent Governance at Tool-Call Level

> Named after the banking pattern where one person creates a transaction (maker) and a different person must approve it (checker). Applied to AI agents.

## What It Solves

Not "how do I sandbox an agent" but **"how do I prove an agent only did what it was authorized to do."** Moves from containment (sandbox, permissions) to **governance** (who authorized what, with what limits, with what audit trail). Targets regulated, adversarial-insider environments.

## Three-Layer Architecture

### 1. Scan (`mc scan` / `npx @makerchecker/scan .`)
Static analysis that finds dangerous tool patterns in agent code. Maps findings to **41 real AI incidents** (not generic warnings):
- **Signatures**: verb patterns + argument hints → risk categories (data-loss, financial, exfiltration, etc.)
- **Strong verbs vs weak verbs**: `delete/exec/wire` match on name alone; `eval/run` need confirming arg hints to avoid false positives
- **`--fix`**: can generate governance code automatically
- Every finding names the real incident it resembles (e.g., "resembles the Claude Code agent that force-pushed over a private repo")

### 2. Embedded (`@makerchecker/embedded`)
In-process governance engine. **Zero network dependencies.** Key design:
- **Pure policy engine**: `decide()` is a pure function — policy + request → allow/deny. No side effects.
- **Governor**: stateful wrapper that tracks per-session actors (which roles have acted) for SoD
- **Deny by default**: no grant → no execution. No bypass path.
- **Separation of Duties**: symmetric — if role A conflicts with B, enforced regardless of order. Agent can never approve its own work.
- **Pluggable audit sink**: governor emits events to an `onDecision` callback. No crypto in governor tier — audit chain attaches externally.
- **Limits**: per-skill invocation caps, per-run token budgets, per-transaction amount caps. All **fail closed** (missing amount field → deny).

### 3. Server (optional, self-hosted)
PostgreSQL-backed, adds:
- Human approval workflows (n-of-m named approvers, quorum, forbid-requester)
- **Ed25519-signed hash-chain audit trail** (RFC 8785 canonical JSON → SHA-256 chain → Ed25519 signature)
- Offline verifiable export bundles (anyone can verify with bundle + public key)
- DB hardening: non-owner role can't disable triggers on `audit_events`
- Cron triggers, flow orchestration (sequential steps only — no branching/parallelism)
- Immutable skills (DB trigger rejects modification after publish)
- Roles never deleted (permanent facts in audit history)

## Key Design Decisions Worth Studying

1. **Incident-sourced signatures**: Every scan finding maps to a real incident. Makes security concrete ("this resembles the Replit agent that deleted a production database") vs abstract ("potential data loss risk").

2. **Fail-closed everywhere**: Missing amount → deny. Unparseable limit → deny. Missing identity → deny. Auth-disabled mode refuses reachable bind addresses.

3. **Write-once, append-only**: Skills immutable after publish, roles never deleted, audit chain append-only. Makes the historical record trustworthy.

4. **Separation of policy from state**: Pure `decide()` function receives state as input, doesn't manage it. Governor manages session state and calls pure policy. Clean separation.

5. **SSRF + DNS rebinding defense**: Static URL validation + connect-time IP pinning. Resolves all A/AAAA records, re-checks each address, pins socket to validated address. No second unchecked resolution.

## Relevance to Our Work

| Our Concept | MakerChecker Equivalent |
|---|---|
| OpenClaw approvals (native approvals, elevated) | Approval gates with n-of-m quorum, named approvers |
| Skill permissions | RBAC with deny-by-default grants, versioned skills |
| Agent trust | SoD (agent can't approve its own work), audit trail |
| `tools.exec.security` | Scan signatures (detect dangerous tool patterns) |

### Direct Takeaways
- **Scan signatures concept**: We could build something similar for OpenClaw skill auditing — map skill tool patterns to known incident types
- **SoD pattern**: Formally preventing agents from approving their own work is more rigorous than our current approach
- **Incident naming**: Making security findings concrete with real incident references is much more persuasive than abstract warnings

## Community Health (07-07)
- 41⭐, 1 fork, 1 open issue
- Created 2026-06-11, active through 07-06
- Solo dev (`makerchecker` org) but well-structured (CONTRIBUTING.md, good-first-issues doc)
- Dual license: AGPL-3.0 core, Apache-2.0 SDK
- Good issue discussion quality (see #80 — thoughtful exchange about AAPR companion profile)
- Helm chart, Docker Compose, hardened deployment — production-oriented

## Tracking
- **Signal**: Novel approach (governance not sandbox), incident-sourced signatures, real-world use cases
- **Risk**: Solo dev, very early (41⭐). Could stall.
- **Category**: Agent security/governance
- **Next**: Revisit 07-21 — check star growth, community engagement, whether scan signatures expand

Links: [[agent-security]], [[agent-harness-landscape]], [[skill-trust-landscape-2026-04]]
