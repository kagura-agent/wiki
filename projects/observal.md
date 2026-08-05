# Observal — Cross-Harness AI Component Registry & Analytics

> **Tagline**: "The control plane and system of record for internal AI components."
> 2,218⭐ | Apache-2.0 | Python (server + CLI) | Created 2026-03-30 | v1.10.3 (2026-07-21)
> Team: Haz3-jolt (lead, 1000 commits) + 12 contributors | Active: releases every ~2 days

## What It Solves

Organizations create internal Skills, Agents, MCP servers but suffer from:
1. **No discoverability layer** — AI components scattered across siloed repos with no docs
2. **Missing feedback loop** — developers publish with zero visibility into actual usage; AI failures don't trigger error codes (hallucinations, subtle wrongness)

Observal provides: centralized discovery + governed registry + usage analytics + session replay.

## Architecture

**Dual-DB design:**
- PostgreSQL (Alembic migrations) — CRUD: agents, skills, versions, users, reviews
- ClickHouse — time-series: session events, telemetry, token usage, spans
- Redis — cache, rate-limiting, editing locks

**Monorepo structure:**
- `observal-server/` — Python (FastAPI + GraphQL), async SQLAlchemy
- `observal_cli/` — Python CLI (Typer + Rich), PyInstaller for standalone binary
- `web/` — Next.js frontend (pnpm workspace)
- `docker/` — full stack compose (API, web, PG, CH, Redis, worker, Prometheus, Grafana)

**Harness adapter pattern (Protocol-based):**
Both server-side and CLI-side implement `HarnessAdapter` protocol. Each harness (claude-code, cursor, codex, pi, kiro, opencode, copilot, antigravity) provides:
- Config generation (MCP entries, hooks, skills in harness-native format)
- Session transcript parsing (JSONL → event classification → ClickHouse)
- Token usage extraction (per-harness format differences)
- Local scanning (discover installed MCPs, skills, hooks, agents)

## Key Concepts

### Agent = Portable Context Package
Bundles 5 component types: **MCP servers**, **skills**, **hooks**, **prompts**, **sandboxes**.
One `observal pull <agent> --harness <harness>` generates correct config for any supported harness.

### Layer Hash
Deterministic hash of ALL files that shape AI behavior in a harness config dir.
Not just Observal-installed — includes user rules, custom agents.
Used for change detection, drift alerts, snapshot comparison.

### Self-Learning Pipeline (`services/insights/self_learn.py`)
Takes completed InsightReport → materializes suggestions as registry submissions:
- config_additions → new AgentVersion with updated prompt (pending review)
- features_to_try → new Skill/Hook Listings
- usage_patterns → new Prompt Listings
All enter review queue under agent owner's identity. **Not auto-applied.**

### Eval Engine (PR #968, in development)
Scoring aggregation, outcome alignment, spec DAGs, trace DAGs, adversarial robustness, reasoning explanations, waste classification. 431 tests passing.

### Session Ingest
Per-harness JSONL parsers classify transcript lines → batch insert to `session_events` table.
Deduplication via xxhash. Secrets redaction before storage. Checkpoint-based incremental delivery.

## Relevance to Us

| Aspect | Observal | OpenClaw |
|--------|----------|----------|
| Scope | Org-level registry + analytics | Personal agent runtime |
| Agents | Static packages (MCP+skills+hooks+prompts) | Living autonomous agents |
| Harness | External (Claude Code, Codex, Pi, etc.) | IS the harness |
| Analytics | Session replay + LLM-powered insights | Built-in session history |
| Self-learn | Insight → pending registry items | beliefs-candidates → DNA |

**Key insight**: Observal treats agents as configuration bundles to distribute; OpenClaw treats agents as running entities. Complementary more than competitive — OpenClaw agents could be *consumers* of Observal registry components.

**Adoptable patterns:**
1. **Layer hash** — deterministic snapshot of all AI-shaping config. Could detect config drift between sessions.
2. **Harness adapter protocol** — clean separation between "what to configure" and "how each harness wants it". Relevant if OpenClaw ever exports configs to other tools.
3. **Self-learning pipeline** — from usage analytics → pending improvements → review gate. Structurally similar to our beliefs-candidates → DNA pipeline, but data-driven rather than correction-driven.
4. **Anti-gaming service** (`services/anti_gaming.py`) — worth investigating for detecting star-farming/fake metrics.

**Not applicable:**
- Registry/governance model (we're single-user, not org-level)
- Heavy infrastructure (PG+CH+Redis+Prometheus for a personal tool is overkill)

## Ecosystem Position

- **vs [[waggle]]**: Waggle solves cross-harness artifact *handoff* (attributed references); Observal solves cross-harness component *distribution + analytics*
- **vs [[deja-vu]]**: deja-vu solves cross-harness *memory search*; Observal solves cross-harness *tool/config sharing*
- **vs [[ccglass]]**: ccglass is passive observability proxy; Observal is active registry + analytics with self-learning
- **Category**: Enterprise AI Platform (like Weights & Biases for agent tooling, but self-hosted + open)

## Signals & Health

- 13 contributors, REUSE-compliant, Helm chart (OCI artifact), SAML SSO, SCIM
- Open issues requesting harness support for: Goose, Junie, Claude Cowork, Tabnine, Qwen Code, ForgeCode, Zed, Warp, Kimi Code
- v1.10.x = feature-complete enough for production use (they have eval engine, SSO, Helm, Grafana dashboards)
- **Growing fast**: 2,218⭐ in ~4 months. Enterprise-focused features (SSO, audit logs, SCIM) suggest commercial trajectory

## Open Questions

1. How does the self-learning pipeline actually perform? (quality of LLM-generated suggestions)
2. How does session replay handle large transcripts? (ClickHouse retention policies?)
3. What's the latency story for hook-based telemetry? (defer_session_delivery hint suggests some harnesses need async drain)

## ⛔ Contribution Status: BLOCKED

**Cannot contribute PRs.** Their `AI_POLICY.md` explicitly bans autonomous coding agents:
> "Tools like Devin, SWE-agent, OpenHands, and similar autonomous agents that write and submit code without meaningful human authorship are not allowed to contribute to this project."
> "Any PR identified as having been submitted by an autonomous agent will be closed immediately."

Added to gogetajob blocklist 2026-07-22.

## Contribution Requirements (for reference)

- Claiming: `/take` on good first issue / help wanted
- SPDX headers required on every file
- Conventional Commits
- `make test` before submitting
- CHANGELOG.md entry for user-facing changes
- CLA required
- Pre-commit hooks: `make hooks`

Links: [[agent-harness-landscape]], [[ccglass]], [[waggle]], [[deja-vu]], [[openclaw]], [[acp]]

## 2026-08-05 — Follow-up: operational maturity, not feature expansion

At 2,254⭐, work through 2026-08-03 focused on a fresh-database Alembic guard and resume-safe release/attestation jobs. This is a useful ecosystem signal: once an agent platform reaches enterprise integrations, reliability of install and release paths becomes a product concern. No new architecture surfaced; retain as a mature reference alongside [[ccglass]] rather than chase each maintenance release.
