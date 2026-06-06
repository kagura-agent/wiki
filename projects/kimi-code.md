---
title: "Kimi Code CLI — Moonshot AI's Coding Agent"
date: 2026-06-06
source: https://github.com/MoonshotAI/kimi-code
stars: 1901
license: MIT
language: TypeScript
created: 2026-05-22
tags: [coding-agent, CLI, ACP, subagents, tool-scheduling]
last_verified: 2026-06-06
---

# Kimi Code CLI

> "The Starting Point for Next-Gen Agents" — Moonshot AI's open-source coding agent CLI. TypeScript monorepo, MIT licensed, ~1.9k⭐ in 2 weeks.

## Architecture Overview

### Monorepo Structure (pnpm + Nix)

```
packages/
  agent-core/     — The unified agent engine (Agent, Session, Loop, Tools, Profiles, Skills, Hooks, MCP, Plugins)
  kosong/         — LLM/provider abstraction layer (Anthropic, Google GenAI, OpenAI, Kimi native)
  kaos/           — Execution environment abstraction (local FS/process, SSH remote)
  node-sdk/       — Public TypeScript SDK + harness (kimi-code-sdk)
  acp-adapter/    — Agent Client Protocol adapter (ACP 0.23.0)
  oauth/          — Kimi OAuth + managed auth
  telemetry/      — Client-side telemetry
  migration-legacy/ — Migration from older kimi-cli format
apps/
  kimi-code/      — CLI/TUI application (consumes agent-core via node-sdk)
  vis/            — Visual debugging for sessions/replays (server + web)
plugins/
  marketplace.json — Plugin registry (official: kimi-datasource, curated: superpowers)
```

**Runtime requirements**: Node.js ≥ 24.15.0, pnpm 10.33.0. TypeScript 6.0.2. Uses `tsdown` for build, `vitest` for test, `oxlint` for linting.

### Single-Binary Distribution (Node.js SEA)

Uses **Node.js Single Executable Application (SEA)** — not Rust, not Go, not pkg. The native build pipeline is a 5-stage process:
1. `01-bundle.mjs` — Bundle with tsdown
2. `02-sea-blob.mjs` — Generate SEA blob
3. `03-inject.mjs` — Inject blob into Node.js binary
4. `04-sign.mjs` — Code sign (macOS)
5. `05-verify.mjs` — Verify signature

Built via Nix (`flake.nix`) for reproducible cross-platform builds (x86_64/aarch64 × Linux/macOS). The install scripts (`curl | bash` / PowerShell `irm | iex`) download the pre-built binary — no Node.js needed on user's machine.

## Agent Loop Architecture

### The Loop (`packages/agent-core/src/loop/`)

The loop is **stateless** — it owns no sessions, transport, compaction, permissions UI, or protocol bridging. These are "host-layer responsibilities."

**Key components:**
- **`run-turn.ts`** — Turn-level convergence: abort checks, max-step enforcement, usage aggregation, optional continuation after non-tool stops
- **`turn-step.ts`** — One provider step: beforeStep hook → buildMessages → LLM.chat (with retry) → tool execution → afterStep hook
- **`tool-call.ts`** — Tool-call batch lifecycle: validate → prepare hooks → authorize hooks → execute → finalize hooks → dispatch results
- **`tool-scheduler.ts`** — **Resource-aware concurrent tool execution**: tools with non-conflicting file accesses run in parallel; conflicting accesses are serialized

**Loop flow per turn:**
```
while (not aborted, not max_steps):
  executeLoopStep():
    beforeStep hook → check blocked?
    buildMessages() → construct message array
    chatWithRetry() → call LLM
    recordUsage() → track tokens immediately (before tool exec!)
    if stopReason == 'tool_use':
      runToolCallBatch() → validate → prepare → authorize → execute → finalize
    step.end event
    afterStep hook
  if stopReason != 'tool_use':
    shouldContinueAfterStop? → break or continue
```

### Tool Access Control — The Scheduling Innovation

This is architecturally distinctive. Each tool declares its **resource accesses** via `ToolAccesses`:
- `ToolAccesses.none()` — no conflicts (e.g., resolved errors)
- `ToolAccesses.all()` — globally exclusive (arbitrary side effects)
- `ToolAccesses.readFile(path)`, `writeFile(path)`, `searchTree(path)`, etc.

The `ToolScheduler` then:
1. Checks if a new task conflicts with active + queued tasks
2. Non-conflicting tasks run concurrently
3. Conflicting tasks wait until the conflicting tasks finish

**Conflict detection**: reads vs reads = OK; any write vs read/write on overlapping paths = conflict. Path overlap uses prefix matching with normalization.

This is more sophisticated than Claude Code's approach (which appears to run tools sequentially or with simple parallelism). It enables safe concurrent file reads while serializing writes to the same files.

### Tool Grace Timeout

