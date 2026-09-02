#!/usr/bin/env bash
# shellcheck shell=bash
# PreToolUse (matcher: Bash). Blocks write calls to aws/gh/kubectl/terraform
# unless ALLOW_MUTATION=1 is set for that invocation.

set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$hook_dir/_common.sh"

[ -n "${ALLOW_MUTATION:-}" ] && exit 0

payload="$(cat)"
line="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$line" ] && exit 0

escape_hint="Re-run with ALLOW_MUTATION=1 <command> if intentional."
write_verbs='create|delete|remove|terminate|modify|update|put|attach|detach|revoke|authorize|disable|enable|stop|start|reboot|deregister|register|associate|disassociate|tag|untag|reset|restore|purge|cancel'

if is_command_invoked "$line" 'aws' \
  && printf '%s' "$line" | grep -qE "aws[[:space:]]+[a-z0-9-]+[[:space:]]+(${write_verbs})-"; then
  deny "AWS write call blocked. $escape_hint"
fi

if is_command_invoked "$line" 'gh' \
  && printf '%s' "$line" | grep -qE "gh[[:space:]]+([a-z-]+[[:space:]]+(create|close|merge|delete|edit|reopen|lock|unlock|archive|rename|set|remove|upload|run)\b|api[[:space:]]+.*-X[[:space:]]+(POST|PUT|PATCH|DELETE))"; then
  deny "gh write call blocked. $escape_hint"
fi

if is_command_invoked "$line" 'kubectl' \
  && printf '%s' "$line" | grep -qE "kubectl[[:space:]]+(apply|delete|replace|patch|scale|create|edit|cordon|uncordon|drain|taint|label|annotate|expose|exec)\b|kubectl[[:space:]]+rollout[[:space:]]+(restart|undo|pause|resume)\b"; then
  deny "kubectl write call blocked. $escape_hint"
fi

if is_command_invoked "$line" 'terraform' \
  && printf '%s' "$line" | grep -qE "terraform[[:space:]]+(apply|destroy|import|taint|untaint)\b|terraform[[:space:]]+state[[:space:]]+(rm|mv|push|replace-provider)\b"; then
  deny "terraform write call blocked. $escape_hint"
fi

exit 0
