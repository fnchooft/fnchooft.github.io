#!/usr/bin/env python3
"""
Inject GitHub file content into GitBook markdown files.
Replaces markers like:
  <!-- include: path/to/file.sh -->
  <!-- include: path/to/file.sh lines=10-20 -->
  <!-- include: path/to/file.sh lines=10- -->
  <!-- include: path/to/file.sh lines=-20 -->
  <!-- /include -->

Paths are resolved relative to the markdown file's own directory first.
If not found there, falls back to repo root.
"""

import os
import re
import sys

INCLUDE_RE = re.compile(
    r'<!--\s*include:\s*(?P<path>[^\s]+)'
    r'(?:\s+lang=(?P<lang>\S+))?'
    r'(?:\s+lines=(?P<lines>\S+))?\s*-->'
    r'.*?'
    r'<!--\s*/include\s*-->',
    re.DOTALL
)

def parse_lines(spec, total):
    """Parse a lines= spec like '10-20', '10-', '-20' into (start, end) 0-based indices."""
    if '-' not in spec:
        n = int(spec)
        return (n - 1, n)
    lo, hi = spec.split('-', 1)
    start = (int(lo) - 1) if lo else 0
    end   = int(hi) if hi else total
    return (start, end)

def resolve_path(rel_path, md_dir, repo_root):
    """Resolve rel_path: prefer sibling to the .md file, fall back to repo root."""
    local = os.path.join(md_dir, rel_path)
    if os.path.exists(local):
        return local
    root_path = os.path.join(repo_root, rel_path)
    if os.path.exists(root_path):
        return root_path
    return None  # not found anywhere

def inject(md_path, repo_root):
    md_dir = os.path.dirname(os.path.abspath(md_path))

    with open(md_path, 'r') as f:
        content = f.read()

    def replace(m):
        rel_path   = m.group('path')
        lang       = m.group('lang') or rel_path.rsplit('.', 1)[-1]
        lines_spec = m.group('lines')

        abs_path = resolve_path(rel_path, md_dir, repo_root)
        if abs_path is None:
            print(f"  WARNING: '{rel_path}' not found (tried {md_dir}/ and repo root)", file=sys.stderr)
            return m.group(0)

        with open(abs_path, 'r') as f:
            all_lines = f.readlines()

        if lines_spec:
            start, end = parse_lines(lines_spec, len(all_lines))
            code = ''.join(all_lines[start:end]).rstrip()
        else:
            code = ''.join(all_lines).rstrip()

        # Rebuild marker cleanly
        parts = [f"<!-- include: {rel_path}"]
        if m.group('lang'):
            parts.append(f" lang={m.group('lang')}")
        if lines_spec:
            parts.append(f" lines={lines_spec}")
        parts.append(" -->")
        marker = ''.join(parts)

        return (
            f"{marker}\n"
            f"```{lang}\n"
            f"{code}\n"
            f"```\n"
            f"<!-- /include -->"
        )

    new_content, n = INCLUDE_RE.subn(replace, content)
    if n > 0:
        with open(md_path, 'w') as f:
            f.write(new_content)
        print(f"  {md_path}: {n} snippet(s) injected")

def main():
    repo_root = os.environ.get('GITHUB_WORKSPACE', '.')
    docs_dir  = os.environ.get('DOCS_DIR', 'docs')
    docs_path = os.path.join(repo_root, docs_dir)

    md_files = []
    for root, _, files in os.walk(docs_path):
        for f in files:
            if f.endswith('.md'):
                md_files.append(os.path.join(root, f))

    if not md_files:
        print("No markdown files found.")
        return

    for md in md_files:
        inject(md, repo_root)

if __name__ == '__main__':
    main()
