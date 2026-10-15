# Global Rules
- Write codes and comments in English by default; use Brazilian Portuguese only when explicitly requested.
- When writing Portuguese, always use correct diacritics.
- Do not use ASCII tables.
- Do not use horizontal rules (`---`) or ASCII lines as section separators.
- Do not use the em dash (U+2014, `&mdash;`, `&#x2014;`) as punctuation; use a comma, colon, or rewrite.
- Do not use the en dash (U+2013); use a hyphen or rewrite the sentence.
- Files are UTF-8, LF line endings, with a trailing newline at EOF.

## Precedence
1. Direct user instructions in the current task.
2. Project-specific instructions (e.g. project AGENTS.md, RTK.md).
3. This global file.

## Git Commits
- Commit messages MUST describe only the *what* and *why* of the change.
- Do NOT include tooling metadata, trailers, attribution, or co-author lines (e.g. `Co-Authored-By`, `Signed-off-by`, `Generated-by`, `Made-with`, or any IDE/editor/assistant reference).
- Keep messages tool-agnostic: nothing about the environment used to author the code belongs in the history.
- One commit per logical change (ideally one file/concern at a time).
- Follow Conventional Commits v1.0.0: https://www.conventionalcommits.org/en/v1.0.0/
- Subject line: imperative mood, 50 chars max, no trailing period.
- Body (when needed): wrap at 72 chars, separated from subject by a blank line.
- Reference issues/tickets in the footer (e.g. `Refs: #123`), not the subject.
- Never bundle unrelated changes; split refactors from behavior changes.
- Do NOT auto-generate or template commit messages; write them from the diff.

## Approach
- Think before acting. Read existing files before writing code.
- Be concise in output but thorough in reasoning.
- Prefer editing over rewriting whole files.
- Do not re-read files you have already read unless the file may have changed.
- Test your code before declaring done.
- No sycophantic openers or closing fluff.
- Keep solutions simple and direct.
- Do not create more than a few new files without confirming scope first.

## Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**
Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them; don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## Simplicity First
**Minimum code that solves the problem. Nothing speculative.**
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## Surgical Changes
**Touch only what you must. Clean up only your own mess.**
When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it; don't delete it.
When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.
The test: every changed line should trace directly to the user's request.

## Goal-Driven Execution
**Define success criteria. Loop until verified.**
Transform tasks into verifiable goals:
- "Add validation" becomes "Write tests for invalid inputs, then make them pass".
- "Fix the bug" becomes "Write a test that reproduces it, then make it pass".
- "Refactor X" becomes "Ensure tests pass before and after".
For multi-step tasks, state a brief plan:
~~~
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
~~~
Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Shell / Scripts
- zsh is the interactive shell; validate interactive customizations in `~/.zshrc`.
- For scripts, target POSIX sh unless zsh/bash features are required; always state the shebang used.
- Run shellcheck on shell scripts before declaring done.
- Quote variable expansions; prefer `set -euo pipefail` in bash scripts.

## Secrets
- Never hardcode credentials, tokens, or keys; read from env or a secrets store.
- Never print secrets in logs or commit them.

## Comments
- Comment the why, not the what. No redundant or narrating comments.

## Imports
<!-- Document below what each imported file covers. -->

@RTK.md
