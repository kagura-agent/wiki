---
title: "Alibaba Open-Code-Review"
created: 2026-06-05
updated: 2026-06-05
tags: [code-review, agent, enterprise, alibaba]
last_verified: 2026-06-05
---

# Alibaba Open-Code-Review

Go CLI for AI-powered code review. Battle-tested at Alibaba (tens of thousands of devs, millions of defects over 2 years). Open-sourced 2026-05-18.

Links: [[code-review]], [[code-review-lessons]], [[agent-native-code-search]]

## Stats
- 1308⭐ in 18 days (fast growth)
- Go, OpenAI & Anthropic compatible
- github.com/alibaba/open-code-review

## Architecture — Hybrid Deterministic + LLM Agent

The key design: **two-phase review pipeline**.

### Phase 1: Plan (Deterministic + LLM)
- Diff → file-type matched rules → plan prompt
- Path-based rule system: `**/*.java → java.md`, `**/*.ts → ts_js.md`, etc.
- Built-in fine-tuned rulesets per language (NPE, thread-safety, XSS, SQL injection, dead code, React best practices)
- Plan output: structured JSON with change_summary + risk_points + tool_call_strategy
- Plan is optional, triggered when diff > 50 lines (`PLAN_MODE_LINE_THRESHOLD`)

### Phase 2: Main Review (Agent with Tools)
- Agent has 6 tools: `file_read`, `file_find`, `file_read_diff`, `code_search`, `code_comment`, `task_done`
- Max 20 tool calls per file (`MAX_TOOL_REQUEST_TIMES`)
- 5 min timeout per subtask (`MAX_SUBTASK_EXECUTION_TIME_MINUTES`)
- Agent reads context, searches codebase, then emits structured `code_comment` tool calls with line-level precision
- Comments include: file, line range, severity, category, suggestion, and suggested diff

### Memory Compression
- `MEMORY_COMPRESSION_TASK`: When context grows large, compress conversation history
- Prevents context window overflow on large PRs

### Rules System (the "deterministic" part)
- `system_rules.json` maps file glob patterns → rule markdown files
- Each rule file is language-specific review checklist (e.g., Java: NPE patterns, thread safety, N+1 queries)
- Rules are injected as `{{system_rule}}` in the user prompt
- Users can add custom rules via `rule.json` in project root
- This is where "battle-tested at Alibaba scale" shows — the rules encode years of real review patterns

## What Makes It Different from Our code-review Skill

| Aspect | Alibaba OCR | Our code-review skill |
|--------|-------------|----------------------|
| Architecture | Single agent with tools | Multi-model parallel reviewers |
| Rules | Built-in language-specific checklists | Ad-hoc per-reviewer prompts |
| Tools | file_read, code_search, etc. | Model's native code understanding |
| Output | Structured code_comment tool calls | Free-form review text |
| Scale | Enterprise (millions of defects) | Hobby (our own PRs) |
| Planning | Explicit plan phase for large diffs | None |

## Key Insights

1. **Rules are the moat.** The LLM is commodity; the language-specific review checklists encode institutional knowledge. Anyone can swap the LLM, but the rules took 2 years to refine.

2. **Tool-based commenting > free-form text.** Using `code_comment` as a tool forces structured output (file, line, severity, suggestion). This is more reliable than asking the model to format comments.

3. **Plan phase prevents tool-call waste.** On large diffs, planning which files need deep inspection (with code_search) vs. surface review saves 40-60% of tool calls.

4. **Per-file concurrency model.** Each changed file gets its own review session. Files are reviewed in parallel with configurable concurrency. This is simpler than reviewing the whole PR at once.

5. **The "hybrid" is really "rules as prompt, LLM as executor."** The deterministic part isn't code analysis — it's rule selection and prompt construction. The actual analysis is still LLM. "Hybrid" means "structured prompts + agent tools", not "static analysis + LLM."

## Issues — What Users Want

- Full-repo scan (not just diffs) — currently diff-only
- HarmonyOS .ets file support
- Per-file tool-call limit customization (20 isn't enough for complex files)
- GitLab MR publishing (currently GitHub Actions only)
- Windows support issues (session file writing, binary crashes)
- Model switching integration (cc-switch compatibility)

## Relevance to Us

- Our code-review skill could benefit from their rules approach — inject language-specific checklists instead of relying on models' general knowledge
- The `code_comment` tool pattern is worth adopting — structured output via tool calls
- Plan phase concept applicable to any large-context agent task
- Their benchmark methodology (if published) would be interesting to compare

## Contribution Potential

- **Not accepting external contributions** for the core Go CLI
- But the rules system (`rule_docs/`) and skills (`skills/`) are extendable
- Issues are mostly feature requests, not bugs — codebase seems solid
- Worth monitoring but not a contribution target
