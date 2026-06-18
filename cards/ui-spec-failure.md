---
created: 2026-06-18
tags: [pattern, anti-pattern, ui, specification, recidivism]
status: insight
last_verified: 2026-06-18
---

# UI Spec Failure

> Complex UI interaction features — precise timing, scroll behavior, animations, visual state transitions — cannot be adequately specified through pure text specs.

## The Pattern

Text specs fail for UI interactions because they can't capture temporal/visual behavior precisely enough. Each fix introduces new bugs because the implementer interprets ambiguous prose differently than the spec author intended.

**Signature**: multiple rounds of fixes where each fix breaks something the spec didn't explicitly describe. The spec is technically correct but practically insufficient.

## Origin

Cove plugin issue #274 (unread indicator): 7 rounds of fixes, each introducing new regressions. The spec described the *what* correctly but couldn't capture the *how* — precise timing of state transitions, scroll position thresholds, animation sequencing. This was a 4-day recidivism loop.

## The Gradient

When a UI feature involves complex timing or visual behavior:

1. **Require screen recording** + step-by-step annotated expected behavior (preferred)
2. **Decompose to single behavioral changes** verified one PR at a time — each PR changes exactly one observable behavior
3. **Never accept pure text specs** for features involving timing, scroll, animation, or visual state transitions

## Relationship to Other Patterns

- Identified and analyzed in [[why-was-fable-banned]] as a recidivism pattern
- Instance of [[structural-fix-over-behavioral-rule]] — decomposing to single-behavior PRs is the structural fix; "write better specs" is the behavioral rule that doesn't work
- Led to grade-scaling calibration: repeated spec-interpretation failures at this complexity level informed how agent capability is assessed

Links: [[why-was-fable-banned]], [[structural-fix-over-behavioral-rule]]
