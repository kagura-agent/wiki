---
title: "Code-Duo — Dual-Agent Cross-Review with Claim Watchdog"
slug: code-duo
status: deep-read
created: 2026-06-23
updated: 2026-06-23
stars: 36
repo: norika1207-lab/Code-Duo
tags: [multi-agent, verification, watchdog, loop-engineering]
last_verified: 2026-06-23
---

# Code-Duo

> Two AI coding agents (Claude + Codex) in one window. Stream every step, cross-review, and verify whether the AI actually changed what it claimed.

**Repo**: [norika1207-lab/Code-Duo](https://github.com/norika1207-lab/Code-Duo) | 36⭐ (2d old, 06-21) | Python | No license | Solo dev

## What It Does

Local web UI that drives `claude` and `codex` CLIs (subscription-based, no API keys). Routes prompts to either or both in parallel. Key modes:
- **Single agent**: Normal interaction with streaming step display
- **Both mode**: Same prompt to both agents simultaneously — compare solutions side by side
- **Cross-review**: One click sends one agent's output to the other for audit/takeover
- **Cost dashboard**: Per-vendor tokens, cost, cache-hit rate from local JSONL session files

## Core Innovation: Claim-vs-Reality Watchdog

Three-layer verification system that catches AI bullshit:

### 1. Filesystem Snapshot Diffing
```python
def _snapshot(cwd):
    # Walk project, record (mtime, size) per file
    # Skip .git, node_modules, __pycache__, etc.
    # Cap at 30K files
```
Take snapshot before agent turn. Take another after. `_diff()` finds any file with changed mtime or size.

### 2. Claim Verb Detection
Bilingual regex (EN + CN) counting action verbs:
```python
_CLAIM = re.compile(
    r"(created|added|wrote|updated|modified|deleted|fixed|done|"
    r"建立|新增|修改|完成了|做好了|搞定|加上了|實作)",
    re.I)
```

### 3. File Mention Extraction
Parses backtick-quoted tokens that look like file paths. For each, checks:
- Does it exist? → `missing` if not
- Is it non-empty? → `empty` if 0 bytes
- Was it modified this turn (in diff set or mtime < 300s)? → `verified`

### Bluff Detection Formula
```
bluff = writable_mode AND claims ≥ 2 AND 0 files_changed AND 0 verified
```
Translation: If the agent could write files, claimed it did ≥2 things, but zero files actually changed → **busywork**.

### Loop Detection
Simple streak counter:
```python
if claims >= 1 and changes == 0:
    STREAK[engine] += 1  # consecutive claim-but-no-change turns
else:
    STREAK[engine] = 0
if STREAK[engine] >= 3:
    # "looping 3× — claiming progress with 0 disk changes"
```

## Architecture

Minimal: 1100-line `app.py` (pure stdlib Python, no frameworks) + single `index.html` (vanilla JS). Zero dependencies.

- Thread-per-agent for parallel execution
- In-memory 30-entry behavior ring buffer (not persistent)
- 12-claim-mention cap per turn (prevents excessive I/O)
- Cost tracking reads Claude/Codex local JSONL session files directly

## Tradeoffs & Limitations

- **No content verification**: Checks that files changed, not that changes are correct. Whitespace edit passes.
- **Regex-based claim detection**: No semantic understanding. Future-tense "I'll create..." counts as claim. False positives possible.
- **No license**: Can't derive or contribute. Learning value only.
- **No tests**: 2-day-old project.
- **macOS-primary**: Linux/Windows less tested.

## Relationship to Ecosystem

- **Complements [[ralph-loop-runner]]**: Code-Duo monitors loop quality; ralph provides the loop structure
- **Related to [[neuralyzer]]**: Both address context rot in loops — neuralyzer via context reset, Code-Duo via verification
- **Validates [[multi-model-review]]**: Two-agent cross-review validates our code-review/spec-review multi-model approach
- **Positions against single-agent workflows**: Thesis — one AI will talk you into a wall; two AIs watching each other won't

## Applicability to Us

**Directly applicable.** Our DNA rule "verify subagent external operations" lacks a concrete tool. Code-Duo's watchdog provides a reference implementation.

Potential implementation:
1. **`verify-subagent-claims.sh`**: Snapshot repo before `claude --print`, snapshot after, compare claims vs changes
2. **Streak detection in FlowForge**: Track consecutive claim-but-no-change turns across subagent invocations
3. **Bilingual claim detection**: We're already multilingual (CN+EN workspace)

The mtime+size approach is pragmatically correct: fast, no file reads, catches 95% of real changes. Content hashing is unnecessary overhead for this use case.

## Key Insight

> The most interesting verification tool isn't what checks whether code is correct — it's what checks whether code was written at all. The gap between "AI said it did something" and "something actually happened on disk" is wider than most people realize.

This is the [[trace-gate-pattern]] applied to filesystem operations: trace claimed outputs back to actual state changes. See also [[agentic-sop-to-work]] for the abstract pattern.
