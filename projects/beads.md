---
title: "Beads — Distributed Graph Issue Tracker for AI Agents"
created: 2026-05-12
source: https://github.com/gastownhall/beads
stars: 24460
language: Go
license: Apache-2.0
status: active
last_verified: 2026-06-18
---

# Beads (bd)

> Distributed graph issue tracker for AI agents, powered by Dolt. By Steve Yegge (ex-Google/Amazon/Grab). 23K⭐, v1.0.4 (2026-05-09).

## What It Does

Replaces markdown plans and TODO files with a **dependency-aware graph database** backed by [Dolt](https://github.com/dolthub/dolt) (version-controlled SQL). Core primitive: issues with typed links (`relates_to`, `duplicates`, `supersedes`, `replies_to`) forming a knowledge graph.

Key workflow:
- `bd ready` — surfaces tasks with no open blockers (auto-scheduling)
- `bd prime` — injects workflow context + persistent memories into agent session start
- `bd remember "insight"` — stores persistent project memory (replaces MEMORY.md files)
- `bd compact` — AI-driven summarization of old closed issues ("memory decay")

## Architecture

```
CLI (bd) → Dolt Database (.beads/dolt/) → Dolt Remote (push/pull)
```

**Why Dolt?** Version-controlled SQL with cell-level merge. Every write auto-committed to Dolt history = complete audit trail. Native push/pull to remotes (DoltHub, S3, GCS). Offline work just works.

**Hash-based IDs** (`bd-a1b2`): Random UUID → short hash. No sequential ID collisions in multi-agent/multi-branch workflows. Progressive scaling (4→6 chars as DB grows).

**Two storage modes:**
1. **Embedded** (default) — Dolt in-process, single-writer, `.beads/embeddeddolt/`
2. **Server** — `dolt sql-server`, multi-writer capable

## Key Design Decisions

### Compaction = Semantic Memory Decay
Uses Claude Haiku to summarize old closed issues. Tier-based: Tier 1 = 7+ days closed, includes 2 levels of dependency context. Preserves audit trail while reducing context window cost. Configurable per-repo.

### Agent Integration Model
`bd setup <agent>` injects workflow instructions into agent config files (AGENTS.md for Codex/Factory, hooks for Claude Code). `bd prime` provides session-start context injection. MCP server available via `beads-mcp` PyPI package.

### Contributor vs Maintainer Mode
`bd init --contributor` routes planning to `~/.beads-planning` (separate from fork). `bd init --stealth` uses locally without repo commits. Smart role detection via SSH/HTTPS credentials.

## Relevance to Us

**Direct overlap with our architecture:**
- We use `MEMORY.md` + `memory/*.md` + `TODO.md` for task tracking and memory → Beads replaces all three with structured SQL graph
- We use `wiki/` with `[[wikilinks]]` for knowledge → Beads' graph links (`relates_to`, `supersedes`) serve similar purpose but with typed edges
- Our `bd prime` equivalent is AGENTS.md + SOUL.md session startup sequence
- Our FlowForge workflows ~ Beads' dependency-aware `bd ready` (auto-scheduling based on blockers)

**What Beads does better:**
- **Collision-free multi-agent**: Hash IDs prevent conflicts when multiple agents create tasks concurrently. Our sequential TODO items would collide.
- **Structured memory decay**: Tier-based compaction with AI summarization. We just manually clean MEMORY.md.
- **Audit trail**: Every change committed to Dolt history. We lose edit history in markdown files.
- **Dependency graph**: Typed links between issues. Our TODO is flat list.

**What we do differently (and arguably better):**
- **Simplicity**: Our markdown files are human-readable, zero tooling required. Beads needs Go binary + Dolt.
- **Portability**: Our wiki travels as plain git. Beads' Dolt DB is opaque.
- **Flexibility**: Our wiki supports freeform notes, concept cards, narrative. Beads is issue-focused.
- **Integration depth**: Our memory/DNA system is deeply integrated with agent identity. Beads is project-scoped.

**Verdict**: Not a replacement for us — our memory system serves identity continuity, not just task tracking. But Beads' specific innovations worth borrowing:
1. **Hash-based IDs** — for any multi-agent task creation scenario
2. **Tiered compaction with AI summarization** — could apply to our memory/*.md files
3. **`bd prime` pattern** — structured session-start injection (we already do this but less formally)
4. **Typed graph links** — our wikilinks are untyped; adding `supersedes:`, `contradicts:` types could improve knowledge navigation

## Issues / Weaknesses (from GitHub issues)

- `bd close` silently no-ops status update on specific rows (data integrity concern)
- `bd export` is lossy — JSONL doesn't round-trip wisps/events/comments (51GB→53MB data loss)
- Server mode ignores TLS config
- v1.0.4 was a breaking change marketed as patch (semver violation)
- `--dry-run` ignored by some subcommands

## Ecosystem Position

Beads occupies a unique niche: **structured task memory for coding agents**. Not a general agent framework, not a memory system — specifically a dependency-aware issue tracker designed for AI agent workflows.

Competitors: GitHub Issues (not agent-optimized), Linear (SaaS, not embeddable), our markdown TODO (unstructured). Most "agent memory" projects ([[agent-memory-taxonomy]]) focus on conversational or knowledge memory, not task/planning memory.

Links: [[self-evolving-agent-landscape]], [[agent-memory-taxonomy]], [[claude-code-memory-architecture]], [[git-backed-agent-memory]]

### Update 2026-05-31 — v1.0.5 + explosive growth

**Stars**: 24,229 (was 23,555 on ~05-28, +674 in ~3 days). Accelerating.

**v1.0.5 (05-29) — GATED RELEASE**:
- Migration 0043 can **silently and unrecoverably break multi-machine `bd dolt` sync**. Reverted to v1.0.4 on Homebrew, v1.0.6 in progress.
- **Cautionary tale**: Even at 24K⭐, migration testing gaps happen. Their Issue #4259 documents the failure mode.

**New features in v1.0.5**:
- Schema-skew guard: hard fail on forward DB drift (prevents silent corruption)
- Auto-configure contributor routing on fork detect
- Gemini/Claude hook JSON compliance + `--hook-json` flag + legacy migration
- Copilot CLI setup recipe
- `--skip-labels` hydration toggle for `bd list`

**Post-release fix velocity**: 4 PRs in 2 days (workspace rebind, target selection semantics, db commands). Active maintenance but the gated release suggests CI/integration testing gaps.

**Assessment**: Beads continues explosive growth (24K⭐). The gated v1.0.5 release is a real-world example of why migration testing matters — schema-skew guard was ironically added in the same release that shipped a breaking migration. Healthy project with strong community but needs better multi-node sync testing.
**Update 06-09**: 24,418⭐. Dolt 2.1.4 driver bump, deterministic dep primary keys for cross-clone merge safety (#4259), hierarchical `bd create --parent`. Robustness phase.

**Revisit**: 06-04.

### Update 2026-06-10 — Content-hash migration + doctor hardening

**Stars**: 24,444 (was 24,418 on 06-09, +26/day, steady).
**Last push**: today (06-10). Very active.

**Key changes since 06-09**:
- **PR #4270**: Per-migration content hash — addresses the v1.0.5 gated release root cause. Each migration now has a content hash so schema-skew detection is per-migration granular, not just version-based. This is the structural fix for #4259.
- **`bd doctor` actually runs migration content skew check now** (bd-6dnrw.27) — the skew check existed but wasn't wired in. Classic "defense that was never armed" pattern.
- **Remote-migrate gate** wired into proxied-server open path (bd-6dnrw.28) — prevents migrations running on remote Dolt connections where they could corrupt.

**Assessment**: Beads is in a robustness hardening phase. The per-migration content hash is the proper fix for their v1.0.5 fiasco — moving from "detect schema drift" to "detect drift per individual migration." Growth steady at ~25K⭐. Steve Yegge's team shipping quality infrastructure fixes.

**Pattern worth noting**: The "defense that was never armed" (doctor check existed but didn't run) parallels our own [[verify-external-ops]] experience — verification code that isn't actually executed is worse than no verification (false confidence).

**Revisit**: 06-17.

### Update 2026-06-18 — Proxied-server completion + scale critiques

**Stars**: 24,596 (was 24,444 on 06-10, +152 in 8d, ~+19/day — steady).
**Last push**: 06-17 23:58 UTC. Very active.

**Major architectural milestone — proxied-server mode fan-out**:

Past 3 days landed proxied-server support for `bd close` (#4446), `bd show` (#4445), `bd delete` (#4444). Combined with earlier `bd update` (#4433), `bd list` (#4287, #4300), this completes a fundamental architecture split:

- **Domain layer (`internal/storage/domain/db/`)** — pure interfaces (`IssueUseCase`, `DependencyUseCase`, `ConfigUseCase`)
- **SQL repository layer** — implementations agnostic to embedded vs remote Dolt
- **Single UOW (Unit Of Work) per CLI invocation** — `cmd/bd/<cmd>_proxied_server.go` opens one transaction, threads it through all per-id ops + post-loop flags (`--suggest-next`, `--continue`, `--claim-next`), commits once with descriptive message

**Why this matters (the real insight)**:

Previously bd was effectively a single-process tool — embedded Dolt = one CLI process owns the DB file. Proxied-server mode = bd CLI talks to a long-lived Dolt SQL server process. This unlocks:

1. **Multi-tenant agent platforms** (gascity is the driver — see [[git-backed-agent-memory]]). One Dolt server, many agent CLIs.
2. **Atomic batches**: 50 `bd close` calls in one transaction vs 50 separate dolt commits. The PR explicitly notes gascity's `CloseAllWithReason` benefits.
3. **Remote-mode safety**: `bd doctor` migration content-hash gate (06-10 insight) prevents migrations running against shared remote servers — armed defense.
4. **Wire-level decoupling**: matches the [[clawpatrol]] / wire-protocol-as-contract pattern. UI-mode vs proxied-mode tested identically because both go through domain interface.

This is hexagonal architecture done quietly correctly. No fanfare about "DDD" or "ports and adapters" — just methodical port-and-test of each verb, untouched embedded path, full integration tests (e.g., #4445 ships 47 subtests).

**Architecture critiques worth recording**:

**Issue #4369 — No retention/TTL/archival primitive at scale** (filed 06-17 by vbtcl):
> "live DB grew **11k → 98.7k issues in 36h**, ~90% closed automation churn, degrading scan-class queries to 2-minute timeouts"

gascity-style agent platforms create high-churn ephemeral beads (orders, nudges, workflow steps, session records). Cleanup required hand-rolled SQL against Dolt because:
- `bd close` keeps the row forever — no `bd archive`/`bd purge`
- No per-type/label TTL concept

**Generalizable insight**: Issue tracking systems designed for human workflows (~10s of issues/week) break when agent platforms feed them ephemera (~100k/day). The structural fix isn't more CPU — it's a tier separation: durable beads (human-meaningful work) vs ephemeral beads (automation steps). Without retention primitives at the tracker layer, every platform reinvents unsafe bulk-delete SQL.

Cross-link: this is the same shape as [[memory-trash-filter]] — agent memory systems also break when not filtering low-value events. **High-volume agent telemetry needs first-class retention primitives, not afterthought cleanup.**

**Issue #3963 — Pre-commit re-export loop accumulation** (filed 06-17 by fkberthold):

`bd hooks install` creates `chore(beads): post-X bd export reconcile` commits per logical session. Pre-commit re-exports → diff appears → reconcile commit → triggers next hook → 3-5 layers deep. The cited agent comment is excellent:

> "The bd post-commit hook re-exports issues.jsonl after every commit — chasing the loop with another commit just retriggers it. Stopping here; the drift is pure metadata reordering and the next bd-related commit will fold it in naturally."

**Generalizable insight**: This is the same shape as the FlowForge "auto-close stale instance" warning (04-27) — silent side-effects that produce work the user didn't ask for. The agent did the right thing (stop chasing), but the system shouldn't have created the loop in the first place. **Hook ergonomics: any post-commit side-effect that mutates working-tree state needs an idempotence guard.**

**Bigger picture — Beads as agent infrastructure**:

Beads is no longer "an issue tracker that AI agents happen to use." With proxied-server mode, the architecture is explicitly multi-process / multi-tenant. The scale critiques (#4369, #3963) come from a real agent platform (gascity) building on it — that's the validation signal Beads is becoming infrastructure rather than a tool.

For our own direction: this is the [[multica]] / [[nanobot]] multi-tenant gateway question answered for the persistence layer. Worth watching whether retention/TTL primitives land — if yes, Beads becomes a serious contender for our own task memory (vs current markdown TODO).

**Revisit**: 06-25.
