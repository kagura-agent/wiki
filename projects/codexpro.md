---
title: "CodexPro — ChatGPT-to-Local-Repo MCP Bridge"
created: 2026-06-20
updated: 2026-06-20
tags: [mcp, chatgpt, local-agent, cloud-to-local, tunnel, handoff]
last_verified: 2026-06-20
---

# CodexPro — ChatGPT-to-Local-Repo MCP Bridge

**Repo**: [rebel0789/codexpro](https://github.com/rebel0789/codexpro)
**Stars**: 459⭐ (4 days old, created 2026-06-16)
**Language**: TypeScript (~5350 LOC)
**License**: MIT
**Version**: 0.28.5 (npm published)

## What Problem Does This Solve?

ChatGPT web has stronger reasoning models (GPT-5.5 Thinking, etc.) but no local filesystem access. Codex CLI has local access but uses quota fast on high-tier models. CodexPro bridges this gap: it runs a local MCP server that exposes your repo to ChatGPT Developer Mode, so ChatGPT web can read, write, edit, search, and run safe verification commands against your local codebase.

The killer value prop: **use expensive ChatGPT models for planning/review, cheap local models (via Pi/OpenCode) for implementation, with CodexPro as the handoff bridge**.

## Why Now?

1. ChatGPT Developer Mode + MCP app support landed (mid-2026)
2. Model-tier arbitrage is real — high-tier planning + cheap implementation = cost efficiency
3. 459⭐ in 4 days signals genuine demand for cloud-to-local bridging

## Architecture

```
ChatGPT Web (cloud)
  ↓ MCP protocol over HTTPS
  [Cloudflare/ngrok tunnel]
  ↓
CodexPro (local HTTP/stdio MCP server, Express + @modelcontextprotocol/sdk)
  ↓
Local filesystem + git + safe bash
```

### Core Components

- **`server.ts`** (2000+ LOC) — MCP tool registration hub. Uses `@modelcontextprotocol/sdk` McpServer. Registers 15-22 tools depending on tool mode (minimal/standard/full).
- **`guard.ts`** — PathGuard: workspace containment, symlink escape prevention, blocked glob matching (`.env`, `.git`, keys, `node_modules`). WorkspaceManager: multi-workspace session support.
- **`config.ts`** — Three mode axes: `BashMode` (off/safe/full), `WriteMode` (off/handoff/workspace), `ToolMode` (minimal/standard/full). CLI args + env vars.
- **`bashOps.ts`** — Safe bash allowlist (test/build/lint/typecheck commands). Blocks destructive ops, pipes, redirects, env expansion, shell readers. Bash session guard for multi-workspace safety.
- **`http.ts`** — Express server with StreamableHTTPServerTransport, token auth (timing-safe comparison), session management, and a polished onboarding HTML page.
- **`stdio.ts`** — Stdio transport for local MCP clients.
- **`proContext.ts`** — "Pro context fallback" — bundles repo state into a single markdown for models that can't call MCP tools.
- **`workspaceOps.ts`** — AGENTS.md chain loading (AGENTS.override.md → AGENTS.md → agents.md → .agents.md), skill discovery.
- **`capabilitiesOps.ts`** — Discovers workspace/user/plugin skills by scanning skill directories, loads bounded SKILL.md.
- **`redact.ts`** — Auto-redacts OpenAI API keys and secret assignments from all tool output.
- **`toolCardWidget.ts`** — HTML widget for visual cards in ChatGPT UI via Apps SDK resource registration.

### Security Model

Layered defense:
1. **Token auth** — `codexpro_token` in query param or Bearer header, timing-safe comparison
2. **Workspace containment** — all ops must resolve within allowed roots, symlink escape detection
3. **Blocked globs** — `.env`, `.git/**`, `node_modules`, private keys, build outputs
4. **Bash allowlist** — safe mode only allows test/build/lint/git-read commands; blocks rm/curl/ssh/pipes/redirects
5. **Write modes** — off (read-only), handoff (.ai-bridge only), workspace (full write within root)
6. **Bash session guard** — `--bash-session main --require-bash-session` prevents rogue ChatGPT-triggered commands in wrong workspace
7. **Output redaction** — secrets stripped from all tool responses

**Not an OS sandbox** — the README is honest about this. It's developer-tool security, not production isolation.

## The .ai-bridge Handoff Pattern

This is the most architecturally interesting piece. The `.ai-bridge/` directory is a file-based coordination protocol between a cloud planner and local executor:

```
.ai-bridge/
  current-plan.md          ← cloud model writes the implementation plan
  agent-status.md          ← local agent writes execution status
  implementation-diff.patch ← local agent writes final diff
  execution-log.jsonl      ← structured execution events
  decisions.md             ← implementation decisions log
  open-questions.md        ← unresolved questions
  pro-context.md           ← bundled repo context for non-MCP models
```

**Flow**:
1. ChatGPT web calls `handoff_to_agent(agent="pi", plan="...")` via MCP
2. CodexPro writes `.ai-bridge/current-plan.md`
3. Local user runs `codexpro execute-handoff --agent pi --model provider/cheap-model`
4. Or uses `codexpro watch-handoff` daemon to auto-execute on plan changes
5. ChatGPT web reads results via `read_handoff` or `codex_context`

**Is this a reusable pattern?** Yes, but limited. It's essentially "file-based message passing" — the simplest possible coordination protocol. Works for sequential plan→execute→review workflows. Doesn't handle concurrent modification, conflict resolution, or multi-agent negotiation. Compare to [[acp]] which has session management, streaming, and bidirectional communication.

## Tool Exposure Design

Three tiers deliberately limit ChatGPT's tool picker overwhelm:
- **Minimal** (9 tools): config, workspace, read/write/edit, bash, changes
- **Standard** (15 tools): + tree, search, skill loading, handoff, pro-context export
- **Full** (22 tools): + inventory, snapshots, raw git tools, codex-context, compatibility wrappers

Skills discovered in workspace are surfaced as metadata, not individual MCP tools — smart choice to avoid action catalog explosion.

## Tradeoffs

### Security vs Convenience
- Public tunnel with token = easy setup, but token-in-URL is inherently risky
- `--bash full` exists for power users but breaks the safety model
- No OS-level sandbox — trusts the allowlist/glob approach
- Quick tunnels = new URL every restart (bad UX) vs stable tunnels = more setup

### Cloud Dependency
- Requires ChatGPT Developer Mode (Plus/Pro accounts)
- Requires tunnel provider (Cloudflare/ngrok) for HTTPS
- Pro models can't call MCP tools (issue #8) — needs the Pro context bundle fallback
- OpenAI tool safety gate can block bash calls before they reach CodexPro (issue #1)

### Single-User Design
- One MCP session per workspace per port
- No multi-user auth, no team features
- Token auth is flat — no scopes, no roles

## Community & Issues

Active community engagement from maintainer. Key issues:
- **#1, #4, #5**: Generic agent handoff + execute-handoff + watch-handoff — all implemented, showing fast iteration (user ramhaidar wrote extremely detailed feature requests)
- **#8**: GPT 5.5 Pro can't call MCP tools — fundamental ChatGPT platform limitation, not CodexPro bug
- **#12**: Cloudflare tunnel setup friction — real UX problem with tunnel token flow not covered by setup wizard
- **#13**: Bash session guard request — user scared by unexpected ChatGPT-triggered bash; implemented session guard in 4 PRs within hours

No test files found (`find` returned empty) — concerning for a tool that exposes filesystem and bash to remote callers. The `npm run smoke` exists but tests aren't in the repo tree.

## Relationship to Agent Ecosystem

### vs [[openclaw]]
OpenClaw is local-first with its own gateway, channel system, plugin architecture, and ACP for agent-to-agent communication. CodexPro is specifically a ChatGPT→local bridge — narrower scope, simpler architecture. OpenClaw doesn't need CodexPro because it already has local execution + remote model access. But the **demand signal** (459⭐ in 4 days) validates the cloud-to-local bridge pattern.

### vs [[codex-chatgpt-control]]
codex-chatgpt-control bridges Codex→ChatGPT via browser automation (DOM manipulation). CodexPro bridges ChatGPT→local repo via MCP protocol. They solve opposite directions of the same problem. CodexPro's approach (standard protocol) is cleaner than browser automation.

### vs Claude Code / Codex CLI
These are local-first coding agents. CodexPro doesn't compete — it's designed to work alongside them. ChatGPT plans, Codex/Pi/OpenCode executes. The handoff pattern makes them complementary.

### Complements vs Competes
**Complements**: any local coding agent (Claude Code, Pi, OpenCode, Codex) — serves as the planning/review bridge.
**Competes with**: nothing directly — this is a new niche. The closest competitors would be other MCP bridges for ChatGPT, but the field is early.

## Relevance to Our Direction

### Direct Relevance: Low
OpenClaw already has local-first agent execution, multi-model support, and ACP for agent coordination. We don't need a ChatGPT-specific bridge.

### Pattern Relevance: Medium
1. **File-based handoff protocol** (`.ai-bridge/`) — simple but effective for sequential plan→execute→review. Our FlowForge workflows are more sophisticated but this validates the "lightweight handoff file" pattern.
2. **Tool mode tiering** — exposing different tool sets based on context is a good UX pattern. OpenClaw skills already do this but could be more explicit about "minimal vs full" surfaces.
3. **Bash safety design** — the allowlist + blocked pattern approach is well-implemented. Our own exec security could learn from the explicit `safe` vs `full` mode design.
4. **Pro context bundle** — "export everything the model needs as one markdown" is a useful fallback pattern when tool calling isn't available.

### Ecosystem Signal: High
459⭐ in 4 days tells us: developers want to use their best available model for planning while executing locally with cheaper models. The model-tier arbitrage pattern is real and growing.

## Key Takeaway

CodexPro is a well-executed single-purpose bridge that validates the **cloud planner → local executor** pattern. The `.ai-bridge` handoff is simple file-based coordination that works for sequential workflows. The real innovation isn't the code — it's proving that the demand exists for cloud-to-local agent bridging at protocol level (MCP) rather than UI level (browser automation).

## Links

- [[coding-agent-ecosystem]] — broader ecosystem context
- [[codex-chatgpt-control]] — opposite-direction bridge (Codex→ChatGPT via DOM)
- [[acp]] — more general agent communication protocol
- [[openclaw]] — our local-first agent platform
