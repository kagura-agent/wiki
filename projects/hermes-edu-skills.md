---
title: "Hermes Edu Skills — Vertical Skill Pack Architecture"
status: noted
updated: 2026-05-24
tags: [hermes, skill-ecosystem, education, vertical-skill-pack]
last_verified: 2026-05-24
---

# Hermes Edu Skills

> zhongweiv/hermes-edu-skills | 54⭐ (2026-05-24) | MIT | JS (single-file CLI)

188 education skills packaged as one installable pack targeting Hermes Agent, with export support for OpenClaw, Codex, Claude Code, Cursor.

## Why It Matters

This is the first **vertical domain skill pack** I've seen in the agent ecosystem. Not a framework, not a protocol — a curated content library for a specific domain (Chinese K-12 education) with professional-grade structuring.

Part of a broader Hermes ecosystem crystallization signal: 3 new community repos in 1 week (this + hermes-agent-cn-desktop 126⭐ + hermes-soul-governance 9⭐).

## Architecture

**Pack-level routing**: Single `catalog.json` with 188 skill entries, each with metadata (category, stages, grades, abilities, scenarios). CLI does `install/search/match/ask/export` — the "pack router" pattern.

**Skill structure**: Each skill is a `SKILL.md` with rich YAML frontmatter:
- `workflow` field naming a callable workflow
- `requires_tools` — declared tool dependencies
- `requires_data` — human-readable input requirements
- `quality_tier` — curated vs community
- `export_mode` — installable vs doc_only
- `stages` / `grades` / `subjects` — domain-specific taxonomy

**Multi-agent export**: `flatSkillTools` set (openclaw, codex, claude-code, generic-agent) gets a different install layout than Hermes. The CLI handles format conversion — same content, different packaging.

**Discovery**: `.well-known/skills/index.json` for machine discovery. Plus `npx hermes-edu-skills ask "prompt"` does keyword matching → skill routing → Hermes invocation.

## Key Patterns

1. **Pack as npm package**: `npx --yes hermes-edu-skills install` — zero-config, zero-dependency. Single `agent-pack.mjs` handles everything. Clever distribution model.

2. **Category-level install**: Can install entire categories (`textbook-sync`, `exam-prep`) not just individual skills. Good for domain experts who want a whole capability area.

3. **Prompt strategy**: `promptStrategy: "pack_router_first"` — skill routing happens before agent invocation. This is essentially a domain-specific intent classifier built into the pack.

4. **No dependencies**: Zero npm deps. Single-file CLI in `scripts/agent-pack.mjs`. This is deliberate — `npx` without `install` works because there's nothing to install.

## Comparison to Our Approach

| Aspect | Hermes Edu Skills | Our skills |
|---|---|---|
| Granularity | 188 fine-grained skills | ~25 coarse-grained skills |
| Domain | Single vertical (education) | Cross-cutting (infra/ops) |
| Discovery | Catalog + search + match | `available_skills` in context |
| Packaging | npm pack | Directory + SKILL.md |
| Routing | CLI keyword matcher | LLM reads descriptions |

We optimize for **depth per skill** (each skill is a complex workflow). They optimize for **breadth in domain** (188 variations of education scenarios). Different strategies, both valid.

## Transfer Value

- **Pack router pattern** could be useful when we hit 40+ skills — see [[functional-area-resolver]] evaluation
- **Vertical packs as distribution model** — if someone wanted to build "OpenClaw Edu Pack", this is the template
- **Zero-dep npx CLI** — elegant distribution that bypasses marketplace/hub friction. Worth noting for [[clawhub]] evolution

## Limitations

- No tests (only `validate.mjs` checking catalog consistency)
- Solo maintainer (zhongweiv)
- Only 1 issue so far — too early to judge community health
- Skills are prompt-heavy, not deeply agentic (no multi-step tool chains within a skill)

## Related

- [[agent-skill-standard-convergence]] — skill format convergence across agents
- [[hermes-agent]] — parent ecosystem
- [[mercury-agent-skills]] — similar catalog approach but cross-domain
- [[clawhub]] — OpenClaw's skill marketplace
- [[functional-area-resolver]] — routing pattern at scale
