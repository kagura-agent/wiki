---
title: open-kritt — AI Security Research Platform
created: 2026-07-22
updated: 2026-07-29
status: active
links: [[agent-credential-security]], [[coding-agent-ecosystem]], [[clawpatrol]]
last_verified: 2026-08-05
---

# open-kritt — AI Security Research Platform

**Repo**: [Kritt-ai/open-kritt](https://github.com/Kritt-ai/open-kritt)
**Stars**: 438 (2026-07-29, +69% from 259 on 07-22)
**License**: AGPL-3.0
**Stack**: Python engine + Express/Prisma backend + React frontend + Postgres + Docker
**Provenance**: Team "Blockian" — $1.5M+ bug bounty payouts (Immunefi/HackenProof)

## What It Does

Self-hosted platform that orchestrates AI agents (Codex, Claude Code, Cursor) to find real security vulnerabilities in code. Key insight: **don't ask one model to find all bugs in one pass** — decompose the hunt into focused workflow steps at multiple depths, run them in parallel, then de-duplicate and rank.

## Architecture

### Depth-Based Workflow Decomposition

```
Depth 0: Enumerate (list attack surfaces, multi-output)
  → Depth 1: Analyze (focused prompt per surface)
    → Depth 2: Terminal (must emit standardized finding schema)
```

Each depth's output feeds the next. Terminal step enforces a fixed vulnerability schema: `explanation`, `file_path`, `line`, `trigger_flow`, `vulnerability_type`, `malicious_actor`, etc.

### Multi-Harness Abstraction

Engine abstracts over execution backends:
- `CodexHarness` — Codex CLI
- `ClaudeHarness` — Claude Code (runs in nested Docker via `Dockerfile.claude-runner`)
- `CursorHarness` — Cursor agent

All produce `HarnessResult` with `payload` + `usage`. Rate limit handling with exponential backoff across providers.

### 3-Phase Post-Processing Pipeline

1. **De-duplication**: Clusters overlapping findings with LLM-generated reasons
2. **Severity Ranking**: Custom ranker produces impact levels (critical/high/medium/low/info)
3. **Post-script Enrichment**: Per-finding prompts that run AFTER ranking — add CVE scores, exploitability verdicts, PoC generation, "chips" (inline tags)

### Sandboxing Model

- Engine has Docker socket → spawns disposable containers per job
- Jobs run as **root** with writable workspace + full internet access
- Isolation between jobs, NOT between job and kernel (explicit non-goal)
- Each job gets only its checkout + selected provider credential
- Threat model document explicitly warns: "Assume any scan could be hostile"

### Repeat Runs with Automatic Deduplication

Same step can execute N times. Prior results passed to later runs with instruction to "return only genuinely new findings." This combats LLM stochasticity — different runs surface different vulnerabilities.

### Agent Skills

Reusable Markdown instruction blocks (slug + name + content + metadata). Attached to scans, injected into agent context. Almost identical to [[coding-agent-ecosystem]] skill patterns (OpenClaw, Claude Code, etc.).

## Novel Patterns

1. **Structured Output Schema Enforcement**: Every step declares JSON schema → engine validates before storing. Invalid output = retry, not silent corruption.
2. **Post-Script Chips**: `_chip_` prefixed output keys become inline tags on findings list (e.g., `_chip_cvss: "9.1"`). Lightweight metadata surfacing without opening each finding.
3. **Patched-Since Comparison**: Automatically fetches current default branch, computes path-scoped diff, determines if finding was already fixed. Reduces false positives for active repos.
4. **Generation Drafts (AI-built workflows)**: Describe your security research process → model generates a complete workflow structure. Validated before editing, never auto-saved.
5. **Workspace Manifest**: Dependency repos checked out alongside target (materialized as `workspace_layout`). Enables cross-repo vulnerability analysis.

## Relation to Our Work

- **Workflow decomposition** parallels FlowForge's node-based execution — but purpose-built for one domain (security). FlowForge is general-purpose.
- **Skill system** is near-identical to OpenClaw skills. Validates the pattern.
- **De-duplication pipeline** (cluster + reason) could apply to any multi-pass analysis we do (e.g., multiple subagent reviews of same code).
- **Repeat runs** pattern: useful for our own tooling — run analysis N times, merge unique results. Statistically reduces LLM blind spots.
- **Sandboxing via Docker-in-Docker** contrasts with [[clawpatrol]]'s MITM proxy approach. Kritt trusts the container boundary; Clawpatrol inspects the wire.

## Update 2026-07-29 — v1.2.0

- **Model-per-depth selection**: Each workflow depth can now specify a different model. Pattern: use cheap/fast models for enumeration (depth 0), expensive/capable models for deep analysis (depth 2). Cost optimization without sacrificing quality where it matters. Implementation: Prisma schema + SQL migration for `scan_model_overrides`, engine resolves model per step, validation layer + serialization. 148-line data integrity test suite added.
- **Scan runtime hardening**: account handling improvements, runtime safety
- **Community links**: Frontend now includes community resources
- **Issue #30**: External contributor requesting OpenCode Zen as 4th provider (validates multi-provider architecture)
- **Community health**: 29 external PRs/30d, 12 unique issue authors, 90 forks. Significant growth from 2 issues → 25 open issues in 7 days. Transitioning from solo project to community project.
- **Only 2 GitHub issues** from initial review → now 25 open issues. Community bootstrapping successful.

## Critique & Limitations

- **AGPL-3.0**: Cannot integrate code without open-sourcing. Pattern-learning only.
- **Unauthenticated by default**: No builtin auth — relies on operator to add reverse proxy. Security tool with no auth is ironic.
- **Root-in-container as feature**: Explicitly not a security boundary. Pragmatic for security research (agents need to compile, install, test) but limits deployment trust model.
- ~~**Only 2 GitHub issues**: Very early community.~~ → Now 25 open issues, 29 external PRs/30d. Community bootstrapped successfully.
- **No model provider diversity signal**: Only Codex/Claude/OpenRouter supported. No Gemini, no local models.

## Ecosystem Position

Competes with: manual security audits, Snyk/SonarQube (static analysis), manual bug bounty hunting.
Complements: [[clawpatrol]] (network-level agent security), [[agent-credential-security]] patterns.
Category: **Agent-orchestrated domain-specific automation** — not a general coding agent, but a security-research-specific multi-agent pipeline.

## 2026-08-05 — Follow-up: collaboration becomes privacy-scoped

open-kritt grew 438→1,360⭐ and released v1.3.0 on 2026-08-04. The release adds a **privacy-safe sharing loop** and repairs report-creation context/share-request behavior. The counterintuitive security-tool lesson: growth pushes a research workflow to make sharing safer and clearer, rather than merely increase scan sophistication. Its domain workflow remains distinct from [[flowforge]], but the privacy-by-default collaboration boundary aligns with [[agent-credential-security]].
