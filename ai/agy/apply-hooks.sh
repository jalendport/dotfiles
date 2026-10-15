#!/bin/bash
set -euo pipefail

config="${1:-$HOME/.gemini/config/hooks.json}"
hooks="$(dirname "$0")/hooks.json"

mkdir -p "$(dirname "$config")"

tmp="$(mktemp "${TMPDIR:-/tmp}/agy-hooks.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

if [ -f "$config" ]; then
  jq --slurpfile hooks "$hooks" '. + $hooks[0]' "$config" > "$tmp"
else
  jq . "$hooks" > "$tmp"
fi

mv "$tmp" "$config"
trap - EXIT
