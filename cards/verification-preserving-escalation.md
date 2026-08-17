---
title: Verification-Preserving Escalation
created: 2026-08-17
tags: [routing, escalation, verification, cost-control, agent-harness]
last_verified: 2026-08-17
---

# Verification-Preserving Escalation

Cost-aware model/executor tiering where **escalation never bypasses the verification step**. Extracted from LongHorizon-Harness PR #29 (external contributor saikethan27, 208 tests). The cheapest known-good configuration runs first; a struggling stretch temporarily upgrades to the strong tier, and the strong result goes through the *same* auditor as the cheap one. A passing audit clears the escalation and routing snaps back to cheap — the expensive model is scoped to exactly the rounds that are stuck.

## Core design decisions

1. **Tier orthogonal to type.** `cheap`/`strong` (model cost) is a separate dimension from `gui`/`cli` (execution type). All four combinations expressible without duplicating executor implementation. Resolution: named tier > type-level section > fallback chain.
2. **Escalation returns.** Not a permanent upgrade — a verified pass resets to the default tier. Cost exposure is bounded to the stuck stretch.
3. **Failure taxonomy is the whole game.** The naive version escalated on round 1 of every task because it counted `incomplete + clean + aligned` (ordinary mid-run progress) as failure. The corrected taxonomy:
   - `blocked` / `suspect` / `needs_revision` / errored episode → counts toward `escalate_after_failures` (round actually went wrong)
   - consecutive clean rounds naming the *same* unclosed gap → `escalate_after_stalled_rounds` (cheap tier is spinning)
   - `incomplete` + clean + aligned with a **new** gap each round → ordinary progress, NOT failure
   Lesson: *what counts as a trigger matters more than the trigger mechanism.*
4. **Trust-labeled escalation briefing.** Episodes are one-shot (no resumable session across a backend swap), so the escalated executor is briefed with the prior attempt **labelled as that executor's own unaudited claim**, while the auditor report is labelled authoritative — same trust boundary drawn by the base manager protocol. Bounded to 3 most recent failures, char-clipped, disable-able.
5. **Deliberately JSON-free control protocol.** Manager emits plain-language lines (`Next: cli` / `Executor tier: cheap`), never JSON — same convention as [[Lobster0]]'s exact-argv boundary and [[MAWL]]'s rules-over-LLM-judge.

## Related

- [[smart-routing]] / [[semantic-model-routing]] — routing as model selection; this card adds the verification-preserving + return-to-cheap lifecycle.
- [[delegating-executor-pattern]] — delegation structure; escalation is the dynamic half.
- [[agent-budget-control]] — cost as a first-class constraint.
- [[tiered-processing-collapse]] — the anti-pattern: tiering that degrades guarantees as cost drops.

## Applicability to our stack

- [[FlowForge]] branch logic: cheap default model + escalate-on-struggle + verified return, guarded by the failure-taxonomy rule to prevent spurious escalation.
- [[study-saturation]] gate: its skip accounting is itself a failure/status taxonomy — same shape.
- Subagent handoffs: trust-labeled briefings (unaudited claim vs authoritative audit) could formalize escalation between cheap/strong subagents.

## Falsifiable checks

- Does the failure taxonomy actually prevent spurious escalation in a 2-tier FlowForge setup? (Test: run N normal rounds, assert zero escalations.)
- Does return-to-cheap survive noisy verification? (Auditor flakiness would pin the system in strong tier — the sticky-until-pass design assumes auditor reliability.)
