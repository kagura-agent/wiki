---
title: "Gensee Crate — Runtime Safety for AI Coding Agents"
created: 2026-06-25
tags: [agent-safety, runtime-security, rust, macos, linux, coding-agents, transactional-runtime, parallel-agents, idempotent-operations, crash-recovery]
source: https://github.com/GenseeAI/gensee-crate
status: following
last_verified: 2026-08-03
---

# Gensee Crate — Runtime Safety + Transactional Runtime for AI Coding Agents

## What It Is

Rust sidecar that provides full-stack runtime safety AND transactional workspace management for AI coding agents (Claude Code, Codex, Antigravity). Two pillars:
1. **Safety**: Policy enforcement + provenance lineage (original v0.1.x)
2. **Transactional runtime**: Process-level forking via tclone for parallel agent exploration (v0.2.0)

**Author:** GenseeAI (company, small team: yiying-zhang, shengqi-gensee, jayanth-gensee)
**Born:** 2026-06-23
**Stars:** 116⭐, 9 forks (as of 08-03)
**Status:** Active, v0.2.1-dev (managed sandbox CLI). GROWING 3/6.

## v0.2.0 — Transactional Runtime (NEW, 07-22)

The major evolution: from pure safety sidecar → full agent workspace orchestrator.

### Architecture: Process-Level Forking

