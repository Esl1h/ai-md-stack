#!/usr/bin/env bash
# shellcheck shell=bash
# SessionStart. Injects git branch/status so Claude doesn't need to spend a
# turn running these itself at the start of every session.

set -euo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch="$(git branch --show-current 2>/dev/null || echo 'detached HEAD')"
dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
last_commit="$(git log -1 --format='%h %s' 2>/dev/null || echo 'no commits yet')"

context="Git branch: $branch"
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  context="$context (WARNING: on protected branch)"
fi
context="$context
Dirty files: $dirty
Last commit: $last_commit"

jq -n --arg c "$context" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
