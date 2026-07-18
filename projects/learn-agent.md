---
title: learn-agent — From-Scratch Coding Agent Engineering Course
status: deep-read
discovered: 2026-07-04
source: https://github.com/7-e1even/learn-agent
stars: 149
language: JavaScript
license: MIT
author: 7-e1even (Reina developer)
tags: [coding-agent, engineering, education, agent-internals, memory, completion-gate, cache-engineering]
last_verified: 2026-07-18
---
# learn-agent

> "从零写一个能活下来的 AI Agent" — 20 progressive lessons, zero deps, from real product Reina.

## What It Is
20 runnable single-file lessons covering the **real engineering** behind coding agents (Claude Code, Codex, etc.). Each lesson is battle-tested — mechanisms extracted from [Reina](https://github.com/Reina-Agent/Reina), a production desktop coding agent (Electron + React + TypeScript). Now with GitBook publishing (07-08).

Not a toy tutorial: every lesson starts with "the crash" → design decision → runnable code → production cross-reference → challenge.

## Key Architectural Insights

### s06 — Context Compaction: Three-Segment Model
- **Shape**: [system (untouched)] → [middle history → model summary] → [launch user message VERBATIM ★] → [recent tail kept]
- **Critical rule**: Launch message must survive compaction word-for-word. Summaries are model-generated → progressive drift. After 2-3 compressions, "refactor utils/date.js to support timezones" becomes "user is optimizing code" → agent forgets original task.
- **Fallback**: Extractive summary (string-only, zero-LLM) when model summary call fails. "Lossy memory > crashed session."
- Reina commit `ce4724f` fixed this exact bug.

### s07 — Prompt Cache Engineering: 10x Price Difference
Three disciplines for prefix cache stability:
1. **System prompt byte-stable across turns** — move time-varying data (timestamps, budget remaining, todos) to tail user message
2. **Tools array order-stable** — no runtime sorting, no conditional add/remove, no dynamic content in descriptions
3. **Messages append-only** — never modify old messages (even "helpfully" truncating old tool output breaks cache from that point forward)

Cache hit = ~0.1x price. A 50-turn task with 95% hit rate costs ~7x less than 0% hit. **Regression test**: assert system prompt is byte-identical regardless of volatile state.

### s09 — Subagent Watchdog: Two-Tier Stale Detection
- **Context isolation**: Subagent = fresh empty `messages[]`, same chat+dispatch+budget, BUT no `task` tool (depth limit = 1, no recursion)
- **Heartbeat**: Event-based `lastEventAt`. Stale budget is TWO tiers:
  - Idle (no tool running): 450s → kill
  - In-tool (running test suite etc.): 1200s → different threshold (silence during tool execution is normal)
- **Wall-clock hard cap + liveness extension**: At timeout, check if events in last 30s → if yes, extend 300s more (don't kill active workers)
- **Two-phase salvage**: After kill, give one more turn with short timeout for "last words" (what was the task, what did you do, what's left). Recovers ~80% of work.
- **Dedup**: Same-brief tasks (normalized: whitespace + lowercase) → reuse first result, don't spawn duplicate

### s15 — Progressive Tool Disclosure: Cache-Safe Approach
- **Problem**: 30+ tools = thousands of tokens every turn in tools array. Tools array is at cache prefix start.
- **Naive approach BROKEN**: Disclose tool → add to tools array → cache prefix invalidated every time
- **Correct approach**: Tools array stays CONSTANT. Disclosed tool schema returned in search results (message body, at cache tail = safe). Actual invocation via proxy `run_tool({name, input})`. Zero cache breakage.
- **Permission gotcha**: `run_tool` permissions must check TARGET tool, not `run_tool` itself — huge security hole otherwise
- CJK-aware search (unigram + bigram) better than pinyin-based BM25

### s18 — Completion Gate: Two-Gate Autopilot Termination (NEW 07-07)
- **Problem**: Autonomous agents either quit too early (declare done after 1/3 of work) or narrate-then-stop (plan each turn, never execute)
- **Root cause**: The model that does the work also judges if it's done — same hand writing and grading
- **Solution**: `declare_audit_done` tool with two serial gates:
  - **Gate 1 (Goal contract)**: Goals declared at task start must be explicitly closed (`mark_goal_met` with evidence OR `cancel_goal` with reason). Open goals = rejection
  - **Gate 2 (Independent judge)**: Separate model call (temp=0, JSON-only) reads compressed execution trace. Skeptical by default: "no concrete evidence (tool output, file changes, test results) in a pretty summary = fail"
- **Trace compression**: 18k chars → 415 chars. Judge sees: turn count, tool call sequence (names only), last 8 assistant narrations (200 chars each), goal contracts + evidence
- **Anti-deadlock**: verifyRounds cap (3), fail-open on judge failure, cancel_goal escape, total turn limit + stagnation detection
- **Feedback loop**: Judge rejection reopens goals → next declare hits Gate 1 again → model must actually work
- **Relevance to us**: Our FlowForge completion checks are simpler (no independent judge). The compressed-trace-for-judge pattern is directly applicable to subagent outcome verification

### s19 — Compaction-Cache Conflict: Three-Account Resolution (NEW 07-07)
- **Core tension**: Compaction rewrites history (breaks cache prefix); cache needs history stable. These fight.
- **Account 1 — When to compress**: Threshold trigger (75% window) beats per-turn trimming. 20 turns: threshold = 0.9× cost (1 cache break), per-turn trim = 1.5× cost (17 cache breaks). "Rewriting history is a per-occurrence fee — batch it."
- **Account 2 — Summary call billing**: Ride the main agent's just-cached prefix. Use identical system+tools+native messages (byte-for-byte match for cache hit), append summary instruction as final user message. 99.9% cache hit vs 0% for independent request. Trade-off: must fence against tool calls in summary response (discard + fallback if model defects)
- **Account 3 — Where to put summary**: Fold into history as `restored-context` message (pays full price once, then cached at 0.1× every future turn). NOT as per-turn system-reminder (pays full every turn forever)
- **Key insight**: "Use cheap model for summary" vs "ride main model's cache" — latter usually cheaper. Cache isolation is per model+provider
- **Relevance to us**: OpenClaw's compaction should verify it's not doing per-turn trimming. The prefix-riding pattern for summary calls is a concrete optimization we could adopt

### s20 — Dream Consolidation: Cross-Session Long-Term Memory (NEW 07-17)
- **Problem**: s17's review loop handles within-session learning. This handles cross-session, cross-project memory maintenance without billing explosion
- **Three pitfalls** (from real product crashes):
  - Timing: Consolidating mid-task creates false "facts" from intermediate states
  - Selection: Write-ahead ("looks permanent → write it") → 80% dead weight
  - No exit: Old notes never deleted → contradictory facts coexist
- **Architecture — Three write channels, all demand-driven**:
  1. **Inline notes** (primary): Agent writes notes during work (existing mechanism)
  2. **Retrieval-as-signal** (NOVEL, no other impl has this): When cross-session search hits historical session data, append hint: "this knowledge was re-queried — if reusable, fold into global notes now." Zero scheduler, zero extra model calls. Demand-driven.
  3. **Background dream** (backstop): Fire-and-forget fork with restricted tool whitelist (note CRUD only — no shell, no network). Reads session summaries (not full transcripts). Gated by: master switch + per-project 72h cooldown + minimum 10 idle sessions accumulated
- **Idle filter** (from Codex `min_rollout_idle_hours`): Only sessions idle ≥6h count toward threshold / enter consolidation material. Prevents consolidating intermediate states as facts
- **Pruning via delete_note**: Consolidation agent's whitelist includes delete. Instruction: "superseded/contradicted notes → delete." Only system with explicit memory exit.
- **Stamp-as-lock**: Write `consolidated_at` timestamp BEFORE executing. Concurrent sessions see fresh stamp → skip. Crash = wait for next cooldown cycle (cheaper than recovery logic)
- **Comparison (9 implementations surveyed)**:
  - claude-code: Most complete (per-turn extraction + 24h dream + top-5 injection). Expensive.
  - codex: Heaviest (startup dual-pipeline, SQLite task lease, git-based memory repo)
  - grok: Skeleton adopted here (simplest complete shape)
  - hermes: Lifecycle hooks + pluggable backends
  - Others: Semi-auto or none
- **Relevance to us**: "Retrieval-as-signal" is the standout novel pattern — zero-cost memory promotion driven by actual reuse. Our `memory_search` could append similar hints when hitting old session data. The idle filter is also applicable: our MEMORY.md updates should wait for sessions to cool before extracting facts.

## Relevance to Our Direction
- Compaction three-segment model is the same pattern OpenClaw uses (keep launch message)
- Cache engineering disciplines directly applicable — we should verify our system prompt is byte-stable
- Tool disclosure proxy pattern worth investigating for MCP tool scaling
- Subagent watchdog two-tier stale detection is a more nuanced version of what OpenClaw does
- **Completion gate** (s18): Independent judge pattern applicable to FlowForge/subagent outcome verification
- **Compaction-cache** (s19): Prefix-riding for summary calls is a concrete optimization; verify we're not per-turn trimming
- **Dream consolidation** (s20): "Retrieval-as-signal" is directly implementable in our memory system. Idle filter applicable to MEMORY.md maintenance.

## Tracking
- 53⭐ → 149⭐ (+181% in 14 days) — strong organic growth
- Now 20 lessons (was 15). Course structure expanding into advanced topics (memory, self-evolution)
- Author actively maintaining Reina alongside course
- GitBook published (07-08) — professionalization signal
- Revisit: 07-25 (check s21+, community growth)

[[coding-agent-ecosystem]], [[agent-harness-landscape]], [[prompt-cache-engineering]], [[agent-memory-consolidation]], [[completion-verification]]
