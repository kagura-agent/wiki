---
title: Progressive Degradation
created: 2026-06-23
last_verified: 2026-06-23
type: card
tags: [pattern, resilience, distributed-systems]
---

# Progressive Degradation

A system gracefully reduces capability or quality in defined tiers when resources are constrained or conditions worsen, rather than failing abruptly.

## Degradation Ladder

```
full → reduced → minimal → offline
```

Each tier preserves the most critical function while shedding lower-priority features. The system remains useful at every rung.

## Examples

- **Distributed systems**: full replication → read-only replicas → cached responses → maintenance page
- **UX**: rich interactive UI → static content → text-only → error page with ETA
- **Agent tool selection**: preferred tool → fallback tool → heuristic → refuse gracefully
- **Network**: streaming video → lower bitrate → audio-only → buffering notice

## Key Properties

1. **Tiered, not binary** — multiple defined levels, not just on/off
2. **Automatic** — triggers based on measurable conditions (latency, error rate, resource usage)
3. **Reversible** — system recovers upward when conditions improve
4. **Observable** — each tier change is logged/alerted so operators know the current level

## Inverse Pattern

Progressive *escalation* applies the same tiered approach in reverse: start minimal and ramp up capability when basic approaches fail. See [[browser-search]] for an example (fast-cheap → normal → stealth).

## Related

- [[browser-search]] — uses progressive escalation (the inverse direction)
- [[closed-loop-vs-open-pipe]] — degradation requires feedback to detect which tier is needed
