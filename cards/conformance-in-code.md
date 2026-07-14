---
title: Conformance-in-Code
type: concept
status: stub
created: 2026-07-14
source: projects/understory.md
tags: [agent-patterns, validation, schema-enforcement]
last_verified: 2026-07-14
---

Format compliance should be enforced by code validation, not prompt instructions. When an agent's output must conform to a schema—frontmatter fields, link syntax, required sections—relying on the prompt to "remind" the model is brittle. A validation layer that rejects malformed output and triggers a retry is both more reliable and easier to audit.

This principle emerged from [[understory]], where memory files require strict YAML frontmatter and wikilink formatting. Early iterations used detailed prompt instructions to enforce structure; these drifted silently as prompts evolved. Moving conformance checks into code (JSON-Schema validation, regex guards, structural linters) eliminated an entire class of silent corruption.

The pattern generalises beyond memory systems. Any agent output that must match a contract—API response schemas, tool-call argument shapes, structured logs, card metadata—benefits from the same separation: let the model generate freely, then validate programmatically. See also [[agent-memory-landscape-202603]] for the broader landscape of agent memory approaches where this principle applies.
