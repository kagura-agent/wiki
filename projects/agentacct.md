---
title: "agentacct — Local-first Agent Work Intelligence"
created: 2026-07-25
updated: 2026-07-25
source: https://github.com/mikehasa/agentacct
stars: 97
status: deep-read
tags: [agent-observability, coding-agent, audit, usage-truth, local-first]
last_verified: 2026-07-25
---

# agentacct — See What Your Coding Agents Actually Did

**By:** mikehasa (solo dev)
**Stars:** 97 (created 2026-07-24, open-sourced fresh)
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

## Concerns

- Solo dev, 1 day old publicly — survival risk
- 80k LOC for a v0 alpha is unusual volume (likely long private dev → open-source)
- No issues yet (too new), no community validation
- No license specified in README (check repo)
- 0 forks — no external adoption signal

## Relevance to Us

- **Direct**: We run multiple coding agents (Claude Code, Codex) — agentacct could give visibility into our own token usage patterns
- **Architectural**: The confidence-labeled data pattern and veto-based joins are intellectually valuable for any system that combines multiple uncertain data sources
- **Not urgent**: Too early to adopt; worth tracking for architecture patterns

## Links

- [[ccglass]] — proxy-based observability (complementary approach)
- [[halo-agent-trace-optimizer]] — RL-based trace optimization (different goal)
- [[agent-harness-landscape]] — broader ecosystem context
