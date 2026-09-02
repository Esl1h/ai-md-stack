#!/usr/bin/env bash
# shellcheck shell=bash
# PreToolUse (matcher: Bash). Validates `git commit` subjects against the
# Conventional Commits + trailer rules already documented in AGENTS.md.

set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$hook_dir/_common.sh"

payload="$(cat)"
line="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$line" ] && exit 0

is_command_invoked "$line" 'git' || exit 0
printf '%s' "$line" | grep -qE '(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?git[[:space:]]+commit\b' || exit 0

subject=""
if printf '%s' "$line" | grep -qE "<<-?[[:space:]]*['\"]?EOF"; then
  subject="$(printf '%s\n' "$line" | sed -n "/<<-\{0,1\}[[:space:]]*['\"]\{0,1\}EOF/{n;p;q}")"
elif [[ "$line" =~ -m[[:space:]]+\"([^\"]*)\" ]]; then
  subject="${BASH_REMATCH[1]}"
elif [[ "$line" =~ -m[[:space:]]+\'([^\']*)\' ]]; then
  subject="${BASH_REMATCH[1]}"
fi

# Can't see a subject (editor-based commit, unusual quoting): nothing to validate.
[ -z "$subject" ] && exit 0

type_re='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9_.-]+\))?!?: .+'

if ! printf '%s' "$subject" | grep -qE "$type_re"; then
  deny "Commit subject does not follow Conventional Commits (required by AGENTS.md).
Expected: type(scope): imperative description
Got: $subject"
fi

if [ "${#subject}" -gt 50 ]; then
  deny "Commit subject exceeds 50 characters (AGENTS.md limit): ${#subject} chars.
Got: $subject"
fi

if printf '%s' "$subject" | grep -qE '\.[[:space:]]*$'; then
  deny "Commit subject ends with a period (AGENTS.md forbids trailing period).
Got: $subject"
fi

if printf '%s' "$line" | grep -qiE '(Co-Authored-By|Generated-by|Made-with):'; then
  deny "Commit message includes a forbidden trailer (AGENTS.md: no tooling attribution)."
fi

exit 0
