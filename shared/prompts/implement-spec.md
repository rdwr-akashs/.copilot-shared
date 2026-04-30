# Implement-a-Spec Prompt Template

Copy this block, paste your spec inside the `<spec>` tags, and send.
The agent will follow the rules in
[`ways-of-working.instructions.md`](../instructions/ways-of-working.instructions.md)
and the [`test-driven-development`](../skills/test-driven-development/SKILL.md) skill.

---

## Default — Strict TDD, one step at a time

```
Implement the spec below following the WAYS OF WORKING in
shared/instructions/ways-of-working.instructions.md.

Mandatory:
- Strict TDD: failing test → minimal code → refactor
- Very small steps — one logical change per step
- After EACH step: stop, show the per-step output block, suggest a
  commit message, and wait for my approval before continuing
- Do NOT generate the full solution in one go
- Ask if anything in the spec is unclear — do not assume

Start with Step 1 (the first failing test only). Stop and wait.

<spec>
PASTE YOUR SPEC HERE
</spec>
```

---

## Variant — Design first, then implement

Use when the spec is non-trivial (multi-file, new API, cross-module).

```
Before implementing, produce:
1. A short Design Doc (problem, scope, approach, API, files to change, risks)
2. A QA Test Plan (functional, edge, negative, integration, regression)

Then STOP and wait for my approval.

After I approve, implement following
shared/instructions/ways-of-working.instructions.md
(strict TDD, very small steps, stop after each step).

<spec>
PASTE YOUR SPEC HERE
</spec>
```

---

## Variant — Bug fix

```
Fix the bug below following shared/instructions/ways-of-working.instructions.md.

Order:
1. Root cause analysis (exact file:method, why it fails)
2. ONE failing test that reproduces the bug — stop and show me
3. After approval, the minimal fix
4. After approval, regression tests for adjacent edge cases

Very small steps. Stop and confirm after each.

<bug>
PASTE BUG REPORT, ERROR, OR REPRO STEPS HERE
</bug>
```

---

## Quick re-engage phrases

If the agent drifts (skips a test, bundles steps, generates too much):

- `stop — go back to step <n> and follow ways-of-working`
- `that's too big — split into smaller steps`
- `where is the failing test? RED first.`
- `don't refactor and add behaviour in the same step`
