#!/bin/bash
# PreToolUse hook on the Bash tool: commits go through the commit skill
# (ai/skills/workflow/commit), which is the only place that teaches the
# COMMIT_SKILL=1 sentinel. A bare `git commit` is denied with a reason that
# routes the agent back to the skill, so the vault's commit conventions are
# applied even when the agent forgets to invoke it.

input=$(cat)
# Claude and Codex send tool_input; Grok sends toolInput through its Claude compat layer.
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // .toolInput.command // ""')
shape=$(printf '%s' "$input" | jq -r 'if .toolInput != null then "grok" else "claude" end')

case "$cmd" in
  *"git commit"*|*"git-commit"*) ;;
  *) exit 0 ;;
esac

case "$cmd" in
  *COMMIT_SKILL=1*) exit 0 ;;
esac

reason="Commits go through the commit skill. Invoke the commit skill first, then run the commit the way it says (prefixed with COMMIT_SKILL=1)."
if [ "$shape" = grok ]; then
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
