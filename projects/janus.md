---
title: Janus — governed evolution for a desktop agent laboratory
created: 2026-08-11
source: study scout / GitHub API deep read
tags: [agent-evolution, governance, evidence, desktop, multi-agent]
last_verified: 2026-08-11
---

# Janus — Governed Evolution for an Agentic Laboratory

**Repository:** `iLearn-Agent/Janus` — 93 stars, 1 fork, 13 open issues when inspected 2026-08-11. Open-sourced 2026-08-10; Electron desktop workspace plus an optional self-hosted cloud service. It positions itself as a persistent human–agent collaboration network rather than a one-shot chat client.

## What it is actually building

Janus separates three things that many “self-improving agent” projects blur together:

1. **Employment and collaboration:** agent recruitment, role assignment, task groups, and deliverable review.
2. **Personal evolution:** an owner-specific Skill/Memory overlay derived from work evidence.
3. **Shared evolution:** a reusable cohort capability that must survive governance, shadow evaluation, and a real-user canary before release.

That makes it closer to a governed organizational runtime than a prompt optimizer. It overlaps with [[self-evolving-agent-landscape]] at the Skill/Memory/Workflow layers, but adds an explicit multi-user release process instead of treating every accepted local lesson as globally reusable.

## Evidence is treated as a controlled asset

The core implementation is unusually concrete about evidence provenance:

- Evidence has a stable identity over owner, agent instance, source kind/id, source version, and content hash. Tests reject unregistered source kinds and memory evidence without a version.
- The evolution worker decrypts and validates evidence before it becomes eligible, writes access audits, and quarantines privacy/credential-like payloads. Missing decryption keys retry only five times before terminal failure; a later key recovery can validate the item.
- Personal runs need at least five validated evidence records; selected records are frozen into an immutable run snapshot. Candidates are encrypted overlays rather than silent edits to the base Skill.
- Rejected evidence cannot be reused unchanged: a new evidence category peer or a changed algorithm/policy basis is required. This prevents a repeated evaluator loop from “trying again” until it gets a desired answer.

This is the strongest transferable pattern: **govern the evidence lifecycle, not only the resulting prompt.** It complements our [[mechanism-vs-evolution]] distinction: a change process is credible only if its inputs, evaluator basis, and rollback path are inspectable.

## Shared evolution has meaningful release gates

`stage8` requires a minimum of seven synchronized users for a cohort and enforces category thresholds (15 total evidence records, including chat, memory, and completed-task evidence). It caps any one user at 15% of effective evidence weight. A candidate then goes through governance/support/privacy checks, shadow evaluation, and a default-enrolled real-user canary; a confirmed privacy violation rejects the canary. The test suite also covers conflict-aware adoption and rollback against personal overlays.

The surprising choice is that participation in the shared cohort is mandatory for synchronized accounts while canary participation defaults to enrolled but supports an explicit opt-out. That is coherent for aggregate learning coverage, but it makes consent semantics and the boundary between synchronization and contribution especially important.

## Current maturity boundary

The repository has real tests across contracts, worker security, cloud/desktop parity, sync, and evolution. Its issue tracker also exposes production-shaped problems rather than only feature requests: stale UI state, background work visibility, synchronization failures, and several approval-flow defects. In issue #23, maintainers state that the underlying protocol cannot change an approval method mid-turn and resume the existing pending request; restarting can inherit persisted conversation and tool results but cannot revive the old execution point.

So Janus’s *post-turn* evolution model is more mature than its *in-turn* continuation model. Durable state is not enough: pending authorization is part of the execution state machine.

## Relevance to Kagura

We already have human-curated behavioral evolution ([[beliefs-candidates]]) and explicit workflow governance ([[flowforge]]). Janus argues for a narrower addition rather than importing its cloud architecture: whenever automation proposes a durable behavior change, retain the input evidence, evaluation basis, decision, and a reversible version reference. We should not automatically generalize an experience merely because it was successful once.

No direct adoption: Janus is new, unspecific about licensing (`NOASSERTION` in repository metadata), and its seven-user shared-evolution model does not map to a single-user workspace. Track it for whether its approval-state continuity and explicit consent model mature.

## Sources inspected

- README and repository metadata through GitHub API, 2026-08-11.
- `cloud/test/evolution-contracts.test.mjs`, `cloud/test/evolution-worker-security.test.mjs`, and `cloud/test/stage8-evolution.test.mjs`.
- `cloud/src/modules/evolution/worker.mjs` and `stage8.mjs`.
- First 20 GitHub issues, including #23 maintainer response.
