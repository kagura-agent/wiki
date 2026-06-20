---
title: Ephemera Retention Primitive
created: 2026-06-18
source: study/followup (beads issue #4369, gascity scale incident)
status: insight
tags: [architecture, agent-platform, scale]
last_verified: 2026-06-20
---

# Ephemera Retention Primitive

> Issue-tracking and memory systems designed for human-scale throughput (10s/week) catastrophically degrade when agent platforms feed them automation ephemera (100k/day). The structural fix is a first-class retention/TTL primitive at the storage layer, not afterthought cleanup.

## The Pattern

**Trigger conditions:**
1. Storage system designed for "durable, human-meaningful" records (issues, memories, events)
2. Agent platform built on top generates high-volume short-lived records (workflow steps, nudges, session records, automation telemetry)
3. Storage has no concept of TTL, archive, or per-record-type retention
4. Result: 10x–100x volume growth in days → scan queries timeout → manual SQL bulk-delete → unsafe

**Real-world examples:**
- **[[beads]] #4369** (2026-06-17): gascity agent platform on Beads — 11k → 98.7k issues in 36h, ~90% closed automation churn, 2-min scan timeouts, required hand-rolled Dolt SQL to purge
- **[[memory-trash-filter]]**: agent memory systems break when not filtering low-value events; trash filter is the same shape but for memory layer
- **[[claude-code-memory-architecture]]**: tiered processing (hot/warm/cold) implicitly addresses this — Beads doesn't have tiers yet

## Why "just delete them" doesn't work

1. **Loss of provenance** — direct DELETE loses audit trail / git history
2. **Bulk operations on transactional stores are scary** — Dolt commits, ACID guarantees, etc.
3. **Each platform reinvents unsafe SQL** — fragments the operational surface, increases blast radius
4. **No per-type policy** — "all closed issues older than 48h" vs "all closed issues of type `automation` older than 1h" needs to be expressible declaratively

## What a proper retention primitive looks like

From #4369's ask + general design:

```
# Config-level
bd config set retention.<type>.<label> 48h
bd config set retention.automation.* 1h

# Bulk operations
bd archive --filter "status=closed AND type=automation AND older=48h" \
           --emit-jsonl ./archive/2026-06-18.jsonl
bd purge   --filter "status=closed AND archived AND older=14d"

# Maintenance command for cron
bd retention apply    # honors all configured TTLs
```

**Key properties:**
- Declarative per-type/label TTL
- Two-phase: archive (export then delete) vs purge (delete already archived)
- JSONL emit before deletion (replayable, auditable)
- Idempotent and cron-safe
- Documented as **the** supported pattern so platforms don't each reinvent unsafe SQL

## Generalizable Rule

**Any storage primitive intended for agent-platform substrate needs first-class retention semantics from day 1.** The "we'll add cleanup later" path leads to:
1. Platforms hit scale → hand-rolled bulk SQL
2. Hand-rolled SQL breaks something → incident
3. Storage layer adds retention reactively → existing platforms don't migrate cleanly
4. Bifurcation: human-issue users vs agent-platform users have different operational expectations

**Counter-example:** Database engines that ship with TTL primitives (Cassandra TTL, Redis EXPIRE, InfluxDB retention policies) avoid this trap because retention is part of the data model, not bolted on.

## Implications for our direction

If we ever build first-class persistence for agent task memory (vs current markdown TODO):
1. Design retention semantics into the schema, not the cleanup tool
2. Differentiate **durable** (human-meaningful: decisions, learnings, commitments) from **ephemeral** (automation: workflow steps, heartbeat checks, scout iterations)
3. Cron-friendly maintenance command, not "remember to clean up sometimes"
4. JSONL-style replayable archive — preserves history for analysis without paying live-query cost

Cross-link: this is exactly why we have [[memory-trash-filter]] — and the same logic should apply to any TODO/task store we build.

Links: [[beads]], [[memory-trash-filter]], [[claude-code-memory-architecture]], [[git-backed-agent-memory]], [[nanobot]]
