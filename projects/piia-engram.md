---
title: "piia-engram — AI Identity Layer (Not Memory)"
created: 2026-05-23
status: noted
tags: [identity, cross-tool, mcp-server, local-first, agent-infrastructure]
stars: 71
repo: Patdolitse/piia-engram
last_verified: 2026-05-23
---

# piia-engram — AI Identity Layer

> "Not session memory, not an agent framework, not a hosted database. It stores *who you are*."

**Repo**: [Patdolitse/piia-engram](https://github.com/Patdolitse/piia-engram) | 71⭐ (2026-05-23, created 05-18) | Python | Apache-2.0

Renamed from `engram` to avoid confusion with [[engram]] (Ironact/engram, the memory layer). Different project, different thesis.

## Core Thesis: Identity ≠ Memory

The key distinction piia-engram makes:
- **Memory layers** (Mem0, [[engram]], [[auto-memory]]): store *what happened* — session transcripts, task context, conversation history
- **Identity layer** (piia-engram): stores *who you are* — profile, preferences, lessons learned, decisions, quality standards

This is the same distinction we implicitly make with SOUL.md (identity) vs memory/YYYY-MM-DD.md (events), but piia-engram makes it explicit and portable across tools.

## Architecture

Local JSON files in `~/.engram/`:
```
engram/
├── identity/
│   ├── profile.json          # role, language, tech level
│   ├── preferences.json      # work patterns, tool prefs, communication style
│   ├── quality_standards.json # code quality rules
│   └── trust_boundaries.json # per-tool access control
├── knowledge/
│   ├── lessons.json          # what you've learned (negative + positive)
│   ├── decisions.json        # key decisions with reasoning
│   └── domains.json          # domain expertise tracking
├── projects/                 # per-project context
└── exports/                  # cross-tool snapshots
```

MCP server exposes 43 tools (tiered: 10 core tools by default, rest opt-in).

## Interesting Design Decisions

### 1. Staging → Verified Tier System
New knowledge enters as "staging". Auto-promoted to "verified" after being accessed 3+ times. Time-based promotion explicitly removed: "mere survival is not proof of value."

This parallels our [[beliefs-upgrade-mechanism]] — we require Triple Verification (Cross-context ≥3, Predictive Power, Non-obvious). piia-engram's threshold is simpler (access count only) but the principle is the same: don't promote just because time passed.

### 2. Trust Boundaries
Per-field access control. Sensitive profile fields can be restricted from certain tools. This is relevant if we ever expose identity data to external MCP clients.

### 3. Reconcile from External AI Configs
Scans and imports from: CLAUDE.md, .cursorrules, .windsurfrules, AGENTS.md, SOUL.md, USER.md, .github/copilot-instructions.md, .trae/rules. Treats the entire AI tool ecosystem's config files as input.

### 4. OpenClaw Interop (Built-in)
`export_to_openclaw()` generates SOUL.md + USER.md + MEMORY.md.
`import_from_openclaw()` parses our files back into Engram format.
They see OpenClaw as one of the asset-layer formats to bridge, not compete with.

### 5. Conflict Detection
Detects contradictory knowledge entries (e.g., "always use TypeScript" vs "prefer Python for backends"). Uses similarity threshold + negation markers.

### 6. Data Fragmentation Warning
Detects when engram data exists in multiple locations (e.g., old path and new path) and warns about incomplete knowledge. Defensive design.

## Comparison with Our Approach

| Aspect | piia-engram | Our DNA System |
|--------|-------------|----------------|
| Identity storage | JSON files, MCP-served | SOUL.md + IDENTITY.md (in-context) |
| Memory storage | Out of scope (explicitly) | memory/*.md + MEMORY.md |
| Cross-tool | Core feature (MCP) | N/A (single platform) |
| Knowledge promotion | access_count ≥ 3 | Triple Verification gate |
| Encryption | Optional field-level | N/A (file-level via git-crypt) |
| Self-governance | N/A | DNA self-update with notification |

**Key insight**: piia-engram solves a problem we don't have (multi-tool identity sync) but validates design choices we already made:
1. Separating identity from memory is the right abstraction
2. Knowledge should earn its way in (staging → verified / candidates → DNA)
3. Trust boundaries matter when identity data crosses tool boundaries

## What We Can Learn

1. **Conflict detection** — We don't explicitly detect contradictions in beliefs-candidates.md. Could add a similarity check when new candidates are proposed.
2. **Access-count tracking for knowledge** — We don't track how often a wiki note or belief is actually referenced. Usage data would help prune stale knowledge.
3. **The "reconcile" pattern** — Scanning external tool configs as knowledge input. If OpenClaw users also use Cursor/.cursorrules, auto-importing those rules could reduce setup friction.

## Verdict

Not directly useful for us (we're single-platform), but validates the identity-vs-memory split and the earned-promotion model. The conflict detection idea is worth stealing.

See also: [[engram]], [[claude-soul]], [[elephant-agent]], [[self-evolving-agent-landscape]], [[beliefs-upgrade-mechanism]]
