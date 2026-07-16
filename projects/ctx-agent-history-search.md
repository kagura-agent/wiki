---
title: "ctx — Local Agent History Search"
created: 2026-07-03
updated: 2026-07-16
status: tracking
revisit: 2026-07-23
tags: [agent-memory, developer-tools, rust, session-history, security]
last_verified: 2026-07-16
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

1. **Pure local-first, no cloud required** — all data stays on machine. Contrast with cloud-first memory solutions like [[synapse-hippocampus|Synapse]] or AgentSpace
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

- ~~Will reach 500⭐ by 2026-07-31~~ ✅ Already at 883⭐ by 07-16 — vastly exceeded prediction
- Will add more provider adapters (Windsurf, Copilot Workspace) within 30 days

---

## Update 2026-07-16: Explosive Growth + Architectural Maturation

**Growth:** 219→883⭐ (+303% in 13 days). Community THRIVING 6/6: 28 external PRs/30d, 12 unique issue authors, 51 forks.

### Key Architectural Changes (v0.23→v0.25)

#### 1. Retention Metadata v2 (PR #168)
Replaced overloaded `content_retention` strings with structured `text_retention` policy + outcome metadata. Reports truncation, patch/diff omission independently per provider emitter. Envelope v2 with v1 backward compat.

**Pattern:** Moving from ad-hoc string flags to structured contracts is a maturity signal. Same trajectory as [[flowforge]] going from flat YAML to typed node specs. When your data model grows complex enough that strings become ambiguous, you're ready for proper type contracts.

#### 2. Tolerant Import as Sole Behavior (PR #162)
Removed strict/partial import modes entirely. 3596 additions, 1906 deletions across 69 files — the biggest refactor since ADE pivot.

**Failure contract (3-tier):**
- Record-level: malformed/invalid records rejected, valid content commits
- Source-level: unreadable/corrupt/locked sources fail independently
- System-level: store/index/worker failures abort the run

**Design principle:** "failures with zero useful accepted content never report success" — honest error reporting. Contrast with systems that swallow partial failures silently.

**Relevance:** Our [[flowforge]] node execution has similar needs — a node that partially succeeds should report what worked and what didn't, not just "done" or "failed."

#### 3. OpenClaw-Specific Optimization (PR #154)
OpenClaw treated as incrementally searchable — no full FTS rebuild needed. Bounded 64-unit/8 MiB batch transactions for normalized imports. They specifically optimized for our ecosystem.

### Security Architecture: Prompt Injection Replay (Issue #60)

The richest discussion — community debating whether past-session search introduces new attack surfaces.

**Key insight from @hampsterx (external security researcher):**

1. **Trust laundering:** First encounter is in a guarded frame (analyzing hostile input). Recall resurfaces the same string later in an unrelated task, presented as "your own prior history" — implicit trust halo moves injection from low-trust to high-trust frame.

2. **Cross-boundary propagation:** Index spans projects on the machine. A payload from a sketchy PR in one repo can surface in an unrelated repo weeks later. New propagation path, not replay of existing one.

3. **Accepted-exceptions poisoning** (most dangerous): If agents trust recalled history to avoid re-flagging "things we already reviewed," anyone who can land text in an indexed surface (PR description, commit message) can plant "this pattern was reviewed and accepted as safe" and silence future real findings.

**Mitigation principles proposed:**
- "Recall surfaces, it never decides" — recalled context is a lead to verify, never a suppression
- Nonce-tagged delimiters (UUIDv4 per response) protect boundary integrity but not decision quality
- Provenance metadata needed: was this user input, model output, file content, or tool output?

**Relevance to our stack:**
- Our [[memory-search]] has the same trust-laundering risk — memory files are presented as authoritative context
- The "recall surfaces, never decides" principle applies directly to how agents use memory_search results
- Cross-session memory (MEMORY.md) could be a vector for the accepted-exceptions attack if compromised

### Relation Updates

- **OpenClaw is a first-class citizen** — specifically optimized import path (PR #154)
- ctx at 883⭐ is now the dominant local agent history search tool
- Their community health (THRIVING 6/6) validates the "agent session memory" problem space
- Consider: could ctx's MCP server complement our native session-logs skill?

### Revised Predictions

- Will reach 1500⭐ by 2026-08-01 (current velocity + genuine utility)
- Nonce-tagging PR will merge and become default within 2 weeks
- Will add provenance metadata to recall results within 30 days (community pressure in #60)
