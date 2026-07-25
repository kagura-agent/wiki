---
title: CodeRankEmbed
tags: [embeddings, code-search, vinv-ai]
created: 2026-07-25
last_verified: 2026-07-25
---
# CodeRankEmbed

Local embedding model (~500MB) used by [[vinv-ai]] for semantic code graph indexing. Runs entirely on-device — no API calls needed for embedding generation.

## Role in VinvAI

VinvAI indexes every function into a semantic code graph using CodeRankEmbed to produce vector representations. These embeddings power the retrieval layer behind its MCP servers (vinv-index, vinv-runtime), enabling trace-grounded context lookups by semantic similarity rather than keyword matching.
