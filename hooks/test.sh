#!/usr/bin/env bash
# shellcheck shell=bash
# Regression tests for the PreToolUse guards, driven by synthetic payloads.
# Usage: hooks/test.sh [hooks_dir]
# hooks_dir defaults to this script's directory; pass ~/.claude/hooks to test
# the installed copies.

set -euo pipefail

dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
passed=0
failed=0

# check <guard> <allow|deny> <command>
check() {
  local out got
  out="$(jq -n --arg c "$3" '{tool_input:{command:$c}}' | "$dir/$1")"
  if [[ "$out" == *'"deny"'* ]]; then got=deny; else got=allow; fi
  if [ "$got" = "$2" ]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    printf 'FAIL %s: want %s, got %s: %s\n' "$1" "$2" "$got" "${3//$'\n'/\\n}"
  fi
}

c=commit-guard.sh
m=mutation-guard.sh

# commit-guard: allowed
check $c allow 'git status'
check $c allow 'git commit -m "feat: add x"'
check $c allow "git commit -m 'fix(hooks): handle y'"
check $c allow 'git commit -m "feat: handle -n flag"'
check $c allow 'git commit -m "feat: add x" && git log -n 1'
check $c allow $'git commit -m "$(cat <<\'EOF\'\nfeat: add x\n\nBody line.\nEOF\n)"'
check $c allow $'cat > f.sh <<\'EOF\'\necho hi\nEOF\ngit commit -m "feat: add x"'
check $c allow 'ALLOW_MUTATION=1 git commit --no-verify -m "feat: add x"'

# commit-guard: denied
check $c deny 'git commit --no-verify -m "feat: add x"'
check $c deny 'git commit -n -m "feat: add x"'
check $c deny 'git commit -m "feat: add x" --no-verify'
check $c deny 'git commit -m "add x"'
check $c deny 'git commit -m "feat: this subject is far longer than the fifty character limit"'
check $c deny 'git commit -m "feat: add x."'
check $c deny $'git commit -m "feat: add x\n\nCo-Authored-By: A <a@b.c>"'
check $c deny $'git commit -m "feat: add x\n\nSigned-off-by: A <a@b.c>"'
check $c deny $'git commit -m "$(cat <<\'EOF\'\nadd x\nEOF\n)"'

# mutation-guard: allowed
check $m allow 'git push origin main'
check $m allow 'echo "git push --force"'
check $m allow 'git status && echo "do not git push --force"'
check $m allow 'git push origin main && git log -f'
check $m allow 'kubectl get pods'
check $m allow 'kubectl apply --dry-run=server -f x.yaml'
check $m allow 'kubectl apply --dry-run=client -f x.yaml'
check $m allow 'terraform plan'
check $m allow 'helm template . | kubeconform -'
check $m allow 'ALLOW_MUTATION=1 git push --force origin main'
check $m allow 'ALLOW_MUTATION=1 kubectl apply -f x.yaml'

# mutation-guard: denied
check $m deny 'git push --force origin main'
check $m deny 'git push -f origin main'
check $m deny 'git push --force-with-lease'
check $m deny 'git push origin +main'
check $m deny 'git status && git push -f'
check $m deny 'kubectl apply -f x.yaml'
check $m deny 'kubectl apply --dry-run=none -f x.yaml'
check $m deny 'kubectl delete pod x'
check $m deny 'kubectl get pods && kubectl delete pod x'
check $m deny 'kubectl delete pod x --dry-run=client && kubectl delete pod y'
check $m deny 'aws ec2 terminate-instances --instance-ids i-1'
check $m deny 'gh pr create --title x'
check $m deny 'terraform apply'

printf '%d passed, %d failed (%s)\n' "$passed" "$failed" "$dir"
[ "$failed" -eq 0 ]
