---
created: 2026-06-01
last_verified: 2026-06-01
---
# Goal-Hive: Master Duty

A concept from the Goal-Hive multi-agent framework defining the master agent's responsibility for **delivery reasonableness**.

## Core principle

The master agent must separate **delivery results** from **reports**. Deliveries should be clean products — no explanatory noise, no meta-commentary about how the work was done. Reports go through a separate channel.

## Why it matters

Without this separation, agent outputs get polluted with self-narration ("I did X because Y"), making deliveries unusable as direct inputs to downstream systems or users. The master duty enforces that what gets delivered is the artifact itself, not a summary of producing it.

## See also

- [[genericagent]] — references master duty in its agent design
