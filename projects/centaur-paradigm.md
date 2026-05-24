---
title: "Centaur — Shared Agent Platform for Teams (paradigmxyz)"
created: 2026-05-24
source: https://github.com/paradigmxyz/centaur
stars: 431
language: Python
license: null
status: early-production
last_verified: 2026-05-24
---

# Centaur (paradigmxyz)

Shared, self-hosted agent platform by paradigm (the Reth/Foundry team). Slack-native: mention the bot, it spins up a K8s sandbox, runs a coding agent, delivers results back to the thread. 431⭐ in 6 days, 24 open issues, 46 forks — strong early traction.

## What It Solves

The "one-off local setup" problem: every team member runs their own Claude Code / Codex locally. Centaur centralizes this into one shared agent with managed sandboxes, credentials, tools, and delivery.

## Architecture

```
Slack/API → Centaur API (Python/FastAPI) → Postgres durable state
                                         → Kubernetes sandbox (per-thread)
                                           → harness adapter (amp/claude-code/codex/pi-mono)
                                           → iron-proxy (credential injection + outbound control)
```

Key modules:
- **`agent.py`** — thin pipe: spawn sandbox, pipe stdin/stdout, NDJSON streaming. "2 layers, 0 queues, 0 threads"
- **`harness_protocol.py`** — pure functions to parse different agent protocol events (amp, claude-code, codex, pi-mono). Detects turn boundaries across harness dialects
- **`warm_pool.py`** — pre-warmed sandbox pool (default 5), eliminates ~15s startup latency. Evicts on API restart to avoid stale image
- **`workflow_engine.py`** — checkpoint/replay durable workflows (inspired by Cloudflare Workflows). Steps discovered at runtime via `ctx.step(name, fn)`, checkpointed to Postgres, replayed on crash
- **`tool_sdk.py`** — secret resolution: ToolContext → pluggable backend → default. Tools are Python dirs with `pyproject.toml` + `client.py`
- **iron-proxy** — controlled outbound access + credential injection without exposing raw API keys

## Harness Adapter Pattern

The `harness_adapter.py` + `harness_protocol.py` split is elegant:
- Adapter: prepares the filesystem for each harness (e.g., Amp needs AGENT.md symlink)
- Protocol: parses NDJSON events to detect turn completion — each harness has different signals:
  - amp/claude-code: `result` event or `assistant` with `stop_reason=end_turn` (excluding subagent events via `parent_tool_use_id`)
  - codex: `turn.completed` / `turn.failed`
  - pi-mono: `agent_end`

This is essentially what [[OpenClaw ACP|acp-router]] does but at a lower level — Centaur wraps CLI agents in K8s containers and speaks their native NDJSON, while OpenClaw wraps them as ACP sessions.

## Relation to Our Direction

**Direct competitor in spirit** — both Centaur and OpenClaw solve "agent as infrastructure." Key differences:

| Aspect | Centaur | OpenClaw |
|--------|---------|----------|
| Target user | Teams (shared agent) | Individuals (personal agent) |
| Deployment | K8s-native, Helm chart | Single binary, runs anywhere |
| Agent harnesses | amp, claude-code, codex, pi-mono | ACP (same harnesses + more) |
| Chat integration | Slack-first | Multi-platform (Discord, Feishu, Telegram, etc.) |
| Credential model | iron-proxy (sidecar) | pass/sops/env integration |
| Workflow engine | Built-in checkpoint/replay | FlowForge (external) |

**Insights for us:**
1. **Warm pool pattern** — pre-spawning sandboxes to eliminate startup latency. Could apply to ACP session pools
2. **Pure harness protocol parsing** — separating protocol detection from I/O is clean. OpenClaw could benefit from similar pure-function event parsing
3. **Organization overlays** — layering custom tools/workflows/prompts without forking the base. OpenClaw does this with skills but Centaur's tool SDK approach (pyproject.toml + client.py + .env) is more structured
4. **Credential boundaries** — iron-proxy as a sidecar that injects credentials without the agent seeing raw keys. More principled than env var passing

## Community Signal

- 24 open issues in 6 days, external contributors already (kkennis on Codex token support)
- gakonst (paradigm founder) actively triaging and deploying
- Real operational issues (NetworkPolicy, sandbox GC, warm pool eviction) = production use
- paradigm team's infra quality bar is high (see Reth, Foundry)

## Tracking

Worth following — paradigm has the engineering depth to make this serious. Revisit 05-31.

Links: [[self-evolving-agent-landscape]], [[agent-memory-landscape-202603]], [[centaur-loop]]
