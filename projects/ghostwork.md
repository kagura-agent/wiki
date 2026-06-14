# Ghostwork (hvardhan878/ghostwork)

> "The first agent you don't prompt." Screen-watching agent that learns your workflows from observation alone, then automates them. macOS + Screenpipe.

- **Stars**: 122 (2026-06-14, created 06-09 = 5 days)
- **Language**: TypeScript (Electron)
- **License**: GPL-3.0
- **Dependencies**: Screenpipe, Playwright, macOS Accessibility API, OpenRouter/Anthropic
- **Community**: 🔴 SOLO (0 PRs, all issues from maintainer, 1 fork)

## Architecture — 4-Layer Memory + Sleep Cycle

The standout design: a neuroscience-inspired memory hierarchy with nightly consolidation.

### Memory Layers (L1-L4)

| Layer | Type | Data | Cadence |
|-------|------|------|---------|
| L1 Working | Live | Frontmost app, URL, OCR text, clipboard | 10s poll |
| L2 Episodic | Raw | Clicks, keys, navigations, app switches | 2min ingestion from Screenpipe |
| L3 Semantic | Rules | WHEN-DO patterns: `"WHEN LinkedIn search → DO export to CRM"` | Promoted nightly (NREM) |
| L4 Procedural | Skills | Executable step sequences with DOM/AX locators | Promoted nightly (REM) |

### Sleep Cycle (2am cron)

Three-phase nightly consolidation modelled on memory research:

1. **NREM** (episodic → semantic): LLM reads 24h of Screenpipe activity text (frames + keys + audio + clipboard), extracts WHEN-DO workflow patterns. Stitches cross-session sequences (research Monday → draft Tuesday). Initial confidence 0.3-0.5.

2. **REM** (semantic → procedural): Rules with ≥3 observations (or ≥2 + ≥1 accepted execution) AND browser-recorded events with DOM locators → compiled into `SkillStep[]` (deterministic replay, zero tokens). 

3. **GC**: Power-law confidence decay, dedup, 90-day prune, `behaviour.md` rewrite. **Poor skill demotion**: skills with <60% success over 5+ runs get deleted and rule falls back to vision. Rule `accept_count` capped to 4 (restarts supervised).

### Earned Autonomy (Trust Model)

Two tiers, earned through acceptance history:

- **Supervised** (default): Executes + HUD notification + Cmd+Z undo
- **Autonomous** (≥5 accepts AND <2 rejections in last 10): Runs silently, logged

**Critical**: externally visible actions (send, post, submit) ALWAYS require approval regardless of tier. This is the safety boundary.

### Execution Stack (3-layer fallback)

1. **Compiled skill replay** — zero tokens, deterministic. Ranked locators per step, fuzzy-match fallback when top locator drifts, only re-plans single broken step with LLM as last resort
2. **AX-first native control** — macOS Accessibility API via AppleScript (`ax_list_elements` + `ax_click_element`). ~95% accuracy on native apps
3. **Claude vision fallback** — pixel-level screenshots + function calling for browsers and AX-empty apps

**Multi-step rollback**: on mid-sequence failure, fires Cmd+Z for each completed reversible step in reverse order.

## Key Design Decisions

1. **No-prompt paradigm**: User never writes instructions. Agent observes → learns → acts. Radical departure from prompt-based agents.

2. **Act first, ask never** (for supervised tier): No "suggest" tier. System executes immediately with Cmd+Z undo. Philosophy: action + undo is faster than approval + action.

3. **Dual data source**: Both Screenpipe raw events AND Ghostwork's own browser-recorded events. Screenpipe provides breadth (all apps), browser recording provides depth (DOM locators for replay).

4. **Blocked rule safety net**: Hardcoded blocklist of terms (`cursor`, `terminal log`, `http 403`, `auth token`) prevents self-referential rules learned while debugging.

5. **Skill compilation = Playwright replay**: Skills are Playwright step sequences with ranked locators. Zero-token execution once compiled. Only broken individual steps trigger LLM re-plan.

## Transfer Value for Us

### High Value
- **Sleep cycle architecture**: The NREM→REM→GC pipeline is a clean pattern for any memory system that needs to consolidate raw observations into actionable knowledge. Our wiki + memory files could benefit from a similar promotion pipeline (raw daily notes → distilled cards → workflow improvements).
- **Earned autonomy model**: Simple trust math (≥5 accepts, <2 rejections in recent 10) is more principled than our binary supervised/autonomous. Could apply to subagent trust.
- **Poor skill demotion**: Auto-deleting skills with <60% success + resetting trust counter. We don't have equivalent quality gates on our skills/workflows.

### Medium Value
- **Behaviour.md as injected context**: Living profile rewritten nightly, injected into every LLM prompt. Similar to our SOUL.md/AGENTS.md but auto-generated vs hand-maintained. Interesting contrast.
- **Ranked locator fallback**: For browser automation, trying multiple locator strategies before LLM fallback. Applicable to our browser-automation skill.

### Low Value (interesting but not applicable)
- **Screen-watching paradigm**: Requires macOS + Screenpipe. Not applicable to our server-based setup.
- **AX-first execution**: macOS-specific Accessibility API.

## Critique

1. **Zero tests visible in repo** — no test files at all. For a system that watches your screen and takes autonomous actions, this is concerning.
2. **Solo maintainer, GPL-3 license** — limits adoption and contribution.
3. **macOS-only** — Screenpipe has Windows builds but Ghostwork uses AppleScript/AX heavily.
4. **LLM dependency for pattern extraction** — NREM/REM phases require multiple LLM calls. Cost and quality depend on model availability.
5. **Privacy-security tension** — raw events include OCR, keystrokes, clipboard. PII stripping before LLM calls is mentioned but effectiveness depends on regex patterns.
6. **5-day-old project** — too early to evaluate execution quality. Architecture is well-designed but no real-world usage evidence.

## Follow-up (06-14)

Initial deep read complete, no revisit needed until 06-28. The 4-layer memory + sleep consolidation architecture is the most interesting design pattern here — worth tracking whether the project gains contributors or stays solo. If still solo at revisit, downgrade to archive.

## Links

- [[screenpipe]], [[agent-autonomy-models]], [[memory-consolidation-as-skill-entry]]
