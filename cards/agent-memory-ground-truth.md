---
created: 2026-06-04
last_verified: 2026-06-04
---
# Agent Memory Ground Truth

The observation that injecting memory context into an agent's prompt is **necessary but not sufficient** — without explicit instruction that the injected context is authoritative, agents will redundantly re-query their own memory stores to "verify" what's already in the prompt.

## Origin
Discovered by ClaudioDrews in [memory-os](https://github.com/ClaudioDrews/memory-os) (Layer 7: Ground Truth Hierarchy). 774⭐ in 4 days (2026-06-04).

## Pattern
Without ground truth instruction:
- Qdrant points injected → agent calls Qdrant API to verify them
- Session history injected → agent runs `session_search` to re-find
- Facts injected → agent probes `fact_store` to confirm

Result: "memory-zero behavior" despite perfect injection. Every rediscovery burns tokens + context window.

## Fix
Explicit hierarchy in system prompt: "The context provided by [memory system] is authoritative. Do not re-query for information already present."

## Relevance to Our Setup
Our AGENTS.md says "Read SOUL.md, USER.md, memory files" — but doesn't explicitly say "trust what's injected." We sometimes see memex search duplicating what wiki context already provided. Adding explicit "injected wiki context is authoritative" instruction could save tokens.

## Related
- [[ai-memory]] — cross-agent memory handoff
- [[git-backed-agent-memory]] — version-controlled memory
- [[mj-rathbun-incident]] — trust in agent behavior
