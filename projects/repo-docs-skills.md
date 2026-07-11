---
status: skim
created: 2026-06-27
updated: 2026-06-27
stars: 62
author: YurunChen
lang: Python (validator) + Markdown (skill)
last_verified: 2026-07-11
---

# repo-docs-skills — Living Documentation Skill for Coding Agents

> A skill that teaches coding agents to maintain living project documentation as a side-effect of normal coding conversations. Not a CLI tool — a prompt engineering framework.

## Core Insight

**Per-turn understanding sync**: Instead of generating docs as a separate pass, the agent checks each turn whether its code changes broke the reader's mental model. If so, it patches the smallest owning page inline. Docs evolve alongside code, not after.

## Architecture

**3-layer knowledge separation** (formalized version of what we do intuitively):

| Layer | Audience | Shape |
|-------|----------|-------|
| Agent memory | Agent across sessions | Thin, pointer-oriented, recent lessons |
| Root agent files (AGENTS.md) | Future agents in this repo | Rules, commands, red lines, routing |
| `repo-docs/` | Humans + agents | Thick authority: walkthroughs, concepts, references |

**Promotion rule**: Memory items that recur get promoted to docs. Similar to our [[beliefs-candidates]] → DNA pipeline.

**Graduated output shapes**: Standard (full) / Lite (small repos) / Seed (new projects). Prevents over-documenting trivial repos.

## Key Design Patterns

1. **Walkthrough-first explanation** — Start with one real behavior traced end-to-end, then branch into concept pages. Anti-pattern: inventory/tree-tour docs that list files without explaining why.

2. **Page ownership** — Each fact has exactly one home (modules/ for concepts, references/ for lookup tables, glossary for terms). Single source of truth, no duplication.

3. **Evidence labels** — Confirmed/Inferred/Planned/Unknown, applied quietly (page-level default + local overrides where confidence changes). Not a form-filling exercise.

4. **Validator (798 lines Python)** — Checks structural integrity, link freshness, template creep detection, source locator verification against repo, low-scent link labels. Deterministic quality gate.

5. **Root agent file contract** — Build mode wires `repo-docs/` into AGENTS.md/CLAUDE.md so future agents maintain docs without being re-taught the policy.

## Relevance to Us

| Our existing practice | repo-docs equivalent | Gap/opportunity |
|----------------------|---------------------|-----------------|
| wiki/projects/ notes | `repo-docs/modules/` | We write analysis summaries; they write behavior traces. Walkthrough-first could improve our project notes |
| MEMORY.md → DNA pipeline | Promotion rule | Already have this; validates our approach |
| AGENTS.md + wiki/ + memory/ | 3-layer separation | We already do this less formally. Good validation |
| No wiki validator | `validate_repo_docs.py` | Could apply: link checking, freshness, structural drift |

## Critique

- **Solo dev, 1 commit, zero community** (no issues, no forks, no contributors). Burst-publish pattern — polished offline, released at once. No signal on real-world effectiveness.
- **High overhead**: The writing rules (WRITING.md) are essentially a full technical writing style guide. Would agents consistently follow all rules? Unclear without testing.
- **No self-tests**: Validator checks output structure, but nothing tests whether the skill actually produces good docs in practice.
- **Token cost**: Per-turn understanding sync adds cognitive load to every coding turn. Cost/benefit unclear for fast iterations.

## What's Novel vs Already Known

- ✅ Novel: The per-turn sync loop as a formalized mechanism (not just "keep docs updated")
- ✅ Novel: Validator detecting template creep (anti-pattern: LLMs producing mechanical repeating structures)
- ❌ Already known: 3-layer separation (we already do it)
- ❌ Already known: Evidence labeling (standard practice)
- ❌ Already known: Walkthrough-first (good practice, well-known in tech writing)

## Tracking Decision

Skim-level tracking. Single-commit solo project, 62⭐. Key patterns already extracted. Check back in 2 weeks to see if community forms or if it's a one-off thought experiment.

### Followup — 2026-07-11
- **Stars**: 343⭐ (+281 since 06-27, +453% growth!). Active development through 07-03.
- **Recent work**: Shape/display rules, evals refinement, background sync delegation, install path alignment.
- **Health**: SOLO 0/6. Only 1 unique merged PR author.
- **Assessment**: VIRAL growth but no community forming. Star count massively exceeded our 200-cap prediction (calibration: WRONG). Content resonating with the zeitgeist. Still solo dev.
- **Recommendation**: Upgrade to following. Growth trajectory demands closer attention despite solo status.
- **Revisit**: 07-18

Links: [[harness-engineering-openai]], [[agents-md-context-patterns]], [[self-evolving-agent-landscape]], [[ace-agentic-context-engineering]]
