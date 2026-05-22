---
title: Semantic Model Routing
created: 2026-05-22
tags: [agent-infrastructure, model-routing, provider-abstraction]
last_verified: 2026-05-22
---

# Semantic Model Routing

Config-driven routing layer between an agent and multiple model backends, selecting which model handles a request based on semantic rules rather than hardcoded logic.

## Pattern

```
Agent → Semantic Router → Model A / Model B / ...
         (config-driven)    (selected by rules)
```

Key properties:
- **OpenAI-compatible transport** — router exposes standard `/v1` chat endpoint
- **Rule-based decisions** — routing config specifies conditions (modality, cost tier, reasoning need) and model cards
- **Observable** — response headers expose routing decisions (`x-vsr-selected-model`, `x-vsr-selected-reasoning`)
- **Fallback** — direct provider fallback on router failure (502/503/504/timeout)
- **Separation of concerns** — agent code doesn't change when routing policy changes

## Implementation: Elephant Agent + vLLM SR

[[elephant-agent]] PR #33 (2026-05-21) integrates vLLM Semantic Router as a provider:
- Extends `OpenAICompatibleProviderAdapter` with routing policy headers and VSR-specific metadata extraction
- Routing policy passed via `x-vsr-routing-policy` header
- Fallback creates a fresh `OpenAICompatibleProviderAdapter` with direct credentials — no router dependency
- Diagnostics surface in `elephant provider status` CLI

Issue #18 plans capability registry — typed provider capabilities (tools, streaming, context length, prefix cache) inspectable without provider-specific imports. This elevates routing from "which URL" to "which capabilities match this request."

## Relevance to OpenClaw

OpenClaw's provider abstraction already routes via `default-llm-sg` etc., but it's **static assignment** — one provider per config slot. Semantic routing would enable:
- **Cost optimization** — route simple queries to cheaper models automatically
- **Capability matching** — send tool-heavy requests to models with better tool support
- **Fallback chains** — automatic degradation when primary provider is down

The key insight: **routing rules as config, not code**. When routing logic is in YAML, operators (or agents themselves) can tune it without code changes.

## Tradeoffs

| Pro | Con |
|-----|-----|
| Decouples model selection from agent logic | Extra infra component (router service) |
| Observable routing decisions | Latency overhead (extra hop) |
| Policy changes without redeploy | Complexity for single-model setups |
| Automatic fallback | Router itself becomes SPOF (mitigated by direct fallback) |

## See Also

- [[agent-brain-portability]] — provider abstraction as portability layer
- [[elephant-agent]] — primary implementer
- [[prompt-cache-optimization]] — prefix cache awareness in routing decisions
