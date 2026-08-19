---
title: "Growth Signal vs Code Signal — Marketing-Driven Star Spikes"
created: 2026-08-18
updated: 2026-08-18
tags: [ecosystem, evaluation, growth-patterns, followup]
status: active
---

# Growth Signal vs Code Signal

Star growth measures *attention*, not *development*. The two diverge in a repeatable, predictable way: **marketing-driven star spikes** (viral HN/README/community push) happen while default-branch code goes quiet.

## Evidence (2 confirmed instances)

| Project | Star delta | Code activity | PR merge state | Verdict |
|---|---|---|---|---|
| [[pi-from-scratch]] (08-15) | 88→982 in 5d (+1000%) | unchanged ~750L | external contributor fix #1 merged (protocol boundary) | growth marketing-driven (LINUX DO + OpenModel sponsor) |
| [[nightcrawler]] (08-18) | 113→743 in 14d (+557%) | silent since 07-28 (README-only 08-03) | Dev9269 #2 closed unmerged; Srimi1 #3 open 08-07 | growth outpaces maintainer bandwidth |

## Diagnostic Signals (check in order)

1. **Star delta vs default-branch commit recency** — big delta + no recent code = spike without dev. `pushed_at` is misleading (any branch push refreshes it); check default-branch commits.
2. **PR merge state** — external PRs sitting open/unmerged for 7+ days while stars climb = maintainer overwhelmed, not healthy growth.
3. **Fork network organicity** — real forks (individuals, 0⭐) vs coordinated accounts (MAWL pattern).

## Prediction Pattern

Marketing spikes without code cool fast. Rule of thumb: **stars ≥ +50% in 7d with code silent → expect < +100% further growth by next check unless code resumes**. Log as calibration prediction.

## Relevance

- Followup tiering: don't upgrade a repo to THRIVING on stars alone; community signal = PRs merged + external issue discussion, not fork count.
- Safety angle: a regex-boundary project ([[nightcrawler]]) hitting viral audience = the known weakness gets a bigger attack surface. Elevated scrutiny, not celebration.

Links: [[pi-from-scratch]], [[nightcrawler]], [[multi-agent-workflow-lab]], [[agent-harness-landscape]]
