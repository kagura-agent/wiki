---
title: Obligation-Anchored Replanning
created: 2026-08-13
last_verified: 2026-08-13
tags: [governance, durable-runs, audit, retry, control-plane]
---

# Obligation-Anchored Replanning

A control plane should not let a retry or replan be a free-form "run again". It should bind the retry to a durable **obligation identity** — the specific past commitment it is answering — so the new attempt is anchored to, and accountable against, the obligation it claims to serve.

## Two separable ideas

1. **Obligation identity** — replanning reads are bound by obligation identity (`bind replan reads by obligation identity`). A retry is tied to a concrete prior obligation rather than re-deriving goals from scratch each time. This is stronger than plain idempotency: idempotency prevents a *duplicate* run, while obligation identity prevents a retry from silently *changing what it is answering*.

2. **Failure-receipt escape** — a hard enforcement gate that *can* be bypassed records a receipt when it is bypassed (LoopX's evidence-log read enforcement is "hard-only with failure receipt escape"). The point is that the bypass path is still audited: enforcement is not softened, but every exception leaves a durable record.

## Why it matters

The shift is from "gate the action" (approve/deny a bounded turn) to "bind the obligation" (anchor every continuation to a durable commitment and audit every exception). This keeps governance intact even when the gate must be bent: the audit trail survives the bypass.

## Boundary

Obligation identity is a *coordination/accountability* property, not a safety boundary on its own. It must not be read as authorizing irreversible external actions; keep it layered with [[durable-state-local-capability-spend-authority|spend/authority scoping]] and human gates for publication and production writes.

## Evidence

[[loopx]] v0.4.5 (2026-08-12) shipped `fix(control-plane): bind replan reads by obligation identity` and `feat(control-plane): make evidence-log read enforcement hard-only with failure receipt escape`, alongside a goal-artifact-lifecycle-projection RFC. Observed 2026-08-13.

## Related

- [[durable-agent-runs]]
- [[FlowForge]]
- [[loopx]]
- [[trace-gate-pattern]]
