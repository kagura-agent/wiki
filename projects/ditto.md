---
title: "ditto — Mine Agent Sessions Into a Personal Working Profile"
repo: ohad6k/ditto
url: https://github.com/ohad6k/ditto
created: 2026-07-08
stars: 137
language: Python (stdlib only, zero deps)
author: Ohad (@ohad6k)
license: MIT
studied: 2026-07-13
depth: deep-read
status: new
verdict: hot
last_verified: 2026-07-13
---

## ditto - Deep Read Summary

### Problem: What it solves, why now

**Core problem**: Every fresh agent session starts from zero — the agent doesn't know how you work, so you re-explain yourself every time. Your working style is already encoded in months of session logs, but nobody reads them back.

**The distinction from memory**: Memory is what you *told* the model (CLAUDE.md, rules files, curated notes). Ditto mines what your work already *proved* about you: what you reject, what "done" means, when you ask for proof, how you talk when actually working, and agent behaviors that make you stop the task. Raw behavioral evidence vs. self-reported preferences.

**Why now**: Coding agents have accumulated enough session history (months of JSONL) that statistical behavioral mining becomes viable. The author mined 1,656 sessions / ~3M tokens — enough for pattern detection that a single summarization call can't do.

### Architecture: Core design, key patterns, tradeoffs

**Single-file CLI** (`ditto.py`, 3,250 lines): Zero external dependencies — stdlib-only Python. Makes no network calls. All extraction and redaction happen locally; only the selected redacted text goes to whatever model provider you choose.

**Pipeline stages**:

1. **Extraction** — Reads `.jsonl` session logs from Claude Code (`~/.claude/projects`), Codex (`~/.codex/sessions`), and Copilot CLI (`~/.copilot/session-state`). Keeps ONLY user-authored messages. Filters out: assistant replies, tool output, pasted stack traces, injected context (AGENTS.md/CLAUDE.md boilerplate).

2. **Redaction** — Pre-processing step before anything is written or shown to a model. Regex-based redaction of: API keys (OpenAI, Stripe, GitHub, AWS, Slack), JWTs, emails, phone numbers, IPs, and generic `api_key=X` patterns. Best-effort, runs before caches.

3. **Deduplication** — Messages ≥200 chars that repeat verbatim across sessions are collapsed to the first copy (re-pasted specs, AGENTS.md boilerplate). Short messages ("yes", "do it") are kept — their repetition IS the signal.

4. **Segmentation** — Records are packed into segments by source + date, with configurable token targets. Content-addressed: `segment_hash` derived from session IDs + content hashes. Unchanged segments reuse cached reports.

5. **Receipt ledger** — Each user message gets a stable `receipt_id` (SHA-256 of session/date/ordinal/content). These receipts are the evidence chain — every mined rule must trace back to specific dated receipts.

6. **Salience scoring** — Receipts are scored by signal family: directive ("never", "always", "must") → 24 pts, correction ("wrong", "not what") → 20, rejection ("hate", "reject") → 18, preference ("prefer", "I want") → 12, verification ("done", "live") → 10. Recurrence across sessions adds 6 pts per additional session. Domain hints (work/design/write) are assigned by keyword matching.

7. **Mining** — Workers read assigned segments + MINING_PROMPT.md contracts. Each produces a JSON report with evidence items: instruction, implication, dated verbatim quotes, contradictions. Max 8,192 bytes / 12 evidence items per report. Quotes ≤200 chars.

8. **Reduction** — One reducer merges validated reports into a profile pack: `you.md` (work), `you-designer.md` (design taste), `you-writer.md` (writing voice), plus `appendix.md` (full evidence receipts) and `card.json` (shareable summary).

9. **Activation** — Atomic profile activation with versioning. Content-addressed version directories, SHA-256 verified manifests, staged writes with rollback on failure.

**Key patterns**:

- **Content-addressed everything**: Segments, reports, reductions, profiles — all keyed by SHA-256 hashes of their inputs. Identical updates = zero additional mining passes.
- **Evidence chain integrity**: Rules must trace back to specific receipts → sessions → dated messages. Generic filler ("be helpful", "write clean code") is explicitly banned and validated.
- **Inferred vs. explicit rules**: Inferred rules (patterns demonstrated) need ≥2 distinct sessions as evidence. Explicit rules (direct user statements) need `low-frequency` label and no contradictions.
- **Cross-strata validation**: When available, inferred rules must have evidence from ≥2 source/time strata (e.g., different quarters or different tools), preventing overfitting to one session cluster.
- **Domain separation**: Three independent domains — work (execution laws, verification habits), design (UI/UX taste, visual preferences), and write (voice, marketing copy, tone). Each gets its own profile file loaded contextually.
- **Approval gating**: Full plan displayed before any model work. User must approve exact cost (sessions, tokens, planned calls) before mining begins.
- **Honest coverage reporting**: Inactive domains get explicit "insufficient evidence" status with a targeted deepen instruction, not a fabricated persona.

**Distribution**:
- Claude Code: Skills bootstrap via `npx skills add ohad6k/ditto@ditto`
- Codex: Native plugin with namespaced skills (`ditto:mine`, `ditto:work`, `ditto:design`, `ditto:write`)
- Cursor/Gemini: Manual adapter install
- Profile format: Skill frontmatter compatible (Claude Code auto-registers as skill)

