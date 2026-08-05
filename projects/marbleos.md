# MarbleOS — File-and-Task GUI for AI Work

> **Status:** surface scan only (2026-08-05). Closed-source macOS beta; no public source, test suite, or issue tracker was found, so its implementation and reliability claims are **unverified**.

## What it presents

MarbleOS frames agent work as a visible workspace of files, tools, tasks, and outputs rather than a chat-thread transcript. Its published examples are business workflows: lead research, client briefs, spreadsheets, outreach drafts, recurring reminders, and morning briefs. Distribution is a macOS `.dmg` beta.

## Ecosystem position

It validates the same interaction-design pressure addressed by desktop harnesses such as [[wmux]], [[diri]], and [[cindy]]: long-running agent work needs inspectable artifacts and state, not only conversational history. MarbleOS is a proprietary end-user productivity product rather than an inspectable agent harness, so it offers product-direction evidence but no reusable implementation pattern.

## Insight and boundary

The noteworthy claim is not a new orchestration architecture but a UI inversion: chat becomes an input surface while files/tasks/outputs are the durable primary interface. That is compatible with [[agent-harness-landscape]] and our [[FlowForge]] workflow approach, which already makes execution state explicit.

The counterweight is important: visibility alone is not verification. The public materials expose neither provenance, task-state transitions, tool permissions, nor evaluation tests. A workspace UI can make an agent feel inspectable without proving that its artifacts are complete or its actions controlled.

## Relevance

For our tools, preserve the separation between **visible workflow state** and **verifiable execution evidence**: a task view should link to command output, branch/commit identity, and explicit gates—not merely summarize progress in chat.

## Sources

- MarbleOS demo and learn pages, accessed 2026-08-05
- HN "What should the GUI for AI agents look like?" (136 points in `tools/hn-scan.sh`, 2026-08-05)

## Deep-read boundary check (2026-08-05)

The public Learn gallery is narrowly oriented around **reviewable first passes**: lead sheets, meeting briefs, candidate workbooks, research spreadsheets, outreach drafts, and recurring brief/reminder tasks. This makes MarbleOS less a general autonomous-agent claim than a product bet on batching low-stakes knowledge work into editable artifacts before a human returns.

There is still no inspectable implementation: `marbleos/demo` returns GitHub repository-not-found for both clone and issue-list requests, so no source, tests, issue critiques, permissions model, or task-state semantics could be assessed. The earlier [[wmux]] pattern remains the useful contrast: its completion-evidence gate can be inspected and tested, whereas MarbleOS's workspace visibility is only a UX claim. Treat it as evidence for the visible-artifacts direction in [[agent-harness-landscape]], not as evidence that it delivers verifiable execution.

## Re-check (2026-08-05)

A GitHub API lookup for `marbleos/demo` returned 404; there remains no public repository to inspect for code, tests, or issues. The HN attention therefore strengthens the **product-direction** signal only, not any claim about implementation quality or agent reliability.
