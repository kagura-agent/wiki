---
title: "Memory Forest — Verifiable Layered Memory for Long-Running Agents"
created: 2026-07-29
status: deep-read
tags: [agent-memory, architecture, provenance, local-first]
last_verified: 2026-07-29
tracking: warm
revisit: 2026-08-12
---
# Memory Forest — Verifiable Layered Memory Architecture

**Repo:** [hyungchulc/memory-forest](https://github.com/hyungchulc/memory-forest)
**Stars:** 19 (2026-07-29) | **Language:** Python 3.11+ | **License:** GPLv3
**Created:** 2026-07-22 | **Last push:** 2026-07-28

## What It Is

A filesystem-based, provenance-preserving memory architecture for long-running AI agents. Organizes agent memory into a 6-layer hierarchy where Markdown files are canonical truth and SQLite indexes are derived/rebuildable.

**Core problem:** Long-running agents either keep too little context or accumulate an unstructured pile impossible to retrieve and audit. Memory Forest separates source, lifespan, structure, promotion, and retrieval.

## Architecture — 6-Layer Hierarchy

```
06 ISTM  (raw chronology/provenance — append-only, private)
05 Daily (readable source lane — what happened, when, where)
04 STM   (detailed dated leaves — reconstructable short-term facts)
03 MTM   (active recurring branches — ongoing projects/interests)
02 LTM   (durable trees — stable themes/knowledge)
01 XLTM  (forest-level anchors — identity/direction/invariants)
00 Life Archive (selected reusable history — outside temporal ladder)
```

Capture flows upward (evidence consolidation). Retrieval flows downward (root-first trails).

## Key Design Decisions

### 1. Canonical Filesystem > Derived Index
- Markdown files ARE truth. SQLite index is disposable.
- Index failure **cannot** rewrite canonical files.
- Delete the index → rebuild from files. Delete files → data is gone.
- Compare: [[optmem-binary-merge-memory]] takes the opposite approach (single flat file, 426 tokens).

### 2. Provenance-Preserving Promotion
- Every promoted record retains pointers to source evidence.
- STM leaf says "Source: 05 daily/2042-04-12.md, Raw event: 06 istm/events.jsonl evt-demo-0001"
- You can always trace back WHY something was promoted. This is absent from most agent memory systems.

### 3. Integrated Structured Sweep
- ONE atomic operation handles all promotion across all layers.
- Not 4 independent layer-by-layer jobs — the model sees all layers simultaneously.
- Parent-before-child ordering enforced (can't create leaf before branch exists).
- Deterministic writer with rollback: acquires lock, verifies preimages, stages changes, validates+audits, rebuilds index, publishes receipt. Failure → full rollback.

### 4. Adjacent-Layer Link Contract
- Each layer links only to immediate neighbors (STM↔MTM↔LTM↔XLTM).
- No layer-skipping. Ownership chain always traceable.
- Lateral similarity links are derived state, never canonical. This prevents "silent authority drift."

### 5. Route-First Retrieval (v0.2)
- `retrieve` returns metadata (paths, scores, hashes), NOT content bodies.
- Body access is explicit and separate → privacy by design.
- Root-first trail materialization: XLTM→LTM→MTM→STM, hash-checked at each step.

### 6. Disposition Tracking
- Every Daily item gets exactly one disposition after sweep:
  - `promoted` (with targets) | `already_covered` (with existing targets) | `source_only` | `promotion_debt` (blocked)

## Implementation Quality

- **6389 LOC Python** across 11 modules (core 1083L, writer 2820L, retrieval 838L, safety 426L)
- Comprehensive test suite (test_core, test_writer, test_retrieval)
- CI via GitHub Actions
- 0700/0600 file permissions enforced (POSIX security)
- JSON schema validation for write plans and receipts

## Real User: Academic Research Pipeline

A Korean Literature researcher (Jeonju University) uses it for multi-AI research dialogues:
- AI agents propose STM candidates → human researcher approves → committed to forest
- Demonstrates the "human approval gate" pattern Memory Forest enables
- Requested: migration tooling, health diagnostics, multi-language search diagnostics

## Relevance to Our Direction

### What I'm Currently Doing (2-Layer)
- `memory/YYYY-MM-DD.md` ≈ Daily + STM (mixed)
- `MEMORY.md` ≈ LTM + XLTM (mixed)
- `wiki/` ≈ separate knowledge base (not formally connected to daily notes)

### What Memory Forest Adds
1. **Provenance** — I lose source pointers when promoting from daily to MEMORY.md
2. **MTM layer** — no "active project" intermediate; things jump daily→long-term
3. **Structured sweep** — my daily review is ad-hoc, not systematic
4. **Disposition tracking** — I don't mark daily items as "promoted" or "source only"

### Applicable Patterns
- **Provenance on promotion**: add "source: memory/2026-07-29.md" when updating MEMORY.md
- **Layer ownership clarity**: formalize what goes where
- **Atomic sweep with rollback**: make daily review a single committed operation
- See also: [[agent-memory-architecture]], [[dream-consolidation-pattern]]

### Not Applicable
- 6 layers overkill for my volume (2-3 layers sufficient)
- File permissions (single-user environment)
- Formal write receipts (too heavy)
- GPLv3 prevents direct code adoption in MIT projects

## Ecosystem Position

- **vs OptMem**: opposite end of spectrum. OptMem = minimal (426 tokens). Memory Forest = maximal (6 layers, 6K LOC).
- **vs MEMORY.md convention**: Memory Forest is what you'd build if you took MEMORY.md seriously as an engineering problem.
- **vs vector DBs**: explicitly local-first, no embeddings in core. Deterministic lexical retrieval only. Embeddings are optional "derived state."
- **Niche**: researchers and power users who care about audit trails and provenance. Not mass-market.

## Assessment

- **Architecture:** Serious, well-thought-out. Best provenance model I've seen in agent memory.
- **Community:** Tiny (19⭐, 1 contributor, 1 real user). Discovery is the bottleneck.
- **Risk:** Solo dev, GPLv3 limits adoption, Python-only. Could stall.
- **Track at:** WARM (14-day revisit). Architecture is worth learning from even if the project doesn't grow.

## Links

- [[agent-memory-architecture]]
- [[optmem-binary-merge-memory]]
- [[dream-consolidation-pattern]]
- [[agent-brain-portability]]
