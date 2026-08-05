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

## Re-check (2026-08-05)

A GitHub API lookup for `marbleos/demo` returned 404; there remains no public repository to inspect for code, tests, or issues. The HN attention therefore strengthens the **product-direction** signal only, not any claim about implementation quality or agent reliability.
