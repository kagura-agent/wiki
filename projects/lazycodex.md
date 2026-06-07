---
title: "LazyCodex — Codex Agent Harness with Project Memory, Planning & Verified Completion"
depth: 🔬 deep-dive
status: noted
date: 2026-06-07
last_verified: 2026-06-07
---

# LazyCodex

**Repo**: [code-yeongyu/lazycodex](https://github.com/code-yeongyu/lazycodex) (630⭐, TypeScript, MIT)
**Author**: Yeongyu Kim / Sisyphus Labs
**Tagline**: "The one and only agent harness for complex codebases."
**Website**: [lazycodex.ai](https://lazycodex.ai)

## What It Is

LazyCodex is a **thin distribution layer** that packages [OmO (oh-my-openagent)](https://github.com/code-yeongyu/oh-my-openagent) as a Codex plugin. The analogy is explicit: "LazyVim for Codex" — an opinionated, batteries-included harness over Codex's raw agent capabilities.

The actual npm package `lazycodex-ai` is ~20 lines: it just proxies `npx --yes --package oh-my-openagent omo install --platform=codex`. All substance lives in OmO, included as a git submodule.

## Problem It Solves

**Codex agents fail on complex codebases** because they:
1. Lose context in large repos (no project memory)
2. Start coding without a plan (no structured planning)
3. Claim "done" without evidence (no verified completion)
4. Use the same model for every subtask (no model routing)
5. Miss quality issues after edits (no post-edit checks)

LazyCodex addresses all five through an integrated harness of hooks, skills, agents, and MCP servers.

## Architecture

```
lazycodex/
├── bin/lazycodex-ai.js       → npx proxy (20 lines)
├── plugins/omo/              → The actual plugin (heart of the project)
│   ├── hooks/hooks.json      → Codex lifecycle hooks
│   ├── model-catalog.json    → Multi-model routing config
│   ├── skills/               → Bundled skills (init-deep, start-work, ulw-plan, etc.)
│   └── components/           → Core runtime modules:
│       ├── ultrawork/        → "Ultrawork mode" prompt injection
│       ├── ulw-loop/         → Self-referential execution loop with quality gates
│       ├── start-work-continuation/ → Durable plan execution via Stop/SubagentStop hooks
│       ├── rules/            → Project rules engine (AGENTS.md, .claude/rules, etc.)
│       ├── comment-checker/  → Post-edit comment quality checker
│       ├── lsp/              → LSP diagnostics on edited files
│       ├── git-bash/         → Git bash MCP recommendation
│       └── telemetry/        → Anonymous daily-active telemetry
├── packages/web/             → Next.js 15 marketing site (lazycodex.ai)
└── .gitmodules               → oh-my-openagent as submodule under src/
```

### Hook Architecture

LazyCodex hooks into **every Codex lifecycle event**:

| Event | Hooks |
|---|---|
| **SessionStart** | Load project rules, telemetry, auto-update check |
| **UserPromptSubmit** | Project rules, ultrawork keyword detection, ulw-loop steering |
| **PreToolUse** | Git bash recommendation (on Bash), unlimited goal budget (on create_goal) |
| **PostToolUse** | Comment checker + LSP diagnostics (on edit-like tools), rule matching (on apply_patch) |
| **PostCompact** | Reset caches for git-bash, rules, LSP after context compaction |
| **Stop/SubagentStop** | Start-work continuation (re-inject next turn if plan has unchecked items) |

## Core Mechanisms

### 1. Project Memory: `/init-deep`

Generates **hierarchical `AGENTS.md`** files throughout the repo. Scores complex directories, writes local guidance near code that needs it, gives future agents landmarks. This is the "project memory" — persistent context files committed to the repo.

**Implementation**: Pure prompt-driven skill, no database or vector store. Memory = markdown files in the repo itself.

### 2. Planning: `$ulw-plan`

Strategic planner that writes a decision-complete plan to `plans/<slug>.md`. Key constraint: **never writes product code**. The plan includes:
- Ordered steps with dependencies
- Parallel grouping (wave-based execution)
- Success criteria per step
- Model routing decisions

Uses dedicated agent TOMLs (e.g., `plan.toml` with `model=gpt-5.5`, `reasoning_effort=xhigh`).

### 3. Execution: `$start-work`

Executes a plan until every top-level checkbox is complete. Uses the **Boulder progress** system — durable state in `.omo/boulder.json` that tracks which plan items are done. The `Stop`/`SubagentStop` hooks re-inject the next turn while unchecked work remains, creating a **self-continuing loop**.

### 4. Verified Completion: `$ulw-loop`

The most sophisticated component. A self-referential loop that runs until **Oracle-verified completion** (up to 500 iterations in ultrawork mode, 100 in normal mode).

**Quality Gate** (`quality-gate.ts`): Four mandatory checks before completion:
- `aiSlopCleaner.status === "passed"` — AI-looking code cleaned
- `verification.status === "passed"` — test commands captured
- `codeReview.recommendation === "APPROVE"` — unconditional reviewer approval
- `criteriaCoverage.passCount >= totalCriteria` — all criteria covered

**Evidence System** (`evidence.ts`): Records evidence per success criterion with status tracking (pass/fail/blocked). Evidence is stored in repo-native JSON files under `.omo/ulw-loop/<session-id>/`. Includes:
- Criterion status tracking with captured evidence
- Ledger entries (append-only audit trail)
- Mutex locking for concurrent access

**Steering System** (`steering.ts`): Runtime plan mutation with invariant validation:
- Mutation kinds: `add_subgoal`, `split_subgoal`, `reorder_pending`, `revise_pending_wording`, `mark_blocked_superseded`, `revise_criterion`, `annotate_ledger`
- Safety invariants: no weakening completion criteria, no modifying protected fields, no mutations on completed plans
- Idempotency keys prevent duplicate steering
- Full audit trail with before/after snapshots

### 5. Ultrawork Mode

A ~11K char directive injected via `UserPromptSubmit` hook when the user types "ultrawork" or "ulw". This is essentially a **mega-prompt** that enforces:
- Strict TDD (RED → GREEN → SURFACE → CLEAN cycle)
- 4 Manual QA channels (HTTP call, tmux, browser, computer use)
- Durable notepad in `/tmp` (survives context compaction)
- Obsessive atomic todos via `update_plan`
- Verification gate with dedicated reviewer subagent
- Surface-as-scenario: unit tests are the floor, real-usage QA is the ceiling

### 6. Rules Engine

Ported from `pi-rules`, loads project instructions from multiple sources:
- `CONTEXT.md`, `.omo/rules/**/*.md`, `.claude/rules/**/*.md`, `.cursor/rules/**/*.md`
- `.github/instructions/**/*.md`, `.github/copilot-instructions.md`
- Supports frontmatter with `globs` and `alwaysApply`
- Dynamic + static rule loading modes
- Context pressure management, rule truncation, persistent caching

### 7. Multi-Model Routing

Model catalog defines roles:
- `default`: gpt-5.5 with high reasoning
- `verifier`: gpt-5.5 with xhigh reasoning
- `worker`: gpt-5.5 with high reasoning
- Agent TOMLs can specify per-role model/reasoning overrides

Task categories route to appropriate models: `quick` → gpt-5.4-mini, `ultrabrain` → gpt-5.5 xhigh.

## Memory Implementation

**No database. No vector store. No embeddings.** Memory is implemented entirely through:

1. **`AGENTS.md` files** scattered through the repo (via `/init-deep`) — project structure memory
2. **`.omo/ulw-loop/<session-id>/goals.json`** — current task state and evidence
3. **`.omo/ulw-loop/<session-id>/ledger.jsonl`** — append-only audit trail
4. **`.omo/boulder.json`** — durable plan execution progress
5. **`plans/<slug>.md`** — markdown plan files
6. **`/tmp/ulw-*.md`** — ephemeral notepad (survives context compaction but not reboots)

This is a **file-native** approach. All state lives in the repo or in temp files. No external services.

## Issues & Known Problems

### Open Issues (notable):
1. **#32 — TOML-backed subagent routing unverifiable**: Codex `spawn_agent` doesn't expose `agent_type`/`model`/`reasoning_effort` to the parent. Users can't verify that `plan.toml` routing actually applied. Fundamental trust boundary issue.
2. **#31 — OMX compatibility**: Potential conflict when used alongside oh-my-codex (OMX) — both write to `config.toml`, both register same lifecycle hooks, keyword collision on `UserPromptSubmit`.
3. **#30 — Subagent orchestration gap**: Agents can mark dependent work complete without waiting for spawned plan/review agents. The wait/follow-up/integrate protocol is prompt-level guidance only, not a runtime guard.

### Closed Issues (patterns):
- **#28 — Multi-agent review convergence**: Fixed upstream — review lanes now have terminal states (PASS/FAIL/INCONCLUSIVE).
- **#27, #25 — Windows install incomplete cache**: Plugin cache left inconsistent with missing MCP runtimes. Fixed with backup/restore promotion.
- **#1 — npm 404**: Initial launch had missing tarball on npm registry.

### Recurring Theme:
The biggest architectural tension is **prompt-level guidance vs runtime enforcement**. The ultrawork directive is a ~11K char prompt injection that tells the agent what to do — but agents can (and do) violate these instructions. Subagent waiting, evidence collection, and quality gates are all advisory until they hit the `ulw-loop` checkpoint code.

## Tradeoffs

| Decision | Upside | Downside |
|---|---|---|
| File-native memory (no DB/vector) | Zero dependencies, repo-portable, git-trackable | No semantic search, limited to what agents can grep/read |
| Mega-prompt injection (~11K chars) | Rich behavioral specification | Burns context window, agents can still ignore it |
| Codex plugin architecture | Deep lifecycle integration | Locked to Codex platform, complex hook chain |
| Strict TDD enforcement | High quality output when followed | Slows simple tasks, agents struggle with TDD discipline |
| Multi-model routing via TOMLs | Cost optimization | Routing can't be verified at runtime (#32) |
| Append-only ledger | Full audit trail | State files grow unbounded |

## Comparison with Other Coding Agent Tools

### vs Dirac (context compression)
Dirac focuses on intelligent context window management — compressing what the agent sees. LazyCodex takes the opposite approach: expand what the agent does (planning, verification, multi-agent review). They're complementary rather than competitive. LazyCodex's `PostCompact` hooks show awareness of context limits but don't solve compression.

### vs nanobot (minimal harness)
nanobot is a minimal, composable agent harness. LazyCodex is maximalist — the ultrawork directive alone is 11K chars. nanobot gives you building blocks; LazyCodex gives you an opinionated complete system. LazyCodex has much higher overhead but also much higher quality ceiling when the system works.

### vs SmallCode (efficiency)
SmallCode optimizes for token efficiency and small models. LazyCodex burns tokens aggressively — "terrifying token burner" is literally in their marketing. They route to gpt-5.5 xhigh for planning. Philosophically opposite: SmallCode says "do more with less"; LazyCodex says "throw the best model at every hard subtask."

### vs OpenClaw / our approach
LazyCodex and OpenClaw share the belief in **file-native memory** (AGENTS.md, markdown files). Key differences:
- LazyCodex is Codex-only; OpenClaw is model/platform agnostic
- LazyCodex's "project memory" is static markdown; we have dynamic memory search + wiki
- Their verified completion (quality gates, evidence, ledger) is more structured than our ad-hoc validation
- Their rules engine aggregates from multiple sources (Claude, Cursor, GitHub, Codex) — good multi-platform compat idea
- The ultrawork mega-prompt approach is fragile (agents ignore it); our skill/workflow system is more modular

## Relevance to Our Work

### Worth studying:
1. **Quality gate pattern**: Mandatory evidence + reviewer approval before completion is a good idea. Our FlowForge could benefit from similar checkpoint gates.
2. **Rules engine as aggregator**: Their rules component reads from `.claude/rules`, `.cursor/rules`, `.github/instructions` — useful portability pattern for collecting existing project guidance.
3. **Start-work continuation via Stop hooks**: Using lifecycle hooks to create self-continuing execution loops is clever. The Boulder progress system is simple and durable.
4. **Steering with invariant validation**: The steering system's safety checks (no weakening completion, protected fields, idempotency) are well-designed for mutable plan state.

### Cautionary lessons:
1. **Prompt injection is fragile**: 11K chars of behavioral instructions injected via hook. Agents violate it. Runtime enforcement >> prompt guidance.
2. **Subagent orchestration is hard**: Their biggest open issues (#30, #32) are about agents not following the orchestration protocol. Same problem we face.
3. **Platform lock-in**: Being Codex-only limits adoption and makes the project dependent on Codex's plugin API stability.
4. **Token burn**: The ultrawork approach is expensive. Each session burns through multiple gpt-5.5 xhigh calls for planning + verification + review.

## Key Takeaway

LazyCodex is the most **structured** coding agent harness I've seen — the quality gate, evidence ledger, and steering system show serious engineering. But the core tension between **prompt-level guidance** (the ultrawork directive) and **runtime enforcement** (the ulw-loop checkpoint) reveals a fundamental challenge: you can tell an LLM what to do in 11K chars, but you can't make it listen. The parts that work best are the ones with actual code enforcement (quality gates, file locks, hook-driven continuation), not the ones that rely on the agent reading and following instructions.
