---
title: Premature Conclusion
created: 2026-06-07
tags: [debugging, cognitive-bias, agent-reliability]
last_verified: 2026-06-07
---

# Premature Conclusion

**Anti-pattern**: Declaring a root cause or verdict the moment a hypothesis "clicks" — before designing a controlled experiment to verify it.

> "Found it!" is a warning sign, not a conclusion. The more certain you feel about a root cause, the less you've verified it.

## Why It's Dangerous

1. **Commits you to the wrong path** — follow-on work builds on a false premise
2. **Makes the real cause harder to find** — confirmation bias filters out contradicting evidence
3. **Five confident wrong diagnoses cost more than one careful right one**

## Mitigation

- When a hypothesis clicks and you want to announce "root cause confirmed" — that's the moment to design a controlled experiment
- Change one variable, hold everything else constant, observe whether the outcome changes
- Return "insufficient evidence" rather than false negative when you can't verify

## Related

- [[invariant-gated-verdict]] — specific case where disabling a guard invalidates the verdict
- [[evidence-driven-rca]] — structured approach to root cause analysis