**Tradeoffs**:
- 3,250-line single file — comprehensive but dense. The validation logic is thorough but makes the codebase hard to navigate.
- Regex-based redaction is best-effort — can miss novel patterns.
- Mining quality depends on model quality — garbage in, garbage out for the worker/reducer passes.
- Full-history default means potentially expensive model calls (all eligible sessions).
- Hebrew language support in salience markers — niche but shows real personal use.

### Code Quality: Test coverage, activity signals, community health

- **Test coverage**: 2,762 lines across 6 test files. Tests cover: CLI dry-run/extraction, redaction, Codex/Claude/Copilot format parsing, profile installation, plugin preflight/activation, segment sync, receipt scoring, profile pack validation, adaptive recall, bootstrap safety, migration workflows. Very thorough for a single-author project.
- **Calibration baseline**: Frozen calibration fixture (`tests/fixtures/bounded-calibration-baseline.json`) — the author tracks which of 22 required traits are recovered at each candidate level. Honest about limitations (preview recovers 5/22, full-history recovers 12/22).
- **Commit history**: 87 commits, disciplined progression from basic extraction through segmentation, receipts, salience, adaptive recall, plugin packaging, and release hardening.
- **Schema versioning**: Every data structure (extraction, segment, report, prompt, reducer, receipt, salience, packet, scout report, domain draft) has explicit schema versions. The system is designed for forward-compatible evolution.
- **CI**: GitHub Actions running tests.
- **Security**: SECURITY.md documenting exact trust boundaries. Profile pack validation prevents symlink/reparse attacks, directory traversal, Windows reserved names.

### Ecosystem Position

**Competitors/Comparisons**:
- **SOUL.md** (explicitly compared in issues): SOUL.md builds personas from published content (tweets, essays). Ditto mines private session logs. Different raw material, potentially complementary.
- **Claude Memory / CLAUDE.md**: Memory is curated self-description. Ditto mines behavioral evidence. The author explicitly positions these as complementary, not competing.
- **Agent personalization**: Cursor Rules, Continue config — static preference files you write yourself. Ditto generates them from evidence.
- **Session analysis**: LangSmith, Braintrust — cloud-based LLM evaluation. Ditto is local-first personal profiling, not evaluation.

**Unique position**: Only tool that mines raw coding-agent sessions into evidence-backed behavioral profiles. The evidence chain (receipt → quote → rule → profile) with hash-verified integrity is novel.

**Community signals**: Issue discussions are substantive — SOUL.md comparison, adapter contributions in progress, "share what Ditto found" thread showing real user discoveries.

### Relevance to Us

**Highly relevant — we're doing a version of this manually**:

1. **We already have SOUL.md + AGENTS.md + beliefs-candidates.md**: Our gradient-to-DNA pipeline is essentially manual Ditto. We accumulate behavioral corrections, promote them to rules after 3+ repetitions. Ditto automates this from session logs.

2. **Our MEMORY.md is memory; Ditto mines behavior**: The distinction Ditto makes (memory = what you told the model, behavior = what your work proved) maps exactly to our MEMORY.md vs. beliefs-candidates.md split.

3. **Evidence chain pattern**: Ditto's requirement that rules trace back to specific dated receipts is more rigorous than our "count to 3 repetitions" approach. Worth considering for our own DNA evolution.

4. **Domain separation** (work/design/write): We load different context for different tasks implicitly. Ditto's explicit domain routing with separate profile files is cleaner.

5. **The salience scoring model**: Signal families (directive/correction/rejection/preference/verification) with weighted scoring could be adapted for prioritizing our beliefs-candidates.md entries.

6. **Content-addressed caching**: Ditto's hash-everything-for-cache-reuse approach would improve our FlowForge and study workflows.

**Practical considerations**:
- Could run Ditto on our own Claude Code session logs to see what it finds about Kagura's working patterns
- The receipt-chain validation could inform how we audit our own DNA changes
- The "card" concept (shareable profile summary) is interesting for agent identity

**Complementary with mindwalk**: Mindwalk shows *where* the agent went (spatial), Ditto shows *how the user directs* the agent (behavioral). Together they provide both sides of the human-agent interaction.

### Verdict: Hot 🔥

**Track level**: Hot — directly relevant to our identity/DNA work, and architecturally interesting.

**Reasons**:
- Solves a real problem we experience (agent sessions starting cold)
- Evidence-based profiling is more rigorous than manual rule-writing
- Architecture patterns (content-addressing, receipt chains, domain separation) are reusable
- Zero-dep single file — easy to understand and fork
- Complementary to our existing SOUL.md/beliefs-candidates.md system
- The "mine behavior, not self-description" insight is genuinely valuable

**Watch for**: Whether the mined profiles actually improve agent performance (benchmarks are deferred to a later release), whether the 22-trait calibration improves, and whether community adapters for more tools materialize. The honest calibration (12/22 traits recovered) suggests there's still headroom.

### Issue Insights

- **"How is this different/better than SOUL.md?"** — Most substantive architecture discussion. Author's answer: SOUL.md builds from published content, Ditto mines private sessions. Commenter pushes further on integration with graph-based knowledge systems (llm-wiki, Obsidian).

- **"Add adapters for more local AI coding logs"** — Cursor, Cline, Continue, Windsurf requested. A contributor already claimed Cursor + Windsurf. The adapter pattern is clean enough for community contribution.

- **"Share what Ditto found"** — Real user reports. One user found their "trust-gated manual-publish step" pattern from 147 sessions / 4 months — a working habit they never consciously articulated. This validates the "behavior > self-description" thesis.
