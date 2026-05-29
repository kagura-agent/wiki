# ADHD — Parallel Divergent Ideation Skill

**Repo**: [UditAkhourii/adhd](https://github.com/UditAkhourii/adhd) | 473⭐ (2026-05-29, created 05-25) | TypeScript | MIT
**Status**: 4-day viral growth (473⭐, 23 forks). Built on Claude Agent SDK. Ships as skill, npm lib, and CLI.

## Core Idea

Treats premature convergence in CoT as an **architectural problem**, not a prompting one. Spawns N isolated reasoning processes under deliberately distorted "cognitive frames" with zero shared context during divergence, then runs a separate critic to score, cluster, prune, and deepen survivors.

**Key insight**: Linear CoT anchors on first-generated tokens. Tree-of-Thought still shares context across branches so anchoring persists. ADHD eliminates cross-branch contamination by complete isolation during divergence.

## Mechanism

1. **Fan out**: N parallel thoughts under different cognitive frames (deliberate distortion)
2. **Critic off** during divergence phase — no evaluation until all branches complete
3. **Score + cluster**: group similar ideas, identify traps
4. **Prune traps**: eliminate converged/trapped branches
5. **Deepen survivors**: invest compute in promising directions

## Ecosystem Signal

- **Distribution**: `npx skills add UditAkhourii/adhd` — works across ~50 agent IDEs via the `skills` CLI
- The `skills` CLI (Vercel Labs) is becoming a de facto skill distribution channel
- Auto-triggers on intents: brainstorm, ideate, design, naming, refactor, "give me a few ways to..."
- Not a standalone agent but a **reasoning augmentation** for existing agents

## Connection to Our Work

- Not directly relevant to [[self-evolving-agent-landscape]] — this is runtime reasoning, not self-evolution
- The [[agent-skill-standard-convergence]] signal: `npx skills add` as distribution mechanism shows the skill ecosystem is maturing toward one-line install
- The cognitive-frames-as-distortion approach is interesting for creative tasks but not for the systematic workflows we do

## Why It Went Viral

- Catchy name + clear problem framing ("architectural fix for premature convergence")
- One-command install across all major agent IDEs
- Preprint gives academic credibility
- Fills a real gap: brainstorming/creative work in coding agents

## Updates

- **05-29**: 473⭐ (+25% in 1d). repowire is first external adopter (PR #313). Oblique Strategies fork PR (211-card Brian Eno frame deck as divergence source) — closed but creative reuse pattern. README restructured, deep content moved to documentation/.

---
*First read: 2026-05-28 | Updated: 2026-05-29*
