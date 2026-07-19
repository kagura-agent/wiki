---
title: Paca — AI-Native Project Management
status: tracking
created: 2026-06-16
updated: 2026-06-16
revisit: 2026-06-23
stars: 1616
repo: Paca-AI/paca
tags: [project-management, scrum, ai-collaboration, mcp, openhands]
last_verified: 2026-07-19
---

# Paca — AI-Native Project Management

> "Jira gives you a backlog. Paca gives your AI agents a seat at the table."

Open-source, self-hosted Scrum platform where AI agents and humans are **equal teammates** — same board, same sprints, same process. 928⭐, Apache-2.0, created 2026-03-20.

## Why It Matters

Most agent-PM integrations bolt a chatbot onto existing tools. Paca inverts this: agents are **first-class Scrum participants** who pick up tasks, write BDD specs, contribute to system design docs, and appear on the Scrumban board alongside humans. This is the [[collaboration-bottleneck]] solution taken seriously — not "AI assists humans" but "AI and humans share a process."

## Architecture (clean, well-documented)

| Service | Stack | Role |
|---|---|---|
| `services/api` | Go (Gin) | Business logic, persistence, event publishing |
| `services/realtime` | Node.js (Socket.IO) | Real-time delivery via Valkey Streams |
| `services/ai-agent` | Python (FastAPI + [[openhands]] SDK) | Agent orchestration, Docker sandbox per agent |
| `apps/web` | React (TanStack Start, shadcn/ui) | UI |
| `apps/mcp` | TypeScript | MCP server with dynamic plugin tool loading |

**Boundary rule**: API owns state, realtime only delivers, ai-agent executes but never writes DB directly. Clean separation.

**Data bus**: Valkey Streams between services. Agent triggers via `paca:agent:triggers`, conversation events via `paca:agent:events`.

## Key Technical Decisions

1. **WASM plugin sandbox** — Backend plugins compile to WebAssembly (Go/Rust/AssemblyScript), run in wazero with capability-based permissions. More secure than JS-based plugin systems. Frontend plugins are standard module bundles.
2. **OpenHands SDK for agent isolation** — Each agent conversation spawns its own Docker container. No shared filesystem. Contrast with our subagent model (shared workspace, JS isolation).
3. **MCP as integration layer** — `@paca-ai/paca-mcp` npm package. Plugin tools registered at runtime. Both user-mode and agent-mode with scoped identity.
4. **Skills distribution** — Ships Claude Code skills (paca, paca-breakdown, paca-clarify, paca-do, paca-doc, paca-epic, paca-estimate, paca-prioritize, paca-setup, paca-sprint, paca-test). This is the SKILL.md format as distribution — similar to [[agentskills-io-standard]].
5. **P-A-C-A cycle** — Plan → Act → Check → Adapt. Explicit formalization of Scrum + scientific method. Similar to our [[flowforge]] but at the project management level.

## Community & Health

- **Solo dev risk**: pikann has 726/866 commits (~84%). Copilot is #2 with 137. Essentially a one-person project with AI assistance.
- **Responsive maintainer**: Issues closed within 24hrs, feature requests acknowledged immediately. 0 open issues.
- **Growth**: 838→928⭐ in 1 day (HN front page effect). 50 forks. Created March 2026.
- **HN reception** (168pts, 60 comments): Positive. People compare to hand-rolled solutions, validate the "agents as team members" model. Key comment: "Where does Jira really sit in a world eaten up by vibecoding?"

## Relevance to Us

**Direct relevance**: Medium. We don't use Scrum/project boards, but the framing is instructive.

**Insights worth internalizing**:
1. **"Same board" framing** is powerful — agents that share the same process/UI as humans feel more like teammates than tools. Our [[team-lead]] skill does something similar but at the GitHub Issue level, not a dedicated PM tool.
2. **WASM plugin sandbox** is more secure than our JS/shell skill system. If OpenClaw ever needs plugin isolation, WASM is the proven path.
3. **Skills-as-distribution** — shipping Claude Code skills alongside the MCP server is a smart distribution strategy. Makes the tool instantly usable from Claude Code without MCP setup.
4. **Docker-per-agent isolation** (via OpenHands) is heavy but secure. Trade-off vs. our lightweight subagent approach.

**What we wouldn't adopt**:
- Full Scrum process overhead — our [[flowforge]] workflows are lighter and don't require a separate UI.
- OpenHands dependency — adds Docker-in-Docker complexity.

