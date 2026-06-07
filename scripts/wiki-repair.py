#!/usr/bin/env python3
"""
wiki-repair.py — Deterministic auto-repair for wiki-lint Error Book issues.

Implements the code-level repair layer from the LLM-Wiki two-layer repair
architecture (arXiv:2605.25480).

Currently supported repairs:
  - Missing frontmatter `title:` field (cards/ and projects/ only)

Usage:
  python3 wiki-repair.py [WIKI_DIR] [--dry-run|--apply]

  --dry-run  (default) Print what would change without modifying files.
  --apply    Actually modify files and append to .repair-ledger.jsonl.
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# Characters that require quoting a YAML scalar value.
YAML_SPECIAL = set(':{}[]#"\',')


def needs_yaml_quoting(value: str) -> bool:
    """Return True if *value* contains characters that need YAML quoting."""
    return any(ch in YAML_SPECIAL for ch in value)


def quote_yaml_value(value: str) -> str:
    """Return a safely-quoted YAML scalar string."""
    if needs_yaml_quoting(value):
        # Use double quotes; escape any embedded double quotes.
        escaped = value.replace('\\', '\\\\').replace('"', '\\"')
        return f'"{escaped}"'
    return value


def title_from_filename(path: Path) -> str:
    """Derive a title from a filename: hyphens → spaces, title-case."""
    stem = path.stem
    return stem.replace('-', ' ').title()


def parse_frontmatter(text: str):
    """Parse YAML frontmatter from markdown text.

    Returns (fm_lines, body) where fm_lines is a list of lines *inside*
    the ``---`` delimiters (excluding the delimiters themselves), or None
    if there is no frontmatter.  body is the remaining text after the
    closing ``---``.
    """
    if not text.startswith('---'):
        return None, text

    # Find the closing ---
    end = text.find('\n---', 3)
    if end == -1:
        # Frontmatter never closed — treat as no frontmatter.
        return None, text

    # Extract frontmatter lines (between the two --- lines).
    fm_block = text[4:end]  # skip opening "---\n"
    fm_lines = fm_block.split('\n')

    # Body starts after the closing "---\n"
    body_start = end + 4  # skip "\n---"
    if body_start < len(text) and text[body_start] == '\n':
        body_start += 1
    body = text[body_start:]

    return fm_lines, body


def has_title_field(fm_lines: list[str]) -> bool:
    """Check whether any frontmatter line defines ``title:``."""
    for line in fm_lines:
        stripped = line.lstrip()
        if stripped.startswith('title:') or stripped.startswith('title :'):
            return True
    return False


def extract_h1(body: str) -> str | None:
    """Return the text of the first ``# Heading`` in *body*, or None."""
    match = re.search(r'^#\s+(.+)$', body, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return None


def repair_missing_title(path: Path, wiki_root: Path, apply: bool,
                         ledger_entries: list) -> str:
    """Attempt to add a missing ``title:`` to *path*.

    Returns a status string: 'repaired', 'skipped', or 'ok'.
    """
    try:
        text = path.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        return 'skipped'

    if not text.strip():
        return 'skipped'

    fm_lines, body = parse_frontmatter(text)

    if fm_lines is None:
        # No frontmatter at all — skip (too risky to auto-add).
        return 'skipped'

    if has_title_field(fm_lines):
        return 'ok'

    # --- Determine title ---
    h1 = extract_h1(body)
    if h1:
        title = h1
        source = 'h1'
    else:
        title = title_from_filename(path)
        source = 'filename'

    quoted_title = quote_yaml_value(title)
    title_line = f'title: {quoted_title}'

    # --- Build new frontmatter ---
    new_fm_lines = [fm_lines[0]] if fm_lines else []
    # Insert title as the first field (after any blank first line).
    insert_idx = 0
    if fm_lines and fm_lines[0].strip() == '':
        insert_idx = 1
        new_fm_lines = [fm_lines[0]]
    new_fm_lines_before = fm_lines[:insert_idx]
    new_fm_lines_after = fm_lines[insert_idx:]

    new_fm = '\n'.join(new_fm_lines_before + [title_line] + new_fm_lines_after)
    new_text = f'---\n{new_fm}\n---\n{body}'

    rel = str(path.relative_to(wiki_root))

    if apply:
        path.write_text(new_text, encoding='utf-8')
        ledger_entries.append({
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'action': 'add_title',
            'file': rel,
            'title': title,
            'source': source,
        })
        print(f'  REPAIRED  {rel}  ← title: {quoted_title} (from {source})')
    else:
        print(f'  WOULD FIX {rel}  ← title: {quoted_title} (from {source})')

    return 'repaired'


def main():
    # --- Parse arguments ---
    args = sys.argv[1:]
    apply = False
    wiki_dir = None

    for arg in args:
        if arg == '--apply':
            apply = True
        elif arg == '--dry-run':
            apply = False
        elif not arg.startswith('-'):
            wiki_dir = arg

    if wiki_dir is None:
        # Default: script's parent's parent (scripts/ → wiki/)
        wiki_dir = str(Path(__file__).resolve().parent.parent)

    wiki_path = Path(wiki_dir).resolve()

    if not wiki_path.is_dir():
        print(f'Error: wiki directory not found: {wiki_path}', file=sys.stderr)
        sys.exit(1)

    mode = 'APPLY' if apply else 'DRY-RUN'
    print(f'wiki-repair [{mode}]  wiki={wiki_path}\n')

    # --- Collect target files ---
    target_dirs = ['cards', 'projects']
    md_files: list[Path] = []
    for d in target_dirs:
        dp = wiki_path / d
        if dp.is_dir():
            md_files.extend(sorted(dp.glob('*.md')))

    if not md_files:
        print('No .md files found in cards/ or projects/.')
        return

    # --- Run repairs ---
    ledger_entries: list[dict] = []
    counts = {'repaired': 0, 'skipped': 0, 'ok': 0}

    print(f'--- Missing title: repair ---')
    for f in md_files:
        status = repair_missing_title(f, wiki_path, apply, ledger_entries)
        counts[status] += 1

    # --- Write ledger ---
    if apply and ledger_entries:
        ledger_path = wiki_path / '.repair-ledger.jsonl'
        with open(ledger_path, 'a', encoding='utf-8') as fh:
            for entry in ledger_entries:
                fh.write(json.dumps(entry, ensure_ascii=False) + '\n')
        print(f'\nLedger: {len(ledger_entries)} entries appended to {ledger_path}')

    # --- Summary ---
    total = sum(counts.values())
    print(f'\n--- Summary ---')
    print(f'  Total files scanned: {total}')
    print(f'  Already OK:          {counts["ok"]}')
    print(f'  Repaired:            {counts["repaired"]}')
    print(f'  Skipped:             {counts["skipped"]}')

    if not apply and counts['repaired'] > 0:
        print(f'\n  (dry-run mode — re-run with --apply to modify files)')


if __name__ == '__main__':
    main()
