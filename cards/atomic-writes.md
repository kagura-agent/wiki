---
created: 2026-06-04
tags: [concept, reliability, architecture]
last_verified: 2026-06-04
---
# Atomic Writes

Pattern for crash-safe file persistence: write to temp file → fsync → os.replace → fsync parent directory. Prevents partial writes from corrupting state files on crash/power loss.

## Implementations

- **nanobot** `_write_text_atomic` (PR #4186, proposed): tmp → fsync → os.replace → fsync parent. Replaces all bare `write_text` calls for history, memory, soul, user files.
- **Standard Unix pattern**: `mkstemp` + write + `fsync` + `rename` (atomic on POSIX) + `fsync(dirfd)`
- **SQLite WAL**: Write-ahead log with checkpoint, different mechanism but same goal

## Why It Matters for Agents

Agent state files (memory, session history, config) are written frequently and read on startup. A crash during write can corrupt the file, losing all state. The "write to temp then rename" pattern ensures either the old or new version exists, never a partial write.

## Relevance to OpenClaw

OpenClaw's memory writes (MEMORY.md, memory/*.md, session state) are currently bare file operations without atomic guarantees. On crash during write, state corruption is possible. The nanobot approach of wrapping all persistence in atomic writes is worth considering.

## Links

- [[nanobot]] — source implementation
- [[write-ahead-session-persistence]] — related durability pattern
- [[dream-single-phase-consolidation]] — context where atomic writes were added
