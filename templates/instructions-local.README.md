# `.github/instructions-local/`

This folder holds **repo-specific** instructions that are NOT shared across repos.

The shared `.github/instructions/` folder is a directory junction into
`C:\rdwr-intelij\.copilot-shared\shared\instructions\` — editing files there
affects every linked repo. Anything specific to THIS repo (exception classes,
build commands, module layout, domain rules) must live here instead.

Copilot loads any `*.instructions.md` file under `.github/`, so files here are
picked up automatically.

## Suggested files

| File | Purpose |
|---|---|
| `project-rules.instructions.md` | Hard rules: error types, dependency management, naming, must/must-not |
| `cli-commands.instructions.md`  | Build, test, run commands specific to this repo |
| `quick-reference.instructions.md` | One-page cheat sheet of paths, classes, and patterns |

## Editing flow

1. Edit any file here freely — changes are tracked by THIS repo's git.
2. Never edit files under `.github/instructions/` — that is the shared junction.
3. If you find yourself wanting to share something across repos, move it to
   `C:\rdwr-intelij\.copilot-shared\shared\instructions\` and remove the local copy.
