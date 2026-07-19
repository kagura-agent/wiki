---
title: Observer Pattern (Overwrite-Injection)
created: 2026-07-19
updated: 2026-07-19
tags: [agent-architecture, context-management]
last_verified: 2026-07-19
---

# Observer Overwrite-Injection

Pattern for managing large, changing external state in agent loops. Instead of appending observations to conversation history (which explodes the context window), fresh state is injected each turn with **overwrite semantics** — the previous observation is replaced, not accumulated.

First documented in [[reverseloom]] / [[graphloom]], where browser state (DOM digest, screenshots, network activity, debugger state) is captured as `observer_message_parts` and overwritten each turn. Past observations live only in `past_steps` summaries, not as raw data.

## Applicability Beyond Browser Agents

Any agent working with large, frequently-changing external state benefits: file-system watchers, monitoring dashboards, database inspectors, CI pipeline observers. The key insight is distinguishing **current state** (overwrite) from **action history** (append).
