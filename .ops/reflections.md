
## 2026-05-30 — Baseline Run

**First run** — no previous data for comparison.

### Key Findings
- **Index drift is the #1 issue**: 211 files not in index.md. The index was never regenerated after bulk card/project creation. `gen-index.sh` exists and works — this should be automated.
- **Broken wikilinks (104)**: Most are references to concepts that were never created as cards. Many are generic terms (MCP, TACO, AGENTS, wiki, tmux) used as wikilinks when they shouldn't be, or refer to cards that exist under slightly different slugs.
- **Stale files (148)**: The staleness threshold is aggressive (14d for projects, 30d for cards). Most of these are study notes that were written once and are still valid — they just lack `last_verified` dates. This is noise, not signal.
- **Frontmatter gaps (124)**: Cards created before the frontmatter convention was established. Bulk-fixing frontmatter would be mechanical but noisy.

### Patterns
- **Slug inconsistency**: `skill-ecosystems` vs `skill-ecosystem`, `acp-protocol` vs `acp`. When creating wikilinks, authors don't check if the target slug exists. Could add a pre-commit check.
- **Redirect stubs**: 3 files that said "moved to X" but were never deleted. These accumulate silently.

### Automation Opportunities
1. **Auto-regenerate index.md**: Add `gen-index.sh` to the fix node or as a pre-commit hook.
2. **Broken link → near-match suggestion**: The lint script could suggest fixes when a near-match exists (Levenshtein distance ≤ 2).
3. **Prev-health rotation**: The workflow should copy `last-health.json` → `prev-health.json` at the start of health-check, so diff always works.

### Workflow Changes
- None this round. The workflow structure (health → diff → fix → reflect → report) is sound. Will evaluate after 3+ runs.
