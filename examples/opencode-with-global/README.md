# opencode-with-global

Demonstrates a gap in OpenCode's instruction loading: when a project has its own `AGENTS.md`, OpenCode uses only that file and ignores `~/.config/opencode/AGENTS.md` entirely. It doesn't concatenate local and global the way Claude Code does.

`opencode.json`'s `instructions` field recovers the global file by listing both paths explicitly:

```json
{
  "instructions": [
    "AGENTS.md",
    "/home/YOUR_USER/.claude/AGENTS.md"
  ]
}
```

Replace `/home/YOUR_USER` with your actual home directory. `~` may not expand reliably here depending on your OpenCode version, so an absolute path is the safer default.

Without this, any rule that only lives in the global file and isn't repeated in the project's `AGENTS.md` (commit conventions, shellcheck requirements, etc.) stays invisible to OpenCode in that project.
