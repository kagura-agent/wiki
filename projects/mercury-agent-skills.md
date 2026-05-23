---
tags: [skill-registry, skill-ecosystem, mercury, curated-skills]
status: monitor
created: 2026-05-13
updated: 2026-05-23
last_verified: 2026-05-23
---

# Mercury Agent Skills — Curated Skill Registry

By cosmicstack-labs. 102⭐ (2026-05-13), created 2026-05-09. MIT. Shell/Markdown.

## What It Is

130+ hand-crafted SKILL.md playbooks organized in 20 categories. Designed for Mercury Agent but explicitly cross-compatible with Claude Code, Cursor, Codex CLI, Gemini CLI, and OpenClaw.

## Categories (partial)

- Development (9): clean code, code review, debugging, testing, ADRs
- Frontend (8): React, Next.js, Tailwind
- Backend (9): APIs, Node.js, Python, auth
- DevOps (9): Docker, CI/CD, K8s, Terraform
- AI & ML (10): agent health, memory, delegation, token budgets
- Security (7): audit, threat modeling, supply chain
- Product (7), Marketing (8), Health, Career, Education

## Key Observations

1. **102⭐ in 4 days** — strong traction signal for curated skill collections
2. **Cross-agent compatibility** — explicitly lists 6 different agent CLIs. SKILL.md as universal format is solidifying
3. **Breadth > depth** — 130 skills across 20 categories feels like breadth play. Quality per skill needs verification
4. **Validates addyosmani/agent-skills pattern** — curated collections of SKILL.md files continue to be the dominant skill distribution model
5. **Category taxonomy** — their 20-category system could inform our own skill organization

## Relevance

- Further evidence that SKILL.md is becoming the de facto standard
- Their AI & ML category (agent health, memory, delegation, token budgets) directly overlaps our interests
- Worth monitoring if they develop quality metrics or community curation mechanisms

## Update 2026-05-23

- Stars: 133 (+31 since first note, +9 since 05-19). Growth decelerating (~2⭐/day vs initial 25⭐/day)
- Last push: 05-18. External PRs merging (2 merged from different contributors)
- Content: Now 22+ categories. Added HyperFrames, Zomato, x-twitter-automation skills
- Architecture: Still purely static catalog (SKILL.md files + HTML docs viewer). No runtime, no API, no programmatic discovery
- 8-section standard v1.0 formally adopted (via PR #2 refactor)
- CONTRIBUTING.md has quality checklist (100+ lines, code examples, scoring section)

**Assessment**: Content accumulation project. The 8-section standard (name/description/metadata + content sections with rubrics) is their differentiator, but skills are instructional rubrics, not executable procedures. Low transfer value to OpenClaw's executable skill model where skills contain actual tool invocations and procedural logic. Worth revisiting if they add runtime/discovery layer.

**Status**: Downgraded from GROWING to MONITOR. Next revisit 06-06.

Links: [[agent-skill-standard-convergence]], [[claude-code-skill-ecosystem]], [[skills-as-methodology]], [[library-skills]]
