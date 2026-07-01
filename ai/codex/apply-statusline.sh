#!/bin/bash
set -euo pipefail

codex_home="${CODEX_HOME:-$HOME/.codex}"
config="$codex_home/config.toml"
status_line='status_line = ["current-dir", "git-branch", "model-with-reasoning", "context-used"]'

mkdir -p "$codex_home"

if [ ! -f "$config" ]; then
  {
    printf '[tui]\n'
    printf '%s\n' "$status_line"
  } > "$config"
  exit 0
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/codex-config.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

python3 - "$config" "$tmp" "$status_line" <<'PY'
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
status_line = sys.argv[3]

lines = src.read_text().splitlines(keepends=True)
table_re = re.compile(r"^\s*\[([^\]]+)\]\s*(?:#.*)?$")

tui_start = None
tui_end = len(lines)
first_tui_subtable = None

for idx, line in enumerate(lines):
    match = table_re.match(line)
    if not match:
        continue
    table = match.group(1).strip()
    if table == "tui":
        tui_start = idx
        tui_end = len(lines)
        continue
    if table.startswith("tui.") and first_tui_subtable is None:
        first_tui_subtable = idx
    if tui_start is not None and idx > tui_start:
        tui_end = idx
        break

if tui_start is None:
    block = ["[tui]\n", f"{status_line}\n", "\n"]
    if first_tui_subtable is None:
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        if lines and lines[-1].strip():
            lines.append("\n")
        lines.extend(block[:-1])
    else:
        lines[first_tui_subtable:first_tui_subtable] = block
else:
    status_idx = None
    for idx in range(tui_start + 1, tui_end):
        if re.match(r"^\s*status_line\s*=", lines[idx]):
            status_idx = idx
            break

    if status_idx is None:
        lines.insert(tui_start + 1, f"{status_line}\n")
    else:
        indent = re.match(r"^(\s*)", lines[status_idx]).group(1)
        lines[status_idx] = f"{indent}{status_line}\n"

dst.write_text("".join(lines))
PY

mv "$tmp" "$config"
trap - EXIT
