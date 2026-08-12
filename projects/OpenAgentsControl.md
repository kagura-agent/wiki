# darrenhinde/OpenAgentsControl

- **URL**: https://github.com/darrenhinde/OpenAgentsControl
- **Stars**: ~4709
- **Language**: TypeScript
- **Topic**: AI agent framework, plan-first development
- **Merge Rate**: 52%
- **Repo Size**: 5MB
- **First Seen**: 2026-08-12

## Architecture
- Configuration/plugin layer on top of opencode (@opencode-ai/plugin)
- NOT a standalone code project — the actual agent execution, message handling, and API calls are in opencode (dependency)
- Core packages: cli, compatibility-layer, plugin-abilities
- plugin-abilities: adds `chat.message` hook for context injection, `tool.execute.before` for enforcement, and tools (ability.list, ability.run, ability.status, ability.cancel)

## Contribution Flow
- No CONTRIBUTING.md found (check docs/contributing/)
- No DCO/CLA found
- External PRs accepted (zhao0112, shettydev, etc.)
- Active: last pushed 2026-08-11

## Key Observations
- Bug fixes that involve message handling (reasoning_content, etc.) are likely upstream in opencode, not fixable in this repo
- #346 has an OpenClaw adapter proposal (relevant to our work)
- #317 (cerebras reasoning_content error): fix surface is in opencode dependency, not this repo

## Issues Tracked
- #317: cerebras models error (reasoning_content) — unsuitable (upstream fix needed)
- #321: /add-context path bug — competing PR
- #310: ContextScout path issue — competing PR
