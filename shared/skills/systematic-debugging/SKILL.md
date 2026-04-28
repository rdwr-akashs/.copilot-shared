---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Activation Rule

**Triggers:**
- Any test failure, build error, runtime exception, or unexpected behavior
- User says "fix", "debug", "why is this failing", or "investigate"
- Maven build fails with compilation or test errors
- Spring Boot startup crashes or returns unexpected responses
- Multiple fix attempts have already failed

> **Override Directive:** This skill overrides default behavior when its conditions are met. NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST — this is non-negotiable.

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue:
- Test failures (`./mvnw test` output)
- Maven build compilation errors
- Runtime Spring Boot startup failures
- Hibernate/JPA mapping issues
- FreeMarker template rendering errors
- Driver contract violations
- Integration test failures (Testcontainers)

**Use this ESPECIALLY when:**
- Under time pressure
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work

## The Four Phases

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past Maven stack traces
   - Read Spring Boot startup exceptions completely
   - Note the originating module (service, driver, feeds)
   - Check if it's a compilation error vs runtime error

2. **Reproduce Consistently**
   ```bash
   ./mvnw test -pl <module> -Dtest=SpecificTest     # Single test
   ./mvnw test -pl <module>                          # Module tests
   ./mvnw clean install                              # Full build
   ```

3. **Check Recent Changes**
   - `git log --oneline -10`
   - `git diff HEAD~3`
   - Did driver-api contracts change? Check all driver modules
   - New dependencies added without `<root-bom>`?

4. **Gather Evidence in Multi-Module Systems**
   ```
   For EACH module boundary:
     - driver-api → drivers: Contract compliance?
     - service → driver-api: Correct interface usage?
     - service → repository: JPA entity mapping correct?
     - controller → service: Correct method signatures?

   Run: ./mvnw clean install -DskipTests
   This reveals which module fails compilation FIRST
   ```

5. **Trace Data Flow**
   - Where does the bad value originate?
   - Trace Controller → Service → Repository → Driver
   - For JSON issues: trace Jackson serialization/deserialization
   - For template issues: trace FreeMarker rendering with input data

### Phase 2: Pattern Analysis

1. **Find Working Examples**
   - Locate similar working code in same module
   - Check other driver versions for the same pattern

2. **Compare Against References**
   - If implementing a pattern, read reference implementation completely
   - Check existing drivers for established patterns

3. **Identify Differences**
   - What's different between working and broken?
   - Different driver version? Different JPA mapping? Different FreeMarker template?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis**
   - "I think X is the root cause because Y"
   - Be specific, not vague

2. **Test Minimally**
   - Make the SMALLEST possible change
   - One variable at a time
   - `./mvnw test -pl <module> -Dtest=SpecificTest#specific_method`

3. **Verify Before Continuing**
   - Did it work? Yes → Phase 4
   - Didn't work? Form NEW hypothesis
   - DON'T add more fixes on top

4. **If 3+ Fixes Failed: Question Architecture**
   - Stop and escalate to Architect agent
   - The design might be wrong, not the code

### Phase 4: Implementation

1. **Create Failing Test Case**
   ```java
   @Test
   void should_reproduceTheBug_when_specificCondition() {
       // Minimal reproduction
   }
   ```

2. **Implement Single Fix** - Address root cause, ONE change at a time

3. **Verify Fix**
   ```bash
   ./mvnw test -pl <module>         # Module passes
   ./mvnw clean install             # Full build passes
   ```

4. **If Fix Doesn't Work** - Return to Phase 1, don't try Fix #4 without re-analysis

---

## Domain-Specific Debugging Playbooks

### Playbook: Silent 404 on New REST Endpoint

**Symptom:** New `@Component` REST resource returns 404 even though the class is correct.

**Root Cause:** The class was not registered in `JerseyConfig.registerEndpoints()`.

**Fix:**
```java
// JerseyConfig.java
private void registerEndpoints() {
    register(TemplateRestService.class);
    register(MyNewRestService.class);  // ← add this line
}
```

