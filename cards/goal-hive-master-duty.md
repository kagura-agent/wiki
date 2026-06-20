---
title: Goal Hive Master Duty
created: 2026-06-01
last_verified: 2026-06-20
---
# Goal-Hive: Master Duty

Multi-agent orchestration SOP from [[genericagent]]'s Goal Hive system, rewritten 2026-06-02 using **engineering control theory** as its grounding framework.

## Control-Theory Framing

- **J\*** = user's true value (objective function, philosophically invariant)
- **Ĵ** = Master's formalized estimate of J\* (evolves as understanding improves)
- **y** = current deliverable
- **e = J\*−y** = deviation/error

Each round: measure e, compress e, make y monotonically approach J\*.

The Ĵ≠J\* distinction names a common failure mode: agents confidently solving the wrong problem because their internal model of "what's needed" drifts from actual user intent.

## Three Iron Rules

1. Master only **decomposes** and **aggregates** — never produces artifacts directly
2. Maintain "current best accepted version" as anchor — merge only if J increases, revert if decreases — **monotonically non-decreasing quality**
3. Loop until budget exhausted, deliver current anchor (not "when done")

## Fractal Loop

探测(probe) → 设計(design) → 執行(execute) → 検査(check) → re-read SOP → next round

**Divergent phases** (probe/check): Multiple workers independently, de-correlated, cast wide net.
**Convergent phases** (design/execute): Master decides, picks one path, faithful execution.

## Check Phase Innovation (x.4)

Multi-angle independent critique:
1. User perspective trial
2. Adversarial/counterargument
3. Boundary/corner cases
4. Third-party independent review
5. **Question the goal itself** — is Ĵ drifting from J\*? Over-designed? Scope creep?

Evidence must match delivery format — code→end-to-end output, not unit stubs. "声明已完成" is not acceptance.

## Instability Detection

Signals: worker busy but J not rising / local artifacts many but overall unusable / process proof replacing user value / Master pulled into details losing global view.

Response: Stop dispatching → re-read J\* → check interface freeze → cut weakest in-flight tasks → if J stagnant for 2 rounds on a dimension, switch to the dimension furthest from passing.

## Why It Matters

Most orchestration SOPs describe *what to do*; this one explains *why each step exists* in terms of error reduction. The 111→49 line compression forced clarity. The monotonic anchor + budget-bounded delivery model prevents common agent failure modes (endless refinement, quality regression on merge).

## See also

- [[genericagent]] — source project
- [[supervisor-pattern]] — general pattern this is an instance of
- [[team-lead]] — our orchestration approach (lacks explicit quality anchoring)
- [[context-compaction]] — related to the Ĵ≠J\* drift problem in long contexts
