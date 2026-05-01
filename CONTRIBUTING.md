# Contributing to `.copilot-shared`

This repo is shared across the Radware R&D team. Contributions from anyone
in the org are welcome — new skills, agent improvements, bug fixes, or
documentation updates.

> **This repo lives on GitHub** (not Bitbucket). PRs and issues happen here.

## Getting started

```cmd
cd %COPILOT_WORKSPACE_ROOT%
git clone https://github.com/rdwr-akashs/.copilot-shared.git .copilot-shared
cd .copilot-shared
git checkout -b feat/my-improvement
```

## How to contribute

### Adding a new skill

1. Create `shared/skills/<skill-name>/SKILL.md`
2. Follow the conventions in `shared/instructions/agent-skills.instructions.md`
3. Key rules:
   - Frontmatter must include `name` (lowercase, hyphens, ≤64 chars) and `description`
   - Description: state **what** it does, **when** to use it, and relevant **keywords**
   - Body: focus on info Copilot wouldn't know from training data
   - Keep under 500 lines (split to `references/` at ~200)
   - Use `<placeholder>` tokens for project-specific values
4. Test it: link a repo, open Copilot Chat, ask it to use the skill

### Adding a new agent template

1. Create `agent-templates/<name>.agent.md`
2. Use `<placeholder>` tokens for project-specific names — see `shared/skills/customize-agents/SKILL.md` for the full token list
3. The agent will be copied (not junctioned) into each repo and customised per-project via the `customize-agents` skill

### Adding a new instruction

1. Create `shared/instructions/<name>.instructions.md`
2. Include YAML frontmatter with `applyTo` glob pattern
3. Keep instructions focused — one concern per file

### Adding a new prompt

1. Create `shared/prompts/<name>.md`
2. Prompts are templates users paste into Copilot Chat to trigger workflows

### Fixing a bin script

The scripts in `bin/` assume `%COPILOT_WORKSPACE_ROOT%\` as the workspace root.
If you're adapting for a different layout, consider making the path
configurable via an environment variable (`COPILOT_WORKSPACE_ROOT`).

## Guidelines

- **Paths**: Use `%COPILOT_WORKSPACE_ROOT%\` in documentation and scripts (our standard workspace root)
- **Product references**: Radware product names (DefenseFlow, Vision, kvision, etc.) are fine — this is an org-specific repo
- **Bitbucket repos**: Use generic repo names as examples (e.g., `<your-repo>`, `<service-name>`) — real internal repo names are gitignored via `shared/memory/`
- **No customer data** — the `cases/` directory is `.gitignore`d for a reason
- **No secrets or credentials** — API tokens, passwords, private keys — ever
- **No OneDrive paths** — use relative paths or `%COPILOT_WORKSPACE_ROOT%\` paths
- **Test your changes** — run `bin\doctor.cmd %COPILOT_WORKSPACE_ROOT%\<any-repo>` after modifications

## Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Skill folder | lowercase, hyphens | `adding-rest-endpoints` |
| Instruction file | `<name>.instructions.md` | `orchestrator.instructions.md` |
| Agent template | `<name>.agent.md` | `developer.agent.md` |
| Prompt file | `<name>.md` | `investigate-customer-case.md` |
| Bin script | `<name>.ps1` (PowerShell) or `<name>.cmd` (simple) | `setup-repo.ps1` |

## Pull request process

1. Create a feature branch: `git checkout -b feat/my-improvement`
2. Make your changes
3. Run `bin\doctor.cmd %COPILOT_WORKSPACE_ROOT%\<repo>` to verify nothing broke
4. Push: `git push -u origin feat/my-improvement`
5. Open a PR on GitHub with a clear description
6. One approval required before merge

## Reporting issues

If you find a bug or have a feature request:
1. Open a GitHub Issue on this repo
2. Include: what you expected, what happened, which repo/skill/agent was involved
3. If it's a skill bug, include the Copilot Chat output

## Questions?

Reach out to the Copilot champions on Teams, or open a GitHub Discussion.
