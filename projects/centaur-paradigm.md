---
title: "Centaur — Shared Agent Platform for Teams (paradigmxyz)"
created: 2026-05-24
source: https://github.com/paradigmxyz/centaur
stars: 431
language: Python
license: null
status: early-production
last_verified: 2026-05-31
---

# Centaur (paradigmxyz)

Shared, self-hosted agent platform by paradigm (the Reth/Foundry team). Slack-native: mention the bot, it spins up a K8s sandbox, runs a coding agent, delivers results back to the thread. 673⭐ (from 431 in 7 days, +57%), 56 open issues, 99 forks — strong sustained traction.

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

## Recent Activity (05-24 → 05-31)

~30 commits in 7 days, mostly infrastructure hardening:
- **Tool-server sidecar**: DB pool routing through iron-proxy, overlay tool deps install, healthz polling before readiness signal
- **Sandbox security**: proxy env hardening against extraEnv override, sandbox permissioning fixes
- **Harness updates**: Claude Opus 4.8 rendering support, Codex fanout disabled (experimental), Codex channel-scoped search fix
- **Workflow engine**: clone API env into workflow-run pods, drop per-run iron-proxy
- **New tools**: Laminar investigation tool, Sentry read-only issue perusal
- **Infra**: bypass proxy for observability services, local smoke auth + broker token bootstrap

Key signal: they're hardening iron-proxy/tool-server integration heavily — production usage driving real fixes. Multiple external contributors active.

## Architecture Insights from Issues (05-31 deep read)

**Iron-proxy as credential boundary** is being stress-tested hard:
- Tool-server sidecar needed DB access → instead of passing raw DSN, they route through iron-proxy (PR #286). Real DB creds stay in proxy pod; sandbox only holds proxied DSN. This is principled but creates dependency chains (startup race when proxy isn't ready → PR #302 retry logic)
- Pattern: every new service that needs credentials goes through the proxy → single trust boundary, but also single point of failure
- Relevance to [[OpenClaw ACP]]: we pass credentials via env vars, which is simpler but less isolated. Iron-proxy pattern is worth considering if we ever do multi-tenant

**Sandbox lifecycle is the hardest problem:**
- Sandbox pods never GC after Slack threads go idle (#172) — no TTL controller, no idle detector. Classic "spawn is easy, cleanup is hard"
- `pause_by_id()` deletes pod but DB says "suspended" → resume fails permanently. 2,206 zombie sessions accumulated. Fix: fall through to fresh spawn instead of raising
- Warm pool eviction on restart leaves orphan pods
- All of these are production-discovered — you can't design for them upfront
- Relevance: OpenClaw ACP sessions don't have this problem (process-level, OS handles cleanup), but any K8s-based agent platform will hit exactly this

**Harness dialect fragmentation:**
- Each harness (amp, claude-code, codex, pi-mono) has different turn-completion signals
- Codex fanout was disabled as "experimental and potentially interfering with renderers" — multi-harness rendering is genuinely hard
- Slack renderer duplicating content when harness is claude-code (#oddharsh issue) — live commentary + final answer concatenated

## Community Signal

- 56 open issues (from 24), 99 forks (from 46) — growing fast
- Multiple contributors: mslipper, Zygimantass, gakonst, kmx411, goksu, NormallyGaussian, decofe, 0xdiid
- gakonst still actively triaging
- Production-quality issues (DB pool races, sidecar routing, credential injection) = real usage

## Tracking

Worth following closely — paradigm has the engineering depth and this is clearly production-used internally. Revisit 06-07.

Links: [[self-evolving-agent-landscape]], [[agent-memory-landscape-202603]], [[centaur-loop]]
