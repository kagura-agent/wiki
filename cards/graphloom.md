---
title: graphloom
created: 2026-07-19
updated: 2026-07-19
tags: [agent-framework, browser-agents]
last_verified: 2026-07-19
---

# graphloom

Agent framework by KuiChi-x powering [[reverseloom]]. Key architectural patterns:

- **Observer pattern** — fresh external state injected each turn with overwrite semantics (see [[observer-pattern]])
- **Compaction** — context-window management via summarization
- **Skills** — modular capability registration for agent actions

Repo: [KuiChi-x/graphloom](https://github.com/KuiChi-x/graphloom)
