---
name: customize-agents
description: Use when seeding a new repo with the shared Copilot setup — rewrites placeholder tokens in `.github/agents/*.agent.md` (and `instructions-local/*`) with this repo's actual project facts, then verifies no template leakage remains
---

# Customize Agents for This Repo

## Activation Rule

**Triggers:**
- User says "customize agents", "customise agents", "tailor the agents",
  "adapt agents to this repo", "run customize-agents"
- A repo was just seeded by `setup-repo.cmd` or `copy-agents.cmd` and the
  agents still contain placeholder tokens like `<DomainEntity>`,
  `<ProjectException>`, `<calling-service>`
- A grep for `<[A-Z][A-Za-z-]+>` inside `.github/agents/` returns hits

> **Override Directive:** Do not skip Step 1. If `copilot-instructions.md` or
> `instructions-local/project-rules.instructions.md` is missing or empty,
> STOP and tell the user to fill them in first. Never invent project facts.

## Overview

The agents and some skills shipped from `.copilot-shared` use generic
placeholders (`<DomainEntity>`, `<ProjectException>`, `<root-bom>`,
`<frontend-app-dir>`, `<calling-service>`, `<orchestrator-service>`,
`<reporter-service>`, `<sibling-repo>`, `<orchestrator-repo>`,
`<core-lib-repo>`, `<product-suite>`, `<reverse-proxy-prefix>`, `<api-path>`,
`<rest-base>`, etc.) instead of names from any one project.

This skill mechanically substitutes those placeholders with values pulled from
**this** repo's `copilot-instructions.md` and
`instructions-local/project-rules.instructions.md`, then sanity-checks the
result.

**Announce at start:** "I'm using the customize-agents skill to tailor the
copied templates for this repo."

---

## Step 1 — Build the fact table

Read both files end-to-end:

1. `.github/copilot-instructions.md`
2. `.github/instructions-local/project-rules.instructions.md`

Extract the table below. Show the table to the user **before** editing any
agent file. If a row cannot be filled from those two files, mark it `?` and
ask the user.

| Placeholder | This repo's value |
|---|---|
| `<this-repo>` | repo folder name |
| `<product-suite>` | product / suite name (or remove) |
| `<DomainEntity>` | representative business entity class |
| `<DomainService>` | typical service class name |
| `<DomainRepository>` | typical repository class name |
| `<DomainController>` | typical REST controller class name |
| `<ProjectException>` | standard exception type the project throws |
| `<LowLevelException>` | lower-level exception, if any (else delete refs) |
| `<root-bom>` | parent / BOM module name (or delete refs) |
| `<frontend-app-dir>` / `<frontend-app>` | frontend folder, e.g. `ui/web/` |
| `<calling-service>` | upstream service that calls this one (or delete) |
| `<orchestrator-service>` / `<orchestrator-repo>` | orchestrator (if any) |
| `<reporter-service>` | reporting/observer service (if any) |
| `<sibling-repo>` | a relevant sibling repo (or delete) |
| `<core-lib-repo>` | shared core library repo (or delete) |
| `<driver-api-repo>` / `<DriverInterface>` | driver SPI (if any) |
| `<managed-device>` | device/target the project manages (if any) |
| `<reverse-proxy-prefix>` | nginx / gateway prefix, e.g. `/api/v1` |
| `<api-path>` | this project's API path segment |
| `<rest-base>` | REST base path, e.g. `/rest/v2` |
| `<api-keyword>` / `<api-keyword-1>` / `<api-keyword-2>` | grep keywords |
| `<entity-keyword-1>` / `<entityKeyword2>` | grep keywords for the domain |
| `<TICKET-ID>` / `<ticket-id>` | issue tracker prefix (e.g. `JIRA-`, leave generic if mixed) |
| Build command | e.g. `./mvnw -pl <module> install` |
| Test command | e.g. `./mvnw test -pl <module>` |
| Run/dev command | e.g. `npm start` from `<frontend-app-dir>` |

If a placeholder doesn't apply to this repo (no orchestrator service, no
driver SPI, etc.), the value is `(delete the reference)`.

---

## Step 2 — Process each agent in `.github/agents/`

Files to handle (skip those that don't exist):

1. `developer.agent.md`
2. `tester.agent.md`
3. `debugger.agent.md`
4. `reviewer.agent.md`
5. `devops.agent.md`
6. `PEplan.agent.md`
7. `squadleader.agent.md`
8. `principal-engineer.agent.md`
9. `expert-react-frontend-engineer.agent.md`
   — **delete the file** if this repo has no React frontend
10. `gem-code-simplifier.agent.md`

For each file, in one pass:

- Substitute every placeholder with its fact-table value. Use `replace_string_in_file` (one occurrence at a time) or read-edit-write the whole file when there are many.
- Where the value is `(delete the reference)`, remove the surrounding sentence/list-item cleanly. Do not leave empty headings, dangling bullets, or trailing commas.
- Update build/test/run commands inline with the table.
- Update each agent's "Triggered by" / "Routing" line if this repo's vocabulary differs from the placeholder examples.
- **Do not** change frontmatter `name:`, `description:` style — only values.
- **Do not** edit anything in `.github/skills/`, `.github/instructions/`, `.github/prompts/`, `.github/plans/` (those are junctions to the shared store; edits would leak into other repos).

---

## Step 3 — Customise `instructions-local/` (light pass)

If the user already filled in `instructions-local/project-rules.instructions.md`,
leave it alone. Otherwise:

- Open `instructions-local/project-rules.instructions.md`
- Replace any remaining `<placeholder>` tokens with fact-table values
- Add a short "Repo glossary" section at the bottom listing the substitutions
  you made, so future contributors can see the mapping

Do NOT add new instruction files unless the user asks.

---

## Step 4 — Sanity check (REQUIRED)

After rewriting, run **both** scans:

```bash
# (a) any unresolved placeholders left in agents?
grep -rnE "<[A-Z][A-Za-z-]+>|<[a-z][a-z-]+>" .github/agents/

# (b) any leftover terms from the original template (edit this pattern for your org's products)
grep -rniE "policytemplate|policy-bom|<product-suite>|<orchestrator-repo>|<sibling-repo>" .github/agents/
```

Both must return zero matches before proceeding. If matches remain:

- Placeholder still present → fact table was incomplete; go back to Step 1
- Old term still present → upstream template wasn't fully genericised; replace
  manually and tell the user to flag it for the central repo maintainer

Show the user the diff (`git diff .github/agents/`) before committing.

---

## Step 5 — Commit

After the user confirms the diff:

```bash
git add .github/agents/ .github/instructions-local/
git commit -m "Customise copied agent templates and instructions-local for this repo"
```

---

## Notes for the AI doing the rewrite

- This is mechanical substitution + light contextual cleanup. **Don't
  redesign** the agents.
- If a section is irrelevant to this repo (e.g. a "Frontend" subsection in a
  backend-only repo), delete it cleanly — don't leave empty headings.
- If a code example showed a pattern (e.g. constructor injection), keep the
  pattern but rename the class to something plausible for this repo.
- Stay terse. Verbose agents distract Copilot at runtime.
- Never edit content under junctioned paths (`skills/`, `instructions/`,
  `prompts/`, `plans/`). Those changes propagate to every linked repo.
