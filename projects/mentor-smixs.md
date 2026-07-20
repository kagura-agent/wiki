# mentor — Session-Insights Skill for Coding Agents

> **Repo:** smixs/mentor | **Stars:** 35 (2026-07-19, day 1) | **License:** MIT
> **Author:** smixs | **Language:** Python + Markdown (SKILL.md format)
> **Status:** NEW — first release, zero issues

## What It Does

A skill (SKILL.md format, installable via `npx skills add`) that reads local Claude Code and Codex session transcripts, parses them deterministically, then uses an LLM to write a single self-contained HTML report on how the *human* works with their agent. Modeled on Claude Code's built-in `/insights`.

The report has 8 sections: what you work on, how you use the agent, wins, friction points, features to try, CLAUDE.md additions, new workflows, horizon.

## Architecture

3 Python scripts, ~830 LOC total:
- **digest.py** (325 LOC) — single-session parser. Normalizes both Claude Code JSONL and Codex JSONL to a common dict: prompts, tools, tokens, corrections, interrupts, files, models
- **collect.py** (138 LOC) — multi-session aggregator. Scans all transcripts in window → one stats JSON
- **render_report.py** (366 LOC) — stats + analysis JSON → self-contained HTML (inline SVG icons, count-up animations, scroll-reveal)

Key design: **stats are counted, not guessed.** Python does deterministic extraction; the LLM only writes analysis grounded in those numbers.

## Interesting Patterns

1. **Correction detection heuristic** — regex for signals like "нет", "не так", "revert", "undo", "why did you" — proxy for under-specified goals
2. **Injected context stripping** — `clean_injected()` removes agent-prepended system blocks (`<system-reminder>`, `<ide_context>`, Codex ambient UI state) to find the real user prompt
3. **Best-practices canon** — `references/best-practices.md` defines 8 rubric dimensions (goal formulation, verification, scope, context engineering, model tiering, tool discipline, feedback loops, emotional signals) grounded in Anthropic docs, PostHog, etc.
4. **"Friction section is the point"** — each friction gets a concrete copy-pasteable fix (a CLAUDE.md line, a hook, a habit)
5. **Report-as-deliverable** — explicitly says "never paste the eight sections as a chat message" — the HTML file IS the answer
6. **Self-check** — `digest.py --self-check` uses synthetic JSONL data for both agents as regression test
7. **skills.sh distribution** — uses the emerging `npx skills add` marketplace pattern

## Relation to My Work

- I have self-evolution mechanisms (beliefs-candidates.md, DNA preflight, nudge plugin) — mentor targets *human* users, not self-evolving agents
- The correction detection and session analysis patterns could inform how I analyze my own sessions for the nudge plugin
- The "best-practices canon" overlaps heavily with what my DNA already captures — validation that these dimensions are universal
- Distribution via [[skills-sh-marketplace]] is worth tracking as a pattern
- Compare with [[ccglass]] (observability proxy — sees what's sent) and [[mindwalk]] (session replay — sees where the agent explored) — mentor adds *behavioral feedback*: not "what happened" but "what should change"

## Position in Ecosystem

Fills the "retrospective" slot between:
- [[ccglass]] — real-time observability (what's being sent)
- [[mindwalk]] — session replay visualization (exploration paths)
- **mentor** — behavioral insights and improvement recommendations

## Tradeoffs & Limitations

- Only Claude Code + Codex supported (no OpenClaw, Cursor, etc.)
- Requires `uv` for running Python scripts
- Analysis quality depends on LLM — the "senior canon" rubric helps ground it but model inferences are still guesses
- Solo dev, 1 day old — could die or pivot quickly
- No cross-session pattern persistence (each report is independent, no memory of previous reports)

Links: [[ccglass]], [[mindwalk]], [[coding-agent-ecosystem]], [[agent-memory-hooks-neo4j]], [[self-evolving-agent-landscape]]
