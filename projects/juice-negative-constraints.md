---
title: "Juice — Negative-Constraint Memory Layer"
created: 2026-05-23
status: noted
tags: [memory, negative-constraints, mcp-server, agent-infrastructure]
stars: 29
repo: alvinunreal/juice
last_verified: 2026-05-23
---

# Juice — Negative-Constraint Memory Layer

> "Teach agents what to avoid repeating — without dumping memory into every prompt."

**Repo**: [alvinunreal/juice](https://github.com/alvinunreal/juice) | 29⭐ (2026-05-23) | TypeScript | Early preview

## Core Idea

An MCP server that stores *only* negative constraints — things an AI agent should not do again. Positive preferences and "always do this" instructions are **rejected** unless convertible to a clear avoided alternative.

This is a focused subset of what our [[beliefs-upgrade-mechanism]] does. Our beliefs-candidates.md captures both positive and negative patterns, but Juice argues that negative constraints are the high-value subset.

## Design

- Scoped: global / project / repo / agent
- Lazy injection: only matching constraints fetched per task (not dumped into every prompt)
- Tiny manifest: agents can check relevance before pulling constraints
- MCP-native: works with any MCP client

## Relevance

The "negative-only" stance is interesting. In practice, our highest-impact beliefs-candidates entries are often negative ("don't estimate data", "don't skip retrieval", "repeating the same mistake is the worst kind of failure"). Whether the positive ones add less value is an empirical question.

Too small/early to track. Note the pattern.

See also: [[beliefs-upgrade-mechanism]], [[claude-soul]], [[piia-engram]]
