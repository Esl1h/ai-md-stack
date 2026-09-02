#!/usr/bin/env bash
# shellcheck shell=bash
# PostToolUse (matcher: Bash). Redacts leaked secrets from stdout/stderr,
# strips known noisy lines, and truncates large output via updatedToolOutput
# before it reaches Claude's context.

set -euo pipefail

payload="$(cat)"
stdout="$(printf '%s' "$payload" | jq -r '.tool_response.stdout // ""')"
stderr="$(printf '%s' "$payload" | jq -r '.tool_response.stderr // ""')"
interrupted="$(printf '%s' "$payload" | jq -r '.tool_response.interrupted // false')"
is_image="$(printf '%s' "$payload" | jq -r '.tool_response.isImage // false')"

[ -z "$stdout$stderr" ] && exit 0

redact() {
  sed -E \
    -e 's/gh[pousr]_[A-Za-z0-9]{20,}/[redacted-github-token]/g' \
    -e 's/github_pat_[A-Za-z0-9_]{20,}/[redacted-github-token]/g' \
    -e 's/sk-ant-[A-Za-z0-9_-]{20,}/[redacted-anthropic-key]/g' \
    -e 's/sk-[A-Za-z0-9]{20,}/[redacted-openai-key]/g' \
    -e 's/AKIA[0-9A-Z]{16}/[redacted-aws-access-key]/g' \
    -e 's/(aws_secret_access_key|secret_access_key)([[:space:]]*[:=][[:space:]]*)[A-Za-z0-9/+=]{20,}/\1\2[redacted-aws-secret]/gI' \
  | sed -E '/-----BEGIN [A-Z ]*PRIVATE KEY-----/,/-----END [A-Z ]*PRIVATE KEY-----/c\
[redacted-private-key]'
}

# Add more noise patterns here as you run into them (e.g. Steampipe's update nag).
denoise() {
  grep -vE '^Refreshing state\.\.\.'
}

truncate_keep_ends() {
  local text="$1" max_bytes=30000 head_bytes=15000 tail_bytes=15000 size
  size=$(printf '%s' "$text" | wc -c)
  if [ "$size" -le "$max_bytes" ]; then
    printf '%s' "$text"
  else
    printf '%s\n[... truncated, %d bytes omitted ...]\n%s' \
      "$(printf '%s' "$text" | head -c "$head_bytes")" \
      "$((size - head_bytes - tail_bytes))" \
      "$(printf '%s' "$text" | tail -c "$tail_bytes")"
  fi
}

new_stdout="$(printf '%s' "$stdout" | redact | denoise || true)"
new_stderr="$(printf '%s' "$stderr" | redact | denoise || true)"
new_stdout="$(truncate_keep_ends "$new_stdout")"
new_stderr="$(truncate_keep_ends "$new_stderr")"

[ "$new_stdout" = "$stdout" ] && [ "$new_stderr" = "$stderr" ] && exit 0

jq -n \
  --arg stdout "$new_stdout" \
  --arg stderr "$new_stderr" \
  --argjson interrupted "$interrupted" \
  --argjson isImage "$is_image" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",updatedToolOutput:{stdout:$stdout,stderr:$stderr,interrupted:$interrupted,isImage:$isImage}}}'
