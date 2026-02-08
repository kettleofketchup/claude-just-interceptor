#!/usr/bin/env bash
# just-interceptor: Claude Code PreToolUse hook
# Blocks raw CLI commands and redirects to project-standard just recipes.
#
# Install: /plugin marketplace add kettleofketchup/claude-just-interceptor
#          /plugin install just-interceptor@claude-just-interceptor
# Config:  .claude/just-interceptor.json in your project root
set -uo pipefail

# Read hook event JSON from stdin
INPUT=$(cat)

# Extract the command being run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Look for project config
# The hook runs from the project root (PWD)
CONFIG_FILE="${PWD}/.claude/just-interceptor.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

# Find first matching enabled redirect
# Uses `. as $r` binding for jq 1.8.x compatibility
MATCH=$(jq --arg cmd "$COMMAND" '
  [.redirects[] | select(.enabled == true) | . as $r | if ($cmd | test($r.pattern)) then $r else empty end] | if length > 0 then .[0] else null end
' "$CONFIG_FILE" 2>/dev/null) || true

if [[ -z "$MATCH" || "$MATCH" == "null" ]]; then
  exit 0
fi

JUST_CMD=$(echo "$MATCH" | jq -r '.just_command')
REASON=$(echo "$MATCH" | jq -r '.reason')
CATEGORY=$(echo "$MATCH" | jq -r '.category')

jq -n \
  --arg just_cmd "$JUST_CMD" \
  --arg reason "$REASON" \
  --arg category "$CATEGORY" \
  --arg original "$COMMAND" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": ("REDIRECT [" + $category + "]: Use `" + $just_cmd + "` instead of `" + $original + "`. " + $reason + "."),
      "additionalContext": ("This project uses just recipes as the standard interface.\n\nUse: " + $just_cmd + "\nReason: " + $reason + "\n\nRun `just --list` to see all available commands.")
    }
  }'

exit 0
