# Onboard Me to This Repo

One-shot onboarding for new developers. Runs three skills in sequence so you don't have to remember the steps.

---

## Send this to Copilot Chat

```
@developer

## Onboard me to this repository

### What to do (in order):

1. **Run the acquire-codebase-knowledge skill** to generate `.github/repo-cache.md`
   and the `docs/codebase/` documentation suite (ARCHITECTURE, CONVENTIONS, etc.)

2. **Read the generated repo-cache.md** and produce a 5-minute summary:
   - What does this service do? Who calls it? What does it depend on?
   - Key modules and their responsibilities (1 line each)
   - Tech stack: language, framework, build tool, database, messaging
   - Build command, test command, how to run locally
   - The 3 most important files a new developer should read first
   - Any gotchas or non-obvious patterns

3. **Fill in the project overview** in `.github/copilot-instructions.md`
   based on what you discovered.

4. **Verify** that `.github/instructions-local/cli-commands.instructions.md`
   has the correct build/test/run commands for this repo.

### Output

A structured markdown summary I can read in 5 minutes to understand this codebase.
After that, restart the IDE so Copilot picks up the new repo-cache.
```

---

## What it triggers

| Step | Skill | Output |
|------|-------|--------|
| 1 | `acquire-codebase-knowledge` | `docs/codebase/*.md` + `.github/repo-cache.md` |
| 2 | (agent summary) | 5-minute overview in chat |
| 3 | (agent edit) | `copilot-instructions.md` project overview filled in |
| 4 | (agent verify) | `cli-commands.instructions.md` validated |
