---
title: "LoopX — local-first control plane for long-running agents"
created: 2026-08-09
last_verified: 2026-08-13
tags: [agent-harness, control-plane, durable-runs, loop-engineering, local-first]
---

# LoopX (huangruiteng/loopx)

**Repository:** https://github.com/huangruiteng/loopx

**Observed 2026-08-09:** 3,608 stars; Python; MIT; default branch `main`.

LoopX is a provider-neutral, local-first state kernel for long-running agent work. It keeps the durable control state—objective, scope, user gates, todos, claims, evidence, handoffs, and quota—separate from the agent runtime that performs a bounded turn.

## Core model

The kernel decides whether a registered agent may act and records validated progress afterward. A typical slice is:

1. inspect whether quota permits another turn;
2. claim a concrete todo with a lease;
3. let a host runtime perform one bounded action;
4. write evidence and a handoff; and
5. account for the completed, validated slice before scheduling the next one.

This is a control plane rather than an autonomous runtime: LoopX does not grant credentials, approve destructive actions, or replace human gates for publication and production writes. Its local state is intentionally not committed to the project repository.

## Relevance

LoopX makes several properties of [[durable-agent-runs]] explicit: durable objective state, claims and leases, evidence-backed handoff, and recovery across bounded turns. Its quota-aware continuation provides a more governed version of a recurring loop: an eligible next tick must still respect a specific user gate, safe fallback, and stopping condition.

The design complements [[FlowForge]]'s workflow topology. FlowForge models workflow transitions; LoopX focuses on the persistent control state that tells a runtime which concrete slice is safe and useful to execute next.

## Evidence and limits

- README and repository metadata inspected 2026-08-09.
- The project describes public and owner-run long-lived examples, but those examples are not independent evidence that LoopX is safe for unattended production control.
- Support boundaries remain explicit: several host integrations and advanced paths are optional, default-off, or experimental.

## Related

- [[sprocket]]
- [[durable-agent-runs]]
- [[FlowForge]]
- [[loop-engineering]]

## Followup 2026-08-13

- **Growth:** 3,608 → 4,399⭐ (+22% since 08-09; +112% since 08-06 NEW), 376 forks, 24 open issues. THRIVING 6/6: 51 external PRs/30d, 18 unique issue authors, 5 merged-PR authors.
- **v0.4.5 shipped 08-12.** Recent control-plane commits concentrate on *hardening*, not new features: reject shell metacharacters in worker commands, validate goal_id to block path traversal in reward routes, drop `ACAO:*` on unauthenticated read responses, and make evidence-log read enforcement **hard-only with a failure-receipt escape**.
- **New RFC: goal artifact lifecycle projection v0** + replan reads bound by **"obligation identity"** (`fix(control-plane): bind replan reads by obligation identity`). The kernel is starting to model the *lifecycle of goal artifacts* and tie replanning to a durable obligation, not a free-form retry.

### Insight: governance is moving from "gate the action" to "bind the obligation"

The early LoopX model was a bounded-turn control plane (claim → act → evidence → handoff). The 08-12 work adds a second layer: durable *obligation identity* that replanning must bind against, and *hard-only* evidence-read enforcement with a failure-receipt escape. That mirrors the [[FlowForge]] distinction between workflow topology (transitions) and durable control state (what is safe to execute next) — but now with an explicit notion of *which past obligation a retry is anchored to*. Counterintuitive detail: the failure-receipt escape means the hard gate still records *when* it is bypassed, preserving audit even on the bypass path. This is directly relevant to our [[durable-agent-runs]] and DNA-governance mainline: retries should be anchored to an obligation, and enforcement bypasses should leave a receipt.