When abort is signaled, tools get a 2-second grace period. If a tool ignores `AbortSignal` and doesn't settle within 2s, it gets a synthetic error result. This prevents hung tools from blocking the agent loop indefinitely.

### User Cancellation Semantics

When user presses stop, the abort reason carries `isUserCancellation` flag. Tool error messages explicitly say "The user manually interrupted" — prevents the model from theorizing about system faults or retrying automatically. Smart detail.

## Subagent Architecture

### Three Built-in Profiles

Defined in `packages/agent-core/src/profile/default/`:

| Profile | Role | Tools | Key Trait |
|---------|------|-------|-----------|
| **coder** | General software engineering | Full (Bash, Read, Write, Edit, Grep, Glob, WebSearch, FetchURL, MCP) | "treat parent agent as your caller" |
| **explore** | Fast codebase exploration | Read-only (no Write/Edit) | Read-only enforcement, parallel tool calls encouraged, git-context injected |
| **plan** | Implementation planning | Read-only | "recommend explore agent first if context insufficient" |

### Subagent Isolation

Subagents are **in-process Agent instances** with their own:
- Context/history (separate from parent)
- Tool set (profile-specific)
- Records persistence
- Model config (inherited from parent)

**Key design decisions:**
1. Subagent inherits parent's model alias and thinking level
2. Subagents don't see parent's context — must receive complete prompt
3. Parent only sees subagent's last assistant message (final summary)
4. Summary quality gate: if result < 200 chars, one continuation attempt to expand
5. Subagents have no cron capabilities (only main agent)
6. 30-minute timeout per subagent execution

### Background Subagents

Two modes:
- **Foreground** (default): blocks parent turn, awaits completion
- **Background**: returns agent ID immediately, result delivered via notification

Background subagents integrate with `BackgroundManager` + `BackgroundTaskPersistence` for durability.

### BTW (Side Questions)

`startBtw()` creates a lightweight subagent for side-channel user questions:
- Uses `InMemoryAgentRecordPersistence` (not persisted)
- Copies parent's projected history
- **All tools disabled** via `DenyAllPermissionPolicy`
- System reminder: "You are a separate, lightweight instance... do not call any tools"

This is clever — it lets the user ask questions mid-task without interrupting the main agent's flow, using the same context but in read-only mode.

## Kosong — LLM Abstraction Layer

Multi-provider support with typed interfaces:
- **Anthropic** (`@anthropic-ai/sdk`)
- **Google GenAI** (`@google/genai`)
- **OpenAI** (both legacy chat completions and responses API)
- **Kimi** (native provider with file handling)

Features:
- Capability registry per model
- Streaming callbacks (text delta, thinking delta, tool call delta)
- Tool schema conversion with Zod → JSON Schema
- Usage/token tracking
- Provider-specific auth resolution

## Kaos — Execution Environment

Abstraction over:
- Local filesystem operations
- Local process execution
- **SSH remote execution** (via `ssh2`) — enables remote coding scenarios

This is the layer that gets swapped in ACP mode — when running under an IDE, file read/write operations route to the client via ACP reverse-RPC instead of local FS.

## ACP Integration

Full ACP adapter (`packages/acp-adapter/`) implementing ACP SDK 0.23.0:

**Coverage: 83% stable agent-side, 44% client reverse-RPC, 1/19 unstable.**

Key capabilities:
- Session lifecycle: new, load, resume, list, prompt, cancel
- Image content blocks (base64)
- MCP forwarding (stdio + HTTP)
- File I/O routed through client (fs/read_text_file, fs/write_text_file)
- Tool approval via session/request_permission
- Config options (model, thinking, mode)

**Not implemented**: terminal reverse-RPC (shell commands still local), audio, embedded context, session/close, logout, most unstable methods.

## Plugin System

Three-tier plugin model:
1. **Official** — maintained by Moonshot (e.g., kimi-datasource)
2. **Curated** — reviewed community plugins (e.g., superpowers)
3. **Community** — any GitHub repo

Plugin manager handles: archive extraction, GitHub resolution, manifest validation, trust-level surfacing. Plugin marketplace available via CDN.

## Hook System

Session lifecycle hooks with trigger points:
- `SubagentStart` / `SubagentStop` — intercept subagent lifecycle
- Tool execution hooks: `prepareToolExecution`, `authorizeToolExecution`, `finalizeToolResult`
- Step hooks: `beforeStep`, `afterStep`, `shouldContinueAfterStop`

Hooks can: block tool calls, replace args, inject synthetic results, stop turns. This enables custom permission policies, output redaction, audit logging.

## Experimental Flags

Feature flags registry at `packages/agent-core/src/flags/registry.ts`:
- Env-driven: `KIMI_CODE_EXPERIMENTAL_<NAME>` toggles one
- `KIMI_CODE_EXPERIMENTAL_FLAG` enables all
- Ship by flipping `default` to `true`

## Interesting Design Tradeoffs

