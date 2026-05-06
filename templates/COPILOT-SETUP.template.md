# GitHub Copilot Setup — Team Onboarding

This repository uses a **shared Copilot configuration** that lives outside the
repo at `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\`. Skills, instructions, prompts, and
plans are junctioned in from there. Agents are copied per-repo and customised.

If you're joining the team, **read this file end-to-end before you start**.

---

## TL;DR

```cmd
git clone <this-repo-url> %COPILOT_WORKSPACE_ROOT%\<repo-name>
:: Get .copilot-shared from a teammate (zip / file share / USB) and place at:
::   %COPILOT_WORKSPACE_ROOT%\.copilot-shared\
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<repo-name>
:: Restart JetBrains. Done.
```

---

## What's where

```
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\          ← Shared store (one per machine)
├── shared\
│   ├── skills\          ← Junctioned to every repo
│   ├── instructions\    ← Junctioned to every repo
│   ├── prompts\         ← Junctioned to every repo
│   └── plans\           ← Junctioned to every repo
├── agent-templates\     ← Copied + customised per-repo
├── templates\           ← Per-repo seed files (this doc, customize-agents prompt, etc.)
├── bin\                 ← Setup scripts
└── README.md

<this-repo>\.github\
├── COPILOT-SETUP.md              ← This document (per-repo copy)
├── customize-agents.prompt.md    ← Paste into Copilot Chat to tailor agents
├── copilot-instructions.md       ← Per-repo project overview
├── personal-instructions.md      ← Per-developer (gitignored)
├── agents\                       ← Per-repo, customised
├── instructions-local\           ← Per-repo Copilot rules
├── instructions\  → JUNCTION → .copilot-shared\shared\instructions
├── skills\        → JUNCTION → .copilot-shared\shared\skills
├── prompts\       → JUNCTION → .copilot-shared\shared\prompts
└── plans\         → JUNCTION → .copilot-shared\shared\plans
```

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| JetBrains IDE (IntelliJ / IDEA) | Any recent version |
| GitHub Copilot plugin | Install from JetBrains Marketplace |
| GitHub Copilot subscription | Individual or business plan |
| Workspace at `%COPILOT_WORKSPACE_ROOT%\` | OR adjust path references in `.copilot-shared\bin\*.cmd` |
| Git Bash (recommended) | For terminal operations on Windows |

> **macOS / Linux teammates:** the central store and scripts are Windows-batch.
> Use symlinks (`ln -s`) instead — see Troubleshooting below.

---

## Onboarding (new team member, fresh machine)

### Step 1 — Get the shared store

The `.copilot-shared\` folder is local-only. Get a copy from a teammate:

```bash
# A teammate zips and shares it
cd $COPILOT_WORKSPACE_ROOT
tar czf copilot-shared.tgz .copilot-shared/

# You unpack it on your machine
cd $COPILOT_WORKSPACE_ROOT
tar xzf copilot-shared.tgz
```

Verify:
```cmd
dir %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin
```
Expect: `setup-repo.ps1`, `setup-local.ps1`, `link-copilot.cmd`, `link-all-copilot.cmd`,
`unlink-copilot.cmd`, `copy-agents.cmd`, `refresh-agents.cmd`.

### Step 2 — Clone repos under `%COPILOT_WORKSPACE_ROOT%\`

```cmd
cd %COPILOT_WORKSPACE_ROOT%
git clone <repo-url> <repo-name>
```

### Step 3 — Link every repo at once

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-all-copilot.cmd
```

This walks `%COPILOT_WORKSPACE_ROOT%\*`, finds every repo with
`.github\copilot-instructions.md`, and creates the four junctions. Repos
without that file are skipped (they need `setup-repo.ps1` first).

### Step 4 — Create your personal instructions (one-time per machine)

```cmd
copy %COPILOT_WORKSPACE_ROOT%\.copilot-shared\templates\personal-instructions.template.md ^
     %COPILOT_WORKSPACE_ROOT%\<repo-name>\.github\personal-instructions.md
```

This file is gitignored — captures your shell preference, paths, etc.

