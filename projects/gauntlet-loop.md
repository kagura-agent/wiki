---
title: "Gauntlet Loop — Bar-Driven Builder/Critic Prompt Skill"
created: 2026-08-07
status: nascent
revisit: 2026-08-21
stars: 104
repo: robonuggets/gauntlet-loop
last_verified: 2026-08-07
---

# Gauntlet Loop

A CC-BY-4.0 Claude skill that turns a user goal into a short prompt for a fresh agent session. Its core claim is that agent quality fails without an external, concrete quality bar: a named, fetchable, comparable reference artifact.

## Evidence checked

- Repository state on 2026-08-07: **104 stars, 13 forks, 0 issues**, two commits, last push 2026-08-05.
- The repository contains only `README.md`, a banner, and `.claude/skills/gauntlet-loop/SKILL.md`; there are **no tests or executable implementation** to validate its effectiveness.
- The complete runtime mechanism is prompt scaffolding: choose a bar, fan out a builder and fresh-context critic, compare outputs blind, and repeat until the critic selects the new work or the user stops it.

## Architecture and trade-offs

The useful design is not generic multi-agent orchestration; it is the **comparison contract**:

1. A bar must be named, fetchable, and comparable, otherwise the critic is instructed to reject it rather than invent an evaluation.
2. A critic gets a binary blind choice plus one largest gap, avoiding self-written numerical rubrics that drift toward approval.
3. The builder and critic are separate contexts, which lowers self-review bias.
4. The stop condition is intentionally unbounded (win or human stop), prioritizing quality over predictable cost and latency.

The last point is also its major operational weakness. “Loop until it wins” does not establish an independent ground-truth verifier, budget, timeout, or anti-sycophancy check. A prompt-only critic can still falsely declare a win; an inaccessible reference makes the comparison unverifiable. The skill says to avoid those failures, but cannot enforce the checks.

## Position in the ecosystem

Gauntlet Loop is a very small, Claude-specific packaging of the evaluator pattern, rather than a durable harness. It sits below systems such as [[FlowForge]] or [[scholar-loop]]: it supplies a one-shot prompt pattern, whereas they can encode state, gates, artifacts, and evidence across runs. Its insistence on an external bar complements [[closed-loop-vs-open-pipe]]: feedback only closes a loop when it is actually consumed, though here the feedback source remains another model rather than a deterministic verifier.

## Relevance to our work

The transferable piece is the **named evidence baseline**. FlowForge review nodes could ask for an issue reproduction, upstream test, or prior artifact that a separate checker can inspect; that is stronger than a builder’s self-reported success. We should not adopt the unbounded loop or “blind” comparison as-is: our execution must retain explicit cost/time limits and independently failable verification, as in [[scholar-loop]]’s frozen scoring model.

## Assessment

Novel as a concise interaction pattern, but not yet a demonstrated tool: no test suite, no issue discussion, only two initial commits, and no evidence that its claimed loop reliably improves outputs. Track lightly for adoption or a concrete implementation with independently verifiable evaluator outputs.

## Links

[[agent-harness-landscape]], [[closed-loop-vs-open-pipe]], [[scholar-loop]], [[FlowForge]], [[predict-then-verify-calibration]]
