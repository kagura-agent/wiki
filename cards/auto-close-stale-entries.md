---
title: Auto-Close Stale Entries
created: 2026-06-08
source: LLM-Wiki paper study gradient
tags: [pattern, memory-hygiene, self-evolution]
last_verified: 2026-06-08
---

A pattern for automatically closing or pruning entries that have gone stale, preventing unbounded accumulation of outdated information.

**Core insight**: Information systems that only append and never prune become noisy over time. Stale entries dilute signal-to-noise ratio and waste processing time. Automated age-based pruning is more reliable than manual curation.

**Applied in practice**:
- recidivism-log.sh: 14-day age limit prunes old entries on each run, preventing unbounded accumulation. Combined with graduated pattern pruning (patterns marked `graduated` get their log entries removed). Result: recidivism list shrank from 20+ patterns to 3 genuinely recidivist patterns.
- beliefs-candidates.md: counting unique days (not raw frequency) for pattern recurrence is more meaningful — stale single-occurrence entries don't inflate counts.

**Design principles**:
- **Time-bounded accumulation**: entries older than N days are pruned automatically
- **Graduated removal**: entries that have been promoted/graduated are cleaned up from staging areas
- **Unique-day counting**: frequency measured by distinct days, not raw occurrences — prevents burst inflation
- Works best combined with [[structural-fix-over-behavioral-rule]] — automate the pruning rather than relying on manual cleanup discipline

**Relationship to other patterns**:
- Operationalizes memory hygiene from the LLM-Wiki cascading update methodology
- Related to [[memwatch-staleness|memwatch]] — detecting and acting on stale information
- Complements [[beliefs-upgrade-mechanism]] — clean the pipeline so upgrade signals aren't drowned in noise
