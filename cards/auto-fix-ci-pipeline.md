---
title: "Auto-Fix CI Pipeline"
created: 2026-05-28
updated: 2026-05-28
last_verified: 2026-05-28
---

# Auto-Fix CI Pipeline

Pattern: Use Claude Code Action (or similar LLM-powered CI) to auto-triage and auto-fix issues opened on a GitHub repo.

## How It Works

1. New issue opened → GitHub Action triggers
2. LLM reads codebase + issue → **triages first** (worth doing? aligned? small? low-risk?)
3. If triage passes → opens a PR with fix + tests
4. If triage fails → comments explaining why (too large, out of scope, unclear)
5. Human reviews and merges — LLM never pushes to main

## Why It's a Community Multiplier

- **Lowers contribution bar**: Users only need to describe a problem → LLM may auto-fix it
- **Attracts direct PRs**: When people see the project is responsive and well-maintained, they submit their own PRs too
- **Evidence**: [[ccglass]] went from 239→317⭐ in 3 days with 5+ external contributors merging features, partly driven by this pipeline

## Prerequisites for Effectiveness

- **Small, clean codebase** — LLM needs to understand the full context
- **Good test coverage** — auto-PRs run tests before submitting
- **Zero/few dependencies** — less surface area for LLM errors
- **Clear project direction** — triage prompt needs to know what's in/out of scope

## Implementation (ccglass example)

```yaml
# .github/workflows/claude.yml
on:
  issues:
    types: [opened]
steps:
  - uses: anthropics/claude-code-action@v1
    with:
      allowed_non_write_users: "*"  # Works for external users
      prompt: |
        STEP 1 — TRIAGE FIRST. Is it worth doing?
        STEP 2 — Only if triage passes, implement the fix.
      claude_args: --max-turns 25
```

Key detail: `allowed_non_write_users: "*"` + `CLAUDE_TRIGGER_PAT` (maintainer PAT) makes it work for issues from anyone, not just repo collaborators.

## Tradeoff

- LLM cost per issue (~$0.50-2.00 for triage + fix)
- Risk of low-quality auto-PRs cluttering the repo (mitigated by triage step)
- Maintainer still needs to review and merge

## See Also

- [[ccglass]] — canonical example of this pattern in production
- [[GenericAgent]] — counter-example: 12K⭐ but few external PRs merged (no auto-fix CI)
