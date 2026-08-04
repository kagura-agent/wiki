---
title: Policy Gates Need a Progress Path
created: 2026-08-04
last_verified: 2026-08-04
---
# Policy Gates Need a Progress Path

A policy that blocks an action until a prerequisite is satisfied must explicitly allow the smallest safe mechanism that can satisfy that prerequisite. Otherwise the gate can self-deadlock.

## Pattern

```text
risk gate blocks action Y until prerequisite X
       ↓
mechanism for X is evaluated by the same gate
       ↓
if it is blocked too: no state transition can satisfy the policy
```

The escape must be **narrow and testable**—not a broad safety bypass. Examples:

- permit local state inspection/recording while a circuit breaker blocks side-effecting tools;
- permit the evaluator-delegation call when a high-risk Loop requires independent review;
- skip-and-audit unattended high-risk work rather than request an approval that cannot arrive.

## Design Checklist

1. State the prerequisite and the exact tool/action that establishes it.
2. Test the blocked state with that action; prove it can progress.
3. Preserve non-bypassable hardlines: recovery permission is not authority to perform the risky action.
4. Add regression tests from every real deadlock or lockout.

## Evidence

[[phoenix-hermes-plugin]] records a `todo` / `delegate_task` / `terminal` Loop deadlock and implements narrowly scoped exceptions. [[flowforge]] likewise depends on routable branch transitions; a gate that requires an unavailable branch action is operationally equivalent to a deadlock.

## Related

[[tool-execution-policy-enforcement]], [[agent-security]], [[flowforge]], [[phoenix-hermes-plugin]]
