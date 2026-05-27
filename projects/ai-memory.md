# ai-memory — Cross-Agent Long-Term Memory

- **repo**: akitaonrails/ai-memory
- **stars**: 290 (2026-05-27, created 05-21 — ~48⭐/day growth)
- **lang**: Rust
- **license**: MIT
- **status**: active | deep-read | ✓2026-05-27

## What It Is

A single Rust binary that gives AI coding agents (Claude Code, Codex, Cursor, Gemini CLI, OpenClaw, OpenCode, etc.) shared long-term memory. The killer feature: **cross-agent handoffs** — quit Claude Code mid-task, start Codex in the same directory, continue without re-explaining.

Implements the [[llm-wiki-karpathy]] pattern faithfully: a [[git-backed-agent-memory]] wiki of markdown pages compiled from observations, not retrieved over raw logs.

## Architecture

### Data Flow
1. Agent CLI emits lifecycle hooks (fire-and-forget HTTP `POST /hook`)
2. Server sanitizes, assigns `ObservationKind`, enqueues write
3. On `SessionEnd`, synthesizes `sessions/<id>.md` summary (rule-based, no LLM)
4. Opens a `Handoff` row for the next agent, auto-commits wiki
5. Optional LLM consolidation: rewrites summaries into richer pages, fans out to `concepts/`, `decisions/`, `gotchas/`
6. Query via FTS5 + link-neighbour RRF + optional vector cosine
7. Forget sweep: retention decay (M8), soft-delete below threshold, hard-delete after 180 days

### Core Domain Model
- **ObservationKind**: 9 types — session-start, user-prompt, pre-tool-use, post-tool-use, pre-compact, notification, stop, session-end, other
- **Page Tiers** (from agentmemory's 4-tier model):
  - **Working**: current session last N observations
  - **Episodic**: per-session summaries with concept tags
  - **Semantic**: distilled facts/architecture notes (wiki pages proper)
  - **Procedural**: repeated patterns from episodic clusters
- **Supersession**: page versioning — old `is_latest=false` links to new `is_latest=true`, never destructive overwrite

### Crate Structure
- `ai-memory-core` — domain types, no I/O (ObservationKind, Page, Tier, Sanitizer)
- `ai-memory-hooks` — lifecycle hook router (ingress from agents)
- `ai-memory-store` — SQLite writer actor (WAL mode, single connection, mpsc)
- `ai-memory-wiki` — markdown file management + git
- `ai-memory-consolidate` — Karpathy LLM wiki pipeline (single-page + multi-page fan-out)
- `ai-memory-mcp` — MCP server (stdio + streamable HTTP)
- `ai-memory-llm` — LLM provider abstraction (Anthropic, OpenAI, OpenAI-OAuth, Copilot, Gemini, compat)
- `ai-memory-web` — read-only HTML UI
- `ai-memory-cli` — CLI entry point

### Security: Sanitized<T> Type Boundary
The `Sanitized<T>` newtype enforces that all persisted text passes through the sanitizer. You literally cannot construct a `Sanitized<T>` without scrubbing — compile-time enforcement, not runtime checks. Redacts: bearer tokens, vendor API keys (sk-, ghp_, AKIA, AIza, xox-), JWTs, PEM private keys, URL-embedded credentials, generic `*_KEY=value` patterns. Extensible via config.

### Memory Decay (M8)
```toml
[decay]
lambda = 0.02    # ↓ = forget less aggressively
sigma = 0.6      # ↑ = reward query-hits more
mu = 0.04        # ↑ = recent hits count more
cold_threshold = 0.20  # below → soft-delete
hard_delete_after_days = 180
```
Query hits bump `access_count` + `last_accessed_at` (reinforcement). Semantic/pinned/freshly-touched pages survive decay.

## Community Health
- 36+ PRs from multiple external contributors (mrpaiva, talDoFlemis, pedrofjr, etc.)
- Active issue discussions on architecture (event vocabulary, web UI, Windows support)
- Issues reveal real usage: FK constraint bugs after purge, MCP session handling, multi-project routing
- Brazilian dev community heavily engaged

## Design Decisions We Can Learn From

1. **Zero-LLM default path**: LLM consolidation is opt-in. System works without any provider configured. This is smart — reduces barrier to entry dramatically.
2. **Writer actor pattern**: Single dedicated thread owns the SQLite connection, all writes go through mpsc channel. Eliminates concurrency issues elegantly.
3. **Fire-and-forget hooks**: Agent never blocks on memory writes. Saturated servers return 429 instead of queueing unbounded work. Great for production reliability.
4. **Watcher + reconciliation**: Filesystem watcher syncs external edits back to SQLite every 30s. Markdown stays source of truth, SQLite is derived index.
5. **Atomic file writes**: tmp + rename + fsync. Watcher ignores own writes by filename prefix. Prevents feedback loops.
6. **Provider auth boundary**: Auth resolves before provider construction. Native clients consume typed `ProviderAuth` material, never read env vars directly.

## Comparison to Our Approach

| Aspect | ai-memory | Our approach (OpenClaw MEMORY.md) |
|---|---|---|
| Storage | SQLite + git-versioned markdown | Plain markdown files + git |
| Memory types | 4-tier (working/episodic/semantic/procedural) | 2-layer (daily memory + curated MEMORY.md) |
| Consolidation | LLM-driven compilation at session-end | Manual + heartbeat-driven review |
| Cross-agent | Built-in handoff protocol | Not applicable (single agent) |
| Decay | Mathematical retention function | Manual pruning |
| Query | FTS5 + vector + link-neighbour RRF | memex semantic search + grep |
| Security | Compile-time Sanitized<T> type | Manual redaction guidelines |

## Relevance to Us

**High relevance.** Several patterns worth studying/adopting:
1. **Supersession chain** — version pages in-place rather than overwriting. Would make our wiki edits auditable.
2. **4-tier memory model** — our 2-layer (daily + curated) maps roughly to episodic + semantic, but we lack working and procedural tiers explicitly.
3. **Sanitized<T> boundary** — compile-time privacy enforcement is superior to our "remember to redact" approach.
4. **Retention decay math** — our manual "drop when stale" could use quantitative signals.
5. **Fire-and-forget hooks** — applicable to our heartbeat/cron memory capture.

## Future Work (Theirs)
- Local embeddings via `ort` (bge-small, no API key needed)
- `sqlite-vec` for scale beyond brute-force cosine
- Scheduled consolidation queue
- LongMemEval-S benchmark harness (framework exists, needs dataset)
