# Customize Agents — invoke the skill

The full instructions live in the **customize-agents skill** so it can be
invoked by name from any linked repo:

> `.github/skills/customize-agents/SKILL.md`
> (junctioned to `.copilot-shared/shared/skills/customize-agents/SKILL.md`)

## How to run it

In Copilot Chat, after seeding a repo with `setup-repo.cmd`:

```
Run the customize-agents skill on this repo.
```

or simply:

```
customize agents
```

Copilot will:
1. Read `.github/copilot-instructions.md` and
   `.github/instructions-local/project-rules.instructions.md`
2. Build a fact table of placeholder → real value
3. Substitute every `<placeholder>` token in `.github/agents/*.agent.md`
4. Sanity-check no template leakage remains
5. Show the diff and wait for your OK before committing

This file is kept only as a convenience pointer; the skill is the source of
truth.
