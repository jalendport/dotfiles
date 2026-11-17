#!/bin/bash
# PreToolUse hook on the Bash tool: commits go through the commit skill
# (ai/skills/workflow/commit), which is the only place that teaches the
# COMMIT_SKILL=1 sentinel. A bare `git commit` is denied with a reason that
# routes the agent back to the skill, so the vault's commit conventions are
# applied even when the agent forgets to invoke it.

input=$(cat)
# Claude and Codex send tool_input; Grok sends toolInput; agy sends toolCall.
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // .toolInput.command // .toolCall.args.CommandLine // ""')
shape=$(printf '%s' "$input" | jq -r 'if .toolCall != null then "agy" elif .toolInput != null then "grok" else "claude" end')

# Match a commit only in command position: at the start of a line or after
# ; && || | ( with optional NAME=value words or env in front. Text inside
# quotes (a search pattern, a heredoc line, a message) is not a command, so
# quoted spans are removed before the match.
stripped=$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
pattern='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(env[[:space:]]+)?(git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit|git-commit)([[:space:]]|$)'
if ! printf '%s\n' "$stripped" | grep -Eq "$pattern"; then
  exit 0
fi

case "$cmd" in
  *COMMIT_SKILL=1*) exit 0 ;;
esac

reason="Commits go through the commit skill. Invoke the commit skill first, then run the commit the way it says (prefixed with COMMIT_SKILL=1)."
if [ "$shape" = grok ] || [ "$shape" = agy ]; then
  jq -n --arg r "$reason" '{decision: "deny", reason: $r}'
  exit 0
fi
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Commits go through the commit skill. Invoke the commit skill first, then run the commit the way it says (prefixed with COMMIT_SKILL=1)."
  }
}'
