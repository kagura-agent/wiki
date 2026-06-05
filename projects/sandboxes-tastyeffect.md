---
title: "sandboxes (tastyeffectco)"
created: 2026-06-04
updated: 2026-06-04
tags: [agent-infrastructure, sandbox, self-hosted, app-builder]
last_verified: 2026-06-05
---

# sandboxes — Self-Hosted Dev Sandboxes for AI App Builders

**Repo**: tastyeffectco/sandboxes | **Stars**: 395 (2 days old, ~200⭐/day) | **License**: MIT | **Lang**: Go
**Created**: 2026-06-03 | **Deep-read**: 2026-06-05

Open-source engine for the "prompt → app → preview URL" pattern (Lovable/Bolt/v0 clones). One Go binary + Docker + Traefik + SQLite, no Kubernetes.

## Architecture

Single binary `sandboxd` controls Docker daemon:
- **Sandbox lifecycle**: create/list/exec/stop/destroy via Docker CLI (no SDK)
- **Workspace persistence**: bind-mounted dirs survive stop/reboot
- **State**: SQLite WAL, reconciled on boot
- **Edge**: Traefik with Docker label provider, per-sandbox preview URLs
- **In-sandbox supervisor** (`runtimed`): manages dev server + coding agent tasks

### Sleep/Wake Model (most interesting pattern)
- **Idle reaper**: stops containers after inactivity threshold, freeing RAM
- **Pressure reaper**: stops containers when host memory runs low
- **Wake-on-request**: catch-all Traefik route (priority-1) forwards to sandboxd → `docker start` → wait for port → serve "warming up" page → auto-refresh
- Result: many users on one machine, only active sandboxes consume RAM

### Isolation
`runc` hardened: `cap-drop=ALL`, `no-new-privileges`, read-only rootfs, `tmpfs /tmp`, memory ceiling, pids-limit. Explicitly NOT for hostile multi-tenancy — threat model assumes authenticated users.

## Comparison with [[opensandbox]]

| Aspect | sandboxes | OpenSandbox (Alibaba) |
|---|---|---|
| Target | AI app builders (Lovable clones) | General agent sandbox infra |
| Complexity | Single Go binary + Docker | Multi-runtime, K8s, gVisor, Firecracker |
| Scale model | One machine, sleep/wake | Cluster, always-on |
| Isolation | runc hardened | gVisor/Kata/Firecracker |
| Protocol | REST API | Sandbox Protocol (OpenAPI specs) |
| Stars | 181 (1 day) | 10.5k |

sandboxes is the "indie hacker" answer to OpenSandbox's enterprise approach. Different audiences, but the sleep/wake pattern is universally useful.

## Relevance to Us

- **Infrastructure commoditization signal**: The Lovable/Bolt UX pattern is now open-source
- **Sleep/wake pattern**: Could apply to OpenClaw's sandbox model (idle agents release resources)
- **Coding agent pre-installed**: OpenCode + Claude Code in sandbox images — validates "sandbox as agent runtime" trend
- Not directly relevant to our identity/self-evolution work, but useful reference for infrastructure design

## Deep Read Notes (2026-06-05)

### Code Quality
Exceptionally clean Go code. Every package has a clear single responsibility. Comments reference a `CLAUDE.md` spec document — this was likely AI-pair-programmed with a very detailed spec.

### Wake Admission (most interesting pattern)
The `wake/admit.go` implements a two-phase admission check:
1. Read `/proc/meminfo`, calculate if waking a sandbox (default 800MB cost) would leave ≥10% headroom
2. If not enough → run a **synchronous pressure-reaper tick** (may stop an idle sandbox to free RAM)
3. Re-read meminfo → if still not enough → denied

This is elegant: the system self-heals under memory pressure by sacrificing idle sandboxes to serve active requests. The `Refused` atomic bool is a fast-path optimization — if the pressure reaper already flagged emergency mode, skip the expensive meminfo read.

### Idle Reaper Design
Two reapers run as goroutines:
- **Idle reaper** (30s interval): stops containers idle past threshold (default 600s). Has a post-WebSocket/SSE disconnect grace period (60s) to handle brief reconnects.
- **Pressure reaper** (10s interval): monitors host memory. Uses cgroup `memory.current` (RSS), NOT OOM events, to rank kill candidates. Three bands: >15% free (safe), 10-15% (stop oldest), 5-10% (stop more aggressively), <5% (emergency, stop by RSS).

Key insight: the pressure reaper reads cgroup memory directly, not relying on OOM kills which come too late. This avoids the D-state stall problem where cooperative allocators get stuck before reaching memory.max.

### Forward Auth
Traefik-based auth for private sandboxes. Cookie JWT validation in the hot path, with Prometheus histogram for p95 monitoring. Clean separation of preview-auth from API-auth.

### Architectural Patterns Worth Borrowing
1. **SQLite as truth, Docker as derived state**: Boot reconciliation diffs DB vs Docker and converges. DB always wins. Simple and correct.
2. **Priority-based routing**: Running sandbox wins (priority 100), catch-all wake route (priority 1). No central routing table to maintain.
3. **Per-ID locks**: `idlock.Registry` prevents concurrent wake/snapshot/destroy on same sandbox. Simple mutex registry pattern.
4. **Synchronous reaper in admission**: Instead of "reject and retry later", the admission path actively frees resources before deciding. Reduces user-visible failures.

### What's Missing (0 issues, too new)
- No egress control beyond default-allow
- No GPU/accelerator support
- No multi-host / clustering
- No billing/metering integration
- These are expected for a 2-day-old project

### Relevance Assessment
- **Direct use**: Low — we don't build app-builder products
- **Pattern transfer**: High — sleep/wake, admission-with-self-heal, SQLite-as-truth patterns are universally applicable
- **Ecosystem signal**: Very high — confirms "agent infrastructure" as the current growth category

## Ecosystem Position

Mid-layer infrastructure: between bare Docker and full K8s orchestration. Competes with [[opensandbox]] at lower end, E2B at cloud end. The "no K8s" positioning is smart — most AI app builders are indie teams who don't want to manage clusters.
