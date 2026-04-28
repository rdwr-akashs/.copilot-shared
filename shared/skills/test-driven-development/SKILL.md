---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Activation Rule

**Triggers:**
- Implementing any new feature, service method, or endpoint
- Fixing a bug (write failing test first to reproduce)
- User says "implement", "add feature", "fix bug" — write test before code
- Plan step says "Write the failing test"

> **Override Directive:** This skill overrides default behavior when its conditions are met. NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

## Red-Green-Refactor

### RED - Write Failing Test

Write one minimal test showing what should happen.

<Good>
```java
@Test
void should_retryFailedOperations_when_transientError() {
    // Arrange
    AtomicInteger attempts = new AtomicInteger(0);
    Supplier<String> operation = () -> {
        if (attempts.incrementAndGet() < 3) throw new TransientException("retry");
        return "success";
    };

    // Act
    String result = retryService.execute(operation);

    // Assert
    assertThat(result).isEqualTo("success");
    assertThat(attempts.get()).isEqualTo(3);
}
```
Clear name, tests real behavior, one thing
</Good>

<Bad>
```java
@Test
void testRetry() {
    var mock = mock(Supplier.class);
    when(mock.get()).thenThrow(new RuntimeException()).thenReturn("ok");
    retryService.execute(mock);
    verify(mock, times(2)).get();
}
```
Vague name, tests mock not code
</Bad>

**Requirements:**
- One behavior
- Clear `should_X_when_Y()` name
- Real code (no mocks unless unavoidable)

### Verify RED - Watch It Fail

**MANDATORY. Never skip.**

```bash
./mvnw test -pl <module> -Dtest="ClassTest#should_specificBehavior_when_condition"
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

### GREEN - Minimal Code

Write simplest code to pass the test.

<Good>
```java
public <T> T execute(Supplier<T> operation) {
    for (int i = 0; i < 3; i++) {
        try {
            return operation.get();
        } catch (TransientException e) {
            if (i == 2) throw e;
        }
    }
    throw new IllegalStateException("unreachable");
}
```
Just enough to pass
</Good>

<Bad>
```java
public <T> T execute(Supplier<T> operation, RetryConfig config) {
    // configurable max retries, exponential backoff, circuit breaker...
    // YAGNI
}
```
Over-engineered
</Bad>

### Verify GREEN - Watch It Pass

**MANDATORY.**

```bash
./mvnw test -pl <module> -Dtest="ClassTest#should_specificBehavior_when_condition"
```

Confirm:
- Test passes
- Other tests still pass: `./mvnw test -pl <module>`
- Full build still works: `./mvnw clean install -DskipTests`

### REFACTOR - Clean Up

After green only:
- Remove duplication
- Improve names
- Extract helpers
- Apply Lombok where appropriate

Keep tests green. Don't add behavior.

### Repeat

Next failing test for next behavior.

## Test Quality

| Quality | Good | Bad |
|---------|------|-----|
| Name | `should_returnTemplate_when_idExists` | `testGetTemplate` |
| Scope | One behavior | Multiple behaviors |
| Dependencies | Real objects, mocked boundaries | Everything mocked |
| Assertions | AssertJ fluent | Multiple unrelated asserts |
| Framework | `@ExtendWith(MockitoExtension.class)` | `@SpringBootTest` for unit tests |

## Maven Commands

```bash
# Single test method
./mvnw test -pl service -Dtest="PolicyTemplateServiceTest#should_returnTemplate_when_idExists"

# Single test class
./mvnw test -pl service -Dtest=PolicyTemplateServiceTest

# Module tests
./mvnw test -pl service

# Full build
./mvnw clean install

# With coverage
./mvnw test -pl service -P jacoco
```

## Performance Guidelines

- Test ONE behavior per test method — don't combine multiple assertions for different behaviors
- Use `./mvnw test -pl <module> -Dtest="Class#method"` for fastest feedback (seconds, not minutes)
- Write the simplest possible code to pass — resist over-engineering during GREEN phase

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Tester** | Primary user — writes tests following TDD cycle |
| **Developer** | Follows Red-Green-Refactor for all implementations |
| **Debugger** | Creates failing test to reproduce bug before fixing |
| **Reviewer** | Validates test quality (naming, scope, assertions) |

## Decision Heuristics

- **Always use TDD** for new service methods, repository queries, and business logic
- **Skip TDD** for trivial changes (config files, Lombok annotations, imports)
- **Combine with `writing-plans`** — plans include TDD steps by default
- Example: "Add findByName to PolicyTemplateService" → TDD (write test first)
- Example: "Add @Builder to DTO" → skip TDD (trivial Lombok annotation)
- Example: "Fix NPE in driver" → TDD (write failing test reproducing the NPE)

## Quick Start

1. Write ONE failing test: `should_X_when_Y()`
2. Run: `./mvnw test -pl <module> -Dtest="Test#method"` — confirm FAIL
3. Write minimal code to pass
4. Run again — confirm PASS
5. Refactor → repeat for next behavior

## Prompt Template

```
Implement [feature] using TDD.
Module: [service/drivers/feeds]
Use the test-driven-development skill — write failing test first.
```

## Inter-Skill References

- **For plan creation** → `writing-plans` includes TDD steps by default
- **For debugging** → `systematic-debugging` when tests reveal unexpected behavior
- **After implementation** → `requesting-code-review` validates test quality
- **Verification** → `verification-before-completion` before claiming done
