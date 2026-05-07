# Central Knowledge Store

`.copilot-shared/shared/memory/` is the **single source of truth** for all AI context across all repos.

## Directory Structure

```
shared/memory/
├── README.md                    # This file
├── customer-cases.md            # Case patterns (symptom → root cause → fix)
├── known-bugs.md                # Bug reference (ID, versions, workaround)
├── tech-discoveries.md          # Repo registry, tech stack patterns
├── cross-repo-learnings.md      # Architecture decisions & patterns that span repos
├── architecture-map.md          # Auto-generated: service relationships, APIs, data flows
├── active-context.md            # Current focus: what's being worked on right now
│
├── cross-repo/                  # Shared learnings across all repositories
│   ├── architecture-patterns.md
│   ├── deployment-learnings.md
│   └── incident-retrospectives.md
│
├── <repo-specific>/             # Per-repo memory (one folder per repo)
│   ├── df_core/
│   │   ├── memory.md
│   │   ├── performance-notes.md
│   │   ├── architecture.md
│   │   └── bugs-and-patterns.md
│   ├── kvision_configuration_service/
│   ├── kvision_incident_response/
│   ├── webui_components/
│   └── vision_core/
│
├── repo-contexts/               # Auto-generated: full context pack per repo
│   ├── _index.md               # Index of all scanned repos
│   └── <repo-name>.md          # One file per repo (tree + files + contents)
│
└── templates/                   # Seed templates used by setup-local.ps1
```

## What lives where

| Knowledge type | File | Updated by |
|----------------|------|-----------|
| Customer case patterns | `customer-cases.md` | `save-learning` skill after case resolution |
| Known bugs | `known-bugs.md` | `save-learning` skill after bug diagnosis |
| Repo tech structures | `tech-discoveries.md` | `save-learning` skill / `setup-local.ps1` |
| Cross-repo architecture | `cross-repo-learnings.md` | Manual + `save-learning` |
| Cross-repo insights | `cross-repo/*` | Team members & agents |
| **Repo-specific memory** | **`<repo-name>/memory.md`** | **Copilot agents in each repo** |
| **Repo performance notes** | **`<repo-name>/performance-notes.md`** | **Team members during optimization** |
| **Repo bugs & patterns** | **`<repo-name>/bugs-and-patterns.md`** | **Agents & developers** |
| Service topology map | `architecture-map.md` | `bin/workspace-scan.ps1` |
| Current work focus | `active-context.md` | Agent or user at start/end of session |
| Full repo source context | `repo-contexts/<repo>.md` | `bin/repo-mix-all.ps1` |

## How agents access this

From any linked repo, the memory is at:
```
$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\shared\memory\
```

The `memory-bank.instructions.md` tells agents to read these files at the start of every session.

## Refresh commands

| What | Command | When to run |
|------|---------|-------------|
| All repo context packs | `bin\repo-mix-all.ps1` | Weekly or after major changes |
| Architecture map | `bin\workspace-scan.ps1` | After adding/removing repos |
| Full refresh (everything) | `bin\full-context-refresh.ps1` | Monthly or new team member |
| One repo context | `bin\repo-mix.ps1 -RepoPath <path> -Central` | After big changes in that repo |
