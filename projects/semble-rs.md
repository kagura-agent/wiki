---
title: "semble_rs — Agent-Native Code Search in Rust"
created: 2026-05-23
status: noted
tags: [code-search, rust, token-optimization, agent-tooling, build-compression]
stars: 101
repo: johunsang/semble_rs
last_verified: 2026-05-23
---

# semble_rs — Agent-Native Code Search in Rust

> "Hybrid BM25 + semantic, Tree-sitter AST chunking, dependency & impact analysis."

**Repo**: [johunsang/semble_rs](https://github.com/johunsang/semble_rs) | 101⭐ (2026-05-23, created 05-12) | Rust | No license yet

## What It Is

Single-binary code search CLI designed specifically for AI coding agents. Replaces grep/cat/read/ls with token-efficient alternatives. Three main features:

1. **Hybrid search** — BM25 + Model2Vec static embeddings fused with RRF, code-aware reranking
2. **Tree command** — Token-cheap codebase overview (4×–747× compression vs ls -R)
3. **Digest** — Build/CI output compression (up to -98.9% on GitHub Actions logs)

## Relevance

The `digest` feature overlaps with our TACO-inspired `compress-output.sh` script. semble_rs's approach is more comprehensive (auto-detects cargo, npm, pytest, go test, etc.) but requires a Rust binary. Our shell script is lighter but less capable.

The hybrid search could be interesting for our wiki search if it ever outgrows memex.

**Not tracking** — useful tool but not in our core direction. Note for tooling reference.

See also: [[worktree-convergence-2026-05]]
