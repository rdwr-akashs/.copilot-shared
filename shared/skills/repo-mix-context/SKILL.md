---
name: repo-mix-context
description: Generate centralized Repomix-style context packs for one or all repos — stored in .copilot-shared as the single source of truth
---

# Repo Mix Context

## When to use

Use this skill when you need codebase context for:
- AI prompt context (single or multi-repo features)
- Investigation handoff across repos
- Quick architecture review of sibling repos
- Cross-repo onboarding

## Architecture: Central Store

All context packs live in ONE place accessible from every linked repo:

```
.copilot-shared/shared/memory/repo-contexts/
├── _index.md              # auto-generated index of all scanned repos
├── README.md              # documentation
├── df_core.md             # context pack for df_core
├── war-room.md            # context pack for war-room
├── kvision_collector.md   # context pack for kvision_collector
└── ...                    # one file per repo
```

Any agent in any linked repo can read sibling context at:
```
$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\shared\memory\repo-contexts\<repo-name>.md
```

## Commands

### Scan ALL repos (recommended — run periodically)

```powershell
# Scan every git repo in workspace, store centrally
$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\bin\repo-mix-all.cmd
```

Options:
```powershell
# Scan specific repos only
bin\repo-mix-all.ps1 -Include df_core,war-room,bgp

# Exclude large repos
bin\repo-mix-all.ps1 -Exclude huge_repo,archive

# Custom limits
bin\repo-mix-all.ps1 -MaxFiles 200 -MaxFileSizeKB 128
```

### Scan ONE repo (store centrally)

```powershell
$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\bin\repo-mix.cmd -RepoPath <path> -Central
```

### Scan ONE repo (store locally in that repo)

```powershell
$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\bin\repo-mix.cmd -RepoPath <path>
```

## How agents access cross-repo context

From any linked repo, an agent can read another repo's context:

```powershell
# Read sibling repo context
cat $env:COPILOT_WORKSPACE_ROOT\.copilot-shared\shared\memory\repo-contexts\df_core.md

# Check what repos are indexed
cat $env:COPILOT_WORKSPACE_ROOT\.copilot-shared\shared\memory\repo-contexts\_index.md
```

## Notes

- Uses git tracked files by default (ignores .gitignore'd files).
- Skips binary files and oversized files.
- Central store overwrites per repo on each run (always fresh).
- `-Central` flag stores in `.copilot-shared/shared/memory/repo-contexts/`.
- Without `-Central`, stores in `<repo>/.agent_work/` (per-repo, timestamped).
- Run `repo-mix-all` after major codebase changes or weekly.
