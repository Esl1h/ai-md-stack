#!/usr/bin/env bash
# shellcheck shell=bash
# Shared helpers, sourced by the other ~/.claude/hooks/*.sh scripts.

is_command_invoked() {
  local line="$1" name="$2"
  line=$(printf '%s' "$line" | tr '\n' ';')
  line=$(printf '%s' "$line" \
    | sed -E "s/'[^']*'/''/g" \
    | sed -E 's/"[^"]*"/""/g')
  printf '%s' "$line" | grep -qE "(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?${name}([[:space:]]|$)"
}

deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}
