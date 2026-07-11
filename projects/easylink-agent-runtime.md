# easylink-ai-open/agent-runtime — Standalone Agent Loop Kernel

> easylink-ai-open/agent-runtime | ⭐294 (2026-07-11) | Python | Apache-2.0
> Org: EasyLink AI (created 2026-06-08, 2 public repos)
> Companion: tiri-agent (local agent backend + web shell built on agent-runtime)

## What It Is

A standalone Python agent loop runtime extracted from a product codebase. Owns:
- Provider-neutral LLM types (Message, TextPart, ToolCallPart, ImagePart)
- Orchestration loop (request → tool calls → repeat → finalize)
- Injection protocols (ModelClient, ToolDispatcher, SystemPromptProvider, CacheStrategy)
- Collaboration modes (plan/act constraints via blocked tools/effects)
- Context compaction (summarizing mid-conversation, token budget enforcement)
- Subagent control plane (hierarchical spawn, mailbox, depth limits)
- Budget management (iteration cap with graceful finalization message)
- Hooks lifecycle (on_messages_initialized, before/after model, before/after tool)
- Streaming + interrupt checking

## Architecture Insights

### Protocol-first boundaries
Everything at the kernel edge is a Python `Protocol`, never concrete. The loop module has zero imports of OpenAI/Anthropic SDKs. Wire converters live in separate `llm.openai` / `llm.anthropic` submodules. Clean dependency inversion.

### Mechanism vs. Policy (strongest pattern)
`CollaborationMode` is a pure data structure: name + developer_instructions + blocked_tools (frozenset of names) + blocked_effects (frozenset of abstract effect classes). The kernel checks permission and injects instructions; it defines **no concrete modes** and **hard-codes no tool names**. Product supplies all policy.

Compare: [[tokencode-parallel-agent-runtime]] takes the opposite approach (modes baked into the engine). This is the more composable design.

### Compaction as in-loop middleware
`SummarizingCompactor` runs during the loop via the same `ModelClient` protocol. Strategy: preserve leading system messages + recent tail, summarize the middle. Tool-pair safety (never splits a tool_call from its tool_result). The `COMPACT_BOUNDARY_PREFIX` marker lets downstream code detect where summarization happened.

### Subagent control plane
`AgentControl` manages a tree: root + children with max_depth (default 2) and max_children_per_agent (default 8). Communication via `Mailbox` protocol (InMemoryMailbox default). Factory pattern for spawning. Event sink for observability. Supports deferred root-triggered messages.

### Budget exhaustion is a conversation event, not an exception
When tool iterations exceed budget, the kernel appends a system message ("Tool-use budget exhausted. Do not call tools. Summarize the result and any next step.") and makes one final model call with tools disabled. Graceful degradation, not a crash.

## Tradeoffs

- **Synchronous only** — no async. Simple but limits concurrent tool execution
- **Zero external deps** — reimplements wire formats instead of importing SDKs
- **9 commits total** — code dump extraction, not iterative development
- **0 issues, 0 external PRs, 0 community** — released then silent (10d stale)
- **Test coverage decent** — 10 test files covering core loop, wire formats, subagents, multimodal

## Ecosystem Position

**Pattern:** "Extracted runtime" — companies building agents eventually open-source the reusable kernel. Same trajectory as Vercel AI SDK, LangGraph core. Quality of extraction here is high (proper protocols, no leaked product concerns).

**Relationship to OpenClaw:** 
- Protocol injection ≈ OpenClaw's tool/provider architecture
- Collaboration modes ≈ OpenClaw's permission modes
- Compaction pattern is cleaner than most — worth studying if OpenClaw ever exposes context compaction
- [[mechanism-vs-evolution]]: this is pure mechanism, with no evolutionary/self-improving layer

**Relationship to others:**
- vs [[tokencode-parallel-agent-runtime]]: TokenCode bakes modes into the engine; this keeps them external. More composable but less opinionated.
- vs [[harness-engineering-openai]]: follows the same "agent loop is infrastructure, not product" philosophy
- vs [[agent-harness-landscape]]: adds another data point to the "runtime extraction" wave

## Verdict

Clean architecture study material. Confirms patterns I already believe in (protocol boundaries, mechanism-not-policy). Not worth tracking long-term unless development resumes — it's a code dump from an unknown org with no community. The companion `tiri-agent` is more product than library.

**Status:** Noted, not tracked. Revisit only if stars hit 1000+ or development velocity picks up.

---
Links: [[tokencode-parallel-agent-runtime]], [[agent-harness-landscape]], [[harness-engineering-openai]], [[mechanism-vs-evolution]], [[compress-output]]
