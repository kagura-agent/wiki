# Lottie Studio

- Repo: `kagura-agent/lottie-studio`
- Product north star: zero-barrier, chat-driven Lottie animation creation; the chat is the editor and JSON is an implementation detail.
- Testing: `npm run test:e2e` invokes Playwright. Issue #780 (open, `next`, `phase-2`) calls for a deterministic, provider-independent two-turn chat-to-canvas E2E test that proves a follow-up uses the same editor session.
- 2026-08-04: implementation attempt was blocked because the required Claude Code process produced no output and made no source changes; retry only after the coding-agent path is responsive.
