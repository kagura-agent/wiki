---
title: "sandboxes (tastyeffectco)"
created: 2026-06-04
updated: 2026-06-04
tags: [agent-infrastructure, sandbox, self-hosted, app-builder]
last_verified: 2026-06-04
---

# sandboxes — Self-Hosted Dev Sandboxes for AI App Builders

**Repo**: tastyeffectco/sandboxes | **Stars**: 181 (1 day old) | **License**: MIT | **Lang**: Go
**Created**: 2026-06-03

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

## Ecosystem Position

Mid-layer infrastructure: between bare Docker and full K8s orchestration. Competes with [[opensandbox]] at lower end, E2B at cloud end. The "no K8s" positioning is smart — most AI app builders are indie teams who don't want to manage clusters.
