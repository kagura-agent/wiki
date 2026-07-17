---
title: "AgentSpace — Human + Agents. One Team. One Workspace"
created: 2026-07-04
updated: 2026-07-17
status: following
stars: 690
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

### 4. Persona-Card Export (MERGED 07-15)
PR#15 by external contributor @lodar: `agent-space employee export-persona --name <employee> [--sign] [--out <path>] [--json]`

**Architecture (worth studying):**
- **Clean layer separation**: Pure `employeeToPersona()` mapper in domain package (runtime-agnostic, no node:crypto) → signing layer in CLI (Node-dependent). Composable design.
- **Privacy-first**: Sensitive fields (instructions, skills, owner) REDACTED by default. Must explicitly opt in with `includeSensitive: true`. Good pattern for shareable identity artifacts.
- **Zero-dep ed25519 signing**: did:key derivation (multicodec 0xed01 prefix + base58btc) + stable JSON canonicalization (recursive key sort) using only `node:crypto`. No external crypto libs.
- **Self-verifying**: Card carries its own PEM public key + base64 signature. Any party can verify without contacting the issuer.
- **OpenAgent v0.2 spec**: JSON persona document with id, name, role, org, behavior, face (with generation recipe), voice (written rules + sample), posts_about, provenance block.
- **Deterministic anchoring**: FNV-1a hash of name → stable hex color for visual identity.

**Relevance to [[agent-identity]]:** This is a concrete implementation of portable, verifiable agent identity. The privacy-default + opt-in sensitive pattern is directly applicable to any agent exporting its identity to external systems.

### 5. Memberless Channel Privacy
Channels without explicit members default to private (deny external access). Security-by-default for agent workspaces where sensitive context flows.

## Community Health (07-17, updated)

- **Stars**: 690 (was 649, +6.3% in 6 days — growth resumed)
- **External contributors**: 5 unique merged PR authors (hobostay, xing139565, lodar, TianyuFan0504, DivyanshSingh9073)
- **Merged ext PRs (recent)**: #15 persona-card export (@lodar), #19 Antigravity provider (@TianyuFan0504), #16 channel realtime refresh (@xing139565)
- **Issues**: 7 open
- **30d stats**: 11 external PRs, 13 unique issue authors
- **Dev pace**: Active shipping — persona-card (07-15), antigravity provider (07-13), persona node signing refactor (07-13)
- **Verdict**: 🟢 THRIVING 6/6 — upgraded from WARM. External contributors driving features, not just fixes

## Growth Trajectory

| Date | Stars | Event |
|------|-------|-------|
| 2026-07-04 | 606 | First tracked. Feishu integration merged |
| 2026-07-11 | 649 | Star plateau (+0.15%). Slack in testing. 2 ext PRs merged (hobostay). Downgraded to WARM |
| 2026-07-17 | 690 | +6.3%. Persona-card export merged (PR#15, external). Antigravity provider. Upgraded to THRIVING 6/6 |

## Relevance to Our Direction

1. **Agent-in-channel** pattern — agents as team members, not separate tools. Contrast with [[openclaw]]'s model (agent has its own session, bridges to channels)
2. **Multi-provider daemon** — similar to how OpenClaw routes to different LLM providers via floway
3. **Persona-card export** (#15) aligns with portable agent identity concepts
4. **ESM migration pain** (#18: @slack/web-api dynamic require) — common Node.js ecosystem challenge we also face

## Open Questions

- Will Slack integration reach parity with Feishu?
- Per-provider concurrency: does it scale to 10+ providers?
- ~~How does persona-card export relate to existing standards (OpenAgent spec)?~~ → ANSWERED: uses OpenAgent v0.2 spec exactly, validates with `@5dive/openagent` CLI
- Will other agent platforms adopt the OpenAgent persona-card format? (portable identity standard potential)
- Antigravity provider — what is this? (not documented in README yet)

---

Links: [[agent-identity]], [[openclaw]], [[nanobot]], [[multi-agent-distributed-systems]]
