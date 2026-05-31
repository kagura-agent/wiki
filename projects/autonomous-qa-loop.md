# Autonomous QA Loop (MaxwellCCC)

> Source: github.com/MaxwellCCC/autonomous-qa-loop (54⭐, 05-31)
> Deep read: 2026-05-31

## Problem
AI coding agents become less effective at self-review over successive passes. Once an agent has seen prior assumptions, suspected fixes, or earlier conclusions, it keeps checking the same areas and misses different bug classes.

## Solution
Portable prompt pattern for running QA with **fresh, zero-history agents**:
1. Generate neutral prompt with strict 4-section format (Background / Goal / Review Target / Context Docs)
2. **Hard information firewall**: NO suspected bugs, intended fixes, prior conclusions, focus areas, or diagnosis
3. For broad scope: split into **module-level review packets**, send to parallel fresh agents
4. Triage combined findings in main thread → fix confirmed → fresh pass → repeat until stable

## Key Design Decisions
- **4-section hard format**: prevents sneaking bias through "Known Issues" or "Focus Areas" sections
- **Module-level parallelism**: split by subsystem, not by file — gives each reviewer enough context for architectural issues
- **Defects AND plausible concerns**: reviewers report both, with evidence and uncertainty. Main thread decides severity.
- **"Do not rewrite original requirement as implementation behavior"**: prevents the prompt from validating the implementation rather than testing it

## Comparison to Our Existing Patterns
| Concept | Our Implementation | autonomous-qa-loop |
|---|---|---|
| Fresh-context review | `fresh-context-review.sh` (adopted 05-10 from [[cwc-long-running-agents]]) | PROMPT.md template |
| Adversarial stance | [[doubt-driven-development]] CLAIM→EXTRACT→DOUBT→RECONCILE→STOP | Neutral-only (no adversarial framing) |
| Information firewall | DDD: "do not pass CLAIM, only ARTIFACT + CONTRACT" | "do not add Known Issues, Focus Areas, etc." |
| Parallelism | Not implemented | Module-level parallel packets ✨ |
| Loop termination | DDD: 3 cycles or trivial findings | "Fresh passes stop surfacing meaningful defects" |

## Delta (What's New for Us)
1. **Module-level parallel QA**: We review diffs as single units. Splitting by module and running N parallel reviewers could catch more cross-cutting issues. Applicable when reviewing large PRs or multi-file changes.
2. **Strict section format**: Our fresh-context-review.sh doesn't enforce output format. Adding a 4-section constraint could reduce reviewer drift.
3. **"Plausible concerns" category**: Our DDD classifies findings as contract-misread / actionable / trade-off / noise. Adding "plausible concern" (uncertain but worth investigating) is more permissive — might catch things we'd filter too early.

## Verdict
Mostly validates patterns we've already adopted. Module-level parallel splitting is the main new idea, but our current PR sizes don't warrant it. **No action needed now.** Revisit if we start reviewing large (>500 line) changesets.

## Community Health: 🔴 NEW (0/6)
- 0 issues, 0 external PRs, 3 days old
- Solo author, no license declared
- Track for growth signal, not contribution

Links: [[cwc-long-running-agents]], [[doubt-driven-development]], [[multi-tier-qa-strategy]], [[fresh-context-review]]
