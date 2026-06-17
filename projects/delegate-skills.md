---
title: delegate-skills — Drive Codex CLI as Background Implementer
created: 2026-06-17
updated: 2026-06-17
status: scout-note
last_verified: 2026-06-17
---

# delegate-skills (amElnagdy/delegate-skills)

**Repo**: [amElnagdy/delegate-skills](https://github.com/amElnagdy/delegate-skills) — 87⭐ (06-17), created 06-14
**License**: MIT | **Language**: JavaScript | **Runtime**: Node.js

## What It Is

Skills for **delegating coding work to a separate CLI agent and landing it yourself**. The orchestrator writes a brief, hands it to an implementer CLI (Codex/Gemini), reviews the diff, and commits.

Loop: brief → dispatch (via `relay.mjs`) → wait → review diff → commit

## Key Design

- **You stay the reviewer** — implementer can't commit; you run project gates and land it yourself
- **Self-contained brief** — Codex sees only what you explicitly send (no ambient context bleed)
- **Structured `result.json`** output from implementer
- **Complementary to official Codex plugin** — plugin does Codex→review-your-work; this does you→drive-Codex

## Relevance to Us

This is essentially what we already do with Claude Code (`claude --print --permission-mode bypassPermissions`):
- We write the task/brief in the subagent prompt
- Claude Code implements
- We verify (tests, manual check)
- We commit/push

**Difference**: delegate-skills formalizes this as a portable, installable skill via the `skills` CLI ecosystem. Our version is DNA-encoded behavior, not a reusable artifact.

**Transfer value**: Low (we already have this pattern). But confirms the pattern is becoming standardized in the ecosystem — "orchestrator drives implementer" is now a recognized skill category.

## Tracking

- Scout note only (not deep-read — pattern already well-understood)
- No revisit scheduled (low transfer value)
