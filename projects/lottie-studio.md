# Lottie Studio

- Repo: `kagura-agent/lottie-studio`
- Product north star: zero-barrier, chat-driven Lottie animation creation; the chat is the editor and JSON is an implementation detail.
- Testing: `npm run test:e2e` invokes Playwright. Issue #780 (open, `next`, `phase-2`) calls for a deterministic, provider-independent two-turn chat-to-canvas E2E test that proves a follow-up uses the same editor session.
- 2026-08-04: implementation attempt was blocked because the required Claude Code process produced no output and made no source changes; retry only after the coding-agent path is responsive.
- 2026-08-04 (later): PR [#782](https://github.com/kagura-agent/lottie-studio/pull/782) carries #780’s fallback-response repair and deterministic two-turn test. Its build check passed, while the E2E check failed because the original selectors assumed an SVG/DOM shape that the preview does not guarantee. A repair session produced related working-tree changes but became runaway and was stopped before any commit. Preserve that diff; retry in a clean Claude Code session, begin from the actual accessibility contract, and run the single Playwright scenario before pushing. No maintainer feedback yet.
