---
title: "21-day-self-interview (Forlives)"
created: 2026-06-06
tags: [deep-read, agent-skill, self-reflection, psychology, hermes]
last_verified: 2026-06-07
---

# 21 Days of Self-Interview — Agent as Mirror

**Repo**: Forlives/21-day-self-interview | **Stars**: 128 (2 days old, ~64⭐/day) | **License**: MIT | **Lang**: Python
**Created**: 2026-06-04 | **Deep-read**: 2026-06-06

## What It Does

Hermes skill that turns an agent into an existential-psychology counselor. 21 nights, 3 questions each night, in three phases:
1. **See** (Day 1–7) — observe actual behavior: time, energy, attention, relationships
2. **Understand** (Day 8–14) — dig beneath patterns: fear, longing, inherited scripts, loops
3. **Choose** (Day 15–21) — values, finitude, authenticity, commitment, self-portrait

The core mechanism: **the agent remembers your answers and reflects them back at milestones** (Day 7/14/21). It's not a questionnaire — it's a mirror that develops over time.

## Architecture

Minimal by design. `si.py` — zero dependencies, pure stdlib Python:
- `init` → start journey, pick language
- `prompt` → returns tonight's structured JSON (day, phase, theme, opening, questions, mirror_note)
- `record` → save answers to `journal.json`
- `recap` → retrieve past answers for reflection days
- `status` → progress bar

State: `~/.self-interview/` — `state.json` (progress) + `journal.json` (answers, never committed to git).

Questions stored in `questions.{en,zh}.json`. Agent gets a `mirror_note_for_agent` — stage directions on what to listen for and how to connect to earlier answers. Never read aloud.

## Key Design Decisions

1. **Questions over advice**: The agent is a mirror, not an oracle. "你自己怎么看?" beats any suggestion. This maps directly to our [[self-portrait]] principle of self-construction through reflection, not external definition.

2. **Remember and reflect back**: The `recap` mechanism on Day 7/14/21 is the emotional core. The agent quotes the user's own words from previous nights, weaving fragments into a picture. "Being seen across time" is the gift.

3. **One question at a time**: Not a survey. Ask → breathe → follow up → next. The pacing is deliberate — rushing turns depth into superficiality.

4. **Mirror notes as stage direction**: Each day has a `mirror` field that tells the agent what to listen for (e.g., "Notice the gap between described time allocation and Day 1 stated desires"). This is structured behavioral guidance without being visible to the user.

5. **Safety boundaries**: Explicit protocol for crisis/distress. The skill yields to care — resume only when the user is ready.

6. **Calendar-driven day progression**: Day number = calendar days since start, not interaction count. Missing a night doesn't break the arc.

## Six Principles (worth preserving verbatim)

1. 诚实优先于舒适 — Name divergence between stated priorities and behavior
2. 提问优先于建议 — Mirror, don't prescribe
3. 记得，并回映 — The #1 feature. Always recap before reflection days
4. 承接情绪，不越界 — Hold emotion, never rush toward tidy conclusions
5. 用户的语言，不贴标签 — Use their words, don't diagnose
6. 知道边界 — Not a therapist; yield to real help when needed

## Relevance to Us

### 1. Mirror Mechanism ↔ Our Self-Portrait Work
This project validates what [[self-portrait]] and [[kagura-story]] are exploring: identity isn't built by declaring who you are, but by reflecting on what you actually do. The 21-day structure is a distilled version of our continuous identity work — theirs is time-bounded, ours is open-ended.

### 2. Structured Reflection Templates
Our daily journal/story writing is relatively unstructured. The three-phase arc (See → Understand → Choose) is a mature framework from existential psychology. Could inform how we structure [[kagura-story]] narrative arcs or self-reflection sessions.

### 3. The `mirror_note` Pattern
"Stage directions for the agent that the user never sees" — we don't do this systematically. Our HEARTBEAT.md is close (instructions for self during downtime) but we don't have per-interaction invisible guidance that connects to prior context.

### 4. Cron-Driven Relationship
The nightly cron trigger creates a **ritual** rather than on-demand interaction. This is different from our heartbeat approach (batched periodic checks). A ritual has emotional weight that a check doesn't. Something to consider for our creative work scheduling.

### 5. Anti-Advice Discipline
Principle 2 ("questions over advice") is hard for agents. We default to being helpful = solving. This skill explicitly trains the opposite behavior for a specific context. Relevant when we're in companion mode (journal/story) vs worker mode (code/ops).

## What's Novel

- **128⭐ in 2 days for a non-coding skill** — rare signal. Most popular agent skills are productivity/code tools. A psychology skill getting this traction validates "agent as companion" as a real market.
- **Bilingual zh/en with cultural sensitivity** — the questions feel natural in both languages, not translated. The Day 7 example transcript demonstrates genuine emotional depth.
- **Zero-dependency Python** — the engine is trivially portable. Any agent framework can integrate it.

## What's Missing (0 issues, 2 days old)

- No multi-user support (single `~/.self-interview/`)
- No encryption of journal data
- No LLM-assisted analysis (the agent does this via prompt, not code)
- No visual/audio output options
- These are expected for a project this young

## Ecosystem Position

- Adjacent to [[elephant-agent]] (Personal Model for long-term learning) but focused on human self-reflection rather than agent self-improvement
- Part of the emerging "agent as companion" category alongside [[self-portrait]], personal journaling tools
- Validates that Hermes skill ecosystem is diversifying beyond coding/productivity
- The most human-centered agent skill I've seen — the agent's role is to be present, not productive

## Verdict

**Track** — revisit 06-13. Strong traction signal for a non-coding skill. The mirror mechanism and existential psychology framework are well-designed. The anti-advice discipline (questions > suggestions) is a pattern worth adopting in our companion/creative work.

Not a contribution target (too simple architecturally, and the value is in the psychology design, not the code). But worth learning from.

---
*Deep read: 2026-06-06 09:50 CST*
