---
title: "Ponytail — YAGNI Lazy Senior Dev Skill"
created: 2026-06-13
updated: 2026-06-13
tags: [agent-skill, code-quality, YAGNI, prompt-engineering]
last_verified: 2026-06-13
---

# Ponytail (DietrichGebert/ponytail)

> 965⭐ in <36 hours (2026-06-12). MIT. JavaScript. "Makes your AI agent think like the laziest senior dev in the room."

## What It Does

A multi-agent-portable skill that enforces YAGNI/minimalism in code generation. Core mechanism is a **6-rung ladder** — the agent stops at the first rung that holds:

1. Does this need to exist? (YAGNI → skip)
2. Stdlib does it? → use it
3. Native platform feature? → use it
4. Already-installed dep? → use it
5. Can it be one line? → one line
6. Only then: minimum code that works

## Why It's Interesting

### Benchmark rigor
Proper A/B testing with promptfoo (10 runs/cell, median reported) across Haiku/Sonnet/Opus, compared against "caveman" (prose compression skill) and baseline. Results: **80-94% less code, 47-77% less cost, 3-6× faster**. This is one of the few agent skills with real quantitative validation.

### Agent portability as first-class concern
Adapters for 8+ agent hosts: Claude Code (full plugin with hooks), Codex, OpenCode (server plugin via `experimental.chat.system.transform`), Cursor, Windsurf, Cline, GitHub Copilot, Kiro. The `docs/agent-portability.md` documents a deliberate design: keep adapters thin, point at shared `skills/` and `hooks/` files.

### `ponytail:` comments as upgrade paths
Intentional simplifications are marked with comments naming the ceiling and upgrade path. This is smart — it acknowledges that YAGNI means "not yet", not "never".

### Mode system (lite/full/ultra)
Intensity levels that persist across session. The mode tracker hooks into agent lifecycle events.

## Architecture Notes

- **Plugin structure**: `.claude-plugin/` + `hooks/` for Claude Code lifecycle hooks (session start, prompt tracking)
- **OpenCode integration**: Server plugin via `.opencode/plugins/ponytail.mjs` that injects rules via `experimental.chat.system.transform` each turn
- **Tests**: `tests/hooks.test.js` — tests the hook activation, mode switching, and state persistence. Assert-based, no framework.

## Issues / Weaknesses

- Hook registration bug: `${PLUGIN_ROOT}` expansion issue in Claude Code causes non-blocking errors on session start (#3)
- "Brownfield" question raised but not fully addressed — how does YAGNI interact with existing complex codebases?
- 0 external PRs yet (too new)

## Ecosystem Position

Competes with [[guard-skills]] (quality gates) but from the opposite direction — guard-skills adds checks, ponytail removes code. Complementary to [[caveman]] (prose compression) which it benchmarks against. The viral growth (965⭐ in 36h) suggests strong demand for "less code" tooling — developers frustrated with agent bloat.

## Relevance to Us

- **Direct applicability**: We could adopt the YAGNI ladder as a principle for our own Claude Code prompts. The "stop at first rung" heuristic is mechanically enforceable.
- **Benchmark methodology**: promptfoo-based skill evaluation is a pattern worth considering for our own skill quality gates.
- **Agent portability design**: Their multi-host adapter pattern is relevant if we ever package skills for broader distribution via [[ClawHub]].
- **ponytail: comment convention**: The "mark simplifications with upgrade paths" pattern is useful for our own code.

Previous: [[guard-skills]] (different approach — additive quality vs subtractive minimalism)

---
*Deep read: 2026-06-13 11:25 CST*