## Tradeoffs & Concerns

- Solo dev = bus factor 1. If pikann loses interest, project stalls.
- Phase 1 just completed; Phase 2/3 have RBAC, observability, scaling — basic enterprise features still missing.
- OpenHands SDK is a significant dependency (large, Python, Docker-heavy).
- "0 open issues" can mean great triage or can mean low outside contribution.

## ACP Agent Support (v0.10.0, 2026-07-18)

Paca shipped a full ACP integration in PR#284 (13,301 additions, 79 changed files) — a second agent "shape" alongside their existing LLM/sandbox agents. Key architecture:

### Local Bridge Daemon (`apps/acp-bridge`)

PyPI package `paca-acp-bridge`, runs locally via `uvx`. Wraps OpenHands SDK's `ACPAgent` to spawn coding CLIs (Claude Code, Codex, Gemini CLI, or custom ACP server) as local subprocesses. **No source code leaves the user's machine** — the bridge only relays task requests and streams conversation events back over an authenticated WebSocket.

This is a fundamentally different trust model from their Docker sandbox approach:
- Sandbox agents: Paca clones code into Docker container, manages everything
- ACP agents: user's own machine, own credentials, own git/gh auth, own MCP servers/skills

### Threading/Deadlock Fix (PR#290)

The initial PR used `conversation.run()` on a dedicated thread, but `ACPAgent` treats the **entire ACP turn as a single step** — so `pause()` (which works between steps) couldn't cancel mid-turn. Fixed by switching to `conversation.arun()` as an `asyncio.Task`:
- `interrupt()` now cancels the task immediately → SDK sends real ACP `session/cancel`
- Avoids cross-thread state-lock deadlock documented in OpenHands SDK issues #3348/#3350

The event callback has a dual-path design:
- **Same-loop calls** (from `arun()` task): `create_task()` instead of blocking `run_coroutine_threadsafe().result()` (which would self-deadlock)
- **Cross-thread calls** (from ACPAgent's "portal" thread): `run_coroutine_threadsafe()` is correct here

### Reliability Patterns

1. **Outbox Queue**: `BridgeClient` uses bounded `asyncio.Queue` (5000 max) with a dedicated `_sender_loop` that retries messages across WebSocket reconnects. Prevents lost `turn_status` messages that would leave conversations stuck at RUNNING.
2. **Server-side Watchdog**: `acp_dispatch.py` schedules a timeout task for every dispatched turn. If bridge disconnects mid-dispatch (Valkey Pub/Sub has no delivery guarantee), the watchdog fails the conversation rather than leaving it stuck forever.
3. **Hash-only Token Storage**: Bridge tokens stored as SHA-256 hash, plaintext shown once at generation.

### Relevance to [[openclaw]] ACP

Our ACP uses a similar pattern (spawn ACP harness as subprocess) but through the gateway directly, not a separate bridge daemon. Key transferable insights:
- **The async/thread boundary is the hardest part** — any system bridging async event loops and thread-based agent SDKs will hit the same deadlock patterns. Paca's dual-path callback is a clean solution.
- **Outbox pattern for reliability** — our ACP doesn't have explicit message queuing for reconnect scenarios; worth considering.
- **Watchdog for dispatch** — defensive pattern against message loss in pub/sub systems.
- Paca's approach of running the bridge as a separate daemon (vs. our integrated gateway) trades setup complexity for security isolation.

## Followup Log

- **2026-06-16**: Initial scout. 928⭐, Apache-2.0, created March 2026.
- **2026-07-11**: 1564⭐ (+68% since initial). Pushed 07-10. Very active: sigstore error fix (#264), MCP node version update (#263), agent permission/prompt refactoring (#262). THRIVING 6/6. Phase 2 features shipping.
- **2026-07-19**: 1616⭐ (+3%). v0.10.0 released with full ACP agent support (PR#284, 13k additions). Bridge daemon architecture, arun()-based deadlock fix (PR#290), keyboard shortcuts (PR#293), conversations page (PR#287), custom field filters (PR#286). 13 ext PRs/30d, THRIVING 5/6.

## Links

- [[collaboration-bottleneck]] — Paca's direct answer to turn-based AI interfaces
- [[agent-human-collaboration-product]] — agent as teammate, not tool
- [[centaur-loop]] — related human-governed AI feedback loop concept
- [[agentskills-io-standard]] — skill distribution via SKILL.md
- [[flowforge]] — our lighter workflow approach vs. Paca's full PM
