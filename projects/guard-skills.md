---
title: "guard-skills — Quality Gates for AI-Generated Code"
created: 2026-06-08
updated: 2026-06-08
tags: [agent-ecosystem, code-quality, trust, skills]
repo: amElnagdy/guard-skills
stars: 347
last_verified: 2026-06-08
---

# guard-skills — Quality Gates for AI-Generated Code

## What It Is

A set of **reactive guard skills** for coding agents: second-pass quality gates that catch systematic failure modes of AI-generated code, tests, and docs before they ship. Uses the [skills.sh](https://skills.sh) distribution format (Vercel Labs). Works with Claude Code, Codex, Cursor, OpenCode.

5 guards: `clean-code-guard`, `test-guard`, `docs-guard`, `wp-guard`, `woo-guard`.

## Why It Matters

347⭐ + 45 forks in 2 days (created 2026-06-06). The traction signal says developers **want** post-generation quality gates as a separate concern from the generation itself. This is the separation of "write code" from "verify code" that our trust thesis predicts will become standard.

## Architecture

**Skills-as-instructions pattern**: No server, no API, no executable. Pure markdown instructions (`SKILL.md`) + reference files. The agent reads the skill and applies it as a review pass. This is the lightest possible "tool" — just structured knowledge that changes agent behavior.

Key structural choice: **progressive disclosure via references/**. The SKILL.md is the compact imperative set; `references/` files (ai-failure-modes.md, solid.md, dry-kiss-yagni.md, etc.) are loaded on-demand when the agent needs deeper context. This is good context management — not everything in the prompt at once.

**Guard-pass vs Live mode**: Default is reactive (review after writing). Can also be invoked proactively before a risky edit. This dual-mode design matches how humans use checklists.

## Key Insight: The 14 AI Failure Modes

The `ai-failure-modes.md` reference is the highest-value artifact. It catalogs 14 systematic ways LLMs produce bad code, each with published research citations:

1. Catch-all error swallowing (Karpathy observation)
2. Defensive guards for impossible cases (arXiv 2409.19182)
3. Premature abstraction (Fowler)
4. Comment pollution (HN + arXiv 2402.13013)
5. Code duplication — **8x increase** 2021-2024 (GitClear 2025, 211M LoC study)
6. Hallucinated APIs — **19.6% average rate** (USENIX Security '25, 16 models)
7. Generic naming
8. Long functions — avg 142→267 LoC, complexity 4.2→8.1 (GitClear)
9. Parameter explosion
10. Inconsistency with surrounding code
11. Dead code / half-implementations
12. Hardcoded "success" / mock fixtures in production (Fowler, Claude Code #6984)
13. Plausible-but-wrong code (arXiv 2411.01414)
14. YAGNI / speculative configurability

**Cross-cutting root cause**: 8 of 14 trace to one bias — **the model prefers emitting more code** (more params, more guards, more abstractions). The cure is restraint, not knowledge.

## Test Guard — 9 Universal Rules

The test-guard's 9 rules are equally sharp:
1. Test behavior not implementation
2. Every mock must be justified (only at system boundaries)
3. One scenario per test, data-driven for variants
4. Every test must justify its existence
5. Name tests for the scenario
6. Production regression tests are sacred
7. No tests for framework guarantees
8. State/value objects are real, never mocked
9. (further rules in references)

## Ecosystem Position

- **Complements** coding agents (Claude Code, Codex, Cursor) — adds a verification layer they lack internally
- **Competes with** [[multi-agent-quality-gate]] pattern (multi-panelist scoring) but is simpler — single-pass checklist rather than N-agent jury
- **Related to** our [[self-improving]] beliefs about code quality — several of these 14 failure modes are things we've hit ourselves (error swallowing, premature abstraction, mock abuse)
- **Distribution via** skills.sh (Vercel Labs) — the emerging standard for agent skill packages

## Relevance to Our Direction

1. **Trust thesis validation**: 347⭐ in 2 days = strong demand for "trust but verify" in agent output. The market wants quality gates.
2. **We should consider adopting**: The clean-code-guard and test-guard could directly improve our subagent code output. We already have similar rules scattered in AGENTS.md but not as structured.
3. **Architecture lesson**: The "instructions-only skill" pattern (no server, no executable) is the most portable and lowest-friction guard possible. Worth noting for our own skill design.
4. **The 14 failure modes list** is a research-backed diagnostic checklist we should internalize. Several of them (error swallowing, premature abstraction, dead code) are patterns we've seen in our own subagent output.

## Also Scouted This Cycle

### baoyu-design (JimLiu, 363⭐ in 1 day)
Run Claude Design locally as an agent skill — produce UI mockups, prototypes, wireframes as self-contained HTML without claude.ai/design. Design-to-code agent workflow. Less relevant to our core direction but shows the "extract cloud feature → local skill" pattern gaining traction.

### Microsoft Scout (announced Build 2026-06-02)
Microsoft's first "Autopilot" agent, built on [[OpenClaw]]. Always-on personal agent for Microsoft 365 — scheduling, materials creation, cross-surface (cloud/desktop/web). Private preview via Frontier channel. **Major ecosystem validation** — Microsoft choosing OpenClaw as the agent framework for their flagship autonomous agent product. HN thread (48374079) had significant discussion.

---
*Deep read: 2026-06-08 13:55 CST*
