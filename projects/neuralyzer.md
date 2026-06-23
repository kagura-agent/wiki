---
title: "Neuralyzer — Agent Self-Context-Wipe Tool"
slug: neuralyzer
status: skim
created: 2026-06-23
updated: 2026-06-23
stars: 58
repo: gintasz/neuralyzer
tags: [loop-engineering, context-management, agent-harness]
last_verified: 2026-06-23
---

# Neuralyzer

> Agent harness tool that lets the agent wipe its own session context and restart from the initial prompt. "Men in Black" style.

**Repo**: [gintasz/neuralyzer](https://github.com/gintasz/neuralyzer) | 58⭐ (4d, 06-19) | TypeScript | MIT

## Concept

Traditional loops (`while :; do cat PROMPT.md | pi -p ; done`) keep the loop controller outside the agent. Neuralyzer gives it back: the agent can call `neuralyzer` tool (no args) to wipe all user/assistant messages and re-send the initial prompt.

Key advantage over `/loop`: context doesn't accumulate (no context rot, no token cost growth).

## Example Use
```
Check if @john has submitted a PR fixing auth bug.
If yes → comment "Thank you"
If no → wait 5 min and call neuralyzer
```

## Support
- Pi: `pi install npm:@gintasz/pi-neuralyzer`
- OpenCode: `opencode plugin @gintasz/opencode-neuralyzer`
- Claude Code: **NOT POSSIBLE** (no extension surface for mid-session context manipulation as of June 2026)

## Key Insight

> Loop control is shifting from external orchestration to agent self-orchestration. The agent decides when to reset, not the shell script.

Related: [[ralph-loop-runner]] (external loop), [[code-duo]] (loop quality monitoring), [[openloop-thu]] (loop engineering framework)
