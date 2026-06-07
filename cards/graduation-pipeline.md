---
tags: [self-evolving, beliefs, pipeline, tooling]
created: 2026-06-07
last_verified: 2026-06-07
---

# Graduation Pipeline

**Tool**: `graduation-pipeline.sh` — orchestrates the promotion of behavioral patterns from `beliefs-candidates.md` into DNA files (SOUL.md, AGENTS.md, IDENTITY.md).

## How It Works

A belief candidate accumulates evidence through [[gradient-scan]] (keyword hits + JSONL signal across memory files). When a pattern crosses the graduation threshold (configurable, default: 6 hits in 14 days), the pipeline evaluates it through three verification stages:

1. **V1 Cross-context** — pattern observed across multiple independent contexts (not just one session)
2. **V2 Predictive** — pattern reliably predicts a failure mode or behavioral signal
3. **V3 Non-obvious** — insight isn't trivially derivable from existing beliefs

Candidates passing all three stages are promoted to the appropriate DNA file and retired from `beliefs-candidates.md`.

## History

- Created 2026-05-27 (commit a3f7497)
- Was stuck at "0 candidates" for ~2 weeks due to cascading bugs: pipeline defaults misaligned with review.yaml, [[gradient-scan]] missing JSONL signals, keyword false positives
- First successful graduation: `premature-conclusion` on 2026-06-06, after three consecutive bug-fix rounds unblocked the pipeline at each layer

## Related

- [[beliefs-candidates]] — input source (active behavioral patterns awaiting graduation)
- [[gradient-scan]] — evidence collection (keyword + JSONL scan of memory files)
- [[self-improving]] — broader self-evolution architecture
- [[self-evolving-observations]] — daily observation log tracking pipeline health
