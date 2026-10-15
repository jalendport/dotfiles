#!/bin/bash
# Grok status line. Receives session JSON on stdin.
# Shows: dir | git/worktree | model | live context vs 150K smart zone.
input=$(cat)

LIMIT=150000
ansi_reset=$'\033[0m'

model_name=$(printf '%s' "$input" | jq -r '.model.display_name // "Grok"')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
branch=$(printf '%s' "$input" | jq -r '.workspace.branch // ""')
worktree=$(printf '%s' "$input" | jq -r '.workspace.git_worktree // .worktree.name // ""')
dir=$(basename "$cwd")

# Git segment: use the supplied branch, with a fallback for detached HEAD.
git_seg=""
if [ -z "$branch" ]; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi
if [ -n "$branch" ]; then
  marker=""
  [ -n "$worktree" ] && marker="⑂ "
  git_seg=" | ${marker}${branch}"
fi

# Context tokens: live window vs 150K smart zone.
used=$(printf '%s' "$input" | jq -r '.context_window.context_tokens // 0')
usedk=$(awk -v u="$used" 'BEGIN{printf "%.0f", u/1000}')
pct=$(awk -v u="$used" -v lim="$LIMIT" 'BEGIN{printf "%.0f", u*100/lim}')
if   [ "$used" -ge "$LIMIT" ];              then ctx_color=$'\033[1;31m'
elif [ "$used" -ge "$((LIMIT * 8 / 10))" ]; then ctx_color=$'\033[33m'
else                                             ctx_color=$'\033[32m'; fi

tokens_seg=" | ${ctx_color}${usedk}K/150K tokens (${pct}%)${ansi_reset}"

printf '%s%s | %s%s' \
  "$dir" "$git_seg" "$model_name" "$tokens_seg"
