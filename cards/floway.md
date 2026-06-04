---
title: Floway
created: 2026-06-04
tags: [infrastructure, llm, proxy]
last_verified: 2026-06-04
---

Floway is a self-hosted LLM API proxy running on VM1. It routes LLM requests from our tools to cloud providers, assuming those providers follow JSON schemas reliably. The ai-memory project's OpenAI-compat strict mode validates a concern: if Floway ever routes through local models, schema drift becomes a real issue, requiring a strict/lenient toggle.
