---
title: Dream Single Phase Consolidation
created: 2026-05-31
tags: [concept, memory, architecture]
last_verified: 2026-06-20
---
# Dream Single-Phase Consolidation

Architectural pattern from [[nanobot]] (PR #3990, merged 2026-06-02): replacing a two-phase memory consolidation pipeline with a single agent loop pass.

## Before: Two-Phase Pipeline

1. **Phase 1 (Analysis)**: Pure LLM call scans history, produces tagged facts (`[FILE]`, `[FILE-REMOVE]`, `[SKILL]`)
2. **Phase 2 (Execution)**: Separate `AgentRunner` with file tools applies the tagged changes

Two templates, two LLM calls, separate error handling and cursor management.

## After: Single-Phase via Loop Reuse

One unified `dream.md` prompt + `process_direct(ephemeral=True)` through the main `AgentLoop`:

1. `MemoryStore.build_dream_prompt()` assembles history context
2. `MemoryStore.build_dream_tools()` creates restricted tool registry (read/edit/write/patch only)
3. `AgentLoop._run_agent_loop(ephemeral=True, tools=...)` runs with hook suppression
4. Cursor advances only on `_stop_reason == "completed"`

## Key Design Properties

- **Loop reuse** — Dream inherits all loop improvements (tool contract, provider changes) automatically
- **Ephemeral sessions** — timestamped `dream:YYYYMMDD-HHMMSS` keys, excluded from AutoCompact
- **Tool restriction** — only file-editing tools exposed, not full agent toolset
- **Fail-safe cursor** — failed runs leave cursor unchanged, retried next cycle
- **Hook suppression** — `ephemeral=True` disables nudge, progress callbacks, extra hooks
- **MECE routing** — unified prompt enforces single-canonical-location for each fact

## Pattern: Specialized Tasks via Loop Mode Flags

The broader insight: **specialized agent tasks should reuse the main agent loop with mode flags, not build parallel execution paths.** This applies to:
- Memory consolidation (Dream)
- Self-review / reflection
- Scheduled maintenance tasks
- Skill discovery

Compare: OpenClaw nudge hook (runs in-context, follows this pattern), OpenClaw cron (isolated sessions, middle ground).

## Links

- [[nanobot]] — source project
- [[metadata-driven-context-injection]] — related pattern for persistent state
- [[context-compaction]] — Dream's MECE routing prevents compaction-related duplication
- [[memory-trash-filter]] — SNIP filtering as pre-consolidation gate
- [[atomic-writes]] — crash-safe persistence added alongside Dream changes

## Update 2026-06-04: Dual-Phase Proposal (Issue #4186)

Community member @aishangwuji proposes reverting to **dual-phase Dream**:
- Phase 1: Pure LLM analysis of history.jsonl → structured JSON (no tools)
- Phase 2: AgentRunner with read_file/edit_file/write_file for incremental edits
- EditFileTool `allowed_dir` restricted to memory/ + SOUL.md + USER.md + skills/

Rationale: separating analysis from execution gives better control — the analysis phase can't accidentally modify files, and the execution phase has explicit allowed-directory restrictions. Also adds sensitive info redaction before persist and atomic writes.

**Status**: Open issue, not merged. No maintainer response yet. Worth tracking — if merged, our card needs updating since the "single-phase replaces two-phase" narrative would be partially reversed.

## Update 2026-06-05: Dream Hunger Problem (Issue #3973)

Architectural critique exposing a fundamental input-dependency flaw:

**Problem**: Dream's only input source is `history.jsonl`, which is written to by:
1. **Consolidator** — triggers when session token budget exceeded
2. **AutoCompact** — triggers when session TTL expires (default: disabled)

If neither triggers (common: many short sessions, AutoCompact disabled), `history.jsonl` stays empty → Dream runs on cron schedule but finds nothing to process → long-term memory files (MEMORY.md, SOUL.md, USER.md) are never updated.

**Architectural insight**: This is a **coupling-through-side-effect** anti-pattern. Dream's functionality depends entirely on other subsystems' side effects (token overflow, TTL expiry), not on explicit data flow. The fix isn't just "trigger Dream more" — it requires rethinking how conversation data flows to the consolidation pipeline.

**Relevance to us**: OpenClaw's nudge hook fires on agent_end (every N turns), not on token overflow. This avoids the hunger problem by design — reflection triggers on *usage*, not on *resource pressure*. Worth validating: does our heartbeat-based memory review have similar starvation risks during low-activity periods?
