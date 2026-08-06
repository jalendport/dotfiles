#!/bin/bash
# PreToolUse hook on mcp__solo__spawn_agent: a Claude-runtime Solo lane must
# carry an explicit --model in extra_args — an unmodified spawn inherits the
# main-session model (Fable) and burns frontier quota in a background lane.
# agent_tool_id 5 is this machine's Claude runtime (Solo: list_agent_tools).

input=$(cat)
tool_id=$(printf '%s' "$input" | jq -r '.tool_input.agent_tool_id // 0')

if [ "$tool_id" != "5" ]; then exit 0; fi

has_model=$(printf '%s' "$input" | jq -r '[.tool_input.extra_args // [] | .[] | select(startswith("--model"))] | length')

if [ "$has_model" -gt 0 ]; then exit 0; fi

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Claude Solo lanes must pass an explicit model — an unmodified spawn runs the main-session model (Fable). Re-send with extra_args [\"--model\", \"opus\", \"--effort\", \"high\"] for an implementation lane, or a cheaper model where the work allows."
  }
}'
