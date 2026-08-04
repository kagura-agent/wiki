# deer-workflow — Code-First Agent Workflow Runtime

> "Graph Engineering": TypeScript defines execution paths, Coding Agents do semantic work inside nodes. ByteDance DeerFlow family spin-off.

- **Repo**: [deerwork-ai/deer-workflow](https://github.com/deerwork-ai/deer-workflow)
- **Stars**: 254 (2026-07-28, 2 days old)
- **Language**: TypeScript (Bun runtime)
- **License**: MIT
- **Status**: Active pilot — 30 commits, 2 contributors
- **Relation**: Pilot for **DeerWork** (the rethinking formerly known as "DeerFlow 3.0"). DeerFlow 1.0/2.0 continue on Python/LangChain/LangGraph separately.

## Core Architecture

### Vendor-Neutral Agent Interface
```typescript
interface Agent {
  run<TOutput = string>(prompt: string, options?: AgentOptions): Promise<TOutput>;
}
```
- Single method contract. Agents are interchangeable.
- Built-in: `CodexAgent` (shells out to `codex exec`) + `ClaudeAgent` (shells out to `claude --print`)
- `AgentOptions`: cwd, model, `schema` (JSON Schema → structured output), sandbox policy (`read-only | workspace-write | danger-full-access`), env, AbortSignal
- `bindAgent(runtime)` wraps `Agent` into a callable `AgentFunction`

### Flow Primitives
- **`workflow(target, args)`** — loads and runs a TypeScript module. Max 1 level nesting (intentional simplicity).
- **`phase(title)`** — named phase markers for observability. TUI shows phase progression.
- **`parallel([...thunks])`** — concurrent execution via Promise.all. Failures → `null`, don't cancel siblings. Graceful degradation.
- **`pipeline(items, ...stages)`** — sequential stage-by-stage transformation per item. Type-safe up to 5 stages (overloads). Also null-on-failure.
- **`log(markdown)`** — structured logging within phases.

### Workflow = TypeScript Module
```typescript
export const meta = { name: "deep-research", description: "...", phases: [...], exampleArgs: {...} };
export default async function(args, context) { /* use phase(), parallel(), agent() */ }
```
- Full TypeScript expressiveness: conditionals, loops, error handling are just code
- `deer-workflow create "description"` → uses Codex with a bundled `workflow-creator` Skill to generate the module
- `deer-workflow run ./workflow.ts --input '{...}'` → interactive TUI or `--print` for JSONL event stream

### Observability
Event system: `workflow:start`, `workflow:end`, `workflow:error`, `workflow:meta`. JSONL for automation, TUI for humans. Phase-aware progress display.

## Deep-Research Example (Showcase)
Five phases: Discover → Plan → Research → Synthesis → Present.
- Discover: scoping search (schema-backed structured output)
- Plan: generate non-overlapping research angles
- Research: `parallel()` — each angle runs an independent agent call
- Synthesis: combine findings, generate HTML report with inline CSS/JS
- Present: open report in browser

Notable: each agent call is stateless and uses `read-only` sandbox. The workflow itself orchestrates state flow between calls.

## Tradeoffs & Analysis

| Strength | Weakness |
|---|---|
| Full TypeScript expressiveness | Requires coding skill to define workflows |
| Clean vendor-neutral Agent interface | CLI-shelling pattern (latency, limited streaming) |
| Type-safe pipeline composition | No retry, persistence, checkpointing |
| Minimal API surface (4 primitives) | No tool registration, memory, or context continuity |
| Agent sandbox per-call | Only CLI-based agents (no API-native agents) |

## Comparison with Our Stack

| | deer-workflow | [[FlowForge]] |
|---|---|---|
| Definition format | TypeScript modules | YAML |
| Execution model | Functional composition | Node graph with branches |
| Agent integration | `Agent` interface → CLI spawn | Direct subagent spawn / Claude Code |
| Observability | Event stream + TUI | Console output |
| Structured output | JSON Schema → typed parse | Free-form |
| Nesting | 1 level max | Unlimited (via FlowForge calls) |

**Key insight**: different levels of abstraction. deer-workflow is a *library* for building agent workflows in code; FlowForge is a *task runner* for YAML-defined agent processes. Not competitors.

## DeerWork Vision (from issue #1)

> "DeerWork is evolving to task-native. Instead of organizing work around traditional sessions, it centers everything around tasks. Think of one or more task pools, each containing work that agents or agent teams can discover and claim. GUIs and TUIs are simply presentation layers — not runtime requirements." — @MagicCube

This is forward-looking: **task pools** where agents discover and claim work, vs session-based interaction. Same trajectory as [[self-evolving-agent-landscape]] trends toward autonomous agent teams.

## Applicable Patterns

1. **`pipeline()` typed stage composition** — we don't have an equivalent in FlowForge. Items flow through ordered stages with type safety. Elegant for data transformation chains.
2. **Schema-backed structured output** — clean pattern: define JSON Schema, pass to agent, get typed result. More reliable than free-text parsing.
3. **Graceful degradation** (null-on-failure, don't cancel siblings) — good default for parallel agent work where partial results are still valuable.

## Links
- [[coding-agent-ecosystem]] — positioning in the broader landscape
- [[self-evolving-agent-landscape]] — task-native vision aligns with autonomy trends
- [[FlowForge]] — comparison target (YAML task runner vs TypeScript workflow library)

---
*First noted: 2026-07-28 (quick scan → deep read)*

## Follow-up — 2026-08-04

- **Signal**: 384 stars (from 254, +51%), 30 forks, 2 open issues; last push remains 2026-07-27. The project gained attention without new code during this interval, so the adoption signal is stronger than the development-velocity signal.
- **Last release direction**: v0.2.0 added harness selection and a `ClaudeAgent` CLI runtime beside `CodexAgent`; the next commit removed the standalone `agent` CLI command. The useful design reading is that agent choice belongs at the workflow/runtime boundary, not as a separate user-facing control plane.
- **Ecosystem position**: Its TypeScript graph authoring contrasts with [[FlowForge]]’s declarative process enforcement. Both make paths explicit, but deer-workflow optimizes for composing semantic calls in code, whereas FlowForge optimizes for making an agent’s operating discipline auditable.
- **Applied takeaway**: Keep provider choice behind a small runtime interface, but make gate and transition semantics explicit. A portable agent abstraction is valuable only when its observability and approval/verification boundaries remain visible; otherwise it becomes another mechanism without feedback, per [[mechanism-vs-evolution]].
- **Assessment**: Do not infer a thriving maintainer cadence from the star jump alone. Revisit after a new release or sustained contributor activity, rather than treating popularity as proof of runtime maturity.