### 1. Stateless Loop, Stateful Host
The core loop (`run-turn.ts`) is intentionally stateless — all state (sessions, compaction, permissions) lives in the host layer. This makes the loop testable and portable across contexts (CLI, ACP, SDK).

### 2. Resource-Aware Tool Scheduling
Unlike Claude Code's simpler parallelism, Kimi Code uses file-path-level conflict detection. This enables safe concurrent reads while serializing writes. The tradeoff: more complexity in the scheduler, but fewer races in file operations.

### 3. In-Process Subagents (not separate processes)
Subagents are Agent instances in the same process, sharing the same generate function. This means:
- No IPC overhead
- Shared model auth
- But also: subagent OOM crashes the parent
- And: CPU-bound tools in subagents block the main thread

### 4. Node.js SEA for Distribution
Chose Node.js SEA over alternatives:
- vs. Rust/Go rewrite: keep TypeScript ecosystem, faster iteration, huge npm dependency graph works
- vs. Docker: lighter, faster startup, no container runtime needed
- vs. Electron: terminal-native, much smaller binary
- Tradeoff: requires Node ≥ 24.15.0 for SEA, pinned nixpkgs channel

### 5. Provider Usage Recorded Before Tool Execution
LLM token usage is recorded immediately after `llm.chat` returns, **before** tool execution. This means aborted tool executions still report model cost. Good accounting discipline.

### 6. Agent != Session
The `Agent` class is decoupled from `Session` — an Agent can exist without a Session. This enables headless/SDK usage where you just want the agent loop without session management overhead.

## Comparison to Claude Code

| Aspect | Kimi Code | Claude Code |
|--------|-----------|-------------|
| Language | TypeScript | TypeScript |
| Distribution | Node.js SEA single binary | npm package |
| Agent loop | Stateless loop + stateful host | Monolithic |
| Tool scheduling | Resource-aware concurrent | Simpler parallel |
| Subagents | In-process (coder/explore/plan) | External process (via tool) |
| Provider support | Multi (Anthropic, OpenAI, Google, Kimi) | Anthropic-first |
| ACP | Full adapter (83% stable) | No ACP |
| MCP | Built-in with AI-native config | Built-in |
| Hooks | Rich lifecycle hooks | Limited |
| Plugin system | Three-tier marketplace | Community extensions |
| Video input | Supported | Not supported |

## Comparison to OpenCode

| Aspect | Kimi Code | OpenCode |
|--------|-----------|---------|
| Language | TypeScript | Go |
| Architecture | Monorepo with packages | Single binary |
| Tool scheduling | Resource-aware | Sequential |
| Subagents | Yes (3 profiles) | No |
| ACP | Yes | No |
| Plugin system | Yes | No |

## Community Issues / Critics (as of 2026-06-06)

From the first 500 issues (~2 weeks):
- **Session restore failures** (#477) — resume reliability concerns
- **Compaction context overflow** (#476) — sends wrong context length during compaction
- **"Approve once" vs "Approve for session" behave identically** (#437) — permission memory not working
- **Subagents can't read AGENTS.md** (#489) — subagent context injection gap vs Claude Code
- **Stale timestamp on resume** (#446) — KIMI_NOW cached, never refreshed
- **System prompt self-contradiction** (#459) — "MUST make actual changes" vs "ask for clarification"
- **Feature request: apply_patch tool** (#494) — multi-hunk patch editing (like OpenClaw's apply_patch)

## Relevance to Our Work

### For OpenClaw's ACP Integration
Kimi Code's ACP adapter is a clean reference implementation:
- Session lifecycle mapping (new/load/resume → agent sessions)
- Tool approval routing through ACP's `request_permission`
- File I/O delegation to IDE via reverse-RPC
- MCP forwarding from client config
- Config option management

### For OpenClaw's Harness
The `kimi-code-sdk` (node-sdk) provides a harness pattern with:
- Session transport abstraction
- Auth facade
- Event typing
- Goal/plan management via SDK
- Model switching at runtime

### Tool Scheduling Pattern
The `ToolScheduler` with resource-aware conflict detection is worth studying for OpenClaw's tool execution. Currently OpenClaw runs tools more sequentially; adopting path-based conflict detection could improve throughput for parallel file reads.

### Subagent Design
Their subagent model (in-process Agent instances with profile-based tool sets) is a different approach from OpenClaw's external-process subagents. The "BTW" side-question pattern is clever and could be adapted.

### Hook System
The layered hooks (prepare → authorize → execute → finalize) with the ability to inject synthetic results is more granular than OpenClaw's current hook system.

## Links

- [[coding-agent]] — Coding agent landscape
- [[oh-my-kimichan]] — Community multi-agent orchestration for Kimi Code
- [[ccglass]] — Observability proxy that works with Kimi Code
- [[self-evolving-agent-landscape]] — Where this fits in the agent ecosystem