---

### Playbook: REST Test Hangs or Returns 503

**Symptom:** `@SpringBootTest(webEnvironment=DEFINED_PORT)` tests fail or return 503 immediately.

**Root Cause:** `HaStandaloneStateEvent` was not published before tests run. The HA filter rejects requests until standalone mode is activated.

**Fix:**
```java
@BeforeAll
void setup() {
    eventPublisher.publishEvent(new HaStandaloneStateEvent(this));
}
```

---

### Playbook: RabbitMQ Listener Failures

**Symptom:** Messages arrive on queue but listener crashes or silently drops messages.

**Debugging steps:**
1. Check `RabbitConfiguration` — verify the correct queue name and Jackson converter
2. Add `spring.rabbitmq.listener.simple.retry.enabled=true` in `application-dev.yaml` for debug
3. The retry config is: 5 attempts, 1s initial, 10s max backoff
4. Check if the payload DTO matches the message format exactly (Jackson field names)
5. Enable `spring.rabbitmq.listener.simple.acknowledge-mode=manual` temporarily to inspect raw messages

---

### Playbook: Spring Context Fails to Start

**Symptom:** `@SpringBootTest` fails with `UnsatisfiedDependencyException` or missing bean.

**Debugging steps:**
1. Check the active Spring profile — `test` profile must be active for tests
2. Verify `application-test.yaml` exists and datasource is configured
3. Check if a new `@Configuration` class is present but its dependencies aren't available in the test slice
4. For `ProfileNotActiveException` — the wrong profile is active; add `@ActiveProfiles("test")` to the test class

---

### Playbook: Hibernate ddl-auto Surprises

**Symptom:** Tables exist but columns are missing, or existing data breaks after startup.

**Root Cause:** `ddl-auto: update` only adds columns, never removes them or changes types.

**Debugging steps:**
1. Check `init.sql` — run it manually to see if it conflicts with `ddl-auto: update`
2. For type changes, drop and recreate the table manually in the dev DB
3. Never rely on `ddl-auto: update` for production schema changes — coordinate table changes manually

---

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Debugger** | Primary user — follows the four phases for all investigations |
| **Developer** | Triggers when implementation causes test failures |
| **DevOps** | Uses for build pipeline and infrastructure failures |
| **Reviewer** | References when evaluating fix correctness |

## Decision Heuristics

- **Always use this skill** for any failure — no exceptions, no "quick fixes"
- **Don't skip Phase 1** even when the fix seems obvious
- **Combine with `dispatching-parallel-agents`** when 3+ independent failures exist
- Example: "NPE in <DomainService>" → use this skill (trace data flow)
- Example: "All 13 driver modules fail to compile" → use this skill (check driver-api contract)
- Example: "3 unrelated test classes failing" → use `dispatching-parallel-agents`, each agent uses this skill

## Quick Start

1. Read error message completely — note module and error type
2. Reproduce consistently: `./mvnw test -pl <module> -Dtest=SpecificTest`
3. Check recent changes: `git log --oneline -10`
4. Trace data flow: Controller → Service → Repository → Driver
5. Form hypothesis → test minimally → verify

## Prompt Template

```
Debug this failure:
[paste error output]
Module: [service/drivers/feeds]
Use the systematic-debugging skill — find root cause before fixing.
```

## Performance Guidelines

- Always start with `./mvnw clean install -DskipTests` to identify which module fails first
- Use `-Dtest=SpecificTest#specific_method` for fastest feedback loop
- Don't run full test suite when investigating a single failure
- Check `git log --oneline -10` before diving into code — recent changes are the likely cause

## Inter-Skill References

- **For parallel failures** → `dispatching-parallel-agents` when 3+ independent issues
- **After fix** → `verification-before-completion` to confirm full build passes
- **For test writing** → `test-driven-development` to create regression test for the bug
- **For npm issues** → `npm-errors` if failure is in UI modules
