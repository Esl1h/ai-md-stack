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

OpenCode and AbacusAI CLI read `AGENTS.md` directly. Claude Code reads a project `AGENTS.md` natively since v2.1.277, when the project has no `CLAUDE.md`, but has no user-level equivalent: as a global file, `~/.claude/AGENTS.md` needs a `~/.claude/CLAUDE.md` symlink (`ln -s AGENTS.md CLAUDE.md`). The `CLAUDE.md` symlink in this repository is no longer required at project scope, and it's harmless: Claude Code reads the content once.

This part is shared: AbacusAI CLI only loads `AGENTS.md` from the project workspace, not from a user-level global path, so its copy has to live in each project root rather than symlinked from a single global location.

The file itself is based on the structure from [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills/tree/main), evolved further through running Claude Code across several different environments.

OpenCode loads the global `~/.config/opencode/AGENTS.md` together with the project's `AGENTS.md`, so a project with its own file keeps the global rules without extra configuration.

## hooks/

`AGENTS.md`/`CLAUDE.md` is context, not applied configuration: the model tries to follow it, but nothing guarantees it remembers a rule in a long session. This is the enforcement layer for the rules that must hold regardless.

Claude Code only. Doesn't port to OpenCode's plugin system (`tool.execute.before`/`after`) or to AbacusAI CLI, which has no documented hook mechanism.

- `_common.sh`: shared helpers. `is_command_invoked()` makes a guard fire on `terraform plan` but not on `jq --arg c 'terraform plan'`; `invocation()` scopes a flag check to its own command, so `git commit ... && git log -n 1` is not read as `commit -n`.
- `mutation-guard.sh` (`PreToolUse`): blocks write verbs on `aws`/`gh`/`kubectl`/`terraform` and `git push` force variants. `kubectl --dry-run` passes. Escape hatch: prefix the command with `ALLOW_MUTATION=1`.
- `commit-guard.sh` (`PreToolUse`): validates `git commit` subjects against the Conventional Commits rules already documented in `AGENTS.md`, rejects attribution trailers, and blocks `--no-verify` (same `ALLOW_MUTATION=1` prefix).
- `test.sh`: runs synthetic `PreToolUse` payloads through the two guards. `hooks/test.sh ~/.claude/hooks` tests the installed copies.
- `session-context.sh` (`SessionStart`): injects current branch, dirty file count, and last commit into context.
- `redact-secrets.sh` (`PostToolUse`): redacts leaked secrets (GitHub/OpenAI/Anthropic tokens, AWS access keys, PEM blocks) from command output, strips known noise, and truncates large output, via `updatedToolOutput`.

The guards read the command text and a guard only matches a command in command position, which is why the prefix works. They catch the common slips, not a determined bypass: `git -C dir push -f`, combined short flags (`-nm`) and `git commit -s` are not seen.

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

All three tools accept the same skill format, a directory named after the skill containing a `SKILL.md` with `name`/`description` frontmatter. They differ in where they look:

- **Claude Code**: only `~/.claude/skills/`
- **OpenCode**: `~/.config/opencode/skills/`, `~/.claude/skills/`, and `~/.agents/skills/`
- **AbacusAI**: `~/.abacusai/skills/` and `~/.agents/skills/`

`~/.agents/skills/` is read by every tool except Claude Code, and it's where the [`skills`](https://github.com/vercel-labs/skills) CLI (`npx skills add <repo>`) installs, so it's the canonical folder. Claude Code needs one more symlink per skill. A skill versioned in its own repository, such as `humanize-br` ([github.com/Esl1h/humanize-br](https://github.com/Esl1h/humanize-br)), gets two links:

```bash
ln -s ~/GIT/humanize-br ~/.agents/skills/humanize-br
ln -s ../../.agents/skills/humanize-br ~/.claude/skills/humanize-br
```

Don't also keep a copy in `~/.config/opencode/skills/`: OpenCode reads all three folders, and with duplicate names only the first one found loads. The frontmatter `name` must match the directory name.

AbacusAI has no user-global instructions file, but it does read user-global skills, so skills are the reliable way to carry personal behavior into AbacusAI sessions.

### Skills in use

Skills are discovered by their `description`, so `AGENTS.md` does not list them. Add a line there only when a skill must be forced for a specific case (e.g. "Before writing pt-BR prose, use the humanize-br skill"). This list exists so the stack can be rebuilt on a new machine:

- `humanize-br`: [github.com/Esl1h/humanize-br](https://github.com/Esl1h/humanize-br), symlinked as shown above.
- `humanize-ai-slop`: [github.com/Esl1h/humanize-ai-slop](https://github.com/Esl1h/humanize-ai-slop), symlinked the same way.
- `hallmark`: [github.com/Nutlope/hallmark](https://github.com/Nutlope/hallmark), installed with `npx skills add`.
- `find-skills`: [github.com/vercel-labs/skills](https://github.com/vercel-labs/skills), installed with `npx skills add`.
- `cf-cli`, `diagram-design`, `v-repo-audit`: plain folders in `~/.agents/skills/`; no source is recorded, so copy them from an existing host.
- `ponytail`: a Claude Code plugin, not a skill folder. Source: [github.com/DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail). Install with `/plugin marketplace add DietrichGebert/ponytail`, then `/plugin install ponytail@ponytail`.
