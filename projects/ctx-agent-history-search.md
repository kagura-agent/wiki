---
title: "ctx — Local Agent History Search"
created: 2026-07-03
updated: 2026-07-03
status: tracking
revisit: 2026-07-10
tags: [agent-memory, developer-tools, rust, session-history]
last_verified: 2026-07-03
---

# ctx — Local Agent History Search

**Repo:** [ctxrs/ctx](https://github.com/ctxrs/ctx) | ⭐ 219 | Rust | Apache-2.0 | 2 contributors
**What:** CLI that indexes local coding agent session histories (Claude Code, Codex, Cursor, OpenClaw, Gemini, etc.) into SQLite, then lets current agents search past sessions for decisions, failed attempts, commands, and patches.

## Why It Matters

Coding agents start from zero every session. They can read the current repo but can't recover context from earlier sessions — rejected approaches, debugging attempts, design decisions. ctx bridges this gap by making *all prior agent sessions* searchable.

**50x token efficiency** vs raw transcript search: structured session→event→file metadata with ranked snippets returns ~917 tokens where raw search returns ~45K.

## Architecture (Key Patterns)

### Normalized Session Model
Rich data model with 6 hierarchical layers:
- **CaptureSource** → **Session** → **Run** → **Event** → **FileTouched** → **VcsChange**
- Plus: Artifacts, Summaries, HistoryRecordLinks, SessionEdges
- Each entity has `SyncMetadata` (visibility, fidelity, sync_state) — designed for future cloud sync

### Provider Adapter Pattern
Each agent harness (Codex, Claude, OpenClaw, Cursor, etc.) has a dedicated normalizer that reads native history formats and converts to the unified model. Currently ~14 providers:
- codex_session_jsonl_tree, claude_projects_jsonl_tree, **openclaw_session_jsonl_tree**, cursor_agent_transcript_jsonl, gemini_cli_chat_recording_jsonl, opencode_sqlite, hermes_state_sqlite, etc.
- Provider discovery is path-based (checks `~/.codex/sessions/`, `~/.openclaw/`, etc.)

### Search Architecture
- SQLite FTS (full-text search) on event payloads
- Session-grouped results: searches return session-level matches with best snippet + "more matches in session" count
- File-touch filtering: `--file` flag queries the file-touch index to find sessions that modified a specific file
- Incremental import: tail-import for Codex sessions (detect new events appended to existing JSONL)

### MCP Server
`ctx mcp serve` — read-only MCP server over stdio. Tools: `search`, `sql` (raw read-only SQL), `show_session`, `show_event`, `sources`, `status`. The `sql` tool is powerful — agents can write arbitrary read-only queries against the schema.

### Privacy & Redaction
Strong redaction pipeline: `redact_secret_markers()` catches API keys (sk-*, ghp_*, AKIA*), bearer tokens, passwords, database URLs. `redact_share_safe_markers()` additionally strips local paths. SafePreview is the default redaction state.

## Relation to Our Stack

- **OpenClaw is a first-class supported provider** — `openclaw_session_jsonl_tree` format, discovers `~/.openclaw/` sessions
- Could complement our `session-logs` skill — ctx provides structured search while session-logs does raw jq queries
- The provider adapter pattern is similar to how we normalize different chat platforms in OpenClaw
- Their MCP server could be an alternative to our `memory_search` for cross-session context retrieval

## Tradeoffs & Observations

1. **Pure local-first, no cloud required** — all data stays on machine. Contrast with cloud-first memory solutions like [[Synapse]] or [[AgentSpace]]
2. **No embedding/vector search** — relies entirely on SQLite FTS. Simpler but less semantic. Works because agent transcripts are keyword-rich (file paths, error messages, tool names)
3. **Pivot history** — started as ADE (Agent Development Environment, desktop app), pivoted to CLI search tool. Old ADE moved to separate repo. Shows market pull toward CLI-native developer tools
4. **Small team** (2 contributors) but high code quality — 50K lines of Rust, comprehensive test suite, well-structured crate hierarchy
5. **Agent Skill distribution** — `npx skills add ctxrs/ctx` for marketplace install. Designed to be given to agents as a tool

## Comparison

| Feature | ctx | Our session-logs | Our memory_search |
|---------|-----|-----------------|-------------------|
| Search type | SQLite FTS | jq raw queries | Semantic (embedding) |
| Multi-provider | 14+ providers | OpenClaw only | OpenClaw memory files |
| Index format | SQLite | Raw JSONL | Indexed markdown |
| Agent-facing | MCP + CLI | Skill | Native tool |
| Redaction | Built-in pipeline | None | None |
| File tracking | FileTouched index | No | No |

## Open Questions

- How does incremental import perform on large OpenClaw installations (thousands of sessions)?
- Could we use ctx as an MCP tool in OpenClaw to give agents cross-harness memory?
- Their redaction pipeline is more sophisticated than anything we have — worth studying for our own privacy tools

## Predictions

- Will reach 500⭐ by 2026-07-31 (Show HN bump + agent ecosystem demand for session memory)
- Will add more provider adapters (Windsurf, Copilot Workspace) within 30 days
