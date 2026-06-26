# Foreman — Boris-Style Agentic Orchestrator TUI

**Repo:** VisionForge-OU/foreman (actual dev: n1arash/foreman)
**Stars:** 33 (as of 06-19)
**Created:** 2026-06-17
**Language:** Python 3.11+ (Textual TUI)
**License:** MIT
**Status:** v0.6.0, Phase 1+2 shipped, Phase 3 (hardening) planned

## What It Does

A keyboard-driven TUI that orchestrates headless Claude Code agents through a **gated software-delivery pipeline**: `plan → ADR/PRD → issues → TDD build → e2e`. Human review gates on design phases; guardrailed autonomy for the build phase.

Key property: **no database** — all state is human-readable files committed inside the target repo (`.foreman/`). Crash-safe by design.

## Architecture

### The Gated Pipeline (Phase A — Human in the Loop)

1. **Request** → `request.md`
2. **Plan** (high-reasoning planner agent) → `plan.md`
3. **Grill** (vendored skill challenges plan against codebase) → ADR + PRD
4. **Review** (human approves/requests changes in TUI)
5. **Slice** (breaks PRD into dependency-ordered issues with `touches` sets)
6. **Confirm** (final gate before build)

### The Boris Loop (Phase B — Autonomous Build)

For each ready issue (dependencies met, no `touches` overlap with running workers):
- Spawn worker in its **own git worktree** → TDD red-green-refactor
- Worker saves evidence under `runs/<id>/evidence/`
- **Merge gate** (Foreman runs, never trusting agent):
  - Evidence check
  - Issue's runnable `acceptance_check`
  - Full test/lint/typecheck pass
  - **Regression ratchet** (no previously-passing test may now fail)
  - Independent read-only **evaluator** (separate agent, fresh context) grades 1-5
  - Optional **code-review** + **security-review** gate agents
- Pass → merge. Fail → **bounce** (fresh worker with distilled feedback) or **escalate** (human attention queue)

### Key Design Patterns

1. **Hash-sealed approvals**: SHA-256 of document body at approval time. Auto-invalidates if content changes. Prevents stale approvals surviving edits.

2. **Worktree isolation**: Each worker in its own git worktree, footprint-gated by declared `touches` set. Workers can never collide. Integration branch worktree handles merges.

3. **PreToolUse deny hook**: Workers are hook-blocked from writing `verification.json` / issue files. Enforcement at tool level, not by trusting instructions.

4. **Bounce-vs-escalate graduated policy**: Fresh retry with distilled failure report. After N retries → escalate to human. Repeated evaluator-vs-builder disagreement → escalate both sides.

5. **AgentBackend seam**: Single interface (`ClaudeBackend` real, `MockBackend` tests). Full pipeline testable without tokens. `foreman demo` runs entire flow on canned stream-json.

6. **Evals flywheel** (Phase 2): Every run outcome-labeled → `foreman retro` clusters failures → drafts skill/prompt patches → patches must pass `foreman bench` before landing.

## Dogfood Results (Honest)

Campaign on a FastAPI+SQLite app with Haiku workers:

| Feature | Type | Outcome | Cost | Wall |
|---------|------|---------|------|------|
| F5 | trivial (1-liner) | ✅ done | $3.23 | 31 min |
| F1 | greenfield | ⚠️ stuck | $1.83 | 15 min |
| F2 | brownfield | ❌ doc_review loop | ~$2.0 | — |
| F3 | multi | ❌ grill killed_turns | ~$0.7 | — |
| F4 | vague | ❌ 429 quota | ~$0 | — |

**1/5 completion rate.** Baseline: same trivial feature costs $0.11 in 54s with plain `claude -p`. Pipeline adds **29× cost, 35× time** for trivial work. 49% of all runs killed by turn budget.

## Relevance to Us

### Directly applicable patterns:
- **Merge gate architecture** → our team-lead skill currently trusts subagent self-reports. A structural verification layer (run tests ourselves, independent evaluator) would catch lies. See [[team-lead]].
- **Worktree isolation for parallel workers** → when our team-lead runs multiple subagents on different issues, worktree isolation prevents file conflicts. Currently we rely on branch naming.
- **Distilled failure feedback for retries** → instead of dumping full review text into retry prompt, distill to concise actionable report. Reduces context size for next attempt.
- **Regression ratchet** → mechanical guarantee that previously-passing tests still pass after changes. We lack this.

### Patterns that validate our approach:
- **Grade-scaling is correct**: 29× overhead for a 1-liner proves that full-pipeline for trivial work is wasteful. Our LIGHT/STANDARD/HEAVY grading (from [[why-was-fable-banned]]) is the right response.
- **Enforcement at tool level > instructions**: PreToolUse hooks > "please don't write X". Aligns with our DNA rule about Claude Code constraints.
- **Independent verification > self-report**: Evaluator as separate agent confirms our "验证 subagent 外部操作声明" rule.

### Concerns:
- Solo dev, single-day upload, no community. Watch for whether it goes dormant.
- Heavy Python dependency (Textual TUI). Not easily composable with our Node.js stack.
- The 49% killed_turns rate suggests the 30-turn budget is too tight for the complexity of the tasks — a fundamental tension between cost control and task completion.

## Cross-references

- [[team-lead]] — our multi-agent coordination skill
- [[why-was-fable-banned]] — grade-scaling pattern we already adopted
- [[architect-loop]] — design-first philosophy Foreman shares
- [[paca]] — another Scrum-like agent coordination platform
- [[genericagent]] — conductor/delegate pattern comparison
- [[ccglass]] — coding agent observability (complementary to Foreman's metrics)

## Applied: Regression Ratchet (2026-06-20)

**What was applied**: Created `tools/test-ratchet.sh` — structural gate that prevents test count decrease and detects new failures after subagent code changes.

**Implementation details**:
- Commands: `snapshot` (before changes), `verify` (after changes), `detect` (auto-detect test cmd), `status`, `clean`
- Parsers: Node native test runner (`ℹ tests N`), vitest (`Tests N failed | M passed (T)`), jest, pytest, go test, TAP
- Storage: `~/.openclaw/workspace/.test-ratchet/<repo-hash>.json`
- Ratchet checks: (1) test count decrease, (2) new failures, (3) previously-passing now failing, (4) exit code regression
- On pass: baseline ratchets forward (new higher baseline for next verify)
- Integrated into `tools/regression-gate.sh` rules + documented in `tools/repo-tests.md`

**What's different now**: Before, we trusted subagent claims about test results (behavioral rule in AGENTS.md). Now we can independently verify by snapshot-before + verify-after. The tool specifically catches the pathological case where a subagent "fixes" a test by deleting it — test count decrease is flagged immediately.

**Verification**: Tested against cove (vitest: 444 tests, correct parsing), gitclaw (Node native runner: 19 tests). Simulated regressions detected correctly: test count decrease and new failures both produce clear FAIL verdicts.

## Tracking

- **Status:** cool (downgraded 06-26)
- **Stars:** 86→116 (+35%, slow growth)
- **Last feature commit:** 05-11 (45 days ago). Recent: CI bumps + PyPI publish only
- **Community:** 0 external contributors, 11 issues (all self-filed)
- **Revisit:** 07-26
- **Downgrade reason:** No feature development in 45 days. All applicable patterns already extracted and applied (test-ratchet, merge gate concepts, worktree isolation). Solo dev in maintenance/polish mode. No community formation.
