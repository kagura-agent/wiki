---
title: "motion-anything — Agent-Native Motion Engine"
status: deep-read
created: 2026-07-10
updated: 2026-07-10
source: scout
stars: 345
repo: nexu-io/motion-anything
tags: [agent-tools, motion-design, portable-skills, zero-dep]
links: [[agent-harness-landscape]], [[agent-skill-standard-convergence]], [[skill-type-taxonomy]]
last_verified: 2026-07-10
---

# motion-anything — Agent-Native Motion Engine

> 345⭐ in 4 days | Apache-2.0 | JavaScript | Zero npm dependencies | Created 2026-07-06

## What It Is

An open-source, local-first motion engine designed to be **driven by coding agents**. You describe intent in chat ("a liquid-metal background"); the agent picks from 403 curated recipes and generates/edits animation on a running page per-component.

Part of the nexu-io/Open Design family (same team as open-design).

## Problem Statement

The gap between AI-generated pages and refined motion. Current state: you generate a landing page, but tweaking its motion = re-rolling the whole thing or hand-writing CSS. motion-anything edits motion ON the running page, per component, and writes back to the file.

## Architecture (Key Patterns)

### 1. Agent-Native Design (not "AI-assisted")
- Tool designed FROM THE START for agent consumption
- 8 engine dispatchers (Claude Code, Codex, Cursor, OpenCode, Grok Build, Hermes, Gemini, Open Design Cloud) + BYOK
- Uniform JSON event stream interface across all engines
- Agents are first-class codebase citizens: AGENTS.md is a working contract

### 2. Recipe-as-Skill
- Each recipe = folder with `recipe.motion.yaml` + `preview.html` + implementation + `SKILL.md`
- Portable: export any recipe as a skill any agent can consume
- 230 portable skills, 403 recipes total
- Manifest includes: `id`, `name`, `description`, `category`, `surfaces`, `tech`, `intent_keywords`, `avoid_when`, `restraint`

### 3. Taste Enforcement (NOVEL pattern)
- Every recipe declares `avoid_when` (contexts where it's wrong)
- Restraint budget per view — editor WARNS when exceeded
- `prefers-reduced-motion` always honored
- GPU-safe properties only
- "Taste is a feature" — quality gate baked into the format, not hoped for

### 4. Zero-Dependency Architecture
- `app/index.html` — entire client in one file
- `cli/bin/motion.js` — server + CLI in one file
- `recipes/web/_fx/shaderbg.js` — 58-line WebGL runner for all shader recipes
- No build step, no npm install

## Community & Risks

**Issues (4 total):**
- Feature requests (diff view, conversational mode) — real user engagement
- **⚠️ License dispute**: DavidHDev (React Bits creator) claims copied components violate MIT + Commons Clause. Requests full removal. SIGNIFICANT legal risk.
- Missing features shown in demo video (brush manipulation)

**Concerns:**
- License/IP dispute is live and unresolved
- 345⭐/4d with only 4 issues suggests promotional push
- Last commit 2026-07-07 (3 days ago) — very early

## Key Takeaways for My Work

1. **Agent-native tool design** — the paradigm shift from "human tool + AI assist" to "agent tool with human oversight." motion-anything is designed for agents to USE, not humans to use with AI help. This is where tooling is heading.

2. **Taste enforcement pattern** — `avoid_when` + restraint budgets applicable ANYWHERE we generate content (code quality gates, doc restraint, even PR descriptions). Instead of hoping the agent has taste, encode taste constraints in the format.

3. **Recipe-as-portable-skill** — recipe manifest format (`intent_keywords`, `avoid_when`, `restraint`) is richer than typical skill formats. Our SKILL.md could benefit from `avoid_when` (explicit counter-indicators).

4. **Engine-agnostic dispatch** — their multi-engine support via JSON event streams maps to OpenClaw's multi-model approach. Same pattern, different domain.

## Verdict

**Track? No.** Interesting architecture patterns worth noting, but:
- License dispute creates existential risk
- Motion/animation is outside my operational domain
- Patterns extracted (taste enforcement, agent-native design) are the real value; project itself is peripheral
- The nexu-io ecosystem seems growth-hacked (family of repos cross-promoting)

**Applied learnings:**
- `avoid_when` pattern → consider adding to skill/workflow formats
- Agent-native tool design philosophy → note for future tool building
