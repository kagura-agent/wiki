---
title: "sandboxd — Self-Hosted Dev Sandbox Engine"
created: 2026-06-11
updated: 2026-06-11
tags: [infrastructure, sandbox, coding-agent, docker, go]
status: following
last_verified: 2026-06-11
---

# sandboxd — Self-Hosted Dev Sandbox Engine

**Repo**: tastyeffectco/sandboxd | **Stars**: 563 (8 days old) | **Language**: Go | **License**: MIT

## What It Does

Open-source backend for AI app-builder products (like Lovable, Bolt, v0, Replit). One command gives you:
- Isolated Linux containers per user/sandbox
- Built-in coding agents (OpenCode + Claude Code pre-installed in images)
- Per-sandbox live preview URLs via Traefik

## Architecture (Why It's Interesting)

Deliberately "boring" stack: **single Go binary + Docker CLI + Traefik + SQLite**. No K8s, no message queue, no separate DB.

Key patterns:
- **Wake-on-demand**: stopped sandboxes auto-restart on first HTTP request. Traefik catch-all → sandboxd wake path → docker start → "warming up" page → auto-refresh. This is the cost arbitrage — dozens of sandboxes share one box instead of one VM each.
- **Dual reapers**: idle reaper (stop after threshold) + memory pressure reaper (stop when host RAM low). Dense packing without OOM.
- **Reconciler**: on boot, diffs Docker state vs SQLite, converges Docker to DB truth. Crash-safe by design.
- **runtimed** (in-sandbox supervisor): compiled into base image, runs as PID 1 inside container. Supervises dev server + runs coding tasks from API.
- **No Docker SDK**: shells out to `docker` CLI. Simpler, fewer dependencies, easier to debug.

## Isolation Model

Hardened runc: `--cap-drop=ALL`, `--security-opt=no-new-privileges`, read-only rootfs + tmpfs /tmp, memory ceiling, pids-limit, fd ulimits. Explicit threat model: "authenticated accountable users, not anonymous hostile multi-tenancy." Kernel-CVE escape mitigated by patching, not VM boundary.

## Current Limitations (v1, from Issues)

- No per-sandbox disk quota (host fs shared)
- No multi-host clustering (single-host only)
- No Firecracker/gVisor runtime (Docker only)
- No ARM64 support yet
- Default-allow egress, no logging

## Ecosystem Position

This is the **infrastructure layer** for the AI app-builder wave. As coding agents commoditize, the differentiator shifts to: sandbox management, preview URLs, cost control, multi-tenant isolation. sandboxd packages the "hard parts" that every app-builder needs.

Competitors/alternatives: E2B (cloud-hosted, not self-hosted), Daytona (heavier), raw Docker/LXD (no multi-tenant features).

## Relevance to [[OpenClaw]]

- **Wake-on-demand pattern**: OpenClaw's sandbox exec model could benefit from similar idle→stop→wake-on-request. Currently sandboxes are always-on or not-present.
- **Reconciler pattern**: SQLite-as-truth + boot-time convergence is a robust pattern for any stateful agent infra.
- **Not a competitor**: sandboxd hosts coding agents; OpenClaw orchestrates them. Could be complementary — OpenClaw spawning work into sandboxd-managed environments.

## Links

- [[agent-ecosystem-scout-2026-06-11]]
- Related: [[guard-skills]] (verification layer for agent-generated code)
