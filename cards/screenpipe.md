---
title: Screenpipe
created: 2026-06-14
tags: [tool, screen-capture, agent-infrastructure, external]
last_verified: 2026-06-14
---

# Screenpipe (mediar-ai/screenpipe)

Screen and audio capture library designed as an input layer for AI agents. Continuously records screen content (OCR), audio (transcription), and user interactions, making them queryable for downstream agent systems.

## Key Properties

- **Platforms**: macOS, Windows, Linux
- **Capture**: Screen frames → OCR text, audio → transcription, keyboard/mouse events
- **Storage**: Local SQLite — all data stays on-device
- **Query API**: Search captured data by time range, app, content text
- **Plugin system**: "Pipes" that process captured data streams

## Relevance

Primary data source for observation-based agents like [[ghostwork]]. Provides the raw event stream (screen OCR + keystrokes + audio) that memory consolidation pipelines then process into patterns and skills.

Privacy-sensitive by design — everything local — but the raw capture includes keystrokes and clipboard, so PII exposure to downstream LLM calls is a real concern.

## Links

- [[ghostwork]]
- [[agent-autonomy-models]]
