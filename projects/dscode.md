---
title: "DSCode — DeepSeek-First Multi-Provider Coding Agent"
created: 2026-08-03
status: active
stars: 101
repo: thinkany-ai/dscode
lang: TypeScript
last_verified: 2026-08-14
---

# DSCode

> Local-first, multi-provider coding agent runtime with DeepSeek V4 Flash as economical default. MIT licensed.

## Key Facts

- **Created**: 2026-07-31 (101⭐ in 3 days, 16 forks)
- **Stack**: TypeScript + Rust (API server) + Bun + Vitest
- **Framework**: Built on `@earendil-works/pi-coding-agent` (internal)
- **Providers**: DeepSeek, OpenAI Codex, OpenAI, Anthropic, OpenRouter, Z.AI, Kimi, MiniMax, xAI (9 total)
- **License**: MIT

## Architecture Patterns

### 1. Provider-Aware Routing
Each provider has configured defaults (model + effort level). DeepSeek gets `max` effort (because cheap), others get `medium`. Provider aliases accepted (`grok` → `xai`, `kimi` → `kimi-coding`). Auth stored in `~/.dscode/auth.json` (0600 perms).

### 2. Parallel Subagents (4 Roles)
```
delegate({ tasks: [{ role, task }] })  // max 8 tasks, 4 parallel
```
- **explorer**: read-only investigation, `--permission plan`, `--sandbox read-only`, thinking=low
- **reviewer**: read-only review, same sandbox as explorer
- **tester**: sandboxed test/diagnostic, workspace-write sandbox
- **implementer**: isolated detached git worktree, `--permission auto`, `--sandbox workspace-write`, thinking=max, returns diff

Key design: implementers get isolated worktrees → can't corrupt main working tree. Subagent spawns are self-recursive (`dscode --print --no-session`). Depth limited to 1 (no sub-sub-agents).

### 3. OS Sandboxing
- **macOS**: Seatbelt (`sandbox-exec`) with path-based write rules
- **Linux/CI**: Docker container (configurable image via `DSCODE_SANDBOX_IMAGE`)
- **Default**: network blocked, credential env vars stripped from child processes
- Modes: `danger-full-access` | `workspace-write` | `read-only`

### 4. Session Storage
Tree-shaped JSONL locally. Sessions survive restarts. `--no-session` for ephemeral subagent runs.

### 5. Ecosystem Compatibility
Reads AGENTS.md + CLAUDE.md. Supports MCP servers, agent skills, hooks, project trust, background jobs. Not creating a new ecosystem — riding the existing one.

## Comparison to Claude Code / Codex

| Aspect | DSCode | Claude Code | Codex |
|--------|--------|-------------|-------|
| Default model | DeepSeek V4 Flash | Claude Opus | GPT-5.6 |
| Multi-provider | 9 providers native | Anthropic only | OpenAI only |
| Sandbox | Seatbelt/Docker | Container | Container |
| Parallel agents | 4-role delegation | CC coordinator | Codex workers |
| License | MIT | Proprietary | Source-available |
| Maturity | 3 days old | Years | Months |

## Relevance to Our Direction

**Interesting patterns:**
1. **Worktree isolation for implementers** — clean separation, main agent owns integration. Similar to our subagent model but with git-level isolation guarantees.
2. **Provider routing as first-class** — not bolted on, each provider gets correct effort/thinking defaults.
3. **Credential stripping** — removing API keys from subprocess environments is a security detail many agents miss.
4. **Seatbelt on macOS** — OS-native sandboxing without Docker overhead. Practical for development.

**Not directly adoptable:**
- Our setup already has multi-model via Floway proxy, so provider routing is less relevant
- The 4-role taxonomy is interesting but fixed — our subagent pattern is more flexible (task-defined roles)
- Worktree isolation could be worth exploring if we do parallel code changes

## Community Assessment

- 2 issues (HTTP server request + Windows support) — both feature requests, no architectural criticism yet
- Too new for meaningful community signal
- Solo dev team (thinkany-ai) — need to watch velocity

## Verdict

Clean, well-structured implementation. Most interesting for the worktree-isolation pattern and credential-stripping approach. Not revolutionary architecture — more of a well-executed synthesis of existing patterns (Claude Code's agent model + DeepSeek's economics + multi-provider flexibility). Worth monthly revisit to see if community develops.

[[coding-agent-ecosystem]] [[agent-harness-landscape]] [[agent-security]]

## 2026-08-14 Follow-up

- **329⭐** (+226% in 11 days, from 101⭐) — explosive growth, no longer "too new for community signal".
- Pushed today (08-14). v0.3.6 + desktop-v0.1.0 shipped 08-13.
- Recent merged PRs: MCP image-tool result fix, desktop personalization, opencode-go login — **3 external PRs in 5 days** (Chal1ce, lihuithe, songlairui), so the solo-dev risk is resolving into a small contributor surface.
- Watch item: growth is outpacing the safety-boundary review — verify Seatbelt/Docker sandbox + credential stripping survive feature velocity.

Links: [[coding-agent-ecosystem]], [[agent-harness-landscape]], [[agent-security]]
