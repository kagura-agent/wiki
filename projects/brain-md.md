---
title: "brain.md — File-Based Project Memory for Coding Agents"
created: 2026-06-24
status: noted
source: https://github.com/mindmuxai/brain.md
stars: 42
last_verified: 2026-06-24
---

# brain.md (mindmuxai/brain.md)

> "A persistent, file-based memory layer for coding agents — give Claude Code, Codex & others a project brain (durable decisions, requirements, constraints) via a zero-dependency CLI."

## Overview

- **Stars:** 42 (2026-06-18, 6 days old)
- **Language:** JavaScript (Node ESM), zero npm dependencies
- **License:** Apache-2.0
- **Org:** MindMux (company-backed, site: projectbrain.md)
- **Agents:** Claude Code, Codex (via skill installation)
- **Tests:** None
- **Issues:** 0 (no community engagement yet)

## Architecture

brain.md lives **per-repo** as a `brain/` directory with plain Markdown files. All access through a single CLI (`brain.mjs`).

### Core pattern: Compiled Truth + Timeline

Each "page" has two sections:
1. **compiled_truth** — rewritable "current best understanding" (like a cache)
2. **timeline** — append-only evidence chain (log of decisions/reversals/evidence)

The CLI enforces that **every compiled_truth rewrite atomically appends a timeline entry**. This makes "silent overwrites" structurally impossible — correctness by construction, no validator needed.

### Fixed structure

- 6 **root pages** (project-level): background, architecture, flow, mindmap, stack, roadmap
- N **pages** (incremental knowledge): 5 categories (project/concept/decision/person/reference)
- `brain wire --agent X` writes instructions into CLAUDE.md/AGENTS.md (idempotent via markers)

### Write path

```
brain create-page --id <id> --category <cat> --title "..."
echo "new understanding" | brain update-truth --id <id> --summary "why"
brain append-timeline --id <id> --kind evidence --summary "..."
brain update-root <slug>  # stdin body
brain reindex && brain lint-links
```

## Comparison to Our Approach

| Aspect | brain.md | OpenClaw/Kagura |
|--------|----------|-----------------|
| Scope | Per-project | Per-agent (workspace-wide) |
| Storage | `brain/` in repo | `wiki/` + `memory/` + `MEMORY.md` |
| Write path | CLI only (enforced) | Direct file write/edit |
| Validation | By construction | Lint scripts, memex index |
| History tracking | Explicit timeline per page | Git commits + daily memory logs |
| Search | `list-pages` (no semantic) | Semantic + keyword hybrid (memex) |
| Portability | Travels with repo in git | Stays in agent workspace |

## Novel Insights

1. **Compiled Truth + Timeline** — Separating "current understanding" from "evidence chain" explicitly is more rigorous than our approach (where wiki card = current state, history = git). Good for decision tracking. Tradeoff: more ceremony per write.

2. **Correctness by construction** — Making the CLI the only write path eliminates a whole class of bugs (malformed frontmatter, orphaned timeline entries). Our approach ("write freely, lint after") is more flexible but less guaranteed. Neither is clearly superior — flexibility vs correctness tradeoff.

3. **Per-repo memory fills a gap** — brain.md is for *project continuity* (different agents/sessions, same repo). Our system is for *agent continuity* (same agent, different projects). These are complementary — an OpenClaw agent could use brain.md inside each project it works on.

4. **No semantic search is a scaling bottleneck** — With only `list-pages` and `read-page`, brain.md relies on the agent knowing which page to read. Fine for < 50 pages, breaks down for larger knowledge bases.

## Verdict

Well-scoped implementation of per-project agent memory. The "compiled_truth + timeline" atomic pattern is the main architectural insight worth noting. Not a competitor to our system (different scope: project vs agent memory). Too early to track actively (42⭐, 0 issues, no community).

**Company-backed** (MindMux) — watch for lock-in moves (`.mindmux/preferences.json` already hints at a runtime layer on top).

## Applicable Patterns

- [[compiled-truth-plus-timeline]]: Consider adding explicit decision timelines to wiki cards for high-churn topics where "why did this change?" matters.
- [[git-backed-agent-memory]]: Another data point in the file-based-memory design space.

## Links

- [[git-backed-agent-memory]] — prior art in same space (brain Rust variant)
- [[agent-memory-landscape-202603]] — landscape context
- [[agent-context-portability-approaches]] — portability angle
