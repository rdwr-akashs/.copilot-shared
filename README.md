# `.copilot-shared` — central Copilot configuration

Single source of truth for GitHub Copilot agents, skills, instructions, and
prompts shared across all repos under `C:\rdwr-intelij\`.

## Why

Without this, every repo would carry its own copy of the same skills and
instructions. Edits in one wouldn't propagate. With junctions, every linked
repo sees the same `.github/{skills,instructions,prompts}` content — edit
once, all repos updated instantly.

## Layout

```
.copilot-shared\
├── shared\                 # Junctioned into every repo's .github\
│   ├── skills\             # Reusable skills (incl. customer-case-intake, support-file-triage, rca-*, case-archive)
│   ├── instructions\       # Generic Copilot rules (orchestrator, agent-skills, memory-bank, customer-case-rca)
│   └── prompts\            # Reusable prompt templates (incl. investigate-customer-case)
├── agent-templates\        # Copied (not junctioned) per-repo; customised locally
├── cases\                  # Local-only solved-case archive — written by case-archive skill
├── templates\              # copilot-instructions, project-rules, personal-instructions
└── bin\                    # Setup scripts (Windows .cmd)
    ├── setup-repo.cmd      # One-shot setup for a new repo
    ├── link-copilot.cmd    # (Re)create junctions for one repo
    ├── link-all-copilot.cmd# Walk parent folder; link every repo
    ├── unlink-copilot.cmd  # Remove junctions from one repo
    ├── copy-agents.cmd     # Seed .github\agents\ from agent-templates\
    ├── doctor.cmd          # Health-check one repo's Copilot wiring
    └── refresh-agents.cmd  # Pull upstream agent-template improvements
