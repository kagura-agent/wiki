---
title: "ai-rules-sync (agentsync)"
created: 2026-06-08
updated: 2026-06-08
tags: [agent-config, developer-tools, coding-agent, sync]
last_verified: 2026-06-08
---

# ai-rules-sync — Agent Rules Sync Tool

**Repo**: PanisHandsome/ai-rules-sync | **Stars**: 116 (7 days old) | **License**: MIT | **Lang**: JavaScript
**Created**: 2026-06-01 | **npm**: @panishandsome/agentsync | **Deep-read**: 2026-06-08

One source of truth for AI coding-agent instruction files. Converts/syncs between AGENTS.md, CLAUDE.md, .cursorrules, copilot-instructions.md, .windsurfrules, .clinerules, CONVENTIONS.md, GEMINI.md, QWEN.md.

## Problem Statement

Every coding agent reads its rules from a different file: Codex → AGENTS.md, Claude Code → CLAUDE.md, Cursor → .cursorrules, etc. Teams using multiple agents maintain duplicate files that drift. agentsync eliminates the drift.

## Architecture

Zero-dependency, pure ESM. Same core engine runs in Node and browser (playground).

### Core Pattern: IR-based conversion
```
Source format → parse → IR (intermediate representation) → render → Target format
```

IR shape:
```js
{ title, intro, sections: [{heading, body}], globs, sourceFormat, warnings }
```

Adding a new tool = one parser + one renderer. Clean extension model.

### Key Components

1. **`src/core/agentsync.js`** — Universal engine (convert, merge, generate, detectFormat). Works in browser too.
2. **`src/node/scan.js`** — Repo scanner. Reads package.json/pyproject.toml/go.mod, detects language/framework/pm, generates spec for AGENTS.md generation.
3. **`src/node/lint.js`** — Validates AGENTS.md against reality: checks referenced paths exist, flags missing commands, catches placeholders/TODOs.
4. **`src/node/sync.js`** — Watches for changes, regenerates targets from source. `--auto` mode detects which file was edited and uses it as truth.

### Sync Modes
- **Source-of-truth** (`agentsync sync`): AGENTS.md → all others. Edit only AGENTS.md.
- **Auto** (`agentsync sync --auto`): Edit any file, tool detects which changed (via `.agentsync-state.json` snapshot), regenerates others from it. Conflict = asks user.
- **Pre-commit hook**: Ensures committed files always in sync.

### Linter (interesting)
The `lint.js` catches "AGENTS.md rot":
- Referenced paths that don't exist on disk
- Missing build/test commands (agents guess → bad)
- `@path` imports that point nowhere
- TODO/FIXME/placeholder text

This is a real problem — instruction files go stale faster than code.

## Test Coverage
Simple but sufficient: format detection, round-trip conversion, scan fixtures (Node+TS+Next, Python+uv+FastAPI), title handling, linting.

## What's Interesting

1. **Convergence signal**: The proliferation of rule-file formats is now officially a tooling problem. Someone built a tool to solve it. This confirms AGENTS.md as the emergent "standard" (it's the default source format).

2. **Lint-as-guardrail**: The idea of linting agent instruction files (checking referenced paths, command freshness) is novel and practical. Agent rules rot is real — instructions written months ago reference deleted directories.

3. **Browser playground**: Same engine in CLI and web app. Smart for adoption — people try it in browser, then install CLI.

4. **Format detection by content heuristic**: When filename isn't enough, it sniffs body content. Handles real-world messiness.

## Limitations

- No issues yet (too new)
- No semantic understanding — it's structural conversion (headings + body), not meaning-aware. Two differently-structured files saying the same thing won't merge intelligently.
- `--auto` conflict resolution is manual (asks user). No three-way merge.
- Scope is narrow (text sync), not a config management system.

## Relevance to Us

### Direct applicability: LOW
We don't maintain multiple rule files — we have AGENTS.md as our single DNA file, read by OpenClaw directly. No .cursorrules or CLAUDE.md to keep in sync.

### Pattern insights: MEDIUM
1. **Lint concept**: We could lint our own AGENTS.md — check referenced paths (tools/*, wiki/*) still exist. Low-hanging fruit.
2. **Format as standard**: AGENTS.md is winning as the canonical agent instruction format. Our AGENTS.md is already in this format (accidentally standard).
3. **Rot detection**: The linter's philosophy ("instructions drift from reality") applies to our wiki/projects/ notes too. Stale `last_verified` dates are the same problem.

### Ecosystem position
This is a **developer experience** tool, not infrastructure. It sits in the "developer workflow" layer alongside linters, formatters, and pre-commit hooks. Modest stars (116 in 7 days) — useful but not explosive growth.

## Verdict

Neat utility, confirms AGENTS.md as emerging standard, lint concept worth noting. Not a tracking candidate (too narrow, won't teach us anything new over time). File-and-forget.
