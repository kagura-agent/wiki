---
title: "ccglass — Coding Agent Observability Proxy"
created: 2026-05-25
updated: 2026-05-25
status: active
depth: deep-dive
stars: 317
last_verified: 2026-05-28
---

# ccglass — See What Your Coding Agent Sends

**Repo**: [jianshuo/ccglass](https://github.com/jianshuo/ccglass)
**Stars**: 239 (3 days old, ~80/day growth)
**Language**: JavaScript (Node ≥18), MIT
**Author**: jianshuo (建硕)

## What It Does

Local reverse-proxy + web dashboard that intercepts traffic between coding agents (Claude Code, Codex, OpenCode, DeepSeek-TUI, Kimi, Ollama, etc.) and their model APIs. Shows you exactly what the agent sends: full system prompts, message history, tool schemas, tool calls, token/cache/cost breakdown, and turn-to-turn diffs.

## Why It's Interesting

Coding agents are black boxes by design — you see the final output but never the intermediate prompts, tool selections, or context management. Traditional HTTP proxies (Charles, mitmproxy) don't work because these CLI tools ignore `HTTP_PROXY`/`HTTPS_PROXY` and use direct HTTPS. ccglass solves this with a clever trick: override the base-URL env var (e.g., `ANTHROPIC_BASE_URL`) to point at a local HTTP proxy, which captures everything in plaintext before forwarding to the real API over HTTPS. No CA certs, no TLS pinning.

## Architecture

```
Agent CLI → plain HTTP → ccglass proxy (localhost) → HTTPS → real API
                ↓
           .ccglass/ JSON logs → web dashboard (SSE live updates)
                ↓
           MCP server (agent self-inspection)
```

**Core modules** (~3000 LOC total, very lean):
- `proxy.js` (77 LOC) — the intercepting reverse proxy. Strips `accept-encoding` so response is plaintext. Records request on receive, response on upstream completion.
- `store.js` (132 LOC) — JSON file persistence + EventEmitter bus for live updates. Auth tokens masked by default (regex-based, covers Bearer + sk-ant patterns). Session = timestamped directory, each request = `NNNN.json`.
- `providers.js` (130 LOC) — provider registry. Each provider knows: env var to override, default upstream URL, wire format (anthropic/openai), CLI command to spawn. 13 providers supported.
- `formats/anthropic.js` + `formats/openai.js` — format-specific adapters for parsing, viewing, reassembling streamed SSE responses, and computing token costs.
- `diff.js` (55 LOC) — SHA1-hash-based content-block diffing between consecutive requests. Shows what context was added/removed between turns. This is the killer feature for understanding context management.
- `mcp.js` (123 LOC) — MCP server that exposes captured logs back to the agent itself. The agent can inspect what it just sent. Meta-observability.

## Key Design Decisions

1. **Base-URL override, not HTTP_PROXY**: Sidesteps the fundamental problem that Node/native CLIs ignore proxy env vars. Each provider just needs one env var override.
2. **No TLS interception**: The agent does its own HTTPS to the real API. ccglass only sees the localhost HTTP hop. Zero certificate setup.
3. **Format-agnostic core**: proxy/store/diff are format-independent. Only the adapters know Anthropic vs OpenAI wire format.
4. **Self-inspection via MCP**: When wrapping Claude Code, ccglass registers its own MCP tools so the agent can query its own request history. This is genuinely novel — the agent debugging itself.
5. **Streamed SSE reassembly**: Both adapters reconstruct the full response from SSE chunks, so the dashboard shows the complete message even though the wire is streaming.

## Tradeoffs & Limitations

- **Codex ChatGPT auth mode bypasses**: Codex in ChatGPT login mode uses WebSocket transport (`wss://chatgpt.com`) that ignores `OPENAI_BASE_URL`. Only API-key mode works.
- **No persistence across sessions by default**: Each run creates a new session directory. Historical analysis requires `ccglass view`.
- **No aggregation/analytics**: Pure capture + view. No trends, no anomaly detection, no cost alerts over time.
- **Windows issues**: Several open issues about Windows compatibility (command not found, path resolution).

## Relevance to Us

### Direct
- **OpenClaw ACP debugging**: We could use ccglass (or its architecture) to observe what our ACP harnesses actually send. Currently opaque.
- **Token/cost visibility**: We track costs at the gateway level, but ccglass shows per-request cache-hit rates and exact token breakdown — more granular.
- **The diff feature**: Understanding how context evolves turn-to-turn is exactly the kind of insight we need for context budget optimization.

### Architectural Patterns Worth Borrowing
- **Base-URL interception pattern**: Applicable to any CLI that reads a base URL from env. Simple, no-dependency, works everywhere.
- **MCP self-inspection**: The idea of an agent querying its own execution history through MCP is powerful. Could OpenClaw expose session history as MCP tools?
- **Format adapter abstraction**: Clean separation between transport (proxy), persistence (store), and format (anthropic/openai) is well-done.

### Not Applicable
- We don't need the proxy for OpenClaw itself — we control the gateway and can log at the source. ccglass is for third-party CLI tools where you don't control the implementation.

## Issues Landscape

33 issues in 3 days. Mostly feature requests (Azure support, IDE integration) and Windows bugs. Claude auto-triage via issue-to-PR automation (documented in README). Active community engagement signal.

## Ecosystem Position

Fills the **coding agent observability** gap. Competes with browser devtools and generic HTTP proxies but purpose-built for the agent use case. The turn-to-turn diff and MCP self-inspection are differentiators no generic tool has.

Related: [[agentops]] (operational layer, different scope — fleet-level vs single-session), [[eval-view]] (eval framework, complementary)

## Update Log

### 2026-05-28 (316⭐, 142 tests)
Rapid evolution from proxy → full observability dashboard:
- **v0.5.0**: Latency tracking (TTFT, gen window, tok/s sparklines), session rollups (tokens, cache-hit %, USD est), model filter, light/dark theme, copy-as-cURL
- **v0.6.0**: Cross-session usage summary — per-model and per-session aggregation across all captures for a project
- Solo dev (jianshuo) shipping at very high velocity. 142 tests now (up from ~100).
- Positioning shift: "see what your agent sends" → "know what your agent costs and how it performs"

### 2026-05-28 — Community Explosion & Auto-Fix Pipeline (317⭐)

**Star growth**: 239→317 in 3 days (+33%). Hitting critical mass.

**Community signal — THRIVING**: 3+ external contributors (KorenKrita 4 commits, marcuslannister 3, ivanberry 1) merging substantial features in v0.5–v0.6. Rare for a ~300⭐ project. Multiple external PRs merged in 48h.

**Key new features (v0.5.0–v0.6.0)**:
- **Latency tracking**: TTFT (time-to-first-token), gen window, tok/s sparklines per request
- **Session rollups**: total tokens, cache-hit %, USD cost estimate per session
- **Cross-session usage summary**: per-model and per-session aggregation across all captures
- **Content-addressed storage** (PR#45): git-style SHA256 blob dedup for captured traffic. System prompts/tools repeated every turn → stored once as `sha256:<hex>` refs. Sharded 2-char prefix dirs.
- **Model filter + light/dark theme** in dashboard
- 142 tests (up from ~100 at first contact)

**Auto-Fix Pipeline Architecture** (the real insight):
The `.github/workflows/claude.yml` workflow is a textbook example of Claude Code CI:
1. Every new issue triggers Claude Code Action
2. Claude TRIAGES first (worth doing? aligned with direction? small+low-risk?)
3. Only opens a fix PR if triage passes; otherwise comments explaining why not
4. Human merges — Claude never pushes to main or bumps version
5. `allowed_non_write_users: "*"` — works for external users too (via `CLAUDE_TRIGGER_PAT`)
6. `@claude` mention in any issue/PR comment triggers iterative response

This is why external contributors are flowing in: the bar to contribute is "open an issue → Claude may auto-fix it → maintainer merges". External contributors also submit their own PRs (KorenKrita, marcuslannister) which suggests the project has earned enough trust for direct contributions.

**Content-addressed blob store** (`src/blobs.js`) — elegant pattern:
- `blobRef(value)` → SHA256 hash of JSON.stringify
- `writeBlob(root, value)` → write-once to `blobs/<ab>/<sha256>.json` (atomic via tmp+rename)
- `packRecord()` splits a full request into: system/tools/each message → blob refs, small metadata stays inline
- Directly analogous to git object storage. Massive dedup for agent traffic where system prompt + tools repeat every turn.

**Relevance to us**:
- The auto-fix CI pattern is directly applicable to our repos. [[OpenClaw]] could benefit from Claude Code Action for issue triage.
- Content-addressed capture storage is a pattern we could use for [[session-logs]] dedup (system prompts repeat across turns).
- TTFT/tok-per-sec metrics in dashboard — we track this at gateway level but ccglass's per-request breakdown is more granular.

## Verdict

**Worth tracking — upgraded to THRIVING.** 317⭐ (was 239 at first contact), 33% growth in 3 days. Community health excellent: multiple external contributors shipping features. Auto-fix CI pipeline is a force multiplier for both velocity and contributor onboarding. Evolving from capture proxy → full observability platform with cost analytics.

**Contribution opportunity**: Low (Claude handles most issues), but the auto-fix pipeline itself is the real takeaway — worth replicating in our repos.
