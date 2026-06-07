---
tags: [tooling, token-efficiency, taco, compression]
created: 2026-06-07
last_verified: 2026-06-07
---

# compress-output

**Tool**: `compress-output.sh` — TACO-inspired terminal output compression for reducing input token consumption in agentic workflows.

## What It Does

Applies regex-based compression to terminal/tool output before it enters the context window. Strips redundant whitespace, repeated log prefixes, verbose stack traces, and other patterns that consume tokens without adding information.

**Reduction**: 71-84% token savings on typical terminal output (build logs, test results, git diffs).

## Why It Matters

Per the [[tokenomics-paper]], input tokens account for 53.9% of total token usage in multi-agent SE systems — a ~2:1 ratio of input to output. Compressing intermediate outputs has outsized impact because:

1. Every compressed output becomes a cheaper input in the next agent turn
2. Review loops (59.4% of total cost) are input-heavy (51.4% input tokens)
3. Smaller context = better reasoning quality + lower cost

## Mechanism

Pure regex — no LLM calls, no AST parsing. Runs as a shell filter, composable with any tool output. The simplicity is the point: compression must cost less than what it saves.

## Related

- [[taco-context-compression]] — the broader TACO project this tool is part of
- [[tokenomics-paper]] — quantitative evidence for prioritizing input compression
