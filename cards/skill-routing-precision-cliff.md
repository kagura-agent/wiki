# Skill Routing Precision Cliff

As an agent's skill catalog grows, routing accuracy degrades in predictable ways depending on the matching strategy used.

## Three Strategies and Their Cliffs

| Strategy | Cliff Point | Failure Mode |
|----------|-------------|--------------|
| Keyword/intent index | ~50-130 skills | Fan-out: generic terms match many skills simultaneously |
| LLM system prompt list | ~40-50 skills | Context bloat: skill descriptions dilute attention, LLM misroutes |
| Dispatcher/hierarchy | ~200+ skills (estimated) | Category misclassification at first hop |

## Evidence

- **[[mercury-agent]] PR #68** (05-29): keyword routing matched ~10 skills on "download X and send to Y" at 130+ skills. Root cause: single generic verb giving 0.70 confidence. Fixed with stoplist + tiered confidence + ambiguity prompt.
- **[[gbrain]] functional-area-resolver** (05-12): `(dispatcher for: ...)` clause is load-bearing for LLM-based hierarchical routing. Without it, accuracy collapses. Sweet spot estimated at 40-50+ skills.
- **OpenClaw `available_skills`**: currently ~25 skills in system prompt, well below cliff. Planning horizon: 40-50 skills.

## Mitigation Patterns

1. **Stoplist generic terms** — remove verbs like "download", "send", "get" from keyword indexes (mercury-agent)
2. **Tiered confidence** — single keyword = weak signal, multiple = strong (mercury-agent)
3. **Ambiguity prompt** — ask user to disambiguate instead of parallel fan-out (mercury-agent)
4. **Explicit picker** — `#skill-name` bypass for power users (mercury-agent), `/skill-name` (others)
5. **Hierarchical dispatch** — category → skill two-hop routing (gbrain, [[functional-area-resolver]])
6. **Progressive disclosure** — only load name+description at startup, full content on invoke (mercury-agent)

## Transfer Value for OpenClaw

Our LLM-based routing is currently fine (~25 skills). When approaching 40-50:
- First step: [[functional-area-resolver]] dispatch layer
- Worth borrowing: ambiguity prompt + explicit picker concepts
- Not needed now: keyword index (LLM judgment handles it)
