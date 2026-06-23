---
title: Trace-Gate Pattern
created: 2026-06-23
last_verified: 2026-06-23
type: card
tags: [pattern, verification, trust]
---

# Trace-Gate Pattern

A verification gate that requires evidence of real side-effects before accepting a claim as true. Instead of trusting an agent's assertion ("I wrote the file"), trace the claimed output back to actual state changes ("show me the diff").

## Core Principle

```
claim → trace to state change → evidence found? → accept/reject
```

The gate blocks progression until the trace succeeds. No evidence = no credit.

## Examples

- **Filesystem verification**: agent claims it wrote code → check `git diff` or file mtime → accept only if changes exist on disk
- **API calls**: agent claims it sent a request → check access logs or response artifacts
- **Deployments**: CI claims deploy succeeded → verify the new version responds at the endpoint
- **Database migrations**: tool claims migration ran → query the schema for the expected column

## Why This Matters

LLM agents hallucinate actions as readily as facts. An agent can produce confident natural-language claims about work it never performed. The trace-gate pattern treats every claim as unverified until corroborated by observable state change.

## Design Guidelines

1. **Automate the trace** — manual verification doesn't scale
2. **Gate early** — catch phantom work before downstream steps depend on it
3. **Fail loud** — a failed trace is a hard stop, not a warning

## Related

- [[code-duo]] — applies trace-gate to filesystem operations between paired agents
- [[mechanical-verification]] — overlapping principle: metrics must be machine-checkable
- [[deploy-without-verify]] — anti-pattern: skipping the gate
