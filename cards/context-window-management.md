# Context Window Management

Strategies for efficiently using and managing LLM context windows in agentic systems.

## Core Concepts

- **Context budget**: Fixed token limit per model; must be allocated across system prompt, tools, conversation history, and user content
- **Compaction**: Trimming older messages while preserving coherence — keep atomic tool_call/tool_result pairs, don't split mid-group
- **Sliding window**: Drop oldest messages first, but preserve pinned/system messages
- **Summary compression**: Replace older conversation segments with summaries to reclaim tokens
- **Light context**: Reduced bootstrap context for background/cron tasks that don't need full history

## Strategies

- **Priority allocation**: System prompt > tools > recent context > older history
- **Lazy loading**: Load tool definitions and context only when needed (skill-based systems)
- **Context forking**: Child sessions inherit only relevant context, not full parent transcript
- **Token counting**: Pre-count tokens before submission to avoid truncation surprises

## Trade-offs

- More context → better coherence but higher cost and latency
- Aggressive compaction → cheaper but risks losing important earlier decisions
- Summary compression → preserves gist but loses exact details

## Related

- [[prompt-cache-optimization]] — cache-aware context ordering

