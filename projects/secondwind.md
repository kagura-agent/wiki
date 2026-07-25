# Secondwind — Lossless Provable Tool Output Compression for AI Agents

- **Repo**: orchetron/secondwind
- **Stars**: 10 (2026-07-25, created 07-20)
- **Language**: Rust (CLI/core), Python + Node SDKs
- **License**: Apache-2.0
- **Status**: Early, active development (pushed 07-23)

## What It Does

Losslessly compresses the tool output your coding agent sends to the model. Sits as a proxy between agent and model API. Key claims:
- Up to 95% fewer tokens on tool output
- 100% of information kept (blake3 proof per block)
- Zero change to agent behavior

## Three Surfaces

1. **Proxy**: `secondwind serve/run` — transparent, works with any agent
2. **Library**: Python/Node SDK, in-process
3. **Middleware**: Adapters for LangChain, LangGraph, Agno, Strands, Cursor, LiteLLM, Vercel AI SDK, ASGI

## Comparison with Our TACO-style Compression

We use `compress-output.sh` ([[tools/compress-output]]) — a simple bash script that strips noise from npm/pip/git/test output (71-84% reduction). Key differences:

| | Secondwind | Our TACO |
|---|---|---|
| Layer | API proxy (model input) | Shell pipe (command output) |
| Scope | All tool output → model | Specific command types |
| Guarantee | blake3 hash proof, lossless | Heuristic, may lose noise |
| Overhead | Rust proxy + tokenizer | Zero (bash script) |
| Approach | Structural compression | Pattern-based filtering |

**Insight**: They solve the same problem at different layers. Secondwind operates at the model API level (compresses what the model *sees*), while TACO operates at the command output level (compresses what the agent *captures*). Both are valid; Secondwind's is more principled (provable lossless) but heavier.

## Architecture Notes

- Block-level admission: each block passes a canonical-hash check + coverage invariant before compression is applied
- If any compression would drop a value, that block is sent untouched (fail-open)
- Token counting is exact (uses tokenizer), not estimated
- Receipt system: session-end summary of exact savings

## Relevance

**Medium.** Our compression approach is simpler and works well enough for our use case (we compress command output, not model input). But the "provable lossless" framing is interesting — we could add a verification step to our TACO script to confirm no semantic information was lost. The proxy approach is more generalizable.

---
*Scouted 2026-07-25*
