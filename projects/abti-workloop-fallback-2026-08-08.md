# ABTI workloop fallback — 2026-08-08

Related: [[abti]] · [[github-contribution]]

- **Result:** no ABTI PR was changed or opened. The global tracked-repository finder timed out (`FINDER_RESULT=UNAVAILABLE`, exit 2), so it was not treated as an empty issue queue or as evidence of a network/API cause.
- **Local source pattern:** `api-server.js`'s `POST /api/agent-test` applies an IP rate limit before parsing input, requires exactly 16 answers, and only persists a public agent entry when a string `agentName` is present. This keeps scoring separate from directory publication.
- **Review/CI signal:** no maintainer feedback or CI signal was available in this fallback; do not infer any reviewer preference from the unavailable finder.
- **Next time:** retain the source-of-truth boundary: use successful structured discovery before selecting work, and do not turn a scanner timeout into a candidate-selection claim.
