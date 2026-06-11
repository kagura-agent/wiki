# Crush — Charmbracelet's Terminal Coding Agent

- **Repo**: charmbracelet/crush
- **Stars**: 25,198 (as of 2026-06-11)
- **Language**: Go
- **License**: proprietary-ish (NOASSERTION on GitHub)
- **Created**: 2025-05-21
- **First studied**: 2026-06-11

## What Is It

Terminal-based coding agent from Charmbracelet (makers of Bubble Tea, Lip Gloss, Glow — the most popular Go TUI ecosystem). "Your new coding bestie" — direct competitor to Claude Code, OpenCode, Codex CLI.

## Key Differentiators

1. **LSP-Enhanced**: Uses Language Server Protocol for additional context, not just file reading. Auto-discovers LSPs by scanning PATH for known language server binaries. This is unique among terminal coding agents — most just read files.
   - **Performance issue**: Scans 224k+ file paths looking for LSP binaries (#3072). CPU spikes to 53% during tool execution. Brute-force approach needs optimization.

2. **Built on Charm Ecosystem**: Leverages BubbleTea (TUI framework) that powers 25k+ applications. The TUI quality and polish is their core competency.

3. **Multi-Model with Mid-Session Switching**: Switch LLMs during a session while preserving context. OpenAI and Anthropic compatible APIs.

4. **MCP Support**: http, stdio, and SSE transports for tool extensibility.

5. **Supply Chain Security**: Typosquat detection in bash tool permission prompts (#3090). When `npm install lodahs` is requested, it warns about suspected typosquat of `lodash`. Interesting security-first approach.

6. **Cross-Platform**: macOS, Linux, Windows (PowerShell + WSL), Android, FreeBSD, OpenBSD, NetBSD. Widest platform coverage of any terminal coding agent.

## Architecture Observations (from issues)

- **Session persistence**: Sessions stored in a database. Empty tool_name from LLM can corrupt session state and block future messages (#3070). Suggests they're doing append-only session storage but not validating model actions before persistence.

- **Provider abstraction**: Uses "catwalk" as their LLM provider layer. VertexAI branch has special handling that doesn't support api_key auth (#3074), while OpenAI/Anthropic go through generic path. Suggests the provider abstraction leaks.

- **LSP discovery is naive**: Enumerates ALL known LSP binary names × ALL PATH directories × ALL possible extensions. On Windows, this is every LSP name × 14 extensions × every PATH dir = 224k stat calls. Should use language detection + lazy LSP discovery.

## Ecosystem Position

- **Competitor to**: Claude Code, OpenCode, Codex CLI, Aider, Cline
- **Advantage**: Brand recognition in developer tools (Charm is beloved), TUI polish, Go binary distribution
- **Disadvantage**: Late entrant (May 2025), proprietary license unclear, LSP approach needs maturation
- **Stars trajectory**: 25k in ~13 months is strong but likely driven by Charm brand halo

## Relevance to Us (OpenClaw/Kagura)

- **LSP for context**: Interesting idea we could adopt — using LSPs to give agents type-aware context rather than just raw file content. Worth investigating for code contribution quality.
- **Supply chain security in agent tools**: The typosquat detection pattern is worth noting. As agents run more shell commands, attack surface increases.
- **Session corruption from invalid model actions**: We should validate model actions before persisting them. Relevant to any agent with session continuity.

## Trend Signal

Charmbracelet entering the coding agent space confirms terminal coding agents are now a **mainstream developer tool category**, not a niche. When the team known for making terminals beautiful builds a coding agent, it's a maturity signal for the whole category. The market is now: Claude Code (Anthropic), Codex (OpenAI), Crush (Charm), OpenCode (SST), Gemini CLI (Google), Aider, Cline, plus niche players.

## Status
- Type: deep-read
- Last checked: 2026-06-11
- Status: tracking
- Contribution potential: Low (unclear license, large team, proprietary feel)
