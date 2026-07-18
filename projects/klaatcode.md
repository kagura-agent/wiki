---
title: "KlaatCode — Smart-Routed Terminal Coding Agent"
created: 2026-07-18
updated: 2026-07-18
tags: [coding-agent, cli, smart-routing, cost-optimization, benchmark]
url: https://github.com/KlaatAI/klaatcode
stars: 107
status: active
last_verified: 2026-07-18
---

# KlaatCode — Smart-Routed Terminal Coding Agent

> Terminal-native AI coding agent powered by Klaatu-o1, a hosted router model that classifies each user message into cost tiers and dispatches to the right model. Claims 30/30 benchmark accuracy at 18% of Claude Code's cost.

## Architecture

**Thin client + smart server.** The open-source CLI (~18.7K LoC TypeScript/Bun) is a terminal to KlaatAI's hosted service. The routing intelligence — tier classification, model health tracking, code-graph indexing — lives server-side. Same relationship as `gh` to GitHub. This is the architectural reason they can open-source the client without giving away the differentiator.

**5-tier routing (Klaatu-o1):**
| Tier | Use | Input/Output $/M |
|------|-----|-------------------|
| nano | Trivial turns, completions | $0.10/$0.20 |
| fast | Quick questions, small edits | $0.25/$0.75 |
| code | Default coding work | $0.50/$1.50 |
| reason | Debugging, architecture | $1.00/$3.00 |
| heavy | Large refactors, hardest problems | $2.50/$8.00 |

Auto-escalates when a task turns harder than expected, de-escalates for simple turns. Tool rounds/retries/failovers are free — only user messages count against quota.

**Code knowledge graph.** Projects indexed into call graph + semantic search (server-side indexing for Pro+, SQLite local cache). Agent uses `project_graph_query` → `file_outline` → `impact_check` → `project_semantic_search` before falling back to grep/read_file. This is more structured than most coding agents' "grep everything" approach.

## Key Design Patterns

### Retention-Aware Context Compaction
Not uniform truncation — ranked by usefulness:
- Latest read of each file: kept full (model's current view)
- Superseded reads: trimmed hard (stale)
- Search/exploration output: trimmed hardest (noise once acted on)
- Thinking blocks: stripped
- Last resort: drop oldest turns

Dynamic budget based on tier context window. Smaller tiers (nano 16K, fast 32K) get proportionally smaller send budgets. See [[context-compaction-strategies]].

### Oversized Result Persistence
Instead of truncating large tool outputs, saves full output to `~/.klaatai/tool-results/` and gives the model a preview + file path. Model can `read_file` slices on demand. Cheaper than resending or regenerating.

### Post-Edit Diagnostics Loop
Auto-runs linter/typecheck after every edit, feeds errors back to the model in the same turn. Currently covers JS/TS (eslint/biome), Python (ruff), Go (gofmt). Issues open for Ruby (rubocop) and shell (shellcheck).

### Sub-Agents via delegate_task
Three personas: "explore" (read-only, parallel), "review", "build". Background mode returns task ID immediately for non-blocking side-work. Clean separation: sub-agent's final report enters main conversation, intermediate steps stay isolated.

### Prompt Cache Optimization
System prompt layered into 3 stable segments:
1. CORE_SYSTEM_PROMPT — static identity + tool policy (never changes)
2. Environment block — cwd, platform, git state (once per session)
3. Project rules — .klaatai/rules.md / AGENTS.md

Static prefix stays byte-stable across turns for server-side prompt caching hits.

## Benchmark Methodology

30 fixtures across 5 categories (11 bugfix, 13 implement, 3 multi-file, 1 refactor, 2 long-context). Self-contained: each has failing tests the agent must fix without editing test files.

**Selfcheck gate:** Every fixture must fail as shipped AND pass with reference solution. CI-safe, no tokens needed.

**Reproducible:** `bun run bench` runs the headless agent loop (real tool execution, sandboxed workspace). Same prompts across agents for fair comparison.

Claimed results: 30/30 solved, $0.026/task vs Claude Code's $0.146/task (18% cost).

## Competitive Analysis

| vs | Advantage | Disadvantage |
|---|---|---|
| [[coding-agent-ecosystem\|Claude Code]] | 5.5x cheaper (routing), code graph | Routing is black box, requires KlaatAI account |
| [[projects/whale-deepseek-agent\|Whale]] | Multi-model vs DeepSeek-only | Whale's prefix-cache optimization deeper for its target |
| opencode | Cost routing, sub-agents | opencode is fully open, KlaatCode depends on hosted service |
| Aider | Code graph, sub-agents | Aider more mature, larger community |

## Signals & Assessment

- 107⭐ in 1 day — strong launch traction
- Company-backed (KlaatAI: web chat + API + CLI products)
- Well-engineered codebase (clean architecture, test coverage, benchmark harness)
- All 10 issues filed by one contributor with polished onboarding templates
- **Risk:** Core value (routing) is a hosted service dependency. If KlaatAI goes down/pivots, the open-source client is a shell

## Relevance to Our Work

1. **Per-request routing** — OpenClaw uses one model per session. Klaatu's per-message tier routing is an interesting cost optimization that could inspire similar approaches (e.g., FlowForge nodes with different model tiers)
2. **Retention-aware compaction** — smarter than uniform truncation. The "latest file read kept full, superseded trimmed" heuristic is directly applicable
3. **Oversized result persistence** — save-to-disk + give model a path is elegant. Better than both truncation and re-reading
4. **Reproducible benchmarks** — the selfcheck pattern (fixture must fail → solution must pass) is a good template for evaluating coding agents

## What I'd Watch For

- Does the 5.5x cost claim hold on real-world projects (not curated fixtures)?
- Community adoption beyond launch spike
- Whether the "thin client" model attracts or repels contributors (can't improve routing, only the terminal layer)

Links: [[coding-agent-ecosystem]], [[smart-routing]], [[context-compaction-strategies]], [[semantic-model-routing]]
