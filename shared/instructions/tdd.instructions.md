---
description: "TDD-first mandate. Applies to every agent and every developer. No production code without a failing test first."
applyTo: "**/*.java,**/*.kt,**/*.js,**/*.jsx,**/*.ts,**/*.tsx"
---

# TDD Mandate

## The Rule

> **No production code is written before a failing test exists.**

This applies to:
- New features (Java service methods, React components, REST endpoints)
- Bug fixes (reproduce the bug with a test before fixing it)
- Refactoring (confirm existing tests pass, refactor, confirm still pass)

It does NOT apply to:
- Config files, YAML, SQL migrations, Docker/Swarm config
- One-off scripts that aren't part of the application
- Trivial getters/setters that have no logic

---

## The Cycle (Non-Negotiable)

```
RED   → Write the test. Run it. It MUST fail for the right reason.
GREEN → Write the minimum code to make it pass. Nothing more.
REFACTOR → Clean up code and tests. All tests still pass.
```

If you write production code and then add a test that passes immediately, you did it backwards. The test didn't verify your code works — it just verified the code already exists.

---

## Java TDD — Quick Reference

**Test layers:**

| What you're testing | Use |
|---|---|
| Service / domain logic | JUnit 5 + Mockito |
| REST controller | MockMvc (`@WebMvcTest`) |
| Repository / database | TestContainers + `@DataJpaTest` |
| Full stack flow | `@SpringBootTest` (sparingly) |

**Test method naming:** `methodName_expectedBehaviour_whenCondition`

```java
@Test
void createItem_throwsDuplicateException_whenNameAlreadyExists() { ... }

@Test
void findById_returnsEmpty_whenIdNotFound() { ... }
```

**Invoke the tdd-java skill** for the full step-by-step pattern.

---

## React TDD — Quick Reference

**Test layers:**

| What you're testing | Use |
|---|---|
| Component rendering + interaction | React Testing Library (RTL) |
| Custom hooks | `renderHook` from RTL |
| API mocking | MSW (Mock Service Worker) |
| Async data loading | `waitFor`, `findBy*` queries |

**Rules:**
- Query by role/label, not CSS class or test ID
- Test all states: loading, success, empty, error
- `userEvent` over `fireEvent`
- No snapshot tests for business logic

**Invoke the tdd-react skill** for the full step-by-step pattern.

---

## What Agents MUST Do

Every agent (`developer`, `full-stack-feature`, `debugger`, etc.) must:

1. **Before writing any production code:** write the test file first
2. **Run the test and confirm it fails** (show the failure output)
3. **Write the minimum implementation** to make it green
4. **Show the passing test output** before moving to the next unit of work

When asked to implement a feature without a test, the agent must:
- Write the test first
- Then implement
- Not ask for permission to follow TDD

---

## Bug Fix Protocol

1. Reproduce the bug with a failing test that captures the exact symptom
2. Confirm the test fails on the current code
3. Fix the code
4. Confirm the test passes
5. Confirm no other tests broke

---

## Coverage Targets

| Layer | Target |
|---|---|
| Domain / Service | 85% branch coverage |
| Controller | 80% line coverage |
| Repository | Integration tested only |
| Config / DTOs | No target (no logic) |

Use the `java-test-coverage` skill to find and close coverage gaps.
