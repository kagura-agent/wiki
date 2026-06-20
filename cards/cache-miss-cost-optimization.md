---
title: Cache Miss Cost Optimization
created: 2026-06-03
tags: [concept, cost, architecture]
last_verified: 2026-06-20
---
# Cache-Miss Cost Optimization

Pattern for reducing LLM API costs by minimizing cache-miss input tokens, especially relevant with providers that charge differently for cache hits vs misses (DeepSeek V4: 50x price difference).

## The Problem

Agent systems mix stable content (system prompt, behavior rules) with dynamic content (recent history, tool results, timestamps) in the same prompt prefix. When dynamic content changes position or content, everything after it becomes a cache miss — even if the stable instructions haven't changed.

Quantified by [[nanobot]] community (issue #4142):
- Cache-hit tokens: 64.8M → $0.18 (negligible)
- Cache-miss tokens: 12.7M → $1.77 (dominant cost)
- **78% of total cost from 16% of token volume**

## Optimization Principles

1. **Stable prefix, dynamic suffix** — keep immutable system instructions at the start, push all dynamic context (time, memory, history) after them. Provider-side KV cache hits on the stable prefix.

2. **Aggressive tool result compaction** — old tool results in conversation history are always cache-miss tokens. Compact/summarize them eagerly, not just when context window is full.

3. **Reasoning token stripping** — persisted reasoning/thinking tokens are volatile (change every turn) and replay as miss tokens. Strip them from history.

4. **Proactive history budget** — don't wait until hitting context limit to consolidate. Set a lower target specifically for cache-miss cost reduction.

5. **Time injection placement** — `current_time` in system prompt invalidates the entire system message cache every turn. Move to user message or dynamic section.

## Relevance to OpenClaw

OpenClaw's system prompt includes dynamic elements (runtime info, model identity, time). The stable/dynamic split principle applies. Cron-based isolated sessions are less affected (short-lived, no history accumulation), but main sessions with long histories face the same pattern.

## Links

- [[nanobot]] — source of quantified data
- [[context-compaction]] — related: when and how to shrink context
- [[dream-single-phase-consolidation]] — Dream uses ephemeral sessions, avoiding cache-miss accumulation
