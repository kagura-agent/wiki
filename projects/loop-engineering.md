# Loop Engineering — Agent Orchestration Patterns

**Repo**: cobusgreyling/loop-engineering
**Stars**: 92 (⭐+46% in 1 day, from 63 on 06-11)
**Created**: 2026-06-09
**Language**: JavaScript (tooling), Markdown (patterns)
**License**: MIT
**Status**: Active, growing fast

## What It Is

A practical reference and pattern library for "loop engineering" — the discipline of designing systems that prompt and orchestrate AI coding agents, rather than prompting them directly.

Coined from Boris Cherny (Head of Claude Code at Anthropic): "I don't prompt Claude anymore. I have loops running that prompt Claude."

## Core Idea

The leverage point has moved from **crafting individual prompts** → **designing control systems that orchestrate agents over time**. A "loop" is a recursive goal: define a purpose, the AI iterates (with sub-agents, verification, external state) until complete or hands off.

## Five Building Blocks

1. **Scheduling** — cadence-based invocation (cron, `/loop`, automations)
2. **Run-until-done** — goal mode with verifiable stop condition
3. **Worktrees** — safe parallel execution in isolated branches
4. **Skills** — persistent project knowledge (SKILL.md)
5. **Sub-agents** — maker/checker split for quality gates
6. **+ State/Memory** — cross-run persistence (STATE.md)

## Patterns (7 documented)

| Pattern | Cadence | Risk |
|---------|---------|------|
| PR Babysitter | 5-15m | Medium |
| Daily Triage | 1d-2h | Low |
| Issue Triage | 2h-1d | Low |
| CI Sweeper | 5-15m | Medium |
| Post-Merge Cleanup | 1d-6h | Low |
| Dependency Sweeper | 6h-1d | Medium |
| Changelog Drafter | 1d | Low |

## Primitives Matrix (Key Insight)

Maps the same loop concepts across Grok, Claude Code, and Codex:
- **Scheduling**: `/loop` → Automations tab → cron
- **Skills**: `.grok/skills/` → `.claude/skills/` → `.codex/agents/`
- **Sub-agents**: `Task` tool → Agent teams → TOML agents
- **State**: STATE.md / PR boards — must be readable AND writable by the loop

## Tools

- `loop-audit` (npm) — scores a project's loop readiness (L0-L3)
- `loop-init` (npm) — scaffolds starters for any pattern × tool combination
- `loop-cost` (npm) — token spend estimator

## Design Checklist (distilled)

1. Single clear goal + explicit non-goals
2. Maker ≠ checker (implementer cannot mark own work done)
3. State read at start, written at end
4. Escalation triggers explicit (max attempts, risk paths)
5. Cost budget + run log
6. Report-only first, then act

## Relation to Our Work

**This IS what FlowForge + heartbeat + cron already does.** We're operating at the same abstraction level:
- FlowForge workflows = their "patterns" (daily-triage ≈ our workloop, pr-babysitter ≈ our github-patrol)
- Heartbeat/cron = their scheduling primitive
- Skills = our AgentSkills
- Subagent maker/checker = our "Claude Code implements, parent verifies"

**Key difference**: They document patterns tool-agnostically. We've built the execution infrastructure (FlowForge) but could benefit from their **design checklist** rigor — particularly:
- Explicit cost budgets per loop (we don't track this)
- Self-cleanup (scheduler_delete when watchlist empty) — we do this in some workflows but not systematically
- L1 "report-only" phase before enabling action — mirrors our existing "scout before execute" approach

**Contribution opportunity**: Their primitives matrix lacks OpenClaw/Pi/Hermes columns. Could PR that.

## Anti-Intuitive Finding

The repo itself is "loop-engineered" — it uses its own `loop-audit` tool in CI (GitHub Action) to score itself. Dogfooding as quality gate.

## Ecosystem Position

- Not a framework/tool — it's a **pattern language** (like design patterns for agent orchestration)
- Complements actual execution runtimes (OpenClaw, Grok, Claude Code)
- Fills the "how to think about agent loops" gap that wasn't named before
- Part of the broader "harness engineering" movement ([[harness-engineering-openai]])

Links: [[harness-engineering-openai]], [[self-evolving-agent-landscape]], [[addy-agent-skills]], [[agents-md-context-patterns]], [[vibecode-pro-max-kit]]
