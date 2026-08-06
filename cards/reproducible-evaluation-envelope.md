---
title: Reproducible Evaluation Envelope
created: 2026-08-06
tags: [evaluation, verification, reproducibility, agent-harness]
last_verified: 2026-08-06
---

# Reproducible Evaluation Envelope

A benchmark result is independently inspectable only when it carries an **evaluation envelope**: the exact task/environment version, resolved runtime configuration, agent trajectory, output artifacts, verifier implementation and result, and the immutable references that bind those pieces together.

[[RealReplicaBench]] demonstrates the useful half of this pattern: every task runs in a pinned container with stateful mock services and task-specific verification, while its runner preserves configuration, trajectories, artifacts, logs, and container metadata. Its current reference leaderboard is still weaker than its execution protocol: raw task-level bundles lack public immutable URLs/checksums, so the public table is an audited aggregate rather than a fully replayable claim.

## Design rule

**Separate execution reproducibility from result reproducibility.** A public Docker image and verifier make a rerun possible; they do not prove that a published aggregate came from those exact inputs unless the result bundle is versioned, available, and content-addressed.

This extends [[graded-agent-guardrails]]: deterministic checks can make a single task outcome strong, but a benchmark-level claim also needs provenance connecting the check to the reported population. It complements [[LongHorizon-Harness]], where auditor-approved state is the trusted handoff boundary; here the envelope is the trusted boundary between an evaluated run and an external score claim.

## Applies when

Use this for agent benchmarks, workflow experiments, or any before/after performance assertion. Minimum viable envelope:

1. immutable task/environment identifier;
2. resolved config with credentials redacted;
3. trajectory and produced artifacts;
4. verifier version plus structured result;
5. manifest/checksum tying the bundle to the reported aggregate.

Without all five, describe the outcome as a managed or audited evaluation, not as independently reproduced evidence.
