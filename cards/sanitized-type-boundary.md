---
title: Sanitized Type Boundary
created: 2026-06-04
tags: [pattern, security, type-system]
last_verified: 2026-08-02
---

The `Sanitized<T>` newtype pattern from ai-memory enforces at compile time that all persisted text passes through a sanitizer. It is impossible to construct a `Sanitized<T>` without scrubbing, preventing accidental persistence of bearer tokens, API keys, JWTs, PEM private keys, and URL-embedded credentials. This is defense-in-depth via the type system rather than runtime checks — a strong form of [[permission-hardening]] and [[agent-credential-security]].