### Step 5 — Restart JetBrains

JetBrains caches `.github/` at project open. Restart for Copilot to pick up
the junctions.

### Step 6 — Verify

In Copilot Chat:
```
What agents and skills are available in this project?
```
You should see agents from `.github/agents/`, skills from
`.github/skills/`, and instructions from `.github/instructions/` plus
`instructions-local/`.

---

## Adding a new repo

For a repo that has no `.github/` yet:

```cmd
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\setup-repo.ps1 %COPILOT_WORKSPACE_ROOT%\<new-repo>
```

This creates `.github/`, seeds `copilot-instructions.md`, creates
`instructions-local/`, copies agents from `agent-templates/`, drops this
`COPILOT-SETUP.md` and `customize-agents.prompt.md` in, and junctions
skills/instructions/prompts/plans.

Then:

1. Edit `.github/copilot-instructions.md` (project overview).
2. Edit `.github/instructions-local/project-rules.instructions.md` (hard rules).
3. Open the repo in JetBrains and ask Copilot Chat:
   ```
   Run the customize-agents skill on this repo.
   ```
   The **customize-agents** skill (in `.github/skills/customize-agents/`)
   will read your two files above and rewrite each agent's placeholder
   tokens (`<DomainEntity>`, `<ProjectException>`, `<calling-service>`, ...)
   with this repo's actual values.
4. Review the diffs, then `git add .github/agents/ && git commit`.

### Adopting the layout in a repo that already has `.github/`

If your repo already has `.github\workflows\`, `CODEOWNERS`, etc. but no
Copilot config:

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

Then manually seed the per-repo files:
```cmd
copy %COPILOT_WORKSPACE_ROOT%\.copilot-shared\templates\copilot-instructions.template.md  ^
     <repo>\.github\copilot-instructions.md
copy %COPILOT_WORKSPACE_ROOT%\.copilot-shared\templates\COPILOT-SETUP.template.md ^
     <repo>\.github\COPILOT-SETUP.md
copy %COPILOT_WORKSPACE_ROOT%\.copilot-shared\templates\customize-agents.prompt.md ^
     <repo>\.github\customize-agents.prompt.md
mkdir <repo>\.github\instructions-local
copy %COPILOT_WORKSPACE_ROOT%\.copilot-shared\templates\project-rules.template.instructions.md ^
     <repo>\.github\instructions-local\project-rules.instructions.md
xcopy /E /I %COPILOT_WORKSPACE_ROOT%\.copilot-shared\agent-templates ^
            <repo>\.github\agents
```

If the repo already has real `skills/`, `instructions/`, `prompts/` folders,
back them up first, decide what's worth contributing back to the shared
store, then delete the locals before re-running `link-copilot.cmd`.

---

## Daily workflow

| To change… | Edit here | Affects |
|---|---|---|
| A shared skill | `.copilot-shared\shared\skills\<name>\SKILL.md` | All repos |
| A shared prompt | `.copilot-shared\shared\prompts\<name>.md` | All repos |
| A shared instruction | `.copilot-shared\shared\instructions\<name>.instructions.md` | All repos |
| Cross-repo plan | `.copilot-shared\shared\plans\YYYY-MM-<slug>.md` | All repos see it |
| Project rules (this repo) | `.github\instructions-local\*.instructions.md` | This repo |
| Project overview | `.github\copilot-instructions.md` | This repo |
| An agent (this repo) | `.github\agents\<name>.agent.md` | This repo |
| Personal preferences | `.github\personal-instructions.md` | You only |

Edits to shared files propagate to every linked repo immediately. After
significant edits, version them:

```cmd
cd %COPILOT_WORKSPACE_ROOT%\.copilot-shared
git add -A && git commit -m "<change>"
```

---

## Distributing changes to teammates

There's no remote git, so changes to `.copilot-shared\` must be shared manually:

```bash
# Source machine
cd $COPILOT_WORKSPACE_ROOT/.copilot-shared
git log --oneline -5
tar czf copilot-shared-update.tgz --exclude='.git' .

