#!/bin/bash
# Claude Code status line. Receives session JSON on stdin.
# Shows: dir | git/worktree | model | live context vs 100K "smart zone"
#        (finance.biggo.com/news/e7209c094224b09c)
#        | real subscription usage: 5h session + 7d weekly (% used + reset countdown).
input=$(cat)

LIMIT=100000
now=$(date +%s)
ansi_reset=$'\033[0m'

# Green <50, yellow 50-80, red >=80 (% of a limit consumed).
pct_color() {
  if   [ "$1" -ge 80 ]; then printf '\033[1;31m'
  elif [ "$1" -ge 50 ]; then printf '\033[33m'
  else                       printf '\033[32m'; fi
}

# Human countdown from a number of seconds: 4d3h / 4d / 2h24m / 12m / now.
countdown() {
  local s=$1 d h m
  [ "$s" -le 0 ] && { echo "now"; return; }
  d=$(( s / 86400 )); h=$(( (s % 86400) / 3600 )); m=$(( (s % 3600) / 60 ))
  if   [ "$d" -gt 0 ] && [ "$h" -gt 0 ]; then echo "${d}d${h}h"
  elif [ "$d" -gt 0 ];                   then echo "${d}d"
  elif [ "$h" -gt 0 ];                   then echo "${h}h${m}m"
  else                                        echo "${m}m"; fi
}

model_name=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
dir=$(basename "$cwd")

# Git segment: branch name, with a ⑂ marker when this is a linked worktree
# (git-dir differs from git-common-dir only inside a linked worktree).
git_seg=""
if branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  gitdir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
  commondir=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)
  marker=""
  [ "$gitdir" != "$commondir" ] && marker="⑂ "
  git_seg=" | ${marker}${branch}"
fi

# --- Context tokens: latest turn's full input + output, vs 100K smart zone -----
used=0
if [ -f "$transcript" ]; then
  used=$(tail -r "$transcript" 2>/dev/null | while IFS= read -r line; do
    t=$(printf '%s' "$line" | jq -r '
      if (.message.usage) then
        (.message.usage
          | (.input_tokens // 0)
          + (.cache_creation_input_tokens // 0)
          + (.cache_read_input_tokens // 0)
          + (.output_tokens // 0))
      else empty end' 2>/dev/null)
    if [ -n "$t" ]; then echo "$t"; break; fi
  done)
fi
[ -z "$used" ] && used=0

usedk=$(awk -v u="$used" 'BEGIN{printf "%.0f", u/1000}')
pct=$(awk -v u="$used" -v lim="$LIMIT" 'BEGIN{printf "%.0f", u*100/lim}')
if   [ "$used" -ge "$LIMIT" ];              then ctx_color=$'\033[1;31m'
elif [ "$used" -ge "$((LIMIT * 8 / 10))" ]; then ctx_color=$'\033[33m'
else                                             ctx_color=$'\033[32m'; fi

# --- Real subscription usage: Claude Code injects .rate_limits into stdin ------
# Present for subscribers after the first API response; segments omitted if absent.
IFS=$'\t' read -r five_pct five_reset week_pct week_reset < <(
  printf '%s' "$input" | jq -r '
    [ (.rate_limits.five_hour.used_percentage  // ""),
      (.rate_limits.five_hour.resets_at        // ""),
      (.rate_limits.seven_day.used_percentage  // ""),
      (.rate_limits.seven_day.resets_at        // "") ] | @tsv')

usage_seg=""
if [ -n "$five_pct" ]; then
  p=$(printf '%.0f' "$five_pct"); c=$(pct_color "$p")
  usage_seg=" | 5h ${c}${p}%${ansi_reset} ($(countdown $(( ${five_reset%.*} - now ))))"
fi
if [ -n "$week_pct" ]; then
  p=$(printf '%.0f' "$week_pct"); c=$(pct_color "$p")
  [ -n "$usage_seg" ] || usage_seg=" |"
  usage_seg="${usage_seg} · 7d ${c}${p}%${ansi_reset} ($(countdown $(( ${week_reset%.*} - now ))))"
fi

tokens_seg=" | ${ctx_color}${usedk}K/100K tokens (${pct}%)${ansi_reset}"

printf '%s%s | %s%s%s' \
  "$dir" "$git_seg" "$model_name" \
  "$usage_seg" "$tokens_seg"
