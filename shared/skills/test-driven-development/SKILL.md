---
name: test-driven-development
description: "TDD overview and language router. Use when you need to write tests first before implementation. Routes to tdd-java for Java/Maven projects or tdd-react for React/TypeScript projects. Covers the Red-Green-Refactor cycle, test naming, and when to stop writing tests."
---

# Test-Driven Development

## Activation Rule

**Triggers:**
- "Write the test first", "TDD", "red-green-refactor"
- Before implementing any new class or function
- Plan step says "add test for X"
- `systematic-debugging` recommends a regression test

> **Override Directive:** Always write a failing test before any production code. No exceptions. See `tdd.instructions.md` for the org-wide mandate.

---

## Language Router

Pick the sub-skill for your language:

| Language / Stack | Use |
|---|---|
| Java, Spring Boot, Maven | [`tdd-java`](../tdd-java/SKILL.md) |
| React, TypeScript, Vitest/Jest | [`tdd-react`](../tdd-react/SKILL.md) |

---

## The Universal Cycle

Regardless of language:

```
RED   → Write the smallest test that fails for the right reason.
        Run: confirm it fails (not compilation error — a logic failure).

GREEN → Write the minimum production code to make the test pass.
        No extra logic. No anticipating future cases.

REFACTOR → Clean up without breaking the test.
           Extract, rename, simplify. Keep the bar green.
```

**Stop writing tests when:**
- Every acceptance criterion from the plan has a test
- All error paths that can actually happen are covered
- The next test you'd write is testing the framework, not your code

---

## Test Naming Convention

```
// Pattern: <methodName>_<condition>_<expectedOutcome>
createItem_withDuplicateName_throwsDuplicateItemException
getById_withUnknownId_returnsEmpty
processItem_whenQueueFull_retrysAfterDelay
```

This makes failure messages self-explanatory.

---

## What NOT to Test

- Framework behaviour (Spring wiring, ORM mappings) — assume they work
- Private methods directly — test them through the public interface
- Configuration classes — test the behaviour they configure
- Getter/setter-only DTOs — no logic, no test needed

---

## Commit Pattern

```
1. Red commit:   "test: <test name> (failing)"
2. Green commit: "feat/fix: <what you implemented>"
3. Refactor:     "refactor: <what you cleaned up>" (if non-trivial)
```

---

## Inter-Skill References

- **Java TDD** → `tdd-java` for Spring Boot, JUnit 5, Mockito, TestRestTemplate
- **React TDD** → `tdd-react` for Vitest, React Testing Library, MSW
- **After tests pass** → `verification-before-completion`
- **Regression tests** → `systematic-debugging` recommends which test to add
