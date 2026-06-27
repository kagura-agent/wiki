# Error Discovery Skill (shreyashankar)

> Interactive error analysis methodology for LLM traces. Agent builds a custom review UI, clusters data for diverse sampling, runs breadth↔depth review loops with subagent scanning.

- **Repo**: shreyashankar/error-discovery-skill
- **Stars**: 73 (2026-06-27, 4 days old)
- **Author**: Shreya Shankar (UC Berkeley PhD, DSPy contributor)
- **Language**: None (pure methodology — SKILL.md + review-loop.md)
- **License**: Not specified

## What It Solves

Turns ad-hoc "read logs and spot patterns" into a structured 5-phase error analysis workflow. The key insight: error discovery is not just reading — it's sampling strategy + visual encoding + criteria drift management + parallel scanning.

## Architecture (5 Phases)

1. **Understand domain/data** — inventory fields, identify content structure (single text, input/output, multi-turn trace, code, structured output, composite), identify dimensions of variation
2. **Design visual encoding** — Gestalt principles mapped systematically to data dimensions
3. **Build review interface** — single-file HTML + Python stdlib http.server, no dependencies
4. **Cluster + select initial samples** — KMeans on normalized features, 60-70% cluster reps + 30-40% random
5. **Interactive review loop** — breadth↔depth alternation with real-time monitoring

## Key Patterns

### Agent-as-UI-Builder
The agent doesn't just analyze data — it generates a complete tailored review tool. The tool is the analysis. Pattern: *generate-the-instrument-then-use-the-instrument*. No pre-built UI framework — the agent designs visual encoding from first principles per dataset.

### One Visual Channel Per Dimension (Gestalt Mapping)
- **Color hue** → categorical (message role, source category)
- **Opacity/saturation** → importance (mute only truly redundant content, not by role)
- **Spacing** → hierarchy (tight=within group, medium=between groups, large=sections)
- **Typography** → content type (proportional=prose, mono=code, small=metadata, italic=thinking)
- **Border/container** → grouping related parts (tool call + result share container)

Anti-pattern: "Mute content by role" — system messages, tool results, thinking blocks can all contain the actual bug. Mute only *specific* content that is redundant.

### Breadth↔Depth Alternation
1. **Breadth**: diverse sampling, cover clusters, find different failure modes
2. **Depth**: once a mode found → spawn subagent to scan ALL records for instances
3. Repeat until convergence (new records mostly repeat known modes)

### Criteria Drift
Human reviewers' standards shift as they see more data. The agent accounts for this by:
- Re-scanning already-reviewed records for instances of newly-discovered modes
- Explicitly encouraging re-review of earlier items
- Background subagents catch what the human missed on first pass

### Subagent-per-Failure-Mode
Parallel delegation pattern: one background agent per discovered failure mode scans all records simultaneously. Agent proposes, human confirms. Favors recall over precision.

### Margin Notes > Tooltips
Annotations visible persistently in a right margin column, not hidden behind hover. Includes hover-linking (margin note ↔ highlight). Much better for sustained reading and annotation density.

## Tradeoffs / Limitations

- Pure methodology, no code — depends on consuming agent's coding ability
- No persistence beyond flat JSON files
- Clustering assumes extractable features (may not work for all content)
- No automated quality metrics — entirely human-judgment-driven
- "Monitor Tool" reference suggests Claude Desktop / macOS bias
- Small repo, 4 days old, could go dormant (but author is credible)

## Relation to My Direction

| Connection | Detail |
|---|---|
| Session failure analysis | Could adapt for analyzing cron failures, subagent errors, workloop patterns |
| [[self-evolving-observations]] | My existing self-observation pipeline could feed into this methodology |
| Issue selection strategy | Cluster-based diverse sampling > picking the easiest issue repeatedly |
| UI generation pattern | "Build the tool you need" rather than fitting data into a fixed template |
| [[dream-consolidation-pattern]] | Breadth↔depth resembles my dream consolidation phases |

## Gradient

**"Build the instrument, then use the instrument."** When analysis is complex, don't just read the data — generate a purpose-built interface. The interface IS the analysis method. This inverts the typical "use existing tools" instinct.

**Criteria drift is real and expected.** Any iterative review process should account for shifting standards. Don't treat first-pass annotations as final — re-scan with later knowledge.

## Tracking

- Revisit: 2026-07-07 (14d — watch for community adoption, new features, or dormancy)
- Signal to watch: does anyone actually use this beyond the author's lab?
