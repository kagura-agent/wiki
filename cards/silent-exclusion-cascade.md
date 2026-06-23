---
title: Silent Exclusion Cascade
created: 2026-06-23
last_verified: 2026-06-23
type: card
tags: [pattern, anti-pattern, debugging, pipelines]
---

# Silent Exclusion Cascade

A broad ignore or filter rule intended to suppress noise accidentally silences meaningful output downstream. The pipeline runs successfully — no errors, no warnings — but downstream consumers are silently starved of data.

## Mechanism

```
broad filter rule (e.g. ignore *.md)
  → intended: skip noisy raw input
  → actual: also excludes processed output that shares the pattern
  → downstream: query returns zero results
  → symptom: "nothing happened" with no error
```

## Why It's Insidious

1. **No error signal** — the pipeline succeeds; it just produces nothing
2. **Works initially** — breaks only when the filtered pattern overlaps with new output paths
3. **Hard to diagnose** — you debug the consumer, the producer, the logic — the filter is the last place you look

## Fix: Surgical Filters

Instead of broad pattern-based exclusion:
- Distinguish raw input paths from processed output paths
- Filter by source stage, not file extension or directory glob
- Use allowlists for output rather than blocklists for input

## Examples

- **memexignore excluding dreaming output**: `.dreams/` (raw) and `dreaming/` (processed) both matched a broad ignore rule; dreaming pipeline produced output that search couldn't find
- **gitignore catching build artifacts**: `*.js` in gitignore also excludes intentional JS config files
- **log filtering**: broad "ignore DEBUG" rule also suppresses DEBUG-level messages that contain error context

## Diagnostic Heuristic

When debugging "no results" in a search-dependent system, check ignore/exclusion filters first. The content may exist but be invisible to the query layer.

## Related

- [[dreaming-observation]] — three instances of this pattern breaking the dreaming pipeline
- [[retrieval-is-the-bottleneck]] — silent exclusion is a special case of retrieval failure
