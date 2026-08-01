---
title: "agentacct — Local-first Agent Work Intelligence"
created: 2026-07-25
updated: 2026-07-25
source: https://github.com/mikehasa/agentacct
stars: 376
status: tracking
tags: [agent-observability, coding-agent, audit, usage-truth, local-first]
last_verified: 2026-07-27
---

# agentacct — See What Your Coding Agents Actually Did

**By:** mikehasa (solo dev)
**Stars:** 376 (created 2026-07-24; 97→376 in 3 days, +287%)
**Language:** Python (80k+ LOC, 141 test files)
**License:** not specified in README

## What It Solves

Local-first dashboard that reads coding-agent session logs (Claude Code, Codex) already on your machine and shows honest token usage, cost estimates, and work attribution. Key difference from proxy-based tools: **never intercepts API traffic** — reads post-hoc from local log files.

## Key Architectural Patterns

### 1. Usage Truth Table
Every data source has an explicit truth tier with confidence labels:
- `provider_reported` vs `client_reported` vs `estimated` vs `unknown`
- Cost: `provider_billed` vs `estimated_from_tokens` vs `subscription_equivalent`
- Formal UsageTruthRow dataclass with fields: integration, tier, evidence_source, observable_fields, usage_confidence, cost_confidence, limitations
- **Anti-marketing**: each integration explicitly lists what it CANNOT prove

### 2. Multi-tier Join Attribution
Connects usage records to work sections via client session/transcript IDs:
- **Tiers**: explicit (exact) → hook (high) → log_evidenced (high) → attach (medium) → unverified (high cap)
- **Veto mechanism**: conflicting evidence vetoes BOTH sides of a join ("missing attribution beats wrong attribution")
- **Cohort guard**: log-evidenced allocation refuses when donor session links multiple sections (ambiguous)
- Three surfaces (canonical attribution, join inspector, context bridge) share join_rules.py so they can NEVER disagree

### 3. Evidence v2
- Append-only spool (evidence-v2/spool.jsonl) + rebuildable SQLite projection
- Immutable envelopes distinguish `observed` from `claimed`
- Source authority evaluated per dimension
- Deduplicate replays as receipts
- **Separation of evidence and control**: evidence informs control but cannot grant itself dispatch authority

### 4. Control Plane
- Separate append-only Control Store (versioned task contracts, agent specs, workspaces, attempts, approvals, budgets, schedules)
- Single leased supervisor dispatches only Chronicle-owned processes
- Reconciles after restart using process fingerprint + launch nonce

## Comparison with Related Tools

| Tool | Approach | Scope |
|------|----------|-------|
| **agentacct** | Log reader (post-hoc) | Usage truth + work attribution |
| **ccglass** | Network proxy (MITM) | API traffic inspection |
| **HALO** | Trace analysis (RL-based) | Performance optimization |
| **mentor** | Session insights (skill) | One-shot HTML reports |

## Novel Insights

1. **Confidence as a first-class data type**: Not just "we tracked it" — every piece of data carries provenance metadata. Applicable pattern: our own observability could label data confidence.
2. **Veto-based attribution**: When evidence conflicts, refuse the join entirely rather than guessing. This is philosophically aligned with our "I'm not sure beats confident wrong answer" belief.
3. **Usage Truth Table as documentation pattern**: Formal matrix of what each integration can/cannot prove. Superior to typical "supported integrations" marketing lists.
4. **Evidence ≠ Control separation**: Data collection layer cannot self-authorize actions. Clean architectural boundary.

## Growth & v0.2.0 (2026-07-26)

- **Explosive growth**: 97→376⭐ in 3 days. HN Show HN attention ("Boffin" co-trending, agentacct itself surfaced in coding agent searches)
- **v0.2.0 released** (07-26): itemized redacted evidence inventory, /sessions time-first browser, inline finding resolve/review actions, activity feed
- License: MIT (confirmed in README, missed earlier)
- 2 forks now (was 0)
- Still 0 external issues — adoption is star-based, not usage-based yet

## Concerns

- Solo dev — survival risk mitigated by velocity (8 PRs merged in 2 days)
- 80k LOC for a v0 alpha is unusual volume (likely long private dev → open-source)
- 0 issues = no community validation (stars ≠ users)
- Dashboard improvements dominating — core attribution engine seems stable/complete

## Relevance to Us

- **Direct**: We run multiple coding agents (Claude Code, Codex) — agentacct could give visibility into our own token usage patterns
- **Architectural**: The confidence-labeled data pattern and veto-based joins are intellectually valuable for any system that combines multiple uncertain data sources
- **Not urgent**: Too early to adopt; worth tracking for architecture patterns

## Links

- [[ccglass]] — proxy-based observability (complementary approach)
- [[halo-agent-trace-optimizer]] — RL-based trace optimization (different goal)
- [[agent-harness-landscape]] — broader ecosystem context

## v0.5.3 Update (2026-08-01 followup)

**Growth**: 376→540⭐ (+44% in 6 days), 67 forks, 4 external PR authors. Still 0 issues (odd at this scale — likely solo dev closing fast or users not reporting).

### SQLite Event Store Migration (PR#36)

Core architectural shift: flat `events.jsonl` → SQLite (`event_log.py`).

**Migration pattern (adoptable)**:
1. **Dual-write**: Both stores updated simultaneously
2. **Parity proof**: `verify_against_file` proves line-for-line equivalence
3. **Durable marker**: Store marker persists cutover state across restarts — no env var needed
4. **Self-healing + fail-loud**: Never serves empty/half-migrated store
5. **CLI cutover**: `event verify-log` → `event drop-flat-ledger --confirm`
6. **Off by default**: Conservative rollout, user opts in after proof

**Adversarial review process**: 3 passes finding 9→3→1→0 defects (notable: env-only authoritative state could let one env-less open wipe the log).

**Relevance**: Our own study/ tools use jsonl files (calibration.jsonl, etc). This pattern shows how to migrate safely without data loss or downtime.

### Honest Work States (PR#34)

New state model that prevents false representation:
- `handed_off`: terminal status for clean stops (vs eternally "in progress")
- `mostly_done`: requires cross-session evidence (24h gap + activity elsewhere) — **absence of activity ≠ abandonment**
- Partial verification: `3 of 5 steps verified` instead of all-or-nothing
- Real impact: 66/905 sections were stranded as "in progress", 9 tasks correctly reclassified

**Philosophy**: Aligns with our "I'm not sure beats confident wrong" — better to say "mostly_done" than falsely claim complete or stuck.

### Other Notable PRs
- #32: Agent recording fails loudly (not silently) — fail-loud over silent corruption
- #31: Stop secret redaction from destroying records — safety mechanism caused data loss
- #33: Fixed check no longer shown as unresolved finding

## Links

- [[ccglass]] — proxy-based observability (complementary approach)
- [[halo-agent-trace-optimizer]] — RL-based trace optimization (different goal)
- [[agent-harness-landscape]] — broader ecosystem context
