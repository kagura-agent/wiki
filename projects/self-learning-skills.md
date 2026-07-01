---
title: "Self-Learning Skills — Golden Path Harvesting Meta-Skill"
date: 2026-07-01
status: noted
stars: 132
last_verified: 2026-07-01
---

# Self-Learning Skills (Kulaxyz)

A **meta-skill** for AI coding agents that automatically recognizes "golden path" moments in sessions and harvests them into reusable Agent Skills or memory entries. Works with Claude Code, Cursor, Codex, and any AGENTS.md-based agent.

Created 2026-06-28, no code (pure skill/docs), MIT. 132⭐ in 3 days. Installable via `npx skills add` or Claude Code plugin marketplace.

## Core Concept

The key insight: **hard-won procedural knowledge evaporates when a session ends.** Every time an agent debugs a tricky issue, discovers project-specific workflows, or figures out a non-obvious command sequence, that knowledge dies with the context window. Self-learning captures it into a persistent skill/rule/memory entry.

## The Loop

1. **Recognize the moment** — proactively, without user prompting:
   - Task worked after several attempts (the successful path is golden)
   - Project-specific facts discovered (where creds live, deploy commands, gotchas)
   - Operational workflow likely to recur
   - User signals explicitly ("remember this")

2. **Triage** — not everything deserves a skill:
   - Multi-step procedure → **skill** (full SKILL.md)
   - Single fact/one-liner → **memory** (MEMORY.md or lightweight notes)
   - Genuine one-off → **skip**

3. **Harvest** — delegate to a fork agent that inherits conversation context:
   - Fork writes SKILL.md to the correct scope (project vs global)
   - Captures the procedure AND the failures ("what didn't work")
   - Never writes secret values (only pointers to where secrets live)
   - Self-validates against authoring spec

4. **Reuse** — next session auto-loads the skill by description matching

## Comparison with Our Approach

| Aspect | Self-Learning Skills | Kagura (us) |
|---|---|---|
| Trigger | Proactive recognition during work | Nudge (agent_end hook, periodic) |
| Output | SKILL.md files | beliefs-candidates.md → DNA/workflow/wiki |
| Triage | skill vs memory vs skip | gradient → triple verification → carrier selection |
| Scope | Project or global | Behavioral (DNA) or domain (wiki) |
| Failures | Explicit "what didn't work" section | Implicit via gradient violations |
| Harvesting | Fork agent with conversation context | skill_workshop tool |

## Novel Patterns Worth Adopting

1. **Proactive recognition without prompting** — we wait for periodic nudges or explicit reflection. This is more organic: detect the moment during work, not after.

2. **Explicit failure capture** — "What didn't work" as a first-class section. Our beliefs-candidates capture positive learnings but don't systematically record ruled-out approaches. Dead-end avoidance may save more time than golden-path following.

3. **Triage before capture** — clean decision tree prevents skill bloat. Our beliefs-candidates pipeline has triple verification but applies it post-hoc. Triage at recognition time is cheaper.

4. **Fork-based harvesting** — keeps golden path extraction out of main context. We already use subagents for code work; could extend to skill harvesting.

## Limitations

- No code — it's purely a prompt/instruction skill. Effectiveness depends entirely on the agent's ability to follow the instructions.
- No semantic matching for deduplication — relies on `ls` to find existing skills.
- 132⭐ in 3 days is fast but may be hype-driven. No community adoption evidence yet.
- Solo author, no established track record.

Links: [[self-evolution-as-skill]], [[beliefs-candidates]], [[skill-trust-landscape-2026-04]], [[conservative-skill-editing]]
