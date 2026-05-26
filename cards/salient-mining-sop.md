# Salient Mining SOP

Structured procedure for mining past conversation sessions to extract long-term user insights. Originated from [[genericagent]] (2026-05-26).

## Core Idea

Conversation logs contain more signal than what's captured during real-time interaction. Post-hoc mining extracts three signal types:

1. **Emotional Events** — tonal shifts (anger, gratitude, frustration), not topic-level sentiment. Key distinction: "discussing sad topic calmly" ≠ emotional event. Sentiment-as-signal, not sentiment-as-content.

2. **Ongoing Activities** — what currently exists in user's life. Strict evidence standard: only user-initiated requests count; passive system references don't. "System has a cooking SOP" ≠ "user cooks."

3. **Disappeared Activities** — what left user's life. Inference allowed: completed one-time events = disappeared without explicit statement.

## Design Principles

- **Database, not report** — each finding is input for downstream tasks, not a summary to read
- **Incremental** — cursor-based processing, never re-scans already-processed sessions
- **Three persistent state artifacts**: activity knowledge layer (read-update-write), emotional events (append-only), incremental marker (cursor)
- **Consistency enforcement** — same item cannot be simultaneously "ongoing" and "disappeared"
- **Locatable** — every finding links to source session ID; unlocatable records have zero value

## Key Insight

This is **life modeling**, not conversation summarization. The frame is "what exists and existed in this user's life" — fundamentally different from "what facts did the user mention."

## Relevance to Our Architecture

We have `memory/YYYY-MM-DD.md` (daily logs) + `MEMORY.md` (curated long-term). Gaps:
- No emotional event tracking (we capture facts, not affect)
- No ongoing/disappeared distinction (MEMORY.md doesn't track staleness)
- No retroactive mining (we process in real-time only)

The "ongoing vs disappeared" framing could inform staleness detection for MEMORY.md entries.

## Anti-Patterns

- Mining by keyword grep → misses tonal signals, only catches explicit mentions
- Treating system/SOP references as evidence of user activity → inflates activity list
- Mixing "ongoing" and "disappeared" into one list with status tags → loses the ontological distinction

See also: [[genericagent]], [[claude-code-memory-architecture]], [[self-evolving-agent-landscape]]
