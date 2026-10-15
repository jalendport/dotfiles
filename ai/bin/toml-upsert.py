#!/usr/bin/env python3
"""Set single-line TOML fragment keys without rewriting other target lines."""

import re
import sys
from pathlib import Path

try:
    import tomllib  # Python 3.11+: validates the fragment
except ImportError:  # macOS system python3 is 3.9: the fragment is not validated
    tomllib = None


TABLE = re.compile(r"^\s*\[([^\]]+)\]\s*(?:#.*)?$")
KEY = re.compile(r"^\s*([^=]+?)\s*=")


def upsert(target, fragment):
    fragment_text = fragment.read_bytes().decode("utf-8")
    if tomllib:
        tomllib.loads(fragment_text)
    tables = {}
    keys = None
    for line in fragment_text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        header = TABLE.match(line)
        if header:
            keys = tables.setdefault(header.group(1).strip(), [])
            continue
        key = KEY.match(line)
        if keys is None or key is None:
            raise ValueError("fragment must use table headers and single-line values")
        # Parsing each assignment also rejects multiline fragment values.
        if tomllib:
            tomllib.loads(line)
        keys.append((key.group(1).strip(), line))

    original = target.read_bytes() if target.exists() else b""
    lines = original.decode("utf-8").splitlines(keepends=True)
    newline = "\r\n" if b"\r\n" in original else "\n"
    for table, assignments in tables.items():
        start = None
        end = len(lines)
        for index, line in enumerate(lines):
            header = TABLE.match(line)
            if start is not None and (header or re.match(r"^\s*\[\[.+\]\]\s*(?:#.*)?$", line)):
                end = index
                break
            if header and header.group(1).strip() == table:
                start = index
        if start is None:
            if lines and not lines[-1].endswith(("\n", "\r")):
                lines.append(newline)
            if lines and lines[-1].strip():
                lines.append(newline)
            start = len(lines)
            lines.append(f"[{table}]{newline}")
            end = len(lines)

        missing = []
        for key, assignment in assignments:
            for index in range(start + 1, end):
                match = KEY.match(lines[index])
                if match and match.group(1).strip() == key:
                    ending = "\r\n" if lines[index].endswith("\r\n") else "\n" if lines[index].endswith("\n") else ""
                    lines[index] = assignment + ending
                    break
            else:
                missing.append(assignment + newline)
        if missing:
            if not lines[start].endswith(("\n", "\r")):
                lines[start] += newline
            lines[start + 1:start + 1] = missing

    result = "".join(lines).encode("utf-8")
    if result != original or not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(result)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: toml-upsert.py <target.toml> <fragment.toml>")
    try:
        upsert(Path(sys.argv[1]), Path(sys.argv[2]))
    except (OSError, ValueError) as error:
        sys.exit(f"toml-upsert: {error}")


if __name__ == "__main__":
    main()
