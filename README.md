# `.copilot-shared` — Radware Shared Copilot Configuration

Single source of truth for GitHub Copilot **agents, skills, instructions, prompts, and memory** shared across all Radware repos under `%COPILOT_WORKSPACE_ROOT%\`.
Edit once — every linked repo sees the change instantly via filesystem junctions.

> **This repo is public** so the community can learn from and adapt our workflow.
> Skills and agents are Radware-specific but the patterns are reusable.
> Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Quick Start — New Team Member

### Step 0: Set workspace root

All repos live side-by-side under one folder:

```cmd
:: Windows (permanent)
setx COPILOT_WORKSPACE_ROOT "C:\rdwr-intelij"
```

> Scripts auto-detect the parent of `.copilot-shared\` if the env var is not set.

### Step 1: Clone this repo

```cmd
cd %COPILOT_WORKSPACE_ROOT%
git clone https://github.com/Radware/copilot-shared.git .copilot-shared
```

### Step 2: Personalise (run once)

```powershell
.copilot-shared\bin\setup-local.ps1
```

Prompts for your Bitbucket workspace slug, product names, and optionally fetches your full repo list. Generates these gitignored files:

| File | Purpose |
|------|---------|
| `shared/instructions/copilot-local.instructions.md` | Injected into every session — agents know your workspace, products, repos |
| `shared/memory/*.md` | Knowledge store seeded from templates, grows with real work |
| `.local.env` | `BB_WORKSPACE` and `BB_BASE_URL` for other scripts |

### Step 3: Clone your product repos

```cmd
cd %COPILOT_WORKSPACE_ROOT%
git clone <bitbucket-url>/repo1.git
git clone <bitbucket-url>/repo2.git
```

### Step 4a: New repo — full setup

```powershell
:: Creates .github/, copies agents, creates all junctions, wires memory-bank/
.copilot-shared\bin\setup-repo.ps1 %COPILOT_WORKSPACE_ROOT%\<repo>

:: Optional: also generate an initial context pack
.copilot-shared\bin\setup-repo.ps1 %COPILOT_WORKSPACE_ROOT%\<repo> -GenerateRepoMix
```

### Step 4b: Existing repo — add Copilot wiring

For repos that already have a `.github/` but aren't yet connected to the shared store:

```cmd
:: 1. Junction skills, instructions, prompts, plans, learning, cases
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<repo>

:: 2. Seed agent templates (skips any already customised)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\copy-agents.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

```powershell
:: 3. Wire memory-bank/ junction → central store
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "%COPILOT_WORKSPACE_ROOT%" `
  -Repos "<repo>" `
  -CreateSymlinks 1 -DeleteLocal 0 -Verify 1
```

Any existing `memory-bank/` content is migrated to central and replaced with a junction automatically.

### Step 4c: All repos at once

```cmd
:: Wire junctions for every repo under the workspace root
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-all-copilot.cmd

:: Set up any repo missing .github/copilot-instructions.md
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\setup-all-repos.ps1
```

```powershell
:: Centralise memory for multiple repos in one command
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "%COPILOT_WORKSPACE_ROOT%" `
  -Repos "repo1,repo2,repo3" `
  -CreateSymlinks 1 -DeleteLocal 0 -Verify 1
```

### Step 5: Finish in Copilot Chat (one-time per repo)

Open the repo in VS Code and run in Copilot Chat:

```
Run the customize-agents skill on this repo.
Run the acquire-codebase-knowledge skill.
```

Restart VS Code after the second command. Done — full context is live.

---

## How Central Memory Works

Every repo's `memory-bank/` is a **junction** pointing to `.copilot-shared\shared\memory\<repo>\`. Writing there writes to central. No sync needed.

```
<repo>/memory-bank/              ← junction (not a real folder)
        │
        └──▶  .copilot-shared/shared/memory/<repo>/    ← files physically live here

<repo>/.github/learning/         ← junction → shared/learning/
<repo>/.github/cases/            ← junction → shared/cases/
```

Agents write `memory-bank/activeContext.md` → file is immediately readable from every other linked repo.

---

## Layout

```
%COPILOT_WORKSPACE_ROOT%\
├── .copilot-shared\
│   ├── shared\
│   │   ├── instructions\       # Copilot rules (orchestrator, memory-bank, customer-case-rca …)
│   │   ├── skills\             # Reusable skills (cross-repo-exploration, rca-*, save-learning …)
│   │   ├── prompts\            # Reusable prompt templates
│   │   ├── plans\              # Cross-repo feature plans
│   │   ├── learning\           # Central learning materials (best-practices/, troubleshooting/, …)
│   │   └── memory\             # *** CENTRAL KNOWLEDGE STORE ***
│   │       ├── <repo-name>/            # Per-repo memory — junctioned as memory-bank/ in each repo
│   │       ├── cross-repo/             # Learnings spanning multiple repos
│   │       ├── repo-contexts/          # Auto-generated context packs (repo-mix-all)
│   │       ├── active-context.md       # Current work focus
│   │       ├── architecture-map.md     # Auto-generated service topology
│   │       ├── cross-repo-learnings.md # Patterns spanning repos
│   │       ├── customer-cases.md       # Solved case patterns
│   │       ├── known-bugs.md           # Bug reference
│   │       ├── tech-discoveries.md     # Repo registry & tech stacks
│   │       └── logs/                   # Script run logs (gitignored)
│   ├── agent-templates\        # Seed agents — copied (not junctioned) per repo
│   ├── cases\                  # Central case archive (junctioned as .github/cases/ in each repo)
│   ├── templates\              # Seed files for setup-repo.ps1
│   └── bin\
│       ├── setup-local.ps1     # ONE-TIME: personalise after clone
│       ├── setup-repo.ps1      # ONE-TIME per repo: full .github/ + memory junction
│       ├── centralize-memory.ps1  # Wire memory-bank junctions for existing repos
│       ├── link-copilot.cmd    # (Re)create shared junctions for one repo
│       ├── link-all-copilot.cmd   # Walk workspace and link every repo
│       ├── copy-agents.cmd     # Seed .github/agents/ from agent-templates/
│       ├── setup-all-repos.ps1 # Run setup-repo on every repo missing .github/
│       ├── full-context-refresh.ps1  # Rebuild architecture-map + all repo context packs
│       ├── workspace-scan.ps1  # Generate architecture-map.md
│       ├── repo-mix.ps1        # Generate context pack for one repo
│       ├── repo-mix-all.ps1    # Generate context packs for all repos
│       ├── audit.ps1           # Health-check all repos in one table
│       ├── doctor.ps1          # Health-check one repo
│       ├── token-profile.ps1   # Switch per-repo token profile (balanced/aggressive)
│       └── export-memory.ps1 / import-memory.ps1  # Backup/restore central memory
│
├── <repo-1>\
│   ├── memory-bank\        → JUNCTION → .copilot-shared\shared\memory\<repo-1>\
│   └── .github\
│       ├── copilot-instructions.md
│       ├── agents\             # Per-repo customised agents
│       ├── instructions-local\ # Per-repo rules (project-rules, cli-commands)
│       ├── instructions\   → JUNCTION → shared\instructions\
│       ├── skills\         → JUNCTION → shared\skills\
│       ├── prompts\        → JUNCTION → shared\prompts\
│       ├── plans\          → JUNCTION → shared\plans\
│       ├── learning\       → JUNCTION → shared\learning\
│       └── cases\          → JUNCTION → .copilot-shared\cases\
│
└── <repo-2>\  …
```

---

## What's Shared vs Per-Repo

| Item | Type | Edit? |
|------|------|-------|
| `skills/` | Junction → central | Edit in `.copilot-shared` |
| `instructions/` | Junction → central | Edit in `.copilot-shared` |
| `prompts/` | Junction → central | Edit in `.copilot-shared` |
| `plans/` | Junction → central | Edit in `.copilot-shared` |
| `learning/` | Junction → central | Edit in `.copilot-shared` |
| `cases/` | Junction → central | Edit in `.copilot-shared` |
| `memory-bank/` | Junction → `shared/memory/<repo>/` | Agents write here automatically |
| `agents/` | Per-repo copy | Customise per codebase |
| `copilot-instructions.md` | Per-repo | Describes this specific project |
| `instructions-local/` | Per-repo | Project rules, build commands |
| `personal-instructions.md` | Per-developer (gitignored) | Local paths, shell preferences |

---

## Daily Workflow

### Editing a shared skill or instruction

```cmd
:: Edit in .copilot-shared — every linked repo sees it immediately
notepad %COPILOT_WORKSPACE_ROOT%\.copilot-shared\shared\skills\save-learning\SKILL.md
```

After changing shared skills, instructions, prompts, or agent templates:

```powershell
powershell -ExecutionPolicy Bypass -File bin\generate-skill-index.ps1
powershell -ExecutionPolicy Bypass -File bin\audit-copilot-assets.ps1
```

The audit is the maintainer safety net for this central repo: it checks skill
frontmatter, agent template metadata, prompt shape, oversized skills, and stale
generated indexes before changes are shared with the team.

### Refresh the central knowledge store

```cmd
:: Full refresh: architecture map + all repo context packs (~5 min)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\full-context-refresh.cmd

:: Architecture map only
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\workspace-scan.cmd

:: One repo context pack
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\repo-mix.cmd -RepoPath %COPILOT_WORKSPACE_ROOT%\<repo>
```

Run weekly or after adding/removing repos.

### Switch token profile

```cmd
:: Balanced (recommended)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\token-profile.cmd balanced %COPILOT_WORKSPACE_ROOT%\<repo>

:: Aggressive (maximum savings)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\token-profile.cmd aggressive %COPILOT_WORKSPACE_ROOT%\<repo>
```

### Health-check all repos

```powershell
.copilot-shared\bin\audit.ps1
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| VS Code or JetBrains IDE | With GitHub Copilot plugin |
| GitHub Copilot subscription | Individual or Business |
| Workspace at `%COPILOT_WORKSPACE_ROOT%\` | All repos cloned here side-by-side |
| Bitbucket access | For product repos |
| Git Bash (Windows) | For terminal operations |

> **macOS / Linux:** Use `ln -s` instead of junctions. Adapt `.cmd` scripts to shell equivalents — PRs welcome.

---

## Included Content

### Agent Templates (15)

| Agent | Purpose |
|---|---|
| `developer` | Day-to-day implementation |
| `tester` | Test writing and coverage |
| `debugger` | Bug investigation and fix |
| `reviewer` | Code review (Bitbucket PR-aware) |
| `devops` | Build, CI/CD, deployment |
| `principal-engineer` | Architecture, design decisions, pre-implementation gate |
| `squadleader` | Sprint planning and task breakdown |
| `case-investigator` | Customer escalation RCA (DefenseFlow / Vision) |
| `gem-code-simplifier` | Code simplification |
| `expert-react-frontend-engineer` | React frontend (webui_* repos) |
| `full-stack-feature` | End-to-end feature: Java backend + React frontend |
| `elasticsearch-expert` | ES query debugging, mapping conflicts, index design |
| `akka-expert` | Actor hierarchy design, dead-letter debugging, dispatcher tuning |
| `perf-investigator` | Performance triage across JVM, Akka, ES, RabbitMQ, React |
| `story-writer` | Write Jira stories, bugs, and spikes in EARS notation |

### Skills (35)

| Skill | What it does |
|---|---|
| `tdd-java` | JUnit 5 / Mockito / TestContainers Red→Green→Refactor |
| `tdd-react` | RTL / Jest / MSW component, hook, and page testing |
| `java-test-coverage` | Jacoco analysis — find uncovered branches, write targeted tests |
| `api-contract-first` | OpenAPI spec-first — spec before code |
| `adding-rest-endpoints` | REST endpoint scaffolding |
| `elasticsearch-debug` | `_explain`, `_profile`, mapping checks, index health |
| `rabbitmq-debug` | Consumer lag, dead-letter, prefetch tuning |
| `akka-debug` | Dead letters, dispatcher starvation, ask timeout |
| `systematic-debugging` | Structured bug investigation |
| `log-analysis` | Parse logs, find error patterns, extract stack traces |
| `save-learning` | Append investigation findings to shared memory |
| `acquire-codebase-knowledge` | Deep-dive unfamiliar repos; writes `.github/repo-cache.md` |
| `remember` | Save lessons and patterns for future sessions |
| `customer-case-intake` | Ingest support bundles; checks memory first |
| `support-file-triage` | Parallel subagent triage of support files |
| `rca-document` / `rca-evidence-mapping` | Generate structured RCA docs |
| `case-archive` | Persist solved cases; appends to shared memory |
| `dependency-upgrade` | Safe Maven/npm upgrade with CVE check |
| `npm-errors` | npm/UI build failure triage |
| `writing-plans` / `executing-plans` | Design-first development |
| `brainstorming` | Structured ideation and requirements exploration |
| `dispatching-parallel-agents` | Fan-out independent tasks to subagents |
| `commit-push` | Git commit + push with conventional commits |
| `requesting-pr-review` / `handling-pr-review-comments` | Bitbucket PR workflow |
| `finishing-a-development-branch` | Merge prep checklist |
| `cross-repo-exploration` | Read/search sibling repos via terminal |
| `remote-repo-exploration` | Search across Bitbucket repos using MCP + shallow clones |
| `verification-before-completion` | Never claim done without proof |
| `customize-agents` | Tailor agent templates to a specific repo |
| `writing-skills` | Create and edit Copilot skills |

### Shared Instructions

| File | Purpose |
|---|---|
| `orchestrator.instructions.md` | Auto-dispatch, cache-first context loading, agent routing |
| `memory-bank.instructions.md` | Persistent memory — write paths and tiered loading policy |
| `tdd.instructions.md` | TDD-first mandate |
| `java-conventions.instructions.md` | Constructor injection, no null returns, exception hierarchy |
| `react-conventions.instructions.md` | Component naming, hooks patterns, accessibility-first |
| `design-principles.instructions.md` | SOLID, DRY, KISS, YAGNI |
| `performance-awareness.instructions.md` | N+1, allocation, I/O, concurrency |
| `customer-case-rca.instructions.md` | Customer case investigation process |
| `shell.instructions.md` | Terminal usage conventions |
| `agent-skills.instructions.md` | Guidelines for writing skills |

### Central Memory (grows from real work)

`shared/memory/` — gitignored in this public repo; maintain in your internal repo.

| File | Contains |
|---|---|
| `customer-cases.md` | Symptom → root cause → fix patterns |
| `known-bugs.md` | Bug table with log evidence and workarounds |
| `tech-discoveries.md` | ES indexes, RabbitMQ queues, Akka topologies, repo registry |
| `active-context.md` | Current work focus across all repos |
| `architecture-map.md` | Auto-generated service topology (workspace-scan) |
| `cross-repo-learnings.md` | Patterns spanning multiple repos |
| `<repo-name>/` | Per-repo memory — junctioned as `memory-bank/` in each repo |

---

## Updating After Upstream Changes

```bash
# Pull latest shared config — skills, instructions, prompts, plans go live immediately
cd %COPILOT_WORKSPACE_ROOT%\.copilot-shared
git pull

# Refresh agent templates in a specific repo (merges new templates, skips customised ones)
bin\refresh-agents.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

| What changed | Propagation |
|---|---|
| `shared/skills/`, `shared/instructions/`, `shared/prompts/`, `shared/plans/` | **Instant** via junction — just `git pull` |
| `agent-templates/` | **Manual** — run `refresh-agents.cmd` per repo |
| `bin/` scripts | **Instant** — scripts run from `.copilot-shared` directly |

---

## Command Reference

Full list of every script in `bin/` with usage.

### Setup Scripts

| Script | What it does |
|--------|-------------|
| `setup-local.ps1` | **One-time** — personalise after cloning. Prompts for Bitbucket workspace/products, generates `copilot-local.instructions.md`, seeds memory templates, writes `.local.env` |
| `setup-repo.ps1 <repo-path>` | **One-time per repo** — full `.github/` setup: creates junctions (skills, instructions, prompts, plans, learning, cases), copies agent templates, wires `memory-bank/` to central |
| `setup-all-repos.ps1` | Runs `setup-repo.ps1` on every repo under workspace root that is missing `.github/copilot-instructions.md` |

```powershell
# One repo
powershell -File bin\setup-repo.ps1 %COPILOT_WORKSPACE_ROOT%\<repo>

# All repos at once
powershell -File bin\setup-all-repos.ps1
```

---

### Junction Scripts

| Script | What it does |
|--------|-------------|
| `link-copilot.cmd <repo-path>` | Create (or recreate) junctions for skills, instructions, prompts, plans, learning, cases in one repo. Also writes `memory-bank/` to `.gitignore` |
| `link-all-copilot.cmd` | Walk every sibling repo under workspace root and run `link-copilot.cmd` on each |
| `unlink-copilot.cmd <repo-path>` | Remove all `copilot-shared` junctions from a repo (safe — only removes junction points, never deletes files) |
| `copy-agents.cmd <repo-path>` | Seed `.github/agents/` from `agent-templates/`. Skips any agent file that already exists (won't overwrite customisations) |
| `install-hooks.cmd <repo-path>` | Install shared git hooks (`commit-msg`, `pre-push`) from `shared/hooks/` into the repo's `.git/hooks/` |

```cmd
:: Wire one repo
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<repo>

:: Wire all repos
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-all-copilot.cmd

:: Remove wiring from a repo
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\unlink-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<repo>

:: Seed agents (new repos or after adding a new agent template)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\copy-agents.cmd %COPILOT_WORKSPACE_ROOT%\<repo>

:: Install git hooks
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\install-hooks.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

---

### Memory Scripts

| Script | What it does |
|--------|-------------|
| `centralize-memory.ps1` | Migrate existing `memory-bank/` content to central store and replace with junction. Idempotent — safe to re-run |
| `export-memory.ps1` | Export `shared/memory/` to a timestamped zip archive (backup before sharing) |
| `import-memory.ps1` | Restore `shared/memory/` from a previously exported archive |

```powershell
:: Wire memory-bank junction — one repo
powershell -File bin\centralize-memory.ps1 `
  -RepoPath "%COPILOT_WORKSPACE_ROOT%" `
  -Repos "<repo>" `
  -CreateSymlinks 1 -DeleteLocal 0 -Verify 1

:: Wire memory-bank junction — multiple repos
powershell -File bin\centralize-memory.ps1 `
  -RepoPath "%COPILOT_WORKSPACE_ROOT%" `
  -Repos "repo1,repo2,repo3" `
  -CreateSymlinks 1 -DeleteLocal 0 -Verify 1

:: Backup memory
powershell -File bin\export-memory.ps1

:: Restore memory
powershell -File bin\import-memory.ps1 -ArchivePath "path\to\archive.zip"
```

---

### Context / Knowledge Scripts

| Script | What it does |
|--------|-------------|
| `workspace-scan.ps1` | Scan all repos and generate `shared/memory/architecture-map.md` — service topology |
| `repo-mix.ps1 -RepoPath <path>` | Generate a single-file context pack for one repo → `shared/memory/repo-contexts/<repo>.md` |
| `repo-mix-all.ps1` | Generate context packs for all repos in the workspace |
| `full-context-refresh.ps1` | Run `workspace-scan` + `repo-mix-all` in one pass (~5 min) |
| `generate-skill-index.ps1` | Regenerate `shared/skills/INDEX.md` from skill frontmatter after adding, removing, or renaming skills |
| `extract-support-bundle.ps1` | Extract RCA-critical files from a DefenseFlow/Vision support bundle (reads zip index, decompresses only what matters — fast even for 4–5 GB bundles) |
| `audit-copilot-assets.ps1` | Validate shared skills, instructions, prompts, and agent templates before publishing central repo changes |

```cmd
:: Full refresh (weekly / after adding repos)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\full-context-refresh.cmd

:: Architecture map only
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\workspace-scan.cmd

:: One repo context pack
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\repo-mix.cmd -RepoPath %COPILOT_WORKSPACE_ROOT%\<repo>
```

```powershell
:: Extract support bundle (RCA)
powershell -File bin\extract-support-bundle.ps1 -BundlePath "path\to\bundle.zip"
```

---

### Health-Check Scripts

| Script | What it does |
|--------|-------------|
| `doctor.ps1 <repo-path>` | Health check one repo — verifies all junctions, agent files, `memory-bank/`, gitignore entries |
| `doctor.cmd <repo-path>` | Thin cmd wrapper for `doctor.ps1` |
| `audit.ps1` | Run `doctor` on every repo under workspace root and print a summary table |

```cmd
:: Check one repo
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\doctor.cmd %COPILOT_WORKSPACE_ROOT%\<repo>

:: Check all repos
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\audit.ps1
```

---

### Agent / Token Scripts

| Script | What it does |
|--------|-------------|
| `refresh-agents.cmd <repo-path>` | Pull updates from `agent-templates/` into a repo's `.github/agents/`. Merges new templates, skips customised files (saves conflicts as `.template.new`) |
| `merge-agent-templates.ps1` | Auto-merge `.agent.md.template.new` conflict files into live agent files after a `refresh-agents` run |
| `token-profile.ps1 <profile> <repo-path>` | Switch Copilot token profile for a repo (`balanced` or `aggressive`) — copies the appropriate template instructions file |
| `token-profile.cmd <profile> <repo-path>` | Thin cmd wrapper for `token-profile.ps1` |

```cmd
:: Refresh agents after upstream update
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\refresh-agents.cmd %COPILOT_WORKSPACE_ROOT%\<repo>

:: Balanced profile (default — good quality, fewer tokens)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\token-profile.cmd balanced %COPILOT_WORKSPACE_ROOT%\<repo>

:: Aggressive profile (maximum token savings)
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\token-profile.cmd aggressive %COPILOT_WORKSPACE_ROOT%\<repo>
```

---

## Reference

| Doc | Purpose |
|-----|---------|
| [CENTRALIZED_MEMORY_SETUP.md](./CENTRALIZED_MEMORY_SETUP.md) | Full memory architecture and setup guide |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | How to contribute to this repo |
| [shared/memory/README.md](./shared/memory/README.md) | Central knowledge store structure |
| [cases/README.md](./cases/README.md) | Case archive structure |
| [TOKEN_OPTIMIZATION_ANALYSIS.md](./TOKEN_OPTIMIZATION_ANALYSIS.md) | Where tokens are being spent and why |
| [TOKEN_OPTIMIZATION_IMPLEMENTATION.md](./TOKEN_OPTIMIZATION_IMPLEMENTATION.md) | Step-by-step guide to reduce token usage |
| [TOKEN_USAGE_BEST_PRACTICES.md](./TOKEN_USAGE_BEST_PRACTICES.md) | Ongoing best practices |

---
