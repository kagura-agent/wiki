---
title: Command Approval Context Gap
created: 2026-08-07
last_verified: 2026-08-07
---
# Command Approval Context Gap

A shell-command approval is not an authorization decision over the command text alone. Its actual authority is the command plus mutable execution context: scripts, configuration, dependencies, credentials, filesystem state, and network destination.

## Consequence

A familiar label such as `npm run analyze` can conceal arbitrary execution if a prior agent action changed `package.json` or an imported file. Repeatedly asking a human to reconstruct that provenance creates both false accepts (fatigue) and false rejects (workflow blockage). The [[scalex-permission-fatigue]] game data illustrates the tradeoff; it does not establish real-world attack frequency.

## Design response

Bind sensitive approvals to effective capabilities and evidence: the data scope, destination, persistence effect, and provenance of the invoked code. Pair that with sandboxing and scoped credentials, rather than attempting to make users inspect every low-level command.

This distinguishes [[action-authorization-vs-context-integrity]] in practice, operationalizes [[permission-hardening]], and requires the safe state transition properties in [[policy-gate-progress-path]]. [[Sprocket]] illustrates bounded authorization through merchant/amount payment mandates; [[FlowForge]] illustrates evidence-bearing state transitions.
