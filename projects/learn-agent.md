---
title: learn-agent — From-Scratch Coding Agent Engineering Course
status: deep-read
discovered: 2026-07-04
source: https://github.com/7-e1even/learn-agent
stars: 53
language: JavaScript
license: MIT
author: 7-e1even (Reina developer)
tags: [coding-agent, engineering, education, agent-internals]
last_verified: 2026-07-04
---
# learn-agent

> "从零写一个能活下来的 AI Agent" — 15 progressive lessons, zero deps, from real product Reina.

## What It Is
15 runnable single-file lessons covering the **real engineering** behind coding agents (Claude Code, Codex, etc.). Each lesson is battle-tested — mechanisms extracted from [Reina](https://github.com/Reina-Agent/Reina), a production desktop coding agent (Electron + React + TypeScript).

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

## Relevance to Our Direction
- Compaction three-segment model is the same pattern OpenClaw uses (keep launch message)
- Cache engineering disciplines directly applicable — we should verify our system prompt is byte-stable
- Tool disclosure proxy pattern worth investigating for MCP tool scaling
- Subagent watchdog two-tier stale detection is a more nuanced version of what OpenClaw does

## Tracking
- Author also maintains Reina (10⭐, just launched 07-03)
- Course created 07-03, growing fast (53⭐ in 1 day)
- Revisit: 07-11 (check if more lessons added, community traction)

[[coding-agent-ecosystem]], [[agent-harness-landscape]], [[prompt-cache-engineering]]
