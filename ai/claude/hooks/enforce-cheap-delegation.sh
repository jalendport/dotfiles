#!/bin/bash
# PreToolUse hook on the Agent tool: grunt-lane subagents (scout, grunt,
# Explore) must run on a cheap model. The per-call model param outranks agent
# frontmatter, so frontmatter alone cannot guarantee it — this hook closes
# that hole. Thinking lanes (Plan, general-purpose, claude, ...) pass through.

input=$(cat)
subagent=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // ""')
model=$(printf '%s' "$input" | jq -r '.tool_input.model // ""')

case "$subagent" in
  scout|grunt|Explore) ;;
  *) exit 0 ;;
esac

# CLAUDE_CODE_SUBAGENT_MODEL outranks the model param AND agent frontmatter,
# and its resolution is invisible to this hook — when it forces an expensive
# model, deny rather than let the lane silently re-route.
case "${CLAUDE_CODE_SUBAGENT_MODEL:-}" in
  ""|inherit|haiku|sonnet|claude-haiku-*|claude-sonnet-*) ;;
  *)
    jq -n --arg s "$subagent" --arg e "$CLAUDE_CODE_SUBAGENT_MODEL" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("CLAUDE_CODE_SUBAGENT_MODEL is set to \($e), which overrides every agent model pin and would run this \($s) lane on an expensive model. Unset the variable before spawning grunt lanes — it is not part of the dotfiles config.")
      }
    }'
    exit 0
    ;;
esac

case "$model" in
  haiku|sonnet|claude-haiku-*|claude-sonnet-*) exit 0 ;;
  "")
    # scout/grunt frontmatter pins a cheap model; Explore would inherit Fable.
    if [ "$subagent" != "Explore" ]; then exit 0; fi
    ;;
esac

jq -n --arg s "$subagent" --arg m "${model:-inherit}" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Grunt lanes run on cheap models. This \($s) spawn resolves to model \($m). Re-send it as subagent_type scout (read-only legwork) or grunt (defined implementation) with no model override, or pass model: haiku or sonnet. For delegated planning or review, use a thinking agent type (Plan, general-purpose) instead.")
  }
}'
