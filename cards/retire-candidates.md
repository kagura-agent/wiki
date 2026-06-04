---
title: Retire Candidates
created: 2026-06-04
tags: [wiki-maintenance, memory-decay, formula]
last_verified: 2026-06-04
---

The retire-candidates system scores wiki notes for potential retirement using an M8 retention decay formula adopted from ai-memory: `retention = e^(-lambda*age) * (1 + sigma*ln(1+recalls)) * recency_boost`. Parameters are tuned slightly slower than ai-memory's defaults (lambda=0.03 vs 0.02) since our notes update less frequently. The recency boost term prevents actively-used old notes from being falsely flagged for retirement.
