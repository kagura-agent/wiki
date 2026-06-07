---
title: "Harness Engineering: OpenAI's Agent-First Development"
status: noted
depth: 🔬 deep
created: 2026-06-07
updated: 2026-06-07
source: https://openai.com/index/harness-engineering/
tags: [openai, codex, agent-first, coding-agent, AGENTS.md, knowledge-management]
last_verified: 2026-06-07
---

# Harness Engineering (OpenAI Blog, June 2026)

OpenAI's internal experiment: building a real product (internal beta w/ daily users) with **0 lines of manually-written code**. ~1M LOC, ~1500 PRs merged, 3.5 PRs/engineer/day, 5 months, team of 3→7 engineers.

## Key Lessons

### 1. AGENTS.md as Table of Contents, Not Encyclopedia (~100 lines)
They tried "one big AGENTS.md" and it failed:
- Context is scarce — a giant instruction file crowds out the task
- Too much guidance becomes non-guidance
- It rots instantly (stale rules)
- Hard to verify mechanically

**Solution:** Short AGENTS.md (~100 lines) as map/index, pointing to structured `docs/` directory as system of record. **Progressive disclosure**: agents start with stable entry point, navigate deeper as needed.

**Our parallel:** Our AGENTS.md + wiki/L1.md navigation index follows this exact pattern. Validates our approach.

### 2. Repository as System of Record
- Anything not in-repo "doesn't exist" to the agent
- Slack discussions, Google Docs, people's heads = invisible
- Push everything into repo-local, versioned artifacts

**Our parallel:** Our wiki/ directory serves this function. But we still have knowledge in chat threads, memory files, etc. that isn't always discoverable.

### 3. Agent Legibility > Human Legibility
- Optimize code/docs for agent understanding first
- "Boring" technologies are easier for agents (composable, stable APIs, well-represented in training data)
- Sometimes cheaper to reimplement than deal with opaque upstream

### 4. Mechanical Enforcement
- Linters and CI validate knowledge base freshness
- "Doc-gardening" agent scans for stale documentation, opens fix PRs
- Architecture invariants enforced via CI, not documented rules

**Our parallel:** We have wiki-lint.py but could go further with automated staleness detection.

### 5. Agent-to-Agent Review Loop ("Ralph Wiggum Loop")
- Codex reviews own changes locally
- Requests additional agent reviews (local + cloud)
- Responds to feedback, iterates until all reviewers satisfied
- Humans may review but aren't required to

**Connection to Tokenomics:** This review loop is exactly where 59.4% of tokens go per the Tokenomics paper. OpenAI seems to accept this cost as worthwhile for quality.

### 6. Multi-Hour Agent Runs
- Single Codex runs work for 6+ hours on complex tasks
- Often run while humans sleep
- Bootable per-worktree app instances for isolated testing

### 7. "What capability is missing?"
When something fails, the fix is never "try harder." Engineers ask: "what capability is missing, and how do we make it legible and enforceable for the agent?"

## Quantitative Results
- 1M+ lines of code, 0 human-written
- ~1500 PRs merged in 5 months
- 3.5 PRs/engineer/day (increasing with team growth)
- ~1/10th the time vs manual coding
- Started August 2025, ongoing

## Our Takeaways
1. **AGENTS.md size validation**: Our current AGENTS.md is much longer than 100 lines. Consider whether to trim or restructure with more aggressive progressive disclosure.
2. **Doc-gardening agent**: We should build automated staleness detection for wiki entries (currently manual).
3. **Repository-first knowledge**: Good confirmation of our wiki/ approach, but need to be more disciplined about pushing chat-thread decisions into wiki.
4. **Agent legibility framing**: Useful mental model — when structuring docs/code, ask "can the agent find and use this?"

## Related
- [[agents-md]] — Agent identity via markdown (related standard)
- [[tokenomics-paper]] — Quantitative backing for the review cost OpenAI is implicitly paying
- [[taco-terminal-compression]] — Addresses the input-token bloat in review loops
