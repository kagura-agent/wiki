# Agent Ecosystem Scout — 2026-05-24

## PR Portfolio Snapshot (30 open PRs)

### Distribution
- **External repos**: 20 PRs across 12 repos (emdash, stagehand, qwen-code ×4, multica ×2, vercel/ai, openclaw, gaia ×3, opencode, Archon, DeepTutor, opc, memex, hermes-agent, NemoClaw)
- **Own repos**: 10 PRs (cove ×5, abti ×4, memory-eval ×1)

### Status Patterns
- **QwenLM/qwen-code**: Most active review cycle. Automated `/review` via qwen3.7-max. Two APPROVED (#4461, #4459), one CHANGES_REQUESTED (#4474 round 2). Fast feedback loop — bot reviewer, but human maintainer (wenshao) controls merge.
- **4 abti PRs CONFLICTING**: All hit same root cause — `master` moved under them (3 commits: dynamic OpenRouter model list, deploy script fix, Claude Opus 4.6 reliability data). Conflicts in `agents.html`, `results.json`, `provider.test.js`. Need workloop rebase.
- **openclaw #85705**: "Real behavior proof" CI flaky — 5 failures, 3 successes in same run. Likely intermittent test, not caused by my change.
- **hermes-agent #30357**: `test` CI failing. All other checks (ruff, nix, build, e2e, windows) pass. Worth investigating if test failure is related to my `.env` quoting change.

### Observations
1. **All 20 external PRs < 3 days old** — high submission velocity this cycle. No stale PRs to ping or close.
2. **Bot reviewer pattern** (qwen-code): wenshao runs automated code review via Qwen model. Interesting precedent — maintainer delegates first-pass review to AI, preserves merge authority. Similar to [[Archon]]'s model.
3. **Own repo conflict debt**: 4 conflicting abti PRs = submitted too many PRs without merging sequentially. Pattern: when PRs touch overlapping files (test/provider.test.js), submit-and-merge one at a time.

### Actionable (for workloop)
- [ ] Rebase 4 abti PRs (sequential: #363 → #366 → #378 → #379, resolve conflicts each step)
- [ ] Address qwen-code #4474 CHANGES_REQUESTED (round 2 review)
- [ ] Investigate hermes-agent #30357 test CI failure
- [ ] Check openclaw #85705 "Real behavior proof" failure logs
