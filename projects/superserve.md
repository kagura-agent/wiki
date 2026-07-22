# Superserve — Firecracker MicroVM Sandbox for AI Agents

- **Repo**: superserve-ai/superserve (419⭐, Apache-2.0, TypeScript)
- **Sister project**: superserve-ai/sandtrace (4⭐, Rust) — hypervisor-level audit trails
- **Created**: 2025-10-10 (pivoted from "agentic-ray"/RayAI to sandbox infra ~2026-04)
- **Last push**: 2026-07-21
- **Team**: 3 core devs (meAmitPatil 72, nirnejak 54, pavitrabhalla 34 commits)
- **Links**: [[agent-credential-security]], [[opensandbox]], [[sandboxd]], [[sandboxes-tastyeffect]], [[clawpatrol]], [[agent-safety]]

## What It Does

Persistent, pausable Firecracker microVM sandboxes for AI agents. SDK-first (TypeScript + Python). Key differentiator: **secret proxy pattern** and **Sandtrace audit layer**.

## Architecture

```
Control Plane (API)          Data Plane (per-sandbox)
├── Sandbox CRUD             ├── boxd-{id}.{host} subdomain
├── Secret management        ├── WebSocket exec (superserve.exec.v1)
├── Template/Snapshot        ├── File upload/download
└── Network policy           └── Secret proxy daemon (egress swap)
```

Monorepo: Bun workspaces + Turborepo + uv (Python). Next.js 16 console. Mintlify docs.

## Key Patterns

### 1. Secret Proxy (most novel)

Agent never sees real credentials. Flow:
1. Team stores secret with allowed hosts (`Secret.create({ provider: "anthropic", value: KEY })`)
2. Sandbox binds secret to env var (`secrets: { ANTHROPIC_API_KEY: "anthropic-prod" }`)
3. Agent reads env var → gets **proxy token**, not real key
4. In-host daemon intercepts outbound to declared hosts → swaps proxy for real credential
5. Every proxy-mediated request is audited (`secret.getAudit()`)
6. Rotation: `secret.rotate(newValue)` — sandbox env unchanged, new value used on next egress

**Why this matters**: Eliminates credential exfiltration vector entirely. Even if agent dumps its environment, the real key never existed inside the VM.

### 2. Sandtrace (hypervisor-level audit)

Captures from **outside the VM** (agent cannot influence instrumentation):

| Layer | Mechanism | Records |
|-------|-----------|---------|
| Network | AF_PACKET on Firecracker tap device | All TCP/UDP: dst, port, bytes |
| Filesystem | OverlayFS upper-dir monitoring | Files created/modified/deleted |
| Syscall | ptrace on jailer (optional) | System call activity |

Audit log is **hash-chained JSONL** (SHA-256 of record + prev_hash). Tamper-evident — any modification/insertion/deletion/reordering detected in O(n) verification pass.

Policy manifest (YAML) evaluates events in real-time → allow/deny/anomaly verdicts.

### 3. Pause/Resume Lifecycle

Sandboxes can be paused (cold) and resumed. Auto-delete on pause timeout (`autoDeleteSeconds`). Useful for cost management of long-idle agent sessions.

### 4. WebSocket Exec Protocol

- Binary frames: 1-byte channel tag (0x00=stdin, 0x01=stdout, 0x02=stderr)
- JSON text frames: lifecycle/control
- 32KB stdin chunking (backward compat with older server limits)
- Token refresh on stale connection → resume transparently

## Competitive Position

| vs | Superserve advantage |
|---|---|
| E2B | Secret proxy (E2B exposes keys inside sandbox), Sandtrace audit, open monorepo |
| Daytona | Purpose-built for agents (not dev environments), lighter weight |
| OpenSandbox (Alibaba) | Apache-2.0 community model, secret proxy pattern |
| [[sandboxd]] | Managed service vs self-hosted-only, secret proxy |

Sandtrace explicitly supports E2B/Daytona as providers → positioning as audit **layer** across sandbox ecosystem, not just their own VMs.

## Relevance to Our Direction

1. **Secret proxy pattern** validates [[agent-credential-security]] principles — we should never let agents hold real credentials in their environment
2. **Hash-chained audit** is a concrete implementation of agent accountability that could inform trust scoring
3. **Pause/resume** is relevant to long-running cron agents — could save resources
4. **The pivot** from agentic-ray to sandbox infra is a market signal: isolation infrastructure > yet another agent framework
5. **Sandtrace as external observer** aligns with [[clawpatrol]]'s philosophy (security from outside the agent, not inside)

## Anti-intuitive Findings

- **Repo pivoted hard** — older issues reference "RayAI" (a Ray wrapper for agent orchestration). The team bet that sandbox isolation would be more valuable than yet another orchestration layer. The star count (419) after pivot suggests market agreed.
- **Secret proxy is invisible to the agent** — the agent code doesn't need to know about the proxy. It just reads `process.env.ANTHROPIC_API_KEY` and the host daemon handles the rest. Zero agent-side changes required.
- **Sandtrace is provider-agnostic** — despite being built by the Superserve team, it adapts to any Firecracker-based sandbox. They're betting the audit layer is more defensible than the sandbox itself.

## Health Assessment (2026-07-22)

- 30+ commits in 3 weeks (Jul)
- Active SDK development (exec chunking, LangChain integration)
- Small team (3-5 people), consistent output
- Young (419⭐) but differentiated
- Watch for: community growth, external contributors, Sandtrace adoption

## Deep Read Date

2026-07-22 (first study). Revisit 07-29.
