# Cometline

> AI companion for your workspace, with per-project memory, coding agents, and a native desktop chat UI.

| Field | Value |
|---|---|
| **Repo** | [Cometline/cometline](https://github.com/Cometline/cometline) |
| **Status** | Active (daily commits, single developer) |
| **Stars** | 32 |
| **Language** | Go (backend) + TypeScript/SvelteKit (frontend) |
| **License** | Apache-2.0 |
| **Created** | 2026-06-14 |
| **Last checked** | 2026-06-20 |
| **Platform** | macOS only (Apple Silicon + Intel), Electron desktop |

## What It Is

Cometline is a **local-first desktop AI companion** with three layers:

1. **cometline** — Electron + SvelteKit chat UI (desktop shell)
2. **cometmind** — Go agent runtime (brain: agent loop, SQLite persistence, memory, tools, ACP delegation, Discord gateway)
3. **comet-sdk** — Go provider-agnostic LLM I/O library (Anthropic, OpenAI, OpenAI-compatible, Codex)

The desktop app runs cometmind as a **sidecar process** on `127.0.0.1:7700`, communicating via HTTP/SSE. The dependency direction is strictly one-way: cometline → cometmind → comet-sdk.

## Problem It Solves

A locally-running AI assistant with:
- **Per-project workspace isolation** (sessions, tools, memories don't leak across projects)
- **Persistent semantic memory** that learns across sessions
- **Coding agent delegation** via ACP (to OpenCode, Claude Code, etc.)
- **Companion persona** (Minako/Souma) with switchable avatars and system prompts
- **Discord bot** running the same agent runtime

The "why now" is the convergence of ACP as a standard protocol + capable local-first LLMs + the gap between terminal coding agents and polished desktop UX.

## Architecture Deep Dive

### Agent Loop (`cometmind/internal/agent/runner.go`)

Standard multi-step agent loop (up to 50 steps):
1. Load SDK messages from SQLite
2. Retrieve memories (semantic search) — only on step 0, with a 3s timeout
3. Build prompt: system prompt + skill index + memories + transcript
4. Stream LLM call via comet-sdk
5. Forward SSE events to desktop client (text_delta, reasoning_delta, tool_call, etc.)
6. If tool calls: execute in workspace-sandboxed registry, persist results, loop
7. On completion: background goroutine extracts memories from the turn

Key design decisions:
- **Memory retrieval has a hard timeout** (3s) — if embedding call is slow, proceed without memories
- **Memory extraction is fire-and-forget** in a background goroutine after SSE stream closes
- **MemorySem** bounds concurrent extraction goroutines across sessions (prevents N simultaneous LLM calls)
- **TurnStore interface** decouples agent loop from SQLite for unit testing

### Memory System (`cometmind/internal/memory/`)

This is the most sophisticated subsystem — a **full lifecycle memory manager**:

#### Storage
- SQLite table `memories` with: id, scope, kind (fact/preference/project), content, embedding (BLOB), base_weight, access_count, pinned, archived, timestamps
- FTS5 virtual table `memories_fts` for full-text search
- `memory_events` audit table tracking every memory lifecycle action

#### Retrieval (Hybrid: Vector + FTS + RRF)
1. **Decision gate** (`query.go:DecideRetrieval`) — deterministic heuristic (no LLM) that scores whether the user message warrants an embedding call. Checks for question signals, task signals, memory keywords, context references, code signals. Score ≥ 2 triggers retrieval; low-value messages (ok, hi, thanks) are skipped.
2. **Query construction** (`query.go:BuildRetrievalQuery`) — assembles recent context snippets + current message (max 6000 chars), no LLM involved.
3. **Hybrid ranking** (`retriever.go`) — cosine similarity over stored embeddings + SQLite FTS5 keyword search, merged via **Reciprocal Rank Fusion** (RRF, k=60). Pool size: top 20 from each ranking.
4. **Effective weight** (`scorer.go`) — `base_weight × decay × usage_boost`. Decay: half-life 30 days from last access. Usage boost: `1 + ln(1+access_count) × 0.15`, capped at 2.0. Pinned memories bypass decay.
5. **Final score** = RRF_score × effective_weight. Top N (default 5) above similarity threshold (0.5) are injected.

#### Extraction (LLM-based)
- After each turn, `extractor.go` takes last 8 messages, builds transcript
- Sends to LLM with structured prompt → JSON array of proposed memories with kind, confidence, should_save
- **Deduplication**: embed proposed content → cosine similarity against all active memories
  - sim > 0.92 → skip (near-duplicate)
  - sim ∈ [0.80, 0.92) → update/merge/supersede (LLM decides)
  - sim < 0.80 → create new
- Low-value turns (ack-only messages like "ok", "thanks") are skipped entirely

#### Preferences
- Special memory kind with **category caps**: language(1), tone(1), verbosity(1), model(1), tooling(2), workflow(2), coding_style(2)
- **Baseline preference injection**: top 3 preferences always injected regardless of semantic match
- Automatic category inference from content keywords

#### Compaction / Lifecycle
- **Decay forget**: memories below `ForgetThreshold` (0.1 effective weight) are archived
- **Merge pass**: bottom 20% by weight clustered by cosine similarity ≥ 0.80, then LLM merges clusters into single consolidated memories
- **Force forget**: if still over cap (default 500), archive lowest-weight unpinned memories
- **Compaction target**: 80% of max (400 active after compacting from 500)
- Triggered on extraction when `CompactionOnExtract` is true

#### Embeddings
- OpenAI (`text-embedding-3-small`) or Ollama (`nomic-embed-text`)
- Stored as BLOB in SQLite, cosine similarity computed in Go

### ACP Delegation (`cometmind/internal/acp/`)

- Uses `github.com/coder/acp-go-sdk` — the standard ACP protocol
- `delegate_coding_task` tool spawns external agent (OpenCode, Claude Code, etc.)
- Creates a child session in SQLite with delegation_status tracking
- `WorkspaceClient` implements `acpsdk.Client`:
  - Auto-approves permission requests (dogfood mode)
  - Streams progress updates back as SSE events (subagent_progress, subagent_complete)
  - Workspace-sandboxed file operations
- Supports async delegation (fire-and-forget) or synchronous wait
- Optional verify_command (e.g., `go test ./...`) runs after coding completes

### Agent Skills

- Same SKILL.md format as OpenClaw (YAML frontmatter with name + description)
- Multi-root discovery: `~/.cometmind/skills/`, workspace `.agents/skills/`, `.claude/skills/`, OpenCode roots
- Skills injected as system prompt index, invoked via `/skill-name` slash commands
- Built-in `load_skill`, `read_skill_file`, `write_skill` tools

### Desktop App (`cometline/`)

- **Electron + SvelteKit (Svelte 5)** with TypeScript strict mode
- Sidecar lifecycle: Electron main process spawns/restarts cometmind binary, polls `/health`
- Settings stored in `~/.cometmind/cometline-settings.json`, synced to cometmind config
- OpenAPI-generated TypeScript client from `cometmind/openapi.yaml`
- Chat UI: streaming text/reasoning/tool-call rendering, SubagentPanel for ACP progress
- First-turn flight animation, hero composer, auto-update (electron-builder)
- Settings panels for: providers, models, memory, appearance, shortcuts, CometMind config, Discord

### Discord Gateway

- Same cometmind agent runtime, different I/O adapter
- Per-thread sessions with persistent memory
- @mention gating, allowlisted users/channels
- `cometmind gateway run --platform discord`

### Provider SDK (`comet-sdk/`)

- Single `Provider` interface with `Stream(ctx, req) (<-chan Event, error)`
- Anthropic, OpenAI, OpenAI-compatible, and **ChatGPT Codex** adapters
- Codex adapter reuses local Codex CLI session cookies for auth
- Streaming event types: TextDelta, ReasoningStart, ReasoningContent, ToolCallDone, StepFinish, Error
- `llm.StreamMessage` wraps provider channel into a typed `Stream` with `Events()` and `Result()`
- `llm.GenerateJSON` convenience for structured output (used by memory extraction/compaction)
- Retry logic with exponential backoff for 429, 5xx, Anthropic 529

## Development & Testing

- **Mono-repo** with root Makefile: `make install`, `make check`, `make build`, `make package`
- No `go.work` — run Go commands from `comet-sdk/` or `cometmind/`
- SDK tests: unit/integration without live API calls, live tests behind build tag
- CometMind tests: `httptest` + temporary SQLite (pure Go, no CGO via `modernc.org/sqlite`)
- Frontend: Vitest + svelte-check
- Contract tests enforce SSE event schema consistency
- **Closed-loop self-improvement**: can register its own repo as workspace and ask cometmind to delegate coding improvements via ACP

## Contributor Profile

- **Solo developer**: Tom Liu (Tomlord1122), 383 commits as of 2026-06-20
- Very high commit velocity (12+ commits/day on active days)
- No external contributors, no open issues
- Merged 8 PRs in the past week (monorepo migration, settings CLI, lint cleanup)
- Appears to be a personal/hobby project evolving into a more polished product

## Key Tradeoffs

| Decision | Tradeoff |
|---|---|
| **Electron** | Cross-platform potential but currently macOS-only. Heavy runtime (~200MB) for a sidecar wrapper. Native feel via traffic light animations, tray icon, etc. |
| **Go runtime (no CGO)** | Pure Go SQLite via modernc.org avoids CGO cross-compilation pain, but slower than C SQLite. Good for local-first app where DB scale is small. |
| **SQLite for everything** | Sessions, messages, memories, embeddings all in one file. Simple but no concurrent writer scaling. Perfect for single-user local app. |
| **In-process embedding cosine** | Loads ALL active memories, computes cosine sim in Go. O(n) scan. Works for ≤500 memories, won't scale to thousands without indexing (HNSW, etc). |
| **LLM for memory extraction** | Every turn triggers an LLM call for memory extraction. Cost/latency concern, but runs async in background. |
| **ACP auto-approve** | WorkspaceClient auto-approves all permission requests in "dogfood mode". Security concern for production use. |
| **SvelteKit in Electron** | Modern reactive UI, but adds Vite dev server complexity. OpenAPI codegen ensures type-safe API contract. |
| **No workspace-scoped memory isolation** | Memories are all "global" scope despite workspace isolation for sessions. The `scope` field exists but everything is "global". |

## Novel Patterns Worth Noting

### 1. Hybrid Retrieval with RRF
The vector+FTS hybrid with Reciprocal Rank Fusion is a solid pattern. Most similar projects do pure vector or pure keyword — the RRF merge is production-grade IR technique applied to memory retrieval.

### 2. Retrieval Decision Gate
The deterministic heuristic that decides whether to even attempt retrieval (`DecideRetrieval`) is clever cost optimization. Skips embedding calls for ack messages, greetings, and low-signal turns. No wasted API calls.

### 3. Preference Category Caps
Per-category memory caps (language:1, tone:1, coding_style:2) prevent preference accumulation. When a new preference for "language" is extracted, it auto-compacts old ones. Forces convergence.

### 4. Memory Decay with Usage Boost
The `base_weight × half-life-decay × ln(1+access) boost` formula is a nice balance between recency and frequency. Frequently-retrieved memories survive longer.

### 5. Closed-Loop Self-Improvement
The ability to register its own repo as workspace and delegate coding improvements to itself via ACP is elegant dogfooding.

### 6. SSE Contract Testing
Contract tests (`cometmind/internal/contract/`) enforce that OpenAPI spec, Go event types, TypeScript types, and SSE reducers all agree. Prevents silent API drift.

### 7. Structured Postmortems
The `cometline/docs/postmortem/` directory has detailed postmortems for specific bugs — memory subsystem bugs, streaming UI issues, traffic light transitions, etc. Systematic debugging culture.

## Relationship to Ecosystem

| Project | Relationship |
|---|---|
| **OpenClaw** | Closest parallel. Both: Go runtime, agent loop, memory, ACP delegation, skills, Discord gateway. OpenClaw is more mature with multi-node architecture, but Cometline has a polished desktop UI that OpenClaw lacks. |
| **Cursor** | Cursor is IDE-embedded; Cometline is standalone desktop companion. Both target coding workflows but Cometline is workspace-agnostic. |
| **Eve (Cove)** | Similar desktop AI companion concept. Cometline's persona system (Minako/Souma) echoes Eve's companion approach. Both use Electron. |
| **OpenCode** | Cometline delegates TO OpenCode via ACP. OpenCode is the terminal coding agent; Cometline is the orchestrating companion. Complementary, not competitive. |
| **Claude Code** | Also a delegation target via ACP. Cometline is agent-agnostic — delegates to whatever ACP agent is configured. |

**Not a direct competitor to OpenClaw** — more like a parallel evolution. Cometline is a local-first desktop app for individual developers; OpenClaw is a multi-node agent platform. They share design DNA (Go, agent loop, ACP, skills, memory, Discord) but serve different scales.

## Relevance to OpenClaw

### Patterns to Learn From

1. **Memory lifecycle management**: Cometline's memory system is more sophisticated than OpenClaw's current approach. The decay scoring, preference caps, compaction pipeline, and hybrid retrieval with RRF are production-ready patterns. OpenClaw's memory is file-based (MEMORY.md, daily logs) — good for transparency but lacks the retrieval sophistication.

2. **Retrieval decision gate**: The deterministic heuristic that skips embedding calls for low-value messages could reduce unnecessary API costs in any memory-augmented agent system.

3. **Contract testing across layers**: SSE contract tests ensuring Go types, OpenAPI spec, and TypeScript types all agree is a pattern OpenClaw should adopt as its gateway grows.

4. **Background memory extraction with semaphore**: The `MemorySem` pattern — bounding concurrent background LLM calls across sessions — is a practical solution OpenClaw could use for any async background processing.

5. **Postmortem-driven development**: Having a `docs/postmortem/` directory with structured bug analysis is worth emulating for complex subsystems.

### Patterns We Do Better

1. **Multi-node architecture**: OpenClaw's gateway + node architecture supports distributed agents, mobile nodes, cross-machine workflows. Cometline is single-machine only.

2. **DNA/self-governance**: OpenClaw's SOUL.md + beliefs-candidates + gradient system is more sophisticated identity infrastructure than Cometline's static persona SOUL.md.

3. **Memory transparency**: OpenClaw's file-based memory (MEMORY.md, daily logs) is human-readable and directly editable. Cometline's SQLite-stored memories require the Settings UI to inspect/edit.

4. **Workflow system**: FlowForge, gogetajob, and the workflow-guard enforcement layer have no equivalent in Cometline.

5. **Community/ecosystem**: ClawHub skill registry, multi-model review skills, team-lead coordination — OpenClaw has a broader agent ecosystem.

### Potential Collaboration/Integration

- Cometline uses standard ACP — it could theoretically delegate to OpenClaw agents
- The `comet-sdk` Go library is cleanly designed and could be useful reference for OpenClaw's provider layer
- Memory retrieval patterns (RRF, decay scoring) could inform OpenClaw memory skill improvements