Uses [GenseeAI/os4agent](https://github.com/GenseeAI/os4agent) tclone (CRIU-based container clone) on Linux:

```
Source Container (running agent + workspace)
  │ gensee run fork --copies N --approach "..."
  ▼
┌─────────────────────────────────────┐
│  Fork 0: "minimal upgrade"          │
│  Fork 1: "aggressive latest-version"│
│  (full process + filesystem clones) │
└─────────────────────────────────────┘
  │ All finish → comparison prompt to source
  ▼
gensee run compare → gensee run choose --merge|--promote|--discard-all
```

**Key difference from file-system isolation** (git worktree, [[sigbound]]):
- Forks include **live process state** — hot caches, running services, environment
- Zero setup overhead (instant CRIU snapshot, not fresh checkout)
- Operates at container level (rootful Podman + btrfs storage driver)

### Parallel Fork Orchestration

1. Named fork groups (`--copies 2 --name try-upgrade`)
2. Each fork gets a bounded `--approach` label (validated, not trusted as instruction)
3. Forks work independently, report completion individually
4. Source receives comparison prompt when all finish
5. `run compare --json` gives size-and-test-status heuristic recommendation
6. User approves → `run choose` merges winner, discards siblings
7. Automatic timestamped suffix if clean names already taken

### Merge Strategies

| Strategy | Scope |
|----------|-------|
| `--git` (default) | Repo patch from fork point (includes staged + committed) |
| `--filesystem` | Overlay delta (tclone upperdir → source) |
| `--paths` | Selective paths under workspace |

All three have rollback backups on failure. Conflict detection for `--filesystem`/`--paths`.

### Security: Host-Control Bridge

Container-side `gensee` invocations reach the host through a request/response spool:

- **Scoped authority**: `TcloneHostControlTargetScope` enum
  - `CallerOrDirectChild` — for `send` (source→fork only)
  - `CallerOnly` — for `fork`, `exec`, `diff`
- **Request freshness + liveness**: Prevents replay attacks on the spool
- **Approval gate**: Every destructive lifecycle action requires user approval recorded in a hook before execution
- **NOT an isolation boundary**: Explicitly trusts the fork agent; prevents confused-agent mistakes, not malicious tampering

### Codex-Mediated Workflow

Codex (or any supported agent) can:
1. `run list --json` — poll available runs
2. `run summary <fork-id> --json` — read changed files + test results  
3. Present merge/promote/discard choices to user
4. Execute lifecycle only after user approval

This is "Codex as coordinator" — the agent orchestrates the exploration but can't autonomously merge.

## Original Safety Features (v0.1.x)

1. **Deterministic policy enforcement** — PreToolUse hook → allow/ask/deny
2. **Long-horizon provenance** — SQLite lineage graph
3. **System event monitoring** — macOS eslogger (Linux: tclone mode)
4. **Dashboard** — now includes transaction history, dependency graph, live feed

## Comparison

| vs | Difference |
|----|-----------|
| [[clawpatrol]] | Network-level MITM vs application-level hooks + OS events |
| [[sigbound]] | File-system OCC partition vs process-level fork (tclone includes live state) |
| [[superserve]] | Firecracker microVM vs Podman+CRIU (lighter, faster fork) |
| [[shikigami]] | Git worktree isolation vs full container clone |
| OpenClaw native approvals | Similar hook model, but Gensee adds provenance + transactional runtime |

## Architectural Insights

1. **Process forking > file forking for exploration**: When agents need to try multiple approaches, forking the running process (including caches, services, env) eliminates setup overhead. File-system isolation (worktrees) requires each fork to rebuild state from scratch.

2. **Approval-gated lifecycle is the right trust model for agent tooling**: The confused-deputy problem (agent accidentally merges/discards) is the real threat, not malicious code inside the fork. Lightweight approval > heavyweight sandboxing.

3. **Comparison heuristic ≠ correctness judgment**: Gensee explicitly frames its `run compare` recommendation as "smallest passing diff" heuristic, not a correctness claim. The human decides. Good epistemic humility.

4. **Host-control bridge scoping** (CallerOnly vs CallerOrDirectChild) is a clean capability model for parent-child agent relationships.

## Relevance to Our Work

- **Parallel exploration pattern** directly applicable: OpenClaw subagents could use similar "try N approaches, compare, pick winner" flow
- **Approval gate pattern** already exists in OpenClaw (native approvals) but lacks the structured comparison step
- **Linux-first** now (tclone requires Linux) — directly usable on our setup
- **Podman + btrfs requirement** is a deployment constraint worth noting

## v0.2.1-dev — Managed Sandbox CLI (NEW, 07-29)

Major new layer: `managed.rs` (1095 LOC) wraps tclone primitives in a production-grade programmatic API.

### Architecture: Idempotent Operation Journaling

Every mutation (create-source, delete-source, fork, merge, promote, discard) follows crash-safe protocol:

```
Client → gensee managed create-source --operation-id X --idempotency-key Y ...
         ↓
    begin_operation()
    ├── Same key + same fingerprint → Cached (return previous result)
    ├── Same key + different fingerprint → Error (idempotency conflict)  
    ├── Same op + running PID alive → InProgress (skip)
    ├── Same op + dead PID → Recover (per-action reconciliation)
    └── New → Execute
         ↓
    execute() → finish_operation() → JSON response
```

**Key design decisions:**
- **Fingerprint matching**: Prevents reuse of idempotency keys for different request shapes
- **PID liveness detection**: Distinguishes "still running" from "crashed" for concurrent retry handling
- **Per-action crash recovery**: `reconcile_interrupted()` has action-specific logic:
  - create-source: checks container+record existence, recovers if complete
  - delete-source: checks if truly gone
  - fork: verifies all expected copies exist, errors on partial
  - Other actions: requires explicit manual reconciliation
- **File-lock journaling**: 300s staleness detection, JSON state file with lock for serialized mutations
- **Protocol versioning**: Every response includes `protocol_version: 1`

### Reconcile Command

`managed reconcile` cross-references:
- Internal state (operation journal / tclone run records)
- Reality (Podman containers via `podman ps -a`)

Outputs: missing containers (record but no container) and orphaned containers (container but no record). Admin tool for state drift detection.

### Performance Optimization Pass (PRs 33-41)

9 open perf PRs systematically reducing fork latency:
- PR#33: End-to-end fork workflow latency reduction (umbrella)
- PR#36: Replace pidfile polling with runtime readiness events
- PR#37: Collapse source preparation round trips
- PR#38: Overlap source capability restore
- PR#39-41: Preinstall/reuse contexts and metadata

Signals: preparing for production use where fork speed is critical.

### Known Issues

Issue #2 (internal, jayanth-gensee): Fundamental concurrency issues in store layer:
1. No file locking on JSONL writes
2. DB/JSONL consistency gap (dual-write without atomicity)
3. Daemon threads share EventStore without JSONL synchronization

Managed CLI adds its own file lock but underlying store still lacks proper locking.

## Architectural Insights (Updated)

5. **Idempotent operation journaling is essential for agent infrastructure CLIs**: Agents crash, retry, run concurrently. Any CLI managing stateful resources needs: idempotency keys, fingerprint matching, PID liveness checks, and per-action crash recovery. This is the "WAL for agent tools" pattern.

6. **Reconciliation as first-class operation**: Long-running agent orchestration accumulates state drift. An explicit "check internal state vs reality" command is not optional — it's a production requirement. Similar to `docker system prune` but more principled.

7. **Systematic latency optimization confirms process forking viability**: 9 focused perf PRs (round-trip elimination, polling→events, context preinstall, operation overlap) suggest sub-second fork times are achievable with effort.

## Relevance to Our Work (Updated)

- **Operation journaling pattern** directly applicable to OpenClaw cron/subagent management: crash detection, idempotent retries, state reconciliation
- **Reconcile pattern** useful for cron jobs ("is the target session still alive?")
- **Perf optimization techniques** (replace polling with events, preinstall contexts) applicable to subagent spawn latency
- **Concurrency gap** is cautionary: building a production API layer on a store with known concurrency issues is risky. Test under real concurrency before trusting.

## Track

- Next revisit: 2026-08-10
- Watch for: perf PR merges (fork latency numbers), concurrency fix for Issue #2, community growth
