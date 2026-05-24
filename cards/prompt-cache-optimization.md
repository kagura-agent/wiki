# Prompt Cache Optimization

Techniques to maximize LLM prompt cache hit rates and reduce latency/cost.

## Core Principles

- **Prefix stability**: Keep system prompt and tool definitions in stable order so prefix caching works
- **Tool ordering**: Sort tools deterministically (by ID/name) to avoid cache invalidation on reorder
- **Cache breakpoints**: Insert `cache_control` markers at logical boundaries (system → tools → context → user)
- **Context compaction**: When trimming context, preserve atomic tool_call/tool_result pairs to avoid cache-busting mid-group splits

## Techniques

- **Anthropic**: `cache_control: {type: "ephemeral"}` on up to 4 breakpoints; 5min TTL; 90% cost reduction on hits
- **OpenAI**: Automatic prefix caching; no explicit markers needed; just keep prefix stable
- **Routing-aware**: Route to same model instance when possible to exploit warm cache

## Related

- [[semantic-model-routing]] — routing decisions that consider cache state
- [[elephant-agent]] — PR#39 tool ordering for cache stability
- [[context-window-management]]