```

## What's shared vs per-repo

| Item | Shared? | Why |
|---|---|---|
| `skills/` | Junction | Pattern-based; same workflow for any repo |
| `instructions/` (generic) | Junction | Routing + memory + skill-loading rules |
| `prompts/` | Junction | Reusable prompt templates |
| `agents/` | Copy | Agents encode project-specific conventions |
| `copilot-instructions.md` | Per-repo | Project overview is unique |
| `instructions-local/` | Per-repo | Exception types, build commands, domain rules |
| `personal-instructions.md` | Per-developer | Local paths, shell preference |

## Quick start

### New repo (no `.github/` yet)

```cmd
C:\rdwr-intelij\.copilot-shared\bin\setup-repo.cmd C:\rdwr-intelij\my_new_repo
```

This creates `.github/`, copies the templates, seeds agents, and creates
junctions. Then edit:
1. `.github/copilot-instructions.md` — describe the project
2. `.github/instructions-local/project-rules.instructions.md` — hard rules
3. `.github/agents/*.agent.md` — adjust to repo conventions

### Existing repo (already has `.github/`)

```cmd
C:\rdwr-intelij\.copilot-shared\bin\link-copilot.cmd C:\rdwr-intelij\existing_repo
```

The script preserves existing real folders (treated as overrides). Agents are
not touched. Only `skills/`, `instructions/`, `prompts/` are junctioned.

### All repos at once

```cmd
C:\rdwr-intelij\.copilot-shared\bin\link-all-copilot.cmd
```

Walks `C:\rdwr-intelij\*`. Skips repos without a `.github/copilot-instructions.md`
(those need `setup-repo.cmd` first).

## Daily workflow

### Editing a shared skill

```cmd
notepad C:\rdwr-intelij\.copilot-shared\shared\skills\writing-plans\SKILL.md
```

Save → every linked repo sees the change immediately. No sync step.

### Adding a new shared skill

1. `mkdir C:\rdwr-intelij\.copilot-shared\shared\skills\my-skill`
2. Create `SKILL.md` (see `skills/writing-skills/SKILL.md` for conventions).
3. Done. Every linked repo can now invoke it.

### Per-repo override of a shared skill

If one repo needs a different `commit-push` skill:

```cmd
cd C:\rdwr-intelij\my_repo
.copilot-shared\bin\unlink-copilot.cmd C:\rdwr-intelij\my_repo
mkdir .github\skills
xcopy /e C:\rdwr-intelij\.copilot-shared\shared\skills .github\skills
REM Edit .github\skills\commit-push\SKILL.md as needed
```

After this, re-running `link-copilot.cmd` will see the real `skills/` folder
and skip junctioning it (preserving your override). The other folders
(`instructions/`, `prompts/`) are still re-junctioned normally.

### Customer case RCA workflow

> Full workflow guide: [`shared/instructions/customer-case-rca.README.md`](shared/instructions/customer-case-rca.README.md) — visible in every linked repo as `.github/instructions/customer-case-rca.README.md`.

When you're handed a customer escalation (RSEG-/SC-/INC-/JIRA- ticket with a
support bundle), use the `case-investigator` agent. Kick off via the prompt at
`shared/prompts/investigate-customer-case.md`.

The workflow is **generic across all repos** — it makes no product-specific
assumptions. Each phase produces evidence-backed output and the agent never
edits product code itself (it hands fixes off to the `developer` agent).

| Phase | What happens |
|-------|--------------|
| 0     | Scaffolds `.agent_work/<case-id>/investigation.md`; **auto-unzips every archive** in the bundle (idempotent) |
| 0.5   | **Prior-case lookup** against `cases/_index.md` — surfaces top-3 matches with confidence % |
| 1     | Problem framing in the investigation MD |
| 2     | **9 triage subagents in parallel** — Identity, Connectivity, Replication, HA, Resources, External-services, Polling, Containers, Time-sync |
| 3     | Maps findings to `repo / file / method / line`; greps `CHANGES.txt` / `CHANGELOG*` / `RELEASE_NOTES*` (replaces any static known-bugs table) |
| 5–6   | Authors `rca-<case-id>.md` (10 sections) including a **draft commit message** |
| 7     | Persists case to `cases/<case-id>/` (rca.md, fix.md, signature.yml) + appends `_index.md` |
| 8     | Hands fix off to the `developer` agent; user gates code edits |

#### Per-product triage rules

To make Phase 2 sharper for a specific product, add a
`.github/instructions-local/triage-rules.instructions.md` to that product's
repo with concrete log paths and grep patterns. The triage skill prefers it
when present and falls back to generic keyword grep when absent. See the
example at the bottom of `shared/instructions/customer-case-rca.instructions.md`.

#### The `cases/` archive

Solved cases land in `.copilot-shared/cases/<case-id>/`. This directory is
**local-only** — it inherits `.copilot-shared`'s no-remote convention and
must never be pushed (it contains internal customer data). See
[cases/README.md](cases/README.md) for layout and the `signature.yml` schema.

### Versioning the central folder

```cmd
cd C:\rdwr-intelij\.copilot-shared
git log --oneline
```

Local-only git repo (no remote). Commit after every meaningful edit so you
can roll back if a change breaks Copilot in any repo.

## Troubleshooting

**Q: How do I check if a repo is wired up correctly?**

```cmd
C:\rdwr-intelij\.copilot-shared\bin\doctor.cmd C:\rdwr-intelij\<repo>
```

Reports PASS/WARN/FAIL on: `.github/` layout, junctions pointing into
`copilot-shared\shared`, `.gitignore` marker block, unresolved
`<placeholder>` tokens in agents, and old template terms left over from
a partial `customize-agents` run. Exit 0 = clean, 1 = warnings, 2 = failures.

**Q: I improved an agent template centrally. How do I push that into existing repos?**

```cmd
C:\rdwr-intelij\.copilot-shared\bin\refresh-agents.cmd C:\rdwr-intelij\<repo>
```

For each `agent-templates/*.agent.md`:
- **NEW** — repo is missing it; copied in (then run `customize-agents` skill).
- **SAME** — repo's copy is byte-identical to the template; nothing to do.
- **CONFLICT** — repo's copy was customised; saved upstream as
  `<agent>.agent.md.template.new` next to the live file. Diff the two,
  merge wanted changes manually, delete the `.template.new`, then re-run
  the `customize-agents` skill in Copilot Chat to fix any new placeholders.

Never overwrites a customised agent.

**Q: JetBrains Copilot doesn't see the shared skills.**
- Verify the junction: `dir C:\rdwr-intelij\<repo>\.github` should show
  `<JUNCTION>` next to `skills`, `instructions`, `prompts`.
- Restart JetBrains; it caches `.github/` on project open.

**Q: Junction creation fails.**
- `mklink /J` does not require admin. Confirm `cmd.exe` (not WSL) is being used.
- If running from PowerShell, `mklink` is a cmd built-in: use `cmd /c mklink ...`
  or just call the `.cmd` scripts (which auto-handle this).

**Q: A repo's junctions disappeared.**
- Some IDE/refactor tools recreate junctioned folders as real (empty) folders.
  Re-run `link-copilot.cmd <repo>` — it's idempotent.

**Q: I want a repo to be excluded from auto-linking.**
- Don't create `.github/copilot-instructions.md` in it. `link-all-copilot.cmd`
  skips repos without that file.

## Adding a new repo to the rotation

```cmd
C:\rdwr-intelij\.copilot-shared\bin\setup-repo.cmd C:\rdwr-intelij\<NEW_REPO>
```

Then customise the three per-repo files (`copilot-instructions.md`,
`instructions-local/project-rules.instructions.md`, `agents/*.agent.md`).

## Removing the integration from a repo

```cmd
C:\rdwr-intelij\.copilot-shared\bin\unlink-copilot.cmd C:\rdwr-intelij\<repo>
```

Junctions are removed. Real folders (`agents/`, `instructions-local/`,
`copilot-instructions.md`) are left untouched.
