# ai-memory — Cross-Agent Long-Term Memory

- **repo**: akitaonrails/ai-memory
- **stars**: 557 (2026-06-10, was 503 on 06-03, steady growth)
- **lang**: Rust
- **license**: MIT
- **status**: active | deep-read | ✓2026-06-10

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

## v0.8→v0.9 Evolution (2026-05-28 to 06-02)

### Key New Patterns

**1. Admission Webhook Chain (PR #55)**
Pre-persistence HTTP hooks on the write path — operator-configurable, sequential, each sees mutations from the previous hook. Extension seam, not a plugin system. Design principles:
- `failure_policy=ignore` by default — flaky webhook never blocks engine
- Actor identity + skip-list prevent feedback loops
- Webhooks can mutate pages (add frontmatter, validate) or observe (mirror to git remote, audit log)
- Engine stays closed for modification — new behaviors ship as independent HTTP services
- This is the [[admission-controller]] pattern from K8s, applied to agent memory writes

**2. OpenAI-Compat Strict Mode (PR #70, Issue #69)**
Reveals a fundamental tension: local/self-hosted models don't reliably follow JSON schemas. The `openai-compat` provider previously used descriptive prompting + tolerant JSON extraction. Under load, models drift:
- Non-reasoning models (mistral-nemo) emit no JSON at all
- Reasoning models produce syntactically valid JSON with wrong enum values (`tier: "state"` instead of `tier: "working"`)
- Solution: opt-in `response_format` via structured output API. Strict fallback narrowed to parse-shape failures only.
- **Lesson**: Any system consuming structured LLM output from diverse providers needs a strict/lenient toggle. Descriptive schema alone is insufficient for production.

**3. Bounded Buffers + Security Hardening**
- Admin routes restricted to root/owner only
- LRU cwd cache (prevents unbounded growth from many project directories)
- Bounded observation buffers
- Combined with existing [[sanitized-type-boundary]], this is defense-in-depth

**4. Move-Project (PR #60)**
First-class project relocation between workspaces without changing `project_id`. Typed conflict errors, V18 handoff coverage. Shows multi-tenant architecture maturing.

**5. Web Wikilinks (PR #68)**
Rendering `[[wikilinks]]` as clickable internal links in the built-in web UI. Base-path support for reverse proxy hosting. The wiki is becoming browseable, not just queryable.

### Community Evolution
- Stars: 290 → 503 (+73% in 7 days) — breakout growth
- External contributors: djalmajr (4 merged PRs: base-path, wikilinks, move-project, admission webhook improvements), brunoomariano (openai-compat strict), rikelmyso7 (Codex stream fix)
- Maintainer pattern: merge external PR → immediately harden/refactor/add tests → commit hardening as separate commits. Very rigorous.
- Brazilian dev community heavily engaged

### Relevance Update

**Admission webhook chain** is directly applicable:
- Our wiki writes (wiki-lint, memex) have no extension point. If we wanted to mirror wiki changes to an external system or validate writes, we'd need to fork the tool.
- The pattern is lightweight: just HTTP POST to a list of endpoints, sequential, with failure_policy.
- Not needed now (our scale is tiny), but the design is worth remembering for [[flowforge]] or [[memex]] extension.

**OpenAI-compat strict mode** validates a pattern we've seen:
- Our LLM interactions via [[floway]] assume cloud providers follow schemas. If we ever route through local models, we'd hit the same drift issue.
- The strict/lenient toggle is the right abstraction.

## Future Work (Theirs)
- Local embeddings via `ort` (bge-small, no API key needed)
- `sqlite-vec` for scale beyond brute-force cosine
- Scheduled consolidation queue
- LongMemEval-S benchmark harness (framework exists, needs dataset)

## v0.13.0 — Wiki Reindex: "DB is Rebuildable" Made Operational (2026-06-08)

557⭐ (+18 from 503 on 06-03). Growth slowing from breakout phase but still healthy.

### The Problem
`design-decisions.md §3` stated "DB is rebuildable from files — corruption is recoverable" but nothing actually rebuilt it. Zeroing `db/` and restarting failed because the watcher's reconcile only validated scopes — it never recreated `(workspace, project)` rows, so reindex failed `NotFound`. And human-readable names lived only in DB, not in the markdown tree.

### Solution: Three Cohesive Pieces (PR #86)

1. **Self-describing `_meta.md` manifests** — per-scope frontmatter files: `wiki/<ws-uuid>/_meta.md` (workspace name) and `wiki/<ws-uuid>/<proj-uuid>/_meta.md` (project name + `repo_path`). Idempotent backfill on startup (unchanged content never rewritten → no git churn). `_meta.md` excluded from page indexing.

2. **`ai-memory reindex` CLI command** — lifecycle op (server stopped). Walks wiki tree, recreates workspaces/projects from `_meta.md` via `ensure_{workspace,project}_with_id` (preserving UUIDs the tree is keyed by), reindexes every page. Use case: move data dir to clean migration lineage without carrying old `refinery_schema_history`.

3. **Page detection by content, not filename** — reserved-name skip (`log.md`, `bootstrap.md`) now checks for YAML frontmatter instead of filename match. A frontmatter file named `log.md` is a real page and gets indexed.

### Architectural Insights

- **Scope = idempotent, episodic = intentionally shed**: Only markdown-derived state rebuilds (pages, links, FTS, embeddings). Episodic DB-only state (sessions, observations, handoffs, decay counters) is NOT reconstructed — consistent with their "compile-don't-hoard" philosophy.
- **Symlink guard**: `read_scope_meta` refuses symlinked manifests — defence against path traversal attacks in the wiki tree.
- **Atomic writes**: `write_atomic` for manifest persistence — no partial state even on crash.
- **Validated at scale**: 659-page instance fully rebuilt from backup wiki alone.

### Relevance to Us ([[git-backed-agent-memory]])

Our wiki system has the same implicit promise: the markdown files ARE the source of truth, memex index is derived. But we never formalized:
1. Can our index be fully rebuilt from files alone? (Probably yes for memex — `memex reindex` exists)
2. Do we have self-describing metadata in the file tree? (No — our wiki relies on in-file frontmatter, not separate manifests)
3. Do we have a content-based page detection vs filename? (We use `.md` extension, not filename-based skipping)

Their pattern of "make the stated guarantee actually work" is a good discipline. Our [[retire-candidates]] already uses their M8 decay; now their reindex pattern validates the file-first design we also adopted.

### Issue #73: Agent Tool Confusion (Architectural UX)

Agents confuse `memory_handoff_begin` (write) with `memory_briefing` (read), creating dangling handoffs. Root cause: tool names and descriptions don't create strong enough read/write boundaries for LLM tool selection. Solution: sharpen descriptions + add handoff cancellation.

**Lesson**: When designing MCP tools, read-only vs state-mutating operations need **aggressive naming differentiation** — not just different descriptions, but different naming patterns (e.g. `get_*` vs `do_*`). Agents don't read fine print; they pattern-match on names.

## Applied: M8 Retention Decay to retire-candidates.sh (2026-06-03)

Adopted the M8 decay formula for our wiki retirement scoring:
- **Before**: Discrete buckets (0/15/30) for age and recall → heavy clustering, 458/751 notes scored 50+ with many ties at 85
- **After**: `retention = e^(-λ*age) × (1 + σ*ln(1+recalls)) × recency_boost` → continuous scoring, 367/751 at 50+, max 65, much better differentiation
- **Parameters**: λ=0.03 (slower than ai-memory's 0.02 — our notes update less frequently), σ=0.6, μ=0.04
- **Key insight**: The `recency_boost` term (how recently a note was recalled) prevents "old but actively used" notes from being flagged. This was the main gap in our v1 approach — it only counted total recalls, not when they happened.
- **Validation**: Recalled notes (106+ recalls) correctly get retention=1.0 (score=10, never retire). Zero-recall 38-day notes get score=65 (review) vs old 85 (strong retire). More conservative = fewer false positives.
- See [[retire-candidates]] concept for the full formula.
