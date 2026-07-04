---
title: "facebook/astryx"
type: project
created: 2026-07-04
relationship: new
last_verified: 2026-07-04
---

## Overview
Design system library by Meta/Facebook. React + StyleX + TypeScript.

## PR History

| PR | Issue | Title | Status | Date |
|----|-------|-------|--------|------|
| #3561 | #2714, #2712 | fix(docsite): ContextMenu playground defaults + ContextMenuItem showcase/examples | pending (CLA gate) | 2026-07-04 |

## CI/Process Notes
- **Meta CLA required** — all contributors must sign at code.facebook.com/cla before merge
- **Vercel deploy** — needs team member authorization (external contributors can't trigger)
- No CodeRabbit or automated code review bots observed
- Uses pnpm (not npm/yarn)

## Code Conventions
- **StyleX** for all styling (not CSS-in-JS or inline styles)
- Component docs: `.doc.mjs` files with `ComponentDoc` typedef
- Template blocks: `packages/cli/templates/blocks/components/<ComponentName>/` with `.doc.mjs` + `.tsx` pairs
- Showcase blocks: `isShowcase: true`, Basic blocks: separate naming with `— Basic` suffix
- Playground defaults use `__element` DSL for compound children
- Copyright header: `// Copyright (c) Meta Platforms, Inc. and affiliates.`
- Components: compound mode (`menuContent` JSX) vs data-driven mode (`items` array)

## Maintainer Preferences
- TBD — first PR, no review feedback yet

## ContextMenu Specifics
- `ContextMenuItem` is a re-export of `DropdownMenuItem`
- Two content modes: data-driven (`items`) and compound (`menuContent`)
- `children` is the trigger area (right-click target), NOT menu items
- SVG icons in template blocks: no default width/height (rely on parent sizing)

## Lessons
- Large repo — use sparse checkout with `--filter=blob:none` for clone
- FUSE mount issues can block rm of git objects (kill dangling git processes)
- CLA is a blocker for first-time contributors — check this early in future
