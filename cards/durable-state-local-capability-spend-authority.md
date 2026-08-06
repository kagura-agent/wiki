---
title: Durable State, Local Capability, and Spend Authority
created: 2026-08-06
last_verified: 2026-08-06
tags: [agent-architecture, authority, durable-runs, payments, computer-use]
---

# Durable State, Local Capability, and Spend Authority

A long-running agent should not treat all “permission to continue” as one token. [[sprocket]] demonstrates a useful three-object model:

1. **Durable coordination state** — a cloud-visible run record, transcript, claim lease, and idempotency key. It survives a browser or process interruption and supports audit/recovery.
2. **Host-local execution capability** — a narrow, random, run-scoped credential held by the local executor. It authorizes a particular process to act on a particular host without putting machine paths or general filesystem authority in cloud state.
3. **Spend authority** — a separately approved, amount/merchant-bounded mandate. User confirmation in a conversation is insufficient; payment needs a durable authorization object confirmed out-of-band.

## Why the separation matters

These objects have different lifetimes and failure modes. A stale executor must lose its run claim without erasing the transcript; a restored browser should not automatically regain local machine authority; a valid work-run capability should never imply permission to spend. Combining them produces confusing recovery semantics and expands the blast radius of a leaked credential.

For [[FlowForge]], durable workflow transitions and evidence belong to coordination state. External actions should retain independent authorization gates, especially where actions are financial or irreversible. This refines the authority-versus-quality distinction in [[agent-security]] and complements [[durable-agent-runs]].

## Design check

When adding a resumable action, identify explicitly:

- What must survive restart and be inspectable by a coordinator?
- What must remain local to the host and expire with the worker/run?
- What needs fresh human or bounded third-party authorization before execution?

If one token answers all three, the design has likely merged incompatible authorities.

## Sources

- [[sprocket]] — inspected architecture, tests, and payment/UCP implementation, 2026-08-06
- [[FlowForge]]
- [[agent-security]]
- [[durable-agent-runs]]
