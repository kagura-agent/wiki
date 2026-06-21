---
title: Duplicate Issue Selection
created: 2026-06-21
last_verified: 2026-06-21
tags: [gogetajob, issue-selection, gradient]
---

# Duplicate Issue Selection

## Problem

Issue funnel re-selects issues where a PR is already open from the same author. Observed in oh-my-pi#2612 — agent selected an issue it already had an in-progress PR for.

## Pattern

Before selecting an issue, check for existing open PRs:

```bash
gh pr list --repo REPO --author=kagura-agent --state=open --search "ISSUE_NUM"
```

If results are non-empty, skip the issue.

## Implementation

**Gate 3b** in `issue-funnel.sh` — inserted between Gate 3 (closed/rejected PR check) and Gate 5 (repo exposure limit).

## Complementarity

| Gate | Catches |
|------|---------|
| Gate 3 | Re-attempts on closed/rejected PRs |
| Gate 3b | In-progress duplicates (open PRs) |
| Gate 5 | Repo exposure (too many PRs to same repo) |

## Source

Gradient from oh-my-pi#2612 incident.

## Links

- [[tracking-health-tool]]
- [[gogetajob-architecture]]
- [[issue-funnel]]
