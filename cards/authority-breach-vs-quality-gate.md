---
title: "Authority Breach vs Quality Gate"
created: 2026-08-06
last_verified: 2026-08-06
tags: [agent-safety, workflow, verification]
---

# Authority Breach vs Quality Gate

A failed agent workflow has two fundamentally different classes of failure:

1. **Quality failure**: the agent’s output is missing, malformed, or disproved by an objective check. The action is still within its authority, so the system can return precise evidence to the same session and request a correction.
2. **Authority breach**: the agent changed a path or invoked an effect outside its granted boundary. The breach is already an unsafe fact; another prompt cannot undo the trust violation. Abort, record the scope, and roll back only changes the harness can prove were introduced by that agent.

## Why this distinction matters

Treating both failures as a retry loop creates a confused deputy: an agent that has already exceeded authority is given another turn with its original context and tools. Treating both as terminal wastes useful working context after a normal failed test or output-contract mismatch.

The correct control plane therefore keeps **authorization** and **quality** independent:

```text
agent action
  ├─ out of authority → deterministic rollback where safe + terminal breach
  └─ authorized
       ├─ claims/tests fail → evidence-bearing correction to same session
       └─ claims/tests pass → next deterministic transition
```

## Evidence

[[super-simple-software-factory]] implements this separation directly: its worktree snapshot/enforcement path raises a non-retriable permission breach, while its envelope gates generate violation evidence for same-session correction. [[agentic-sop-to-work]] and [[deterministic-envelope-for-small-agents]] independently support the larger principle that deterministic machinery should own the checks a model cannot safely self-certify.

## Applies to [[flowforge]] and [[openclaw]]

- Workflow conditions and output validation may yield bounded retry/fix paths.
- External sending, writes outside a declared scope, credential use, and irreversible actions need an authorization boundary—not a quality retry.
- Rollback must be conservative: never “clean up” pre-existing dirty state merely because a breach occurred.

Links: [[agent-security]], [[agent-trust-hierarchy]], [[flowforge]], [[super-simple-software-factory]], [[agentic-sop-to-work]], [[deterministic-envelope-for-small-agents]]
