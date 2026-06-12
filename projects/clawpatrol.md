---
title: "Claw Patrol — Agent Security Firewall (Deno)"
created: 2026-06-12
updated: 2026-06-12
tags: [agent-security, firewall, proxy, hitl, deno]
last_verified: 2026-06-12
---

# Claw Patrol — Agent Security Firewall

**Repo**: denoland/clawpatrol | **Stars**: 772⭐ (2026-06-12) | **Lang**: Go | **License**: MIT
**Created**: 2026-04-28 | **By**: Deno (institutional backing)

## What It Is

A **wire-level security proxy** that sits between AI agents and production systems. Instead of trusting agents to self-police, Claw Patrol intercepts traffic at the network layer and enforces rules written in HCL with CEL expressions.

Three deployment modes:
- `clawpatrol gateway config.hcl` — run the proxy
- `clawpatrol join <gateway>` — WireGuard tunnel for whole host
- `clawpatrol run <agent-cmd>` — per-process tunnel (Linux netns / macOS NetworkExtension)

## Architecture

**Protocol families**: HTTP (MITM TLS termination), SQL (Postgres, ClickHouse), Kubernetes — each family exposes typed facets (http.method, sql.verb, k8s.resource) for CEL conditions.

**Rule system**: HCL config with CEL conditions. Three verdicts: allow, deny, or **approve** (human-in-the-loop). Approve routes through Slack/dashboard human approvers. Unevaluable conditions **fail closed** — safe default.

**HITL (Human-in-the-Loop)**: Async approval flow. Agent's request is parked, operator gets notified in Slack/dashboard, approves or denies. Fingerprinting for deduplication. Retry relay for approved requests.

**Toolgate** (draft, #489): Most interesting upcoming feature — **LLM tool-call gating at the proxy level**. Intercepts `api.anthropic.com` responses, parses `tool_use` blocks, applies rules *before the agent sees them*. For HITL, rewrites the LLM response so the agent polls a clawpatrol endpoint instead. Currently Anthropic-only, env-var configured.

## Key Design Decisions

1. **Wire-level, not application-level** — agents don't need modification. Works with any agent framework (OpenClaw, Claude Code, Codex, anything).
2. **CEL for conditions** — expressive but sandboxed, no arbitrary code execution.
3. **MITM architecture** — terminates TLS to inspect traffic. Requires trust in the proxy.
4. **Fail closed** — evaluation errors deny by default.
5. **SQLite state** — local state management, migrations included.

## vs OpenClaw's Approval System

OpenClaw's exec approval is **application-level** — the agent framework knows about approvals and participates. Claw Patrol is **network-level** — transparent to the agent, works on any traffic.

| Aspect | OpenClaw | Claw Patrol |
|--------|----------|-------------|
| Layer | Application (tool calls) | Network (wire traffic) |
| Agent awareness | Agent participates | Agent unaware |
| Coverage | Tool-specific | Protocol-family-wide |
| Setup | Built-in | Separate infrastructure |
| Granularity | Per-tool | Per-request (CEL on any field) |

**Complementary, not competing.** OpenClaw gates at the intent level (tool calls), Claw Patrol gates at the execution level (actual network requests). Defense in depth.

## Relevance to Us

1. **Validates the trust layer thesis**: The agent ecosystem's biggest bottleneck is trust, and tools like this are the response. 772⭐ in 6 weeks from Deno (institutional) signals real demand.
2. **Toolgate is the frontier**: Intercepting LLM responses before agents see them is a new approach. If this matures, it could become a standard deployment pattern.
3. **Our credential isolation** ([[agent-credential-security]]) could be complemented by Claw Patrol's network-level enforcement.
4. **Contribution opportunity**: Go codebase, good test coverage, active development. The toolgate feature is draft — early contributor advantage.

## Issues Worth Watching

- #489: Toolgate (LLM tool-call gating) — draft, not merged
- #580: Docker survival (relay robustness)
- #398: Dashboard v2

## Verdict

**Track.** Most interesting new project in the agent security space since Agent Safehouse. Wire-level approach is fundamentally different from application-level safety. Toolgate feature could reshape how agent deployments work. Revisit 2026-06-26.

---
*Deep read: 2026-06-12 13:00 CST*
