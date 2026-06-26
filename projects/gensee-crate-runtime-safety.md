---
title: "Gensee Crate — Runtime Safety for AI Coding Agents"
created: 2026-06-25
tags: [agent-safety, runtime-security, rust, macos, coding-agents]
source: https://github.com/GenseeAI/gensee-crate
status: skim
last_verified: 2026-06-26
---

# Gensee Crate — Runtime Safety for AI Coding Agents

## What It Is

Rust sidecar that provides full-stack, long-horizon runtime safety for AI coding agents (Claude Code, Codex). Watches system events, tool calls, skills, and memory. Real-time enforcement via agent hooks + offline lineage/provenance in a web dashboard.

**Author:** GenseeAI (company)
**Born:** 2026-06-23 (2 days old)
**Stars:** 47⭐, 6 forks
**Status:** Alpha, macOS-first

## Key Features

1. **Deterministic policy enforcement** — PreToolUse hook → allow/ask/deny. Path/tool based, not regex (no ReDoS). Fail-closed on policy load failure.
2. **Long-horizon provenance** — SQLite lineage graph linking prompts → tool calls → filesystem effects → artifacts → alerts
3. **System event monitoring** — macOS `eslogger` for exec/file events (interim; signed EndpointSecurity client planned)
4. **4 workflows**: `gensee watch` (sidecar audit), `gensee run` (sandboxed agent launch), `gensee policy` (management), dashboard (web UI)
5. **AgentCanary benchmark** — preliminary results show defense improvement with low overhead
6. **Encrypted local store** — AES at rest with local key

## Architecture

```
Agent (Claude Code / Codex)
  │ PreToolUse hook
  ▼
Gensee Hook Bridge (per-agent integration)
  │
  ▼
Policy Engine (deterministic, path/tool matchers)
  │ allow / ask / deny
  ▼
Local Store (JSONL + SQLite lineage graph)
  │
  ▼
Dashboard (Vite web UI — timeline, lineage, policy, review)
```

## Policy Categories

- Secret reads, destructive ops, out-of-workspace writes
- Cloud-metadata access, control-plane writes
- Dangerous executable content
- Resource governance (read sizes, fan-out, quotas, rate limits)
- Egress allowlists, proxy requirements

## Comparison

| vs | Difference |
|----|-----------|
| [[clawpatrol]] | Claw Patrol = network-level MITM. Gensee = application-level hooks + OS events |
| [[peerd-browser-agent]] | peerd = built-in architecture. Gensee = bolt-on sidecar for existing agents |
| OpenClaw native approvals | Similar hook model, but Gensee adds provenance/lineage graph + cross-session tracking |

## Relevance

- **Corporate angle** — "Contact us" for fleet-wide enforcement. Targets enterprise security teams.
- **Lineage graph** — cross-session provenance is novel. Most safety tools are session-scoped.
- **Bolt-on model** — works with unmodified agents (just hooks). Low adoption friction.
- **macOS-only currently** — limits immediate utility for our Linux setup.

## Track

- Revisit: 2026-07-02 (Linux support progress, community growth, benchmark reproducibility)
