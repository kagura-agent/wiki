---
title: Prompt Cache Engineering
created: 2026-07-04
tags: [prompt-cache, llm, cost-optimization, agent-harness]
last_verified: 2026-07-04
---

# Prompt Cache Engineering

Techniques for maximizing LLM prompt cache hit rates. A cache hit typically costs ~0.1x the price of a cache miss, so a 50-turn agent task with a 95% hit rate costs roughly 7x less than one with no caching. For harnesses running long sessions, cache discipline is a primary cost lever.

## Core Disciplines (learn-agent s07)

1. **System prompt byte-stable across turns.** Move all time-varying data (current date, git status, session state) to the tail of the system prompt. The cache prefix matches from the first byte; any mid-prompt change invalidates everything after it.

2. **Tools array order-stable.** No runtime sorting, conditional adding, or removing of tools between turns. The tools array is part of the cached prefix. Progressive tool disclosure (revealing tools as the agent advances) must append to the end, never reorder or remove earlier entries.

3. **Messages append-only.** Never modify, rewrite, or reorder previous messages in the conversation history. Compaction strategies must preserve the byte-identical prefix of earlier turns.

## Regression Testing

Assert that the system prompt is byte-identical regardless of volatile state (time, working directory, git branch). A single changed character in the prefix voids the cache for everything downstream. Treat prefix stability as a CI-level invariant.

## Links

[[coding-agent-ecosystem]], [[agent-harness-landscape]]
