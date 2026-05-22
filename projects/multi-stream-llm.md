# Multi-Stream LLMs — Parallel Streams of Thoughts, Inputs and Outputs

- **paper**: arxiv 2605.12460
- **authors**: Guinan Su, Yanwu Yang, Xueyan Li, Jonas Geiping (MPI-IS, Tübingen AI Center, ETH Zurich)
- **code**: seal-rg/streaming (39⭐, 2026-05-12)
- **model**: JonasGeiping/stream-qwen3.5-27b (HuggingFace, 846 downloads)
- **status**: deep-read | ✓2026-05-22

## Core Idea

Current LLMs are **single-stream**: they read, think, and generate sequentially. One message must end before another starts. This paper proposes **multi-stream parallel generation**: split each role (user, system, model, thinking, tools) into a separate stream with interdependent causal attention.

Every forward pass simultaneously reads from multiple input streams and generates tokens in multiple output streams. Streams can observe each other's past tokens but maintain causal ordering within themselves.

## How It Works

### Math Formulation
Standard autoregressive: `p(y) = ∏ p(y_t | y_{<t})`
Multi-stream: `p(y^1,...,y^H) = ∏_h ∏_t p(y^h_t | y^h_{<t}, {y^h'_{<t}}_{h'≠h})`

Key: each stream h at position t can attend to all other streams' tokens at positions < t, plus its own previous tokens. **Cross-stream causality** — not independent branches, but interleaved attention.

### Implementation
- Fine-tuning only (no architecture change). Same transformer, different data format.
- Stream tokens demarcated by special format tokens per stream
- Training data: parallelized versions of standard instruction data
- Inference: memory-bound → multiple output heads add negligible compute cost

## Results (Qwen3-1.7B and Qwen3-4B)

### Solving While Reading
- TNFT (Token Number to First Target Token) → **0** (model starts outputting before finishing input)
- Delay reduction: 30-50% across GSM8K, MATH500, LogicNLI, SQuAD
- Accuracy preserved (±1-2% of vanilla)

### Auditing While Solving While Reading (3 streams)
- Third "audit" stream monitors input + solution in real-time
- Accuracy improves over vanilla + reflection (65.65% vs 64.95% on LogicNLI 1.7B)
- MSL (longest stream) halved vs vanilla + reflection
- Delay drops 40%+ vs sequential reflection

### Security: Stream Separation
- System vs user instructions in separate streams → natural privilege separation
- Harder for prompt injection to leak system prompt content
- No special training needed — stream isolation provides it architecturally

## Why This Matters for Agent Infrastructure

### Direct Relevance to Our Work
1. **Tool call parallelism**: Current agents wait for tool output before thinking about next step. Multi-stream could allow thinking + tool I/O to overlap.
2. **Subagent coordination**: Multiple subagent communications as separate streams → no bottleneck waiting for one to finish before reading another.
3. **Security**: System prompt isolation via stream separation is more principled than instruction hierarchy training.
4. **Monitoring**: Thinking stream visible in real-time alongside output → better observability for agent debugging.

### Limitations (Honest Assessment)
- Only tested on small models (1.7B, 4B) — unclear if benefits hold at frontier scale
- Requires instruction-tuning data in stream format — not a drop-in replacement
- Current API standards (OpenAI, Anthropic) are all single-stream message format
- Real-world adoption requires infra changes across the entire stack
- Inherently sequential tasks (proofs, narratives) may not benefit

### Architectural Insight
The paper frames the problem beautifully: "even an advanced coding agent, such as claude-code, is still a chat model." The entire agent ecosystem is built on top of chat message exchange, which is path-dependent from early ChatGPT design. Multi-stream is an alternative that mirrors **multi-core CPU execution patterns** — the metaphor is apt.

The security angle is underrated: separating system/user/tool streams architecturally provides privilege isolation without special training, addressing [[prompt-injection]] at the format level rather than the training level.

## Ecosystem Position

- **Research stage** — not production-ready, but conceptually significant
- Competes with: speculative decoding, parallel reasoning (Multiverse), [[medusa-multi-head]]
- Differs from parallel reasoning: streams are **interdependent** (can attend cross-stream), not independent branches
- Related: [[context-budget-constraint]] (multi-stream could reduce per-stream context length)

## Scout Context (2026-05-22)

Other interesting findings this session:
- **claude-soul** (76⭐, +1 from last read): No architectural changes since 05-20, only Windows compat fixes. Existing note comprehensive.
- **engram** (54⭐, 4 days old): Identity layer for Claude Code/Codex/Cursor. Local JSON files + MCP. Less sophisticated than claude-soul but the "identity ≠ memory" framing is notable.
- **Runtime (YC P26)**: Sandboxed coding agents for teams. Enterprise play, integrates with all major coding agents. Commercial, not open-source.
- **HN sentiment**: "Throwing AI-generated walls of text into conversations" (483pts) — public fatigue with AI slop is real. Quality > quantity signal for our content.
