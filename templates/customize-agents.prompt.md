# Customise Agents for This Repo

Paste this entire prompt into JetBrains Copilot Chat **after** running
`copy-agents.cmd` or `setup-repo.cmd` for a new repo.

The agents in `.github/agents/` were copied from generic templates that contain
Policy-Editor-specific examples (PolicyTemplateException, policy-bom, ui/policy-app-*).
This prompt rewrites them for the current repo using THIS repo's
`copilot-instructions.md` and `instructions-local/project-rules.instructions.md`.

---

You are customising the agent files in `.github/agents/` for the current
repository. Follow this procedure exactly.

## Step 1 — Read the source of truth

Read these two files end-to-end and extract the repo's facts:
1. `.github/copilot-instructions.md`
2. `.github/instructions-local/project-rules.instructions.md`

Build a fact table covering at least:

| Field | Value from the two files |
|---|---|
| Project name |  |
| One-line purpose |  |
| Tech stack (language, framework, build, test) |  |
| Standard exception type |  |
| Module/folder layout |  |
| Build command |  |
| Test command |  |
| Run/dev command |  |
| Naming conventions |  |
| Hard "don'ts" |  |

If any field cannot be answered from those two files, STOP and ask the user.
Do not invent values.

## Step 2 — For each `.agent.md` file in `.github/agents/`

Process the files in this order (skip any that don't exist):

1. `developer.agent.md`
2. `tester.agent.md`
3. `debugger.agent.md`
4. `reviewer.agent.md`
5. `devops.agent.md`
6. `PEplan.agent.md`
7. `squadleader.agent.md`
8. `principal-engineer.agent.md`
9. `expert-react-frontend-engineer.agent.md` — **delete if this repo has no React frontend**
10. `gem-code-simplifier.agent.md`

For each agent file:

- Replace project-specific terms with the values from the fact table:
  - `PolicyTemplateException` → standard exception type (or remove if generic)
  - `PolicyTemplate`, `PolicyTemplateService`, `PolicyTemplateRepository` →
    representative class names from THIS repo (or generic placeholders)
  - `policy-bom` → this repo's BOM/parent module name (or remove the rule)
  - `ui/policy-app-<version>` → this repo's frontend folder structure (or remove)
  - `common_policy_editor` → this repo's name (or "the current repo")
  - `DefenseFlow`, `DefensePro`, `Policy Editor` → this repo's product name
- Update build/test/run commands to match this repo
- Update the agent's "Triggered by" routing if the repo's domain differs
- Preserve the agent's structure (frontmatter, sections, examples)
- Do NOT change the generic skills they invoke (those work cross-repo)

## Step 3 — Sanity check

After rewriting, run:

```
grep -rn "PolicyTemplate\|policy-bom\|policy-app\|common_policy_editor\|DefenseFlow\|DefensePro" .github/agents/
```

Any remaining hits = leakage. Either remove them or replace with this repo's
equivalent. Show the user the diff before committing.

## Step 4 — Commit

After the user confirms the rewrites look correct:

```bash
git add .github/agents/
git commit -m "Customise copied agent templates for this repo"
```

---

## Notes for the AI doing the rewrite

- This is a mechanical substitution + light contextual rewrite. Don't redesign
  the agents.
- If a section is irrelevant to this repo (e.g. React section in a backend-only
  repo), delete it cleanly — don't leave empty headers.
- If a code example showed a pattern (e.g. constructor injection), keep the
  pattern but use a class name plausible for this repo.
- Stay terse. Verbose agents distract Copilot at runtime.
