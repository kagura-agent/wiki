---
title: Durable Agent Runs
created: 2026-08-07
last_verified: 2026-08-08
tags: [agent-architecture, durable-runs, recovery, coordination]
---

# Durable Agent Runs

A durable agent run is a recoverable coordination record, not merely a UI that can reconnect. It preserves enough ordered state for a replacement executor to safely continue or reject stale work after a browser, client, or worker interruption.

## Required properties

- **Stable run identity and idempotency** prevent a retried submit from creating a second logical run.
- **Leases or claims with expiry** ensure a disconnected executor eventually loses authority and a successor does not race it indefinitely.
- **Monotonic completion sequencing** stops delayed output from an old attempt overwriting a newer result.
- **Persisted evidence** makes recovery and audit possible without treating an interface session as the source of truth.

## Boundary

Durability is only a coordination property. It must not restore broad host access or authority for irreversible external actions. Keep [[durable-state-local-capability-spend-authority|durable coordination state]], host-local capabilities, and spend authorization independently scoped.

## Evidence

[[sprocket]] implements these mechanics with an idempotency key, renewable executor claim leases, and completion attempt sequence numbers, covered by run-creation and lease tests inspected on 2026-08-06. Its browser session can be recovered separately from the local executor capability.

## Related

- [[sprocket]]
- [[FlowForge]]
- [[durable-state-local-capability-spend-authority]]
- [[agent-security]]