# Teammate's machine
cd $COPILOT_WORKSPACE_ROOT
mv .copilot-shared .copilot-shared.bak
tar xzf copilot-shared-update.tgz -C .copilot-shared/
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-all-copilot.cmd
```

> **Recommendation:** for >2–3 people, set up a private GitHub repo for
> `.copilot-shared\` and push your local commits there. The local-only
> setup doesn't scale to a team.

---

## Cross-repo plans

When a feature spans repos:

1. Create the plan once at `.copilot-shared\shared\plans\YYYY-MM-<slug>.md`.
2. It appears as `.github\plans\<file>.md` in every linked repo.
3. From any repo's Copilot Chat:
   ```
   Continue executing .github/plans/<filename>.md
   ```
4. In JetBrains, open all involved repos as one multi-root project so each
   repo's `.github/agents/` and `instructions-local/` apply when editing
   files in its tree.

See `.github/plans/README.md` (junctioned in) for the plan template.

---

## Always-on rules

These instructions are loaded into every Copilot interaction in this repo:

| File | What it enforces |
|---|---|
| `instructions/orchestrator.instructions.md` | Lean routing + token budget defaults |
| `instructions/memory-bank.instructions.md` | Targeted memory reads only |
| `instructions-local/project-rules.instructions.md` | Repo-specific hard rules |

Add more files under `instructions-local/` as needed — anything matching
`*.instructions.md` with `applyTo: '**'` frontmatter is auto-loaded.

Token optimization recommendation:
- Keep always-on files to the minimum set above.
- Load `agent-skills`, `design-principles`, and `performance-awareness` only for tasks that need them.
- Prefer narrower `applyTo` patterns instead of `**` whenever possible.

Balanced profile (recommended):
- Keep `orchestrator`, `memory-bank`, and `project-rules` always-on.
- Keep quality instructions (`design-principles`, `performance-awareness`, `tdd`) scoped to source files only.
- Use broad `applyTo: '**'` only for truly universal policy files.

## Token Profile Toggle (Balanced vs Aggressive)

Use a repo-local file to switch behavior without editing shared rules:

1. Copy one profile template from `.copilot-shared/templates/` into:
   `.github/instructions-local/token-profile.instructions.md`
2. Keep only one active profile file at a time.
3. Restart the chat session after switching.

Available templates:
- `token-profile-balanced.template.instructions.md` (recommended default)
- `token-profile-aggressive.template.instructions.md` (maximum savings)

If a shared rule conflicts with a per-repo rule, **the per-repo rule wins**.

---

## Troubleshooting

**Q: Copilot says skills/agents are missing after I clone.**
A: Junctions aren't checked into git. Run
   `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-copilot.cmd <repo>` after every fresh clone.

**Q: A pull recreated `.github/skills/` as a real empty folder.**
A: Run `link-copilot.cmd <repo>` — it detects the empty folder and replaces it.

**Q: I need a custom skill in this repo only.**
A: `unlink-copilot.cmd <repo>`, copy the shared skills into `.github/skills/`
   as a real folder, edit your custom skill, then `link-copilot.cmd` — it
   detects the real folder and won't junction it.

**Q: How do I see what changed in `.copilot-shared\`?**
A: `cd %COPILOT_WORKSPACE_ROOT%\.copilot-shared && git log --oneline`.

**Q: I'm on a Mac.**
A: Replace junctions with symlinks:
   ```bash
   for d in skills instructions prompts plans; do
     ln -s $COPILOT_WORKSPACE_ROOT/.copilot-shared/shared/$d $COPILOT_WORKSPACE_ROOT/<repo>/.github/$d
   done
   ```

**Q: An agent gives advice that contradicts our coding standard.**
A: The agent template wasn't customised for this repo. In Copilot Chat say:
   `Run the customize-agents skill on this repo.`

---

## File reference

- Central documentation: `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\README.md`
- Customise-agents prompt: `.github/customize-agents.prompt.md` (per-repo copy)
- Personal-instructions template: `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\templates\personal-instructions.template.md`
- Cross-repo plan README: `.github/plans/README.md` (junctioned)
