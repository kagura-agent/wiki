---
title: "Parse-What-You-Execute Pattern"
created: 2026-05-21
tags: [security, shell, agent-infrastructure, pattern]
last_verified: 2026-05-21
---

# Parse-What-You-Execute Pattern

> If you're checking a string that will be interpreted by another parser (shell, SQL, etc.), your checker must understand that parser's grammar. Checking the raw string is always bypassable.

## The Problem

Agent permission systems check commands against blocklists/safelists as raw strings. But the execution layer (shell, database, etc.) parses the same string using its own grammar — chains, pipes, substitutions, subqueries. A safe-looking prefix can launder arbitrary dangerous commands.

**Example:** `echo $(rm -rf ~)` matches a "safe read" pattern (`echo *`) but the shell expands `$(...)` first.

## The Fix

Parse the command using the **same grammar** the execution layer will use. Check each parsed segment independently.

[[mercury-agent]] PR#48 implemented `splitShellSegments()` — a recursive tokenizer that:
- Handles quote contexts (single, double, backtick)
- Extracts `$(...)` and backtick substitutions as separate segments
- Recognizes chain operators (`;`, `&&`, `||`, `|`, `&`)
- Falls back conservatively for unparseable input

Auto-approve only when **every** segment independently passes the safelist.

## Classification

- CWE-78 (OS Command Injection)
- CWE-184 (Incomplete List of Disallowed Inputs)

## Applicability

Any agent framework with:
1. Shell execution capability
2. Permission checks on command strings
3. Auto-approval for "safe" commands

Includes: [[OpenClaw]], [[mercury-agent]], [[nanobot]], and any MCP server exposing shell tools.

## Related

- [[agent-security]]
- [[acp-permission-model]]
- [[elephant-agent]] — different domain but similar principle: check what you'll actually execute, not the raw input
