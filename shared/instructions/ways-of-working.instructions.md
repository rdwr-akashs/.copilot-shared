---
description: 'Mandatory ways of working for spec implementation: TDD, very small steps, stop-and-confirm, structured per-step output. Activates whenever the user asks to implement a spec/feature/bugfix.'
applyTo: '**/requirements.md,**/design.md,**/tasks.md,**/*.spec.ts,**/*.spec.tsx,**/*.spec.js,**/*.spec.jsx,**/*Test.java'
---

# Ways of Working — Spec Implementation Protocol

> **This is an OVERRIDE directive.** When the user asks you to implement a spec, feature, or bug fix, these rules supersede default behaviour. Do **not** generate a full solution in one go.

## 1. Mandatory TDD (Red → Green → Refactor)

For every behavioural change:

1. **RED** — Write ONE failing test that pins the next behaviour.
2. **VERIFY RED** — Run the test, confirm it fails for the right reason. Paste the failure output.
3. **GREEN** — Write the minimal implementation to make it pass. Nothing more.
4. **VERIFY GREEN** — Run the test, confirm it passes. Re-run the affected module's tests.
5. **REFACTOR** — Only after green. Keep tests green. No new behaviour.

**Iron law:** No production code without a failing test first. If you wrote code before the test, delete it and start over.

For the full TDD workflow, naming, and Maven commands, see the [test-driven-development skill](../skills/test-driven-development/SKILL.md).

**Skip TDD only for trivial changes:** typos, comments, log strings, config values, Lombok annotations, imports.

## 2. Very Small Steps

- One logical change per step. One test, one minimal implementation, one optional refactor.
- Never bundle multiple behaviours into a single step.
- Never edit files outside the current step's scope.
- If a step starts feeling large, split it.

## 3. Stop-and-Confirm Gate

After **every** step:

1. **STOP.** Do not start the next step.
2. Output the step in the format below.
3. Wait for the user to reply with `proceed`, `next`, `approved`, or feedback.
4. Only after explicit approval, move on.

If something is unclear or under-specified — **ask, do not assume**. List specific questions; do not invent requirements.

## 4. Required Per-Step Output Format

Every step must use this exact structure:

```
### Step <n> — <one-line description>

**Goal:** <what behaviour this step adds>

**Test (RED):**
```<lang>
<failing test code>
```

**Run:** <command used to run the test>
**Result:** <pasted failure output, abbreviated to the relevant lines>

---
⏸  STOP — awaiting approval to write implementation.
```

After the user approves the test, continue:

```
**Implementation (GREEN):**
```<lang>
<minimal code>
```

**Run:** <command>
**Result:** <pass output>

**Refactor (optional):** <description, or "none">

**Suggested commit:**
```
<type>(<scope>): <imperative summary>

<one-line rationale>
```

**Files changed:** <list>
**Next step:** <one-line preview, or "awaiting next requirement">

---
⏸  STOP — confirm before next step.
```

Commit type follows Conventional Commits: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.

## 5. Code Quality Rules

- Prefer simple, readable code over clever code.
- Follow the project's existing conventions (naming, layering, error handling). When in doubt, read a neighbouring file before writing.
- Maintain separation of concerns — no business logic in controllers, no I/O in domain code.
- No speculative generality (no "configurable" parameters, no extension points) unless the current test demands them. YAGNI.
- No dead code, no commented-out code, no `TODO` without an owner.

## 6. Don'ts

- ❌ Do not generate a full multi-file solution in one response.
- ❌ Do not write production code before its failing test.
- ❌ Do not skip the verify-red or verify-green run.
- ❌ Do not refactor and add behaviour in the same step.
- ❌ Do not assume missing requirements — ask.
- ❌ Do not auto-commit or push. Only **suggest** the commit message; the user runs `git`.

## 7. When These Rules Apply

- Activate automatically when the user provides a spec, feature description, or bug to fix.
- Activate when the user pastes a `<spec>...</spec>` block.
- Activate when the user explicitly says "follow ways of working", "use TDD", or "implement step by step".

## 8. When These Rules Do NOT Apply

- Pure questions ("how does X work?", "explain Y").
- Read-only investigations and code reviews.
- Trivial single-line edits as listed in §1.
- Emergency hotfixes when the user explicitly says "skip TDD, just fix it".

In these cases, fall back to default behaviour.
