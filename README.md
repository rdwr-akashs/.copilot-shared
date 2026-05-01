# `.copilot-shared` — Radware Shared Copilot Configuration

Single source of truth for GitHub Copilot **agents, skills, instructions, and
prompts** shared across all Radware repos under `%COPILOT_WORKSPACE_ROOT%\`.
Edit once, every linked repo sees the change instantly — via filesystem junctions.

> **This repo is public** so the community can learn from and adapt our Copilot
> workflow. The skills and agents are Radware-specific but the patterns are
> reusable. Contributions from Radware team members are welcome — see
> [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Quick Start (New Team Member)

### 0. Set your workspace root

All Radware repos live side-by-side under one folder. Set the env var so the
scripts know where to find them:

**Windows (cmd — permanent):**
```cmd
setx COPILOT_WORKSPACE_ROOT "C:\your\workspace\path"
```

**Windows (PowerShell — permanent):**
```powershell
[Environment]::SetEnvironmentVariable("COPILOT_WORKSPACE_ROOT", "C:\your\workspace\path", "User")
```

**macOS / Linux:**
```bash
echo 'export COPILOT_WORKSPACE_ROOT="$HOME/workspace"' >> ~/.bashrc
source ~/.bashrc
```

> If you don't set the env var, the scripts auto-detect by using the parent
> folder of `.copilot-shared/`.

### 1. Clone this repo

```cmd
cd %COPILOT_WORKSPACE_ROOT%
git clone https://github.com/Radware/copilot-shared.git .copilot-shared
```
### 1.5. Run first-time local setup

This is what makes the toolkit **org-specific and powerful**. Run it once after cloning:

```powershell
.copilot-shared\bin\setup-local.ps1
```

You'll be asked for:
1. Your **Bitbucket workspace slug** (e.g. `mycompany`)
2. Your **product names** (used in agent context)
3. Optional: **Bitbucket App Password** to auto-fetch your full repo list

What it generates (all gitignored):

| File | What it does |
|------|-------------|
| `shared/instructions/copilot-local.instructions.md` | **Most impactful** — junctioned into every linked repo so agents always know your workspace name, product names, and key repos. No more `<bb-workspace>` placeholders. |
| `shared/memory/*.md` | Initialised from templates — grows as you investigate cases and bugs |
| `remote-repo-exploration/references/repo-categories.md` | Your real repo list, fetched from Bitbucket API and categorised |
| `.local.env` | `BB_WORKSPACE` and `BB_BASE_URL` for scripts |

Re-run with `-Force` to refresh (e.g. after your repo list grows).
### 2. Clone your product repos from Bitbucket

```cmd
cd %COPILOT_WORKSPACE_ROOT%
git clone https://bitbucket.org/<bb-workspace>/<your-repo>.git
:: ... clone whichever repos you work on
```

### 3. Link one repo

**New repo** (no `.github/` yet):
```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\setup-repo.cmd %COPILOT_WORKSPACE_ROOT%\<your-repo>
```

**Existing repo** (already has `.github/`):
```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<your-repo>
```

### 4. Link ALL repos at once

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\link-all-copilot.cmd
```

Walks `%COPILOT_WORKSPACE_ROOT%\*`. Skips repos without a `.github/copilot-instructions.md`
(those need `setup-repo.cmd` first).

### 5. Customise per-repo

After linking, edit these three files in each repo:

1. `.github/copilot-instructions.md` — describe the project
2. `.github/instructions-local/project-rules.instructions.md` — hard rules for this repo
3. Open Copilot Chat → *"Run the customize-agents skill on this repo."*

Restart your IDE. Done.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| JetBrains IDE or VS Code | With GitHub Copilot plugin installed |
| GitHub Copilot subscription | Individual or business plan |
| Workspace at `%COPILOT_WORKSPACE_ROOT%\` | All Radware repos cloned here |
| Bitbucket access | `<bb-workspace>` workspace — for product repos |
| Git Bash (recommended) | For terminal operations on Windows |

> **macOS / Linux:** Use symlinks (`ln -s`) instead of junctions. Adapt the
> `.cmd` scripts or create shell equivalents — PRs welcome.

---

## Layout

```
%COPILOT_WORKSPACE_ROOT%\
├── .copilot-shared\            ← THIS REPO (cloned from GitHub)
│   ├── shared\                 # Junctioned into every repo's .github\
│   │   ├── skills\             # Reusable skills (cross-repo-exploration, customer-case-intake, rca-*, etc.)
│   │   ├── instructions\       # Copilot rules (orchestrator, agent-skills, memory-bank, customer-case-rca)
│   │   └── prompts\            # Reusable prompt templates (investigate-customer-case, etc.)
│   ├── agent-templates\        # Copied (not junctioned) per-repo; customised locally
│   ├── cases\                  # Local-only solved-case archive (gitignored — contains customer data)
│   ├── templates\              # Per-repo seed files (copilot-instructions, project-rules, etc.)
│   └── bin\                    # Setup scripts (Windows .cmd)
│       ├── setup-repo.cmd      # One-shot setup for a new repo
│       ├── link-copilot.cmd    # (Re)create junctions for one repo
│       ├── link-all-copilot.cmd# Walk %COPILOT_WORKSPACE_ROOT%\; link every repo
│       ├── unlink-copilot.cmd  # Remove junctions from one repo
│       ├── copy-agents.cmd     # Seed .github\agents\ from agent-templates\
│       ├── doctor.cmd          # Health-check one repo's Copilot wiring
│       └── refresh-agents.cmd  # Pull upstream agent-template improvements
├── <your-repo-1>\               ← product repo (Bitbucket)
│   └── .github\
│       ├── copilot-instructions.md
│       ├── agents\             # Copied from agent-templates\, customised
│       ├── instructions-local\ # Per-repo rules
│       ├── instructions\ → JUNCTION → .copilot-shared\shared\instructions
│       ├── skills\       → JUNCTION → .copilot-shared\shared\skills
│       └── prompts\      → JUNCTION → .copilot-shared\shared\prompts
├── <your-repo-2>\               ← another product repo
└── ...                         ← all repos in your Bitbucket workspace
```

---

## What's Shared vs Per-Repo

| Item | Shared? | Why |
|---|---|---|
| `skills/` | Junction | Same workflow patterns for any Radware repo |
| `instructions/` (generic) | Junction | Routing + memory + skill-loading rules |
| `prompts/` | Junction | Reusable prompt templates |
| `agents/` | Copy | Agents encode project-specific conventions |
| `copilot-instructions.md` | Per-repo | Project overview is unique per product |
| `instructions-local/` | Per-repo | Exception types, build commands, domain rules |
| `personal-instructions.md` | Per-developer | Local paths, shell preference (gitignored) |

---

## Daily Workflow

### Editing a shared skill

```cmd
notepad %COPILOT_WORKSPACE_ROOT%\.copilot-shared\shared\skills\writing-plans\SKILL.md
```

Save → every linked repo sees the change immediately. No sync step.

### Adding a new shared skill

1. `mkdir %COPILOT_WORKSPACE_ROOT%\.copilot-shared\shared\skills\my-skill`
2. Create `SKILL.md` (see `shared/instructions/agent-skills.instructions.md` for conventions).
3. Done. Every linked repo can now invoke it.
4. **Push to GitHub** so teammates get it too: `git add . && git commit -m "feat: add my-skill" && git push`

### Per-repo override

If one repo needs a different version of a shared skill:

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\unlink-copilot.cmd %COPILOT_WORKSPACE_ROOT%\my_repo
mkdir %COPILOT_WORKSPACE_ROOT%\my_repo\.github\skills
xcopy /e %COPILOT_WORKSPACE_ROOT%\.copilot-shared\shared\skills %COPILOT_WORKSPACE_ROOT%\my_repo\.github\skills
REM Edit .github\skills\commit-push\SKILL.md as needed
```

Re-running `link-copilot.cmd` will see the real `skills/` folder and skip
junctioning it (preserving your override).

### Customer Case RCA Workflow

> Full guide: [`shared/instructions/customer-case-rca.README.md`](shared/instructions/customer-case-rca.README.md)

When you're handed a customer escalation (RSEG-/SC-/INC-/JIRA- ticket with a
DefenseFlow/Vision support bundle), use the `case-investigator` agent. Kick off
via the prompt at `shared/prompts/investigate-customer-case.md`.

| Phase | What happens |
|-------|--------------|
| 0     | Scaffolds `.agent_work/<case-id>/investigation.md`; auto-unzips archives |
| 0.5   | Prior-case lookup against `cases/_index.md` |
| 1     | Problem framing |
| 2     | 9 parallel triage subagents (Identity, Connectivity, Replication, HA, Resources, etc.) |
| 3     | Maps findings to `repo / file / method / line` in the relevant codebase |
| 5–6   | Authors `rca-<case-id>.md` with draft commit message |
| 7     | Archives to `cases/<case-id>/` |
| 8     | Hands fix off to `developer` agent |

> **⚠️ `cases/` is gitignored** — it contains customer data and must NEVER be pushed.

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
| `full-stack-feature` | End-to-end feature: Java backend + React frontend together |
| `elasticsearch-expert` | ES query debugging, mapping conflicts, index design |
| `akka-expert` | Actor hierarchy design, dead-letter debugging, dispatcher tuning |
| `perf-investigator` | Performance triage across JVM, Akka, ES, RabbitMQ, React |
| `story-writer` | Write Jira stories, bugs, and spikes in EARS notation |

### Skills (35)

Organized in `shared/skills/`:

| Skill | What it does |
|---|---|
| **TDD & Testing** | |
| `tdd-java` | Java TDD: JUnit 5, Mockito, TestContainers, MockMvc. Red→Green→Refactor |
| `tdd-react` | React TDD: RTL, Jest, MSW. Component, hook, and page testing |
| `java-test-coverage` | Jacoco analysis — find uncovered branches, write targeted tests |
| **API Design** | |
| `api-contract-first` | OpenAPI spec-first — spec before code; generate TS types and Java DTOs |
| `adding-rest-endpoints` | REST endpoint scaffolding |
| **Debugging** | |
| `elasticsearch-debug` | ES query wrong/slow: `_explain`, `_profile`, mapping checks, index health. Checks memory first. |
| `rabbitmq-debug` | Consumer lag, dead-letter, prefetch tuning, poison messages. Checks memory first. |
| `akka-debug` | Dead letters, dispatcher starvation, ask timeout, blocking actors. Checks memory first. |
| `systematic-debugging` | General structured bug investigation |
| `log-analysis` | Parse logs, find error patterns, correlate events, extract stack traces |
| **Memory & Learning** | |
| `save-learning` | Append investigation findings to shared memory. Run after every RCA or bug fix. |
| `acquire-codebase-knowledge` | Deep-dive into unfamiliar repos; writes `.github/repo-cache.md` |
| `remember` | Save lessons and patterns for future sessions |
| **Customer Cases** | |
| `customer-case-intake` | Ingest support bundles; checks `customer-cases.md` memory first |
| `support-file-triage` | Parallel subagent triage of support files |
| `rca-document` / `rca-evidence-mapping` | Generate structured RCA docs |
| `case-archive` | Persist solved cases; also appends to shared memory |
| **Dependencies** | |
| `dependency-upgrade` | Safe Maven/npm upgrade: CVE check, one-at-a-time, tests after each |
| `npm-errors` | npm/UI build failure triage |
| **Planning & Design** | |
| `writing-plans` / `executing-plans` | Design-first development |
| `brainstorming` | Structured ideation and requirements exploration |
| `dispatching-parallel-agents` | Fan-out independent tasks to subagents (includes two-stage review) |
| **Git Workflow** | |
| `commit-push` | Git commit + push with conventional commits |
| `requesting-pr-review` / `handling-pr-review-comments` | Bitbucket PR workflow |
| `finishing-a-development-branch` | Merge prep checklist |
| `receiving-code-review` / `requesting-code-review` | Self-review and receiving feedback |
| **Cross-Repo** | |
| `cross-repo-exploration` | Read/search sibling repos via terminal |
| `remote-repo-exploration` | Search across 90+ Bitbucket repos using MCP + shallow clones |
| **Other** | |
| `verification-before-completion` | Never claim done without proof |
| `using-git-worktrees` | Workspace isolation |
| `customize-agents` | Tailor agent templates to a specific repo |
| `writing-skills` | Create and edit Copilot skills |

### Shared Memory (grows over time)

Located in `shared/memory/` — **gitignored here, maintain in your internal repo**.
The structure is provided as a template; each team populates it from real work:

| File | Contains |
|---|---|
| `customer-cases.md` | Symptom → root cause → fix matrix. Checked automatically before every case intake. |
| `known-bugs.md` | Bug table with log evidence patterns and workarounds. |
| `tech-discoveries.md` | ES indexes, RabbitMQ queues, Akka topologies, PG configs, repo registry. |

### Instructions

- **`orchestrator.instructions.md`** — Auto-dispatch, cache-first context loading, agent/skill routing
- **`tdd.instructions.md`** — TDD-first mandate: no production code without a failing test
- **`java-conventions.instructions.md`** — Constructor injection, no null returns, exception hierarchy, boundary validation
- **`react-conventions.instructions.md`** — Component naming, hooks patterns, MSW mocking, accessibility-first
- **`agent-skills.instructions.md`** — Guidelines for writing high-quality skills
- **`design-principles.instructions.md`** — SOLID, DRY, KISS, YAGNI as hard rules
- **`performance-awareness.instructions.md`** — N+1, allocation, I/O, concurrency
- **`customer-case-rca.instructions.md`** — Customer case investigation process
- **`memory-bank.instructions.md`** — Persistent context management
- **`shell.instructions.md`** — Terminal usage conventions

### Prompts (6)

- **`start-feature.md`** — Kick off a full-stack feature (triggers `full-stack-feature` agent)
- **`bug-report.md`** — Structured bug investigation (triggers `debugger` + `systematic-debugging`)
- **`review-request.md`** — Pre-PR self-review (triggers `reviewer` agent)
- **`dependency-audit.md`** — Dependency upgrade prompt (triggers `dependency-upgrade` skill)
- **`investigate-customer-case.md`** — Customer case RCA prompt
- **`cross-repo-knowledge.md`** — Cross-repo exploration prompt

### Git Hooks

Located in `shared/hooks/`, installed via `bin/install-hooks.cmd <repo-path>`:

| Hook | What it enforces |
|---|---|
| `commit-msg` | Conventional Commits format (`feat:`, `fix:`, `docs:`, etc.) |
| `pre-push` | Runs `mvnw test` or `npx jest` before push (bypass with `SKIP_TESTS=1`) |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide. In short:

1. Clone this repo from GitHub (not Bitbucket — this lives on GitHub)
2. Create a branch: `git checkout -b feat/my-improvement`
3. Make your changes (new skill, agent improvement, instruction fix)
4. Test by running `link-copilot.cmd` on a repo and verifying in Copilot Chat
5. Push and open a PR on GitHub

**What to contribute:**
- New shared skills that work across repos
- Agent template improvements
- Instruction fixes and enhancements
- Bug fixes in `bin/` scripts

**What NOT to commit:**
- Customer data or support bundles (`cases/` is gitignored)
- Personal paths in `personal-instructions.md` (gitignored)
- Secrets, tokens, or credentials

---

## Troubleshooting

**Q: How do I check if a repo is wired up correctly?**

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\doctor.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

Reports PASS/WARN/FAIL on: `.github/` layout, junctions pointing into
`.copilot-shared\shared`, `.gitignore` marker block, unresolved
`<placeholder>` tokens, and stale template terms.

**Q: I improved an agent template. How do I push that into existing repos?**

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\refresh-agents.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

For each `agent-templates/*.agent.md`:
- **NEW** — repo is missing it; copied in (then run `customize-agents` skill).
- **SAME** — repo's copy is byte-identical; nothing to do.
- **CONFLICT** — saved as `<agent>.agent.md.template.new` for manual merge.

Never overwrites a customised agent.

**Q: IDE doesn't see the shared skills.**
- Verify the junction: `dir %COPILOT_WORKSPACE_ROOT%\<repo>\.github` should show
  `<JUNCTION>` next to `skills`, `instructions`, `prompts`.
- Restart the IDE; it caches `.github/` on project open.

**Q: Junction creation fails.**
- `mklink /J` does not require admin. Confirm `cmd.exe` (not WSL) is being used.
- If running from PowerShell, `mklink` is a cmd built-in: use `cmd /c mklink ...`
  or just call the `.cmd` scripts (which auto-handle this).

**Q: A repo's junctions disappeared.**
- Some IDE/refactor tools recreate junctioned folders as real (empty) folders.
  Re-run `link-copilot.cmd <repo>` — it's idempotent.

**Q: I want a repo excluded from auto-linking.**
- Don't create `.github/copilot-instructions.md` in it. `link-all-copilot.cmd`
  skips repos without that file.

---

## Removing the Integration from a Repo

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\unlink-copilot.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

Junctions are removed. Real folders (`agents/`, `instructions-local/`,
`copilot-instructions.md`) are left untouched.

---

## License

[MIT](LICENSE) — Copyright 2025 Radware Ltd.
