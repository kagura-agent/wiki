---
title: Observation Without Investigation
created: 2026-05-28
source: beliefs-candidates.md (2026-05-28 gradient), Luna correction
tags: [anti-pattern, debugging, discipline]
links: [[dreaming-observation]], [[self-evolving-observations]], [[verify-before-researching]]
last_verified: 2026-06-17
---

## Pattern

Flagging an issue repeatedly without investigating source code is performative observation. Noting "still broken, no progress" for days while never reading the code that causes the behavior is cargo-cult debugging.

Day-1 response to persistent unexplained behavior: read the source code. Uniform outputs trace to hardcoded inputs.

## Trigger

When an issue stays open for 3+ days with repeated "still open, no progress" notes:
- You have observed the symptom multiple times
- You have not read the relevant source code
- The behavior remains unexplained

## Day-1 Action

1. **Find the code path** — grep for the symptom, trace to the source
2. **Read the implementation** — don't theorize about what it might do
3. **Check for hardcoded values** — uniform outputs (e.g., same confidence score every time) usually mean hardcoded inputs
4. **File or fix** — upstream issue if external, structural fix if internal

## Anti-pattern Example

- Day 1: "dreaming confidence scores are all 0.58, seems wrong"
- Day 2: "still 0.58, no progress"
- Day 3: "decided to investigate but not acted"
- Day 4: finally read `dreaming.ts`, found hardcoded confidence value

The fix took 10 minutes. The delay cost 4 days.

## Evidence

- [[dreaming-observation]] line 145: 4 days of "decided but not acted" broke by actually writing the code
- [[self-evolving-observations]]: gradient from 2026-05-28 Luna correction

## Related

- [[verify-before-researching]] — same principle applied to capability assumptions
- [[structural-fix-over-behavioral-rule]] — what to do after you find the root cause
