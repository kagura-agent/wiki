---
title: "memwatch — Memory Staleness Detection"
created: 2026-06-08
updated: 2026-06-08
tags: [agent, memory, staleness, python]
status: noted
last_verified: 2026-06-08
---

# memwatch — Memory Staleness Detection

**Repo:** kresnapandu/memwatch · **Stars:** 18 (Jun 8) · **Created:** 2026-06-04 · **License:** MIT · **Lang:** Python

## What It Solves

The canonical agent memory failure: "user works at Google" stored once, trusted forever, confidently wrong 6 months later after a job change.

## Mechanism (3-level cascade)

1. **Contradiction detection**: keyword + entity transitions + optional embeddings. Scans new input against stored memories for conflicts.
2. **Freshness scoring** (Ebbinghaus-inspired): `base_score = decay_factor ^ days_elapsed` + access/recency boosts. Score ∈ [0, 1].
3. **Category-aware TTL**: each fact category has its own half-life from real-world change rates:
   - Employment: 180d half-life
   - Location: 365d half-life  
   - General facts: 3650d half-life

## Connection to [[universal-memory-protocol]]

UMP's bi-temporal model (`valid_from`/`valid_to`) makes staleness **representable** but doesn't auto-detect it. memwatch auto-detects contradictions and suggests updates. They're complementary layers:
- UMP = protocol for recording what's true and when
- memwatch = detection engine for when "true" becomes "false"

## Relevance to Us

Our wiki already uses `last_verified` dates and manual review cycles. memwatch's category-based decay is an interesting formalization — could inspire auto-flagging stale wiki cards (e.g., project notes >90 days unverified get a freshness warning).

**Not adopting** — our scale doesn't warrant a Python service for this. But the Ebbinghaus decay model is a useful mental model for wiki maintenance.

Links: [[universal-memory-protocol]], [[agent-brain-portability]]
