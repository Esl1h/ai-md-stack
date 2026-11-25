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

# Prints each `<name> ...` invocation up to the next shell separator, with
# quoted strings blanked, so a guard checks one command's flags and not its
# neighbours' (`git commit ... && git log -n 1`).
# shortcut: regex on the command text; `git -C dir ...`, combined short flags
# (`-nm`, `-fu`) and env-prefixed calls are not seen. Upgrade to a real shell
# parser if that gap starts to matter.
invocation() {
  printf '%s' "$1" | tr '\n' ';' \
    | sed -E "s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g" \
    | grep -oE "(^|[;&|(])[[:space:]]*(sudo[[:space:]]+)?$2[[:space:]][^;&|]*" \
    || true # grep -o exits 1 when nothing matches; an empty result is valid
}

deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}
