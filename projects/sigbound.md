# Sigbound — Parallel Agent Merge Engine

> "Run multiple AI coding agents on one repository in parallel, and merge their work automatically — landing only changes that build and pass your tests."

- **Repo**: [surya-koritala/sigbound](https://github.com/surya-koritala/sigbound)
- **Stars**: 50 (2026-07-26)
- **Language**: Go 1.25+
- **License**: Apache-2.0
- **Created**: 2026-07-21
- **Status**: Active, self-dogfooding (sigbound lands its own changes via sig)

## Problem Statement

Parallel coding agents (via worktrees) generate branches fast, but **merging is where time goes**: 30–50% of parallel-agent time on conflict resolution. Even conflict-free merges can produce builds that fail. Cursor Origin promises this but is closed/waitlist. Sigbound is the open alternative.

## Architecture

### Core: OCC (Optimistic Concurrency Control) for Git

The key insight: most branches touch **disjoint files**, so they can be merged in parallel without conflict risk. The engine:

1. **Partition** — Union-find groups branches by write-set path overlap (O(paths × branches))
2. **Parallel fold** — Each group's overlapping branches are serialized via `git merge-tree` (in-memory, no worktree)
3. **Combine** — Disjoint group heads are unioned via tree-overlay fast path (no 3-way merge at all) or parallel pairwise reduction

### Key Design Choices

- **Object-store only**: All integration uses `git merge-tree` + `git commit-tree`. No checkouts, no working tree, no index locks during integration. This is what makes parallelism possible.
- **Tree overlay fast path** (`StrategyOverlay`): Disjoint group heads don't even need merge — their changed entries are overlaid onto base in the object store directly. Proven byte-for-byte identical to merge-tree for disjoint inputs.
- **Compare-and-swap landing**: Final commit published to ref only if base hasn't moved (prevents silent overwrite of concurrent landings).
- **Single long-lived `cat-file --batch`**: Blob reads for conflict resolution route through one persistent daemon per Cell, not N process spawns.

### Strategies (benchmarkable)

| Strategy | Mechanism | Use |
|----------|-----------|-----|
| `porcelain` | Worktree + `git merge` (serial) | Baseline |
| `naive` | Serial `merge-tree` (no parallelism) | Comparison |
| `mergetree` | OCC partition + parallel fold + merge-tree combine | Fast |
| `overlay` | OCC partition + parallel fold + **tree-overlay combine** | Fastest (default) |

### Performance

17–25× speedup over sequential merge at 64–512 agents. Linear scaling past 4096 agents (docs/SCALE.md).

## BYO Model Architecture

Everything is a shell command:
- `-planner`: Breaks goal into tasks
- `-agent`: Executes a task in its worktree
- `-resolver`: Resolves a conflicted file (gets SIGBOUND_BASE/OURS/THEIRS as temp files)
- `-repair`: Fixes a broken build after merge
- `-verify`: Build + test gate (nothing lands unless it passes)

Presets for common tools: `claude`, `codex`, `aider` for agents; `go`, `node`, `python`, `rust` for verify.

## Safety Mechanisms

1. **File lanes**: Tasks declare allowed files; agent that strays → rejected
2. **Landing policy** (`sigbound.policy`): Committed file declares verify battery, lane strictness, semantic analysis, ack-paths
3. **Run parking**: Changes to sensitive paths are verified but HELD for human `sig ack`
4. **Self-repair**: Failed verify → sent to repair command → re-verified
5. **Audit sample**: Configurable % of clean landings surfaced for human review
6. **Semantic edges**: Optional symbol-level conflict detection (e.g. Go imports) forces seemingly-disjoint branches into same group

## Novel Patterns

- **Union-find for branch partitioning** — simple, efficient, captures transitive overlap
- **"Never guess" resolver contract** — resolver declines on ANY path → entire branch flagged (fail-safe)
- **Continuous mode** (`sig serve -watch`) — picks up new work, same gated loop, no operator
- **Bundle transport** (`sig export`/`sig import`) — multi-machine parallel execution with offline merge
- **Repo-owned policy versioned with code** — the bar is versioned, can only be tightened by flags

## Ecosystem Position

- **vs TokenCode** ([[tokencode-parallel-agent-runtime]]): TokenCode is a parallel agent RUNTIME (manages processes, /race mode). Sigbound is a MERGE ENGINE (post-execution, combine results safely). Complementary layers.
- **vs Shikigami** ([[shikigami]]): Desktop IDE with parallel agents, but merge is manual. Sigbound automates the merge step.
- **vs claude-squad/Conductor**: These run agents in parallel worktrees but leave merge to the user. Sigbound IS the merge.
- **vs Cursor Origin**: Same idea (parallel + auto-merge + gated), but closed/hosted. Sigbound is open, runs locally.
- **vs [[worktree-convergence-2026-05]]**: Sigbound is the most mature implementation of the "worktree per agent, safe merge" pattern that the convergence card documents.

## Relevance to Our Direction

1. **OpenClaw multi-agent**: If OpenClaw ever runs multiple agents in parallel on one repo, sigbound's OCC partition + verify gate is exactly the missing piece.
2. **Safety-first landing**: The "nothing lands without verify" + "flag, never guess" philosophy aligns with our DNA principles.
3. **Dogfooding as validation**: The repo uses itself — `sigbound.policy` gates its own changes. Strong signal of real-world readiness.
4. **File lanes = scope enforcement**: Same concept as our FlowForge task scoping — declare what you're allowed to touch, get rejected if you stray.

## Open Questions / Risks

- 50⭐, 5 days old — very early. Solo dev? Need to watch for stall.
- Go 1.25 requirement limits adoption (cutting-edge Go version).
- Windows support nascent (WaitDelay, POSIX shell dependency).
- No resolver preset yet — user must wire their own model for conflict resolution.

## Issues of Note

- #138 (closed): CAS on landing — race condition where concurrent landing could silently overwrite
- #139 (closed): Own policy didn't cover `./cmd/sig/` — self-found dogfooding gap
- #149 (open): Unland — ability to take back a landing that shouldn't have happened
- #148 (open): Translate existing CI into sigbound.policy — DX for onboarding

---

## Follow-up 2026-08-09 — Tracking Dropped

GitHub API check: **79⭐ / 9 forks / 0 open issues**; the last push was the 2026-08-03 v2.3.0 bounded Git-object-reader change (one product commit since 2026-07-28). The repository has not converted its early implementation velocity into issue or contributor signal, and its star count fell from 95 on 2026-08-02. The OCC partitioning and verified-landing patterns remain useful reference material, but there is insufficient live project signal to justify another portfolio slot.

*Deep-read: 2026-07-26. Follow-up: 2026-08-09. Sources: GitHub REST API repository, commits, and issues endpoints.*
