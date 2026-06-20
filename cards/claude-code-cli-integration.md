---
title: Claude Code Cli Integration
created: 2026-06-12
last_verified: 2026-06-20
status: active
depth: deep-dive
---
# Claude Code CLI Integration Tips

Hard-won lessons from integrating Claude Code CLI as a programmatic bridge (not just `--print` batch mode).

## 1. Message Passing: Use `-p` Not `--input-format stream-json`

`--input-format stream-json` with `user_message` format is **not processed** by Claude Code. Each invocation should use `-p` flag to pass the prompt directly.

```bash
# ✅ Works
claude -p "your prompt here" --permission-mode bypassPermissions

# ❌ Broken — user_message via stdin stream-json silently ignored
echo '{"type":"user_message","content":"..."}' | claude --input-format stream-json
```

## 2. Session IDs: Use Random UUIDs, Not Deterministic

`--session-id` locks the session. If the process crashes, the lock is **not released**, and subsequent runs with the same ID will fail or hang.

```bash
# ✅ Safe — each run gets a fresh session
claude -p "task" --session-id "$(uuidgen)"

# ❌ Dangerous — crash leaves orphan lock
claude -p "task" --session-id "fixed-session-name"
```

## 3. Event Parsing: Match `type`, Not `subtype`

Assistant events do **not** have `subtype: "text"`. Don't rely on subtype filtering for output parsing. Match on `type` directly.

```bash
# ✅ Correct
jq 'select(.type == "assistant")'

# ❌ Wrong — subtype:text doesn't exist on assistant events
jq 'select(.subtype == "text")'
```

## 4. Working Directory: Must Be Independent

`CLAUDE_WORKING_DIR` determines Claude Code's identity context. It must **not** point to your own workspace — Claude Code will read your config files and assume your identity, causing confusion.

```bash
# ✅ Correct — Claude Code operates in the target repo
CLAUDE_WORKING_DIR=/path/to/target-repo claude -p "fix bug"

# ❌ Wrong — Claude Code reads YOUR workspace identity
CLAUDE_WORKING_DIR=~/.openclaw/workspace claude -p "fix bug in /path/to/repo"
```

## Context

- Source: 2026-06-11 gradient (pattern: claude-code-bridge-integration)
- Applies to: Any tool/script/workflow that drives Claude Code programmatically
- Related: [[claude-code-source-analysis]] (architecture), AGENTS.md §Subagent 代码规则 (batch `--print` usage)
