# ALBERT — Autonomous Multi-Agent Harness for Claude Code

> Source: [Sdraugel/albert](https://github.com/Sdraugel/albert) | 93⭐ | Created 2026-07-23 | JavaScript | PolyForm NC 1.0.0
> Deep read: 2026-08-02

## What It Is

A long-running autonomous orchestrator for Claude Code. You give it a goal in plain English (`/albert "Add pagination to the users API"`), and it:
1. Decomposes into a DAG of tasks via a dedicated **Planner** agent
2. Fans tasks out in parallel using **git worktree isolation** (one worktree per task)
3. Each task is implemented by a fresh-context **producer** agent (worker/designer/data-scientist/researcher/devops)
4. Independent **Verifier** agent re-runs ALL verify commands from scratch (never trusts producer claims)
5. **Reviewer gates** (code/security/performance) + **QA** sign off
6. Merges passed work in dependency order
7. Loops until goal met or budget exhausted

Ships with a zero-dependency local HUD console (SSE-based, localhost:4400) and an optional chat dock for steering running orchestrations.

## Architecture

```
User → /albert "goal"
  → INITIALIZER: project.json auto-detect, goal.md, loop-planner → tasks.json
  → LOOP (per chunk, serial):
      chunk-exec.js orchestrates:
        ├─ Load: read tasks for this chunk
        ├─ Worktrees: create isolated git worktrees (serial)
        ├─ Execute: produce + verify + gates + QA (concurrent per task)
        ├─ Merge: merge passed branches into chunk branch (dep order)
        └─ Cleanup: prune worktrees
  → TERMINAL: notify user, open PR, merge if policy allows
```

### Durable State (on disk, never committed to project repo)

```
~/.claude/agent-runs/
  index.json                    # active run registry
  <run-id>/
    goal.md, project.json       # what and where
    tasks.json                  # DAG with roles, verify contracts, model tiers
    progress.json               # iteration count, budget, status
    events.jsonl                # telemetry stream (console reads this)
    inbox/                      # async steering messages (steer/question/info)
    init.ps1                    # idempotent env bootstrap
    ledger.csv                  # research mode: experiment ledger
    iterations/<n>/             # per-iteration logs and evidence
```

### Agent Roster

| Agent | Role | Model |
|-------|------|-------|
| loop-planner | Decomposes goals → tasks.json | opus |
| loop-worker | Generic code producer | sonnet |
| loop-designer | Visual/UI tasks (screenshot-verified) | sonnet |
| loop-data-scientist | Analysis, backtests, stats | sonnet |
| loop-researcher | External information gathering | sonnet |
| loop-devops | CI, infra, containers, deploy | sonnet |
| loop-verifier-dev | Independent verification (re-runs from scratch) | sonnet |
| loop-skeptic-research | Tries to REFUTE research findings | opus |
| loop-qa | Quality assurance | sonnet |
| loop-scribe | Documentation writer | sonnet |
| loop-cleanup | Prunes worktrees, temp artifacts | sonnet |
| code-reviewer / security-reviewer / performance-reviewer | Gate reviewers | sonnet |

## Key Design Patterns

### 1. Model Tier Escalation
Tasks start at the cheapest viable model (haiku → sonnet → opus). On verify failure, the orchestrator re-dispatches at the next tier. This is a cost optimization: most mechanical tasks succeed at haiku, freeing opus budget for genuinely hard reasoning.

### 2. Inbox Pattern (Async Steering)
Running orchestrations have a file-based inbox (`inbox/<timestamp>.json`). External messages queue as steer/question/info. The orchestrator drains the inbox at loop-start BEFORE budget checks. This enables non-interrupting human steering of autonomous runs — you can redirect priorities without killing the loop.

The chat dock talks to the orchestrator through this inbox. At-least-once delivery (crash between reply and archive → re-delivers on next wake).

### 3. Independent Verification as Trust Architecture
The verifier is a SEPARATE agent that:
- Does NOT trust the producer's evidence
- Re-runs verify commands in a freshly bootstrapped environment
- Captures its own stdout/exit codes
- Reports mismatches between claimed and actual results

This is stronger than self-verification. The producer has incentive to claim success; the verifier has no such incentive.

### 4. Research Skeptic (Anti-Self-Deception)
For research/data-science goals, a dedicated skeptic agent tries to REFUTE claimed findings using a pre-registered protocol: null cull, holdout integrity, train-selection check, deflated Sharpe ratio, sensitivity analysis. Defaults to REFUTED when ambiguous.

### 5. Git Worktree Parallelism
Same-chunk tasks run in parallel, each in its own git worktree. File scope disjointness is enforced at planning time. Cross-task conflicts resolved by dependency ordering or task merging. This maximizes throughput for large goals.

### 6. Fresh Context per Iteration
Every producer spawns with clean context and reads state from disk. This defeats context window exhaustion on long runs — each task sees only what it needs, not the full orchestration history.

## Tradeoffs & Observations

- **Windows-first**: PowerShell scripts, backslash paths with `{{CLAUDE_DIR}}` templates. Unusual in the agent ecosystem (most tools target Unix). Cross-platform support contributed externally but not yet merged.
- **Zero dependencies**: Both runtime and console use only Node builtins. Good for portability, limits ecosystem integration.
- **PolyForm NC license**: Non-commercial only. Limits adoption for professional use.
- **Claude Code specific**: Uses Claude's native Task/AgentTool infrastructure. Not portable to other harnesses.
- **Solo dev**: Single contributor, 10 days old, no community yet (0 open issues, 1 closed cross-platform issue). Growth trajectory uncertain.
- **No tests**: No test/ directory observed. The harness verifies USER code but has no self-verification.

## Relevance to Us

| Pattern | Our Equivalent | Delta |
|---------|---------------|-------|
| Independent verifier | FlowForge regression-gate.sh | ALBERT's is a full agent re-running from scratch; ours is a script checking specific outputs |
| Model tier escalation | Not implemented | Could save cost on mechanical subagent tasks |
| Inbox/steering | Cron wake events | ALBERT's is richer (typed messages with reply-and-archive lifecycle) |
| Git worktree parallelism | Not used | We spawn Claude Code subagents but don't isolate at worktree level |
| Fresh context per iteration | Subagent isolation | Similar pattern, different implementation |
| Research skeptic | Not applicable yet | Novel concept for data-validation workflows |

### Applicable Insights

1. **Model tier escalation** could reduce our Claude Code costs: dispatch subagents at sonnet, escalate to opus only on failure.
2. **Typed inbox** pattern for steering long-running processes without interruption is cleaner than our current "wake event with text" approach.
3. The **"verify is a separate agent that never trusts the producer"** framing is stronger than "the same agent checks its own work."

## Ecosystem Position

Competes with: [[claude-code-coordinator]] (Claude's native multi-agent), [[oh-my-kimichan]] (Kimi Code multi-agent), [[optim-plans]] (dual-ring planner+executor).

Differentiated by: HUD console (visual observability), research skeptic pattern, Windows-first design, long-running autonomous operation (hours/days without human intervention).

## Status: Following

Solo dev, early stage, high architectural interest but uncertain longevity. Check back in 2 weeks for community growth signal.

---

Links: [[claude-code-coordinator]], [[multi-agent-consensus]], [[agent-harness-landscape]], [[oh-my-kimichan]], [[optim-plans]], [[supervisor-pattern]]

## 2026-08-16 Followup (98⭐, +5%)

**Signal: maintainer dormant, community waking up.**
- Zero default-branch commits since 07-26 (no code at all since we started tracking 08-02). Pushed_at 07-26 confirmed against default branch — dormant.
- BUT 3 external PRs queued unmerged: macOS compatibility (#2, 08-03), non-localhost console fix (#3, 08-14), POSIX launch instead of powershell shelling (#5, 08-14). External contributors are porting it off Windows-first.
- Star growth 93→98 (+5%) — slow but positive.

**Anti-pattern worth noting:** PR queue growth while maintainer is silent is the classic "community outpaces maintainer" signal. For solo-dev Windows-first projects (PolyForm NC license), the first external PRs are usually portability fixes — if those sit unmerged >2 weeks, the project either gets forked or stalls. Watch #2/#3/#5 merge status at next check.

**Status: Downgraded to warm (14d).** Revisit 08-30 for PR merge status. If all 3 PRs still unmerged with zero new commits → drop trigger (solo dev abandoned).

## 08-30 Follow-up

- ✅ **cal-0816-a1d7 CORRECT**: 3 个外部 PR（#2/#3/#5）仍全 open unmerged。
- Default-branch 自 07-26 后有 2 commits（08-16 时 zero）——微弱 activity，maintainer 仍 dormant。
- **Verdict**: 保持 warm。Revisit 09-13; 3 PRs 仍 unmerged + 0 maintainer 回复 → drop（solo dev abandoned）。
