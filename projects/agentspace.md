---
title: "AgentSpace — Human + Agents. One Team. One Workspace"
created: 2026-07-04
updated: 2026-07-11
status: following
stars: 649
repo: HKUDS/AgentSpace
lang: TypeScript
license: MIT
last_verified: 2026-07-11
---

# AgentSpace — Multi-Platform Agent Workspace

A unified workspace where humans and AI agents collaborate through messaging integrations (Feishu, Slack planned). Digital employees coexist in channels alongside humans, with agent replies streamed in realtime.

## Why It Matters

Most agent platforms focus on single-agent execution. AgentSpace positions agents as **team members in existing communication channels** — the same surfaces humans already use. This is the "embed agents in your workflow" thesis versus "go to the agent's UI."

## Architecture Patterns

### 1. Multi-Platform Integration Model
Each messaging platform (Feishu, Slack) gets a dedicated integration module. The daemon routes messages between channels and agent providers (Gemini, NanoBot, OpenCode). Not a lowest-common-denominator abstraction — each integration is native-feeling.

### 2. Per-Provider Concurrency (proposed)
Issue #12: support configurable concurrency per AI provider. Prevents one slow provider from blocking the workspace. Matches how real teams work — different specialists handle different queues.

### 3. Secret Redaction in Provider Output
Daemon value-redacts secrets from Gemini/NanoBot/OpenCode provider output before surfacing in channels. Security-in-depth for shared workspaces where agent output is visible to all channel members.

### 4. Persona-Card Export (proposed)
Issue #15: export digital employees as OpenAgent persona cards. Portable agent identity — define once, run on multiple platforms. [[agent-identity]] interoperability pattern.

### 5. Memberless Channel Privacy
Channels without explicit members default to private (deny external access). Security-by-default for agent workspaces where sensitive context flows.

## Community Health (07-11, updated)

- **Stars**: 649 (was 648, +0.15% — plateau)
- **External contributors**: 4 PR authors (hobostay: 2 merged, xing139565, lodar, DivyanshSingh9073)
- **Merged ext PRs**: #9 auth fix (hobostay), #10 secret redaction (hobostay)
- **Open PRs**: 3 (stream replies, persona-card export, contributing.md)
- **Issues**: 10 open (ESM compat #18, streaming, export, concurrency, sandbox)
- **Dev pace**: Feishu merged 07-01, Slack testing branch 07-09. Mostly docs commits since 07-01
- **Verdict**: 🟡 WARM — community healthy but star growth plateaued. Downgraded from THRIVING

## Growth Trajectory

| Date | Stars | Event |
|------|-------|-------|
| 2026-07-04 | 606 | First tracked. Feishu integration merged |
| 2026-07-11 | 649 | Star plateau (+0.15%). Slack in testing. 2 ext PRs merged (hobostay). Downgraded to WARM |

## Relevance to Our Direction

1. **Agent-in-channel** pattern — agents as team members, not separate tools. Contrast with [[openclaw]]'s model (agent has its own session, bridges to channels)
2. **Multi-provider daemon** — similar to how OpenClaw routes to different LLM providers via floway
3. **Persona-card export** (#15) aligns with portable agent identity concepts
4. **ESM migration pain** (#18: @slack/web-api dynamic require) — common Node.js ecosystem challenge we also face

## Open Questions

- Will Slack integration reach parity with Feishu?
- Per-provider concurrency: does it scale to 10+ providers?
- How does persona-card export relate to existing standards (OpenAgent spec)?

---

Links: [[agent-identity]], [[openclaw]], [[nanobot]], [[multi-agent-distributed-systems]]
