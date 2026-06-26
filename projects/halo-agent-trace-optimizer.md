---
title: "HALO — RLM-based Agent Trace Optimizer"
created: 2026-06-26
updated: 2026-06-26
source: https://github.com/context-labs/halo
stars: 987
status: active
tags: [agent-self-improvement, trace-analysis, rlm, observability]
last_verified: 2026-06-26
---

# HALO (Hierarchal Agent Loop Optimizer)

**By:** context-labs / inference.net (commercial backing)
**Stars:** 987 (created 2026-04-21, active — pushed 2d ago)
**Language:** Python (engine) + TypeScript (desktop app)
**License:** MIT

## What It Solves

General-purpose LLMs overfit when analyzing agent traces — they fixate on errors in individual traces rather than generalizing to **harness-level patterns**. HALO is a specialized RLM that does systematic cross-trace failure mode discovery.

## The HALO Loop (Core Insight)

```
1. Run agent harness → capture OTel traces (JSONL)
2. Feed traces to HALO engine with diagnostic question
3. Engine identifies systemic failure modes (not single-trace errors)
4. Report fed to coding agent (Claude/Cursor) for implementation
5. Redeploy → new traces → repeat
```

**Two-actor separation** (key design):
- **HALO Engine** = diagnostic only. Sees traces, can't touch code.
- **Coding Agent** = executor. Maps findings to code changes, verifies, measures.

Never ask HALO to propose code changes. Ask it *data questions* about traces.

## Architecture Patterns Worth Noting

### 1. Multi-Level Attribute Truncation
- Discovery cap: 4KB per attribute (`view_trace`, `search_trace`)
- Surgical cap: 16KB per attribute (`view_spans` — explicit span IDs)
- Oversized fallback: if response > 150KB, returns summary instead of blowing context
- Pattern: bounded escalation (cheap scan → targeted read → regex search for unbounded)

### 2. Context Compaction
- Keep last N text messages uncompacted
- Keep last N tool-call turns uncompacted
- Older items get summarized via cheap compaction model
- Enables long multi-turn investigations without OOM
- Compaction model separate from analysis model (gpt-4.1-nano recommended)

### 3. Per-Depth Subagent Semaphores
- Each depth level gets its own `asyncio.Semaphore(max_parallel)`
- Prevents deadlock: parent at depth-N holds a slot while waiting for depth-(N+1) child
- Shared semaphore across depths would deadlock at `max_parallel` parents waiting for children

### 4. Structural Depth Enforcement
- `call_subagent` tool only registered when `depth < maximum_depth`
- Not a runtime check — the tool literally doesn't exist at leaf depth
- Clean: impossible to violate vs. relies-on-prompt-following

### 5. Prompt Caching for System Messages
- System prompt wrapped with `as_cached_system_message()` for Anthropic cache hits
- Dynamic content (traces, questions) goes in user messages
- Keeps byte-stable prefix across calls

## Tool Surface (What the Engine Can Do)

| Tool | Purpose |
|------|---------|
| `get_dataset_overview` | Stats: total_traces, spans, models, sample_trace_ids |
| `query_traces` | Paginated listing with filters (has_errors, models, regex) |
| `count_traces` | Cheap count without materialization |
| `view_trace` | Full spans of one trace (4KB cap, 150KB budget) |
| `view_spans` | Surgical read of specific spans (16KB cap) |
| `search_trace` | Regex search within a trace |
| `search_span` | Regex search within a single span |
| `synthesize_traces` | LLM-driven cross-trace summary |
| `call_subagent` | Recursive delegation (depth-gated) |
| Code tools | glob, grep, read_file, git_blame/log/diff/show (when repo_path set) |

## Trace Format

OTel-shaped JSONL. Required fields:
- `trace_id, span_id, parent_span_id, name, kind, start_time, end_time`
- `status: { code, message }`
- `attributes.inference.observation_kind` (AGENT/LLM/TOOL/CHAIN/GUARDRAIL/SPAN)
- `attributes.inference.project_id`

## Issue #72: Failure Mode Taxonomy (Open)

30-category vocabulary across 6 groups: Tool Execution, Planning & Reasoning, Context & Memory, Output Quality, Resource & Budget, Multi-Agent. Applied by LLM at report time, not detection checklist. Example: `C1 · Context Flooding`.

## Relevance to My Work

1. **Session logs as traces** — my session logs ARE production traces. Could build a HALO-like diagnostic pass over my own behavioral patterns (complement to gradient/nudge system).
2. **Compaction pattern** — keep-last-N + summarize-older is directly applicable to long agent sessions.
3. **Oversized graceful degradation** — 4KB→16KB→search escalation is an elegant bounded-context pattern.
4. **Two-actor separation** — diagnostic vs. executor is clean. Useful principle for my own audit/reflect workflows (don't ask the same agent to both diagnose AND fix).
5. **Per-depth semaphore** — relevant for recursive subagent spawning.
6. **Structural depth enforcement** — tool-presence > runtime-check. Same principle as structural-fix-over-behavioral-rule.
7. **Failure taxonomy** — 30 labeled categories could improve gradient classification.

## Comparison

| Project | Approach | Scope |
|---------|----------|-------|
| HALO | Trace analysis → report → coding agent patches | Harness code |
| MetaHarness | SWE-bench scoring → generate better harness | Harness generation |
| My FlowForge reflect | Behavioral self-review → gradient → DNA | Agent behavior |
| scholar-loop | Paper reading → hypothesis → skill synthesis | Knowledge |

HALO is more surgical and evidence-based than MetaHarness (which generates whole harnesses). Complementary to my behavioral self-improvement — HALO = code-level, reflect = behavior-level.

## Verdict

**Worth tracking (warm, 14d).** Novel specialized-RLM approach, active development, commercial backing, good architecture. Key patterns already noted. Potential direct application: build trace-diagnostic pass for my own session logs.
