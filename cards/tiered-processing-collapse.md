# Tiered Processing Collapse

When a system has multiple processing tiers (quick/deep/meta), shared mutable state between tiers can make higher tiers structurally unreachable.

## Pattern

1. Tier A (low threshold) and Tier B (high threshold) share an accumulation queue
2. Tier A fires and clears the shared queue
3. Tier B's threshold can never be met because Tier A always fires first and resets
4. Result: multi-tier architecture collapses to single-tier in practice

## Origin

[[claude-soul]] Issue #6 (Abdallah01, 2026-05-23): Deep reflection tier structurally unreachable because `clearSignals()` is unconditional after any reflection. Quick fires at 12 signals and wipes. Deep needs 60 but can never accumulate.

## Fix Pattern

Per-tier consumed tracking. Each item tracks which tiers have consumed it (`consumedBy` array). Each tier only reads items unconsumed by its own tier.

## Generalization

Applies to any batched processing system with multiple priority levels sharing a work queue:
- Log aggregation (warning → alert escalation)
- Review cadence (quick nudge → deep review) — relevant to our [[beliefs-upgrade-mechanism]]
- Cache eviction tiers

## Prevention

- **Never share mutable accumulation state across tiers** without per-tier consumption tracking
- Or: use separate queues per tier with a routing/replication layer
- Test: verify each tier fires in isolation. If tier N only fires via time fallback, the threshold path is dead code.

Links: [[claude-soul]], [[beliefs-upgrade-mechanism]], [[self-evolving-agent-landscape]]
