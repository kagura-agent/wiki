---
title: "AgentSmith — Universal Agent Operating Harness"
slug: agentsmith
created: 2026-07-18
updated: 2026-07-18
status: active
tags: [agent-harness, coding-agent, claude-code, discipline, self-improving]
links: [[coding-agent-ecosystem]], [[model-native-vs-model-agnostic]], [[self-evolving-agent-landscape]]
last_verified: 2026-07-18
---

# AgentSmith — Universal Agent Operating Harness

**Repo:** PromptPartner/agentsmith | **Stars:** 100 (2d old) | **License:** MIT
**Author:** PromptPartner (solo dev, 6 months of real production use behind it)

## What It Is

A portable, battle-tested "operating system" for AI coding agents (Claude Code primarily, but model-agnostic via CLAUDE.md/AGENTS.md/GEMINI.md assembly). Not a runtime — it's a **harness template**: core rules + swappable work-type profiles assembled into a single instruction file via `setup.sh`.

## Core Architecture

**Static/Dynamic context split** (first-class design decision):
- **Static** = assembled `CLAUDE.md` = `core/` (universal rules, ~6 files) + chosen `profile(s)` — lean, paid every turn
- **Dynamic** = skills, templates, docs, memory — loaded on demand

**Core modules (6 files, ~60-70 lines each):**
1. `00-identity` — operator identity template, explain-WHY-before-HOW
2. `10-operating-model` — plan→do→verify→finalize→handoff, conductor vs orchestrator modes, when-to-pause rules (only 3 cases: missing credential, external surprise, first write to external system)
3. `20-principle-rules` — 10 rigid rules, each from real failures. Chesterton's Fence, prove-it (failing test first), verify whole chain, atomic commits, finish-including-docs, never delete research, keep surface small
4. `30-anti-rationalization` — STOP table mapping rationalizing thoughts to the rule being skipped. **This is the novel insight.** "I'll verify later" → Rule 5. "Too small to check" → Rule 5. Etc.
5. `40-subagents-and-tools` — routing rules (self-contained → subagent, cross-concern → main), tool discipline, failure recovery (stop after 2 identical failures)
6. `50-git-and-handoff` — handoff protocol: safe-state → write memory → emit kickoff block
7. `60-evolving-the-harness` — meta-rule: fix the system not the symptom, feedback loop

**9 Profiles:** software-dev, devops-setup, marketing-outreach, document-creation, data-crunching, deep-research, creative-design, general-admin, autonomous-loops

**Skills (7 bundled):** verify, handoff, harness-doctor, harness-help, new-research, new-feedback, example-skill

## Key Insights

### 1. Anti-Rationalization Table (STOP table)
The most original contribution. Maps the internal thought patterns that precede rule violations to the specific rule being rationalized away. This is **addressing the metacognitive layer** — not just "what to do" but "what you'll think right before not doing it." Directly applicable to our DNA.

### 2. "Agent = Model + Harness" (10%/90%)
Credits Google's New SDLC whitepaper (Osmani/Saboo/Kartakis, May 2026). The harness IS the agent. Most agent failures are configuration failures. We already believe this but they articulate it more crisply.

### 3. Static vs Dynamic Context as Architecture
Explicit about what goes in always-loaded rules vs on-demand. "Every line in static context makes the agent worse at everything else." We do this implicitly but they've made it a first-class principle.

### 4. Rigor Spectrum (not binary)
Match discipline to stakes — throwaway experiments can be vibe-coded, production needs full verification. The profile sets the floor, you raise with stakes. Good framing.

### 5. Three-Case Pause Rule
Agent only pauses for: (1) missing credentials, (2) external service surprise, (3) first write to external system. Everything else: decide and go. Very tight autonomy boundary.

### 6. Conductor vs Orchestrator Modes
Explicit naming of what we do implicitly — hands-on debugging vs delegated parallel work. "Neither is more advanced — choose by task."

## Relationship to Our Setup

**Heavy overlap with OpenClaw DNA (AGENTS.md + SOUL.md):**
- Their "prove it" = our "验证优先"
- Their "fix the system" = our "beliefs-candidates → DNA升级"
- Their handoff protocol ≈ our memory/YYYY-MM-DD.md system
- Their "keep surface small" = our implicit lean-rules principle

**What they have that we don't (worth considering):**
- **Formalized STOP table** — we have beliefs-candidates but no explicit "thought → rule" mapping
- **verify.sh runner** — deterministic verification script per project. We rely on ad-hoc checking
- **Profile system** — work-type-specific quality gates. We use one DNA for everything

**What we have that they don't:**
- **Runtime** — they're a static template; we have OpenClaw (cron, heartbeat, multi-session, tools)
- **Memory system** — daily notes + MEMORY.md + wiki. They have handoff notes only
- **Self-evolution pipeline** — beliefs-candidates → DNA promotion with frequency tracking
- **Study/learning loop** — systematic knowledge acquisition. They only learn from incidents

## Tradeoffs

- **Pros:** Very well-written, battle-tested (6 months), MIT licensed, model-agnostic, lean design
- **Cons:** Claude Code-centric assembly (CLAUDE.md), no runtime/memory beyond handoff, solo dev (fragility risk), no community yet (1 issue)

## Verdict

High-quality reference implementation of agent discipline. The STOP table and static/dynamic context split are the two most directly applicable ideas. Not a competitor to OpenClaw (no runtime), but a strong complement — their rules could inform our DNA, and our runtime could host their discipline.

**Action:** Consider adapting the STOP table pattern into beliefs-candidates.md or AGENTS.md anti-patterns section.
