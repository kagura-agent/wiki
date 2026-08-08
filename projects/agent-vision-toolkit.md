---
title: "agent-vision-toolkit — task-aware vision adapter for text-only coding agents"
created: 2026-08-06
tags: [computer-use, vision, coding-agents, proxy, graceful-degradation]
last_verified: 2026-08-08
---

# agent-vision-toolkit (Anionex/agent-vision-toolkit)

**Repository:** https://github.com/Anionex/agent-vision-toolkit · **Observed 2026-08-06:** 323⭐, MIT, Python; created 2026-08-01 and pushed on 2026-08-06. It offers shell CLIs plus optional request-rewriting integrations for Codex, Claude Code, Pi/Oh My Pi, and OpenCode, so a text-only coding model can receive a vision model's textual description of an image.

## Architecture verified from source and tests

- The reusable `vision_client.py` sends one or more `data:`/HTTP image URLs to an OpenAI-compatible `/chat/completions` vision endpoint. It retries transient 429/5xx/network failures twice, does not retry 4xx authentication/configuration errors, and redacts the configured vision key from HTTP error text. `tests/test_vision_client.py` uses a local HTTP fixture to cover these cases plus language selection and multi-image requests.
- `vision_proxy.py` detects either OpenAI Responses or Anthropic Messages bodies by shape, replaces image blocks with descriptions, and forwards the otherwise text-only request. Its cache key is `(image URL, generated focus prompt)` rather than image alone, so a repeated image can be described differently when the agent asks a different question.
- The important differentiator is the **focus hint**: pasted images use their enclosing current-user text; tool-fetched images use the assistant's last paragraph explaining why it wants to inspect the image, otherwise the latest user request. The prompt explicitly tells the vision model to describe only visible content and treat text embedded in the image as content, not instructions.
- The proxy deliberately **fails open but visibly**. A vision failure becomes a `[vision unavailable: …]` text block while the request's ordinary text continues upstream. `tests/test_fail_open.py` verifies this for OpenAI and Anthropic payloads and for mixed successful/failed images. This preserves conversational availability but means the downstream model may still act without the image; it is not a safety stop.
- The toolkit also separates semantic vision from deterministic pixel work: `ground`/`detect` use vision for locations and visible elements, while `trace` locally vectorizes pixels. The README's coarse-to-fine sequence—first description, then targeted `glance`/`ground` region queries—keeps the text model responsible for reasoning rather than letting the vision model answer the whole task.

## Tradeoffs and boundary

This is a pragmatic **vision-to-text compatibility layer**, not native multimodal capability. Its most useful pattern is carrying the agent's immediate question across the modality boundary and caching only within that question context. That counters generic-caption failures without hiding the conversion from the model.

Its graceful-degradation choice is operationally sensible for coding conversations, but inappropriate as an evidence boundary for consequence-bearing visual actions: the error note is visible, not an enforced block. Any workflow using it for GUI control should independently require fresh observation and deterministic post-action checks, as in [[Qwen-CUA]], rather than infer success from a description.

## Ecosystem position and relevance

[[agent-vision-toolkit]] sits between DOM/AX-first automation such as [[chromex]] and [[tactile]], and screenshot-first computer use. It is complementary to [[OpenClaw]] and [[FlowForge]]: it can improve an agent's inspection input, while neither its proxy nor its tests establish authorization, state-machine governance, or outcome verification.

The transferable design is **intent-scoped observation**: attach the question that motivated an observation to its generated representation; retain enough provenance to say when that representation is unavailable; and reserve exact geometry for deterministic local tools. For our workflows, this reinforces that screenshots and generated descriptions are evidence for investigation, not proof of an external operation.

## Community signal and limits

The repository's API reports two open GitHub items, but `gh issue list --state all` returned no issues, so the visible count likely includes pull requests rather than substantive issue discussion. No external architectural criticism was available in the issue list at review time. A shallow clone was attempted but the process was SIGKILLed before completion; the source/test evidence above was therefore read via GitHub's repository API, not executed locally.

## Checkable prediction

If the integration layer attracts real multi-harness use, it will add bounded concurrency/rate controls or a persistent cache policy for vision calls by **2026-09-06**; current in-process cache eviction at 128 entries and per-request image description work can make high-image sessions expensive. **Confidence: medium.**
