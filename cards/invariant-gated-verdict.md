---
title: Invariant-Gated Verdict Downgrade
created: 2026-06-07
source: ironcurtain PR #281
tags: [agent-reliability, self-assessment, testing-patterns]
last_verified: 2026-06-07
---

# Invariant-Gated Verdict Downgrade

**Pattern**: When an agent disables a safety invariant (lock, guard, sanitizer, upstream check) to reach a code path under test, it cannot then cite that same invariant as proof the bug doesn't fire. This is circular reasoning — disabling the invariant to reach the site and then citing it as mitigation.

**Detection**: An agent's "mitigated" or "safe" verdict references a mechanism that was disabled/bypassed during the test that produced the verdict.

**Resolution**: Either:
1. Re-run under a configuration where the invariant is present AND show the effect is absorbed
2. If no invariant-present config can be built that still reaches the site, keep the hypothesis open — do NOT mark it as terminal
3. Return "insufficient evidence" rather than false negative

## Generalization Beyond Security Testing

This pattern applies to any agent workflow where agents self-evaluate results:

| Domain | Invariant | Circular Claim |
|--------|-----------|----------------|
| **Security fuzzing** | Sanitizer abort | "Bug is mitigated" (but abort prevented reaching the sink) |
| **Agent task completion** | Modified success criteria | "Task complete" (but criteria were weakened) |
| **CI/CD** | Skipped test | "All tests pass" (but relevant test was disabled) |
| **Code review** | Suppressed warning | "No warnings" (but linter rule was turned off) |

## Key Insight

The deeper principle is **evaluation context integrity**: an agent cannot modify its own evaluation context and then use the modified context to certify its work. The evaluator must be independent of the evaluated.

## Related
- [[premature-conclusion]] — "Found it!" before verification
- [[abort-masks-sink]] — specific instance where sanitizer abort prevents downstream bug discovery
- [[harness-engineering-openai]] — agent-to-agent review as an evaluation integrity mechanism
