---
title: Multi-Model Review
created: 2026-06-23
last_verified: 2026-06-23
type: card
tags: [pattern, code-review, llm-ensemble]
---

# Multi-Model Review

Send the same artifact to multiple LLMs for independent review, then consolidate findings. Reduces single-model blind spots by exploiting the fact that different models fail in different ways.

## How It Works

1. **Fan-out** — distribute the artifact (code, spec, plan) to N independent models
2. **Independent review** — each model reviews without seeing others' output
3. **Consolidate** — merge findings, weighting by confidence and cross-agreement
4. **Act** — address issues flagged by 2+ models with higher priority; single-model flags get human triage

## Why It Works

Each LLM has systematic blind spots shaped by its training data and RLHF. A bug that Claude misses, GPT may catch (and vice versa). Independent review prevents groupthink — unlike a single model reviewing twice, different models bring genuinely different priors.

## Examples

- **Our code-review skill**: 3 models (GPT-5.5, Claude Opus 4.7, Gemini 2.5 Pro) review independently
- **Spec-review skill**: same multi-model fan-out for design documents
- **Code-Duo project**: two agents cross-review each other's implementation in real-time

## Trade-offs

- **Cost**: N models = N x inference cost per review
- **Latency**: mitigated by parallel fan-out
- **Noise**: more reviewers = more false positives; consolidation logic matters

## Related

- [[code-duo]] — validates this pattern via two-agent cross-review
- [[code-review-lessons]] — lessons from single-model review limitations
- [[immutable-evaluation]] — reviews must be independent to be meaningful
