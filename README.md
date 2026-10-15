# ai-md-stack

Base, standard configuration I run with Claude Code: a single canonical `AGENTS.md` shared with OpenCode and AbacusAI CLI, plus a small enforcement layer of Claude Code hooks.

Full writeup: [My AI setup: Claude, Abacus, and OpenCode](https://esli.blog/posts/ai-setup-claude-opencode/).

## Tools this targets

- **Claude Code**
- **OpenCode**
- **AbacusAI CLI**

## Layout

```
ai-md-stack/
├── AGENTS.md                        canonical instruction file
├── CLAUDE.md -> AGENTS.md           symlink, same content
├── settings.example.json            hook registration for Claude Code
└── hooks/                           Claude Code enforcement layer
    ├── _common.sh
    ├── mutation-guard.sh
    ├── commit-guard.sh
    ├── session-context.sh
    └── redact-secrets.sh
```

## AGENTS.md / CLAUDE.md

`CLAUDE.md` is a relative symlink to `AGENTS.md` (`ln -s AGENTS.md CLAUDE.md`), so both Claude Code and OpenCode read the same file. Claude Code only recognizes `CLAUDE.md` natively; OpenCode and AbacusAI CLI read `AGENTS.md` directly.

This part is shared: AbacusAI CLI only loads `AGENTS.md` from the project workspace, not from a user-level global path, so its copy has to live in each project root rather than symlinked from a single global location.

The file itself is based on the structure from [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills/tree/main), evolved further through running Claude Code across several different environments.

OpenCode loads the global `~/.config/opencode/AGENTS.md` together with the project's `AGENTS.md`, so a project with its own file keeps the global rules without extra configuration.

## hooks/

`AGENTS.md`/`CLAUDE.md` is context, not applied configuration: the model tries to follow it, but nothing guarantees it remembers a rule in a long session. This is the enforcement layer for the rules that must hold regardless.

Claude Code only. Doesn't port to OpenCode's plugin system (`tool.execute.before`/`after`) or to AbacusAI CLI, which has no documented hook mechanism.

- `_common.sh`: shared `is_command_invoked()` helper, so a guard fires on `terraform plan` but not on `jq --arg c 'terraform plan'`.
- `mutation-guard.sh` (`PreToolUse`): blocks write verbs on `aws`/`gh`/`kubectl`/`terraform`, with an explicit `ALLOW_MUTATION=1` escape hatch.
- `commit-guard.sh` (`PreToolUse`): validates `git commit` subjects against the Conventional Commits rules already documented in `AGENTS.md`.
- `session-context.sh` (`SessionStart`): injects current branch, dirty file count, and last commit into context.
- `redact-secrets.sh` (`PostToolUse`): redacts leaked secrets (GitHub/OpenAI/Anthropic tokens, AWS access keys, PEM blocks) from command output, strips known noise, and truncates large output, via `updatedToolOutput`.

All shellcheck-clean and `bash -n` validated.

## RTK

Also running [RTK](https://www.rtk-ai.app/) (Rust Token Killer), a CLI proxy that rewrites shell commands before execution to cut token usage. Registered as its own `PreToolUse` hook, separate from the ones in `hooks/`.

## Usage

```bash
mkdir -p ~/.claude ~/.config/opencode
cp AGENTS.md ~/.claude/AGENTS.md
ln -s AGENTS.md ~/.claude/CLAUDE.md
ln -s ~/.claude/AGENTS.md ~/.config/opencode/AGENTS.md

cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

Then merge the `hooks` block from `settings.example.json` into `~/.claude/settings.json`.

## Skills

Skills follow the same source-of-truth pattern as `AGENTS.md`. All three tools accept the same format, a directory named after the skill containing a `SKILL.md` with `name`/`description` frontmatter, but each one scans its own user-scoped directory:

- **Claude Code**: `~/.claude/skills/`
- **OpenCode**: `~/.config/opencode/skills/`
- **AbacusAI**: `~/.abacusai/skills/`

Two ways to keep one canonical copy:

1. **Version the skill in your regular GIT path** (e.g. `~/GIT/<skill-repo>` with `SKILL.md` at the root) and symlink it into all three CLIs.
2. **Keep the skill inside one CLI's directory** and symlink it into the other two.

Either way, one edit lands in the canonical copy and every CLI reads the same file. The frontmatter `name` must match the directory name.

Example, `humanize-br` ([github.com/Esl1h/humanize-br](https://github.com/Esl1h/humanize-br)), a skill versioned at `~/GIT/humanize-br` and symlinked into all three:

```bash
ln -s ~/GIT/humanize-br ~/.claude/skills/humanize-br
ln -s ~/GIT/humanize-br ~/.config/opencode/skills/humanize-br
ln -s ~/GIT/humanize-br ~/.abacusai/skills/humanize-br
```

`v-repo-audit` uses the other arrangement: the canonical copy lives in OpenCode's directory (`~/.config/opencode/skills/v-repo-audit`) with symlinks from Claude Code and AbacusAI. Note the difference from `AGENTS.md`: AbacusAI has no user-global instructions file, but it does read user-global skills, so skills are the reliable way to carry personal behavior into AbacusAI sessions.
