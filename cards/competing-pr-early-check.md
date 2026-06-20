---
title: Competing PR Early Check
created: 2026-06-20
source: hermes PR race incidents
tags: [oss-contribution, workflow]
last_verified: 2026-06-20
---
# Competing PR Early Check

**Pattern**: Before investing implementation time on a GitHub issue, check whether competing PRs already exist or are in progress.

## Why

High-star repos with detailed community RCA comments attract fast submitters. The window between study and implementation can be hours — enough for someone else to submit a fix first.

## Mechanism

Gate check at the start of the implement phase (not just at issue selection):
- Search open PRs mentioning the issue number
- If a competing PR exists → bail immediately, move to next issue
- Avoids wasting a full implementation cycle on work that will be superseded

## Lesson

Time between study→implement is the danger zone. A check only at issue-selection time misses PRs that appear during the study/planning phase.

## See Also

- [[pr-superseded-lessons]] — post-mortem patterns from superseded PRs
- [[oss-contribution-discipline]] — broader contribution workflow
