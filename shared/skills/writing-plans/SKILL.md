---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Activation Rule

**Triggers:**
- Requirements or spec exists and needs an implementation plan
- User says "plan this", "create a plan", "how should we build this"
- Brainstorming phase is complete and design is validated
- Multi-step feature needs structured task breakdown

> **Override Directive:** This skill overrides default behavior when its conditions are met. Write the plan BEFORE touching any code — plans prevent wasted work and architectural mistakes.

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which modules and files to touch for each task, code, testing, how to verify. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled Java developer, but know almost nothing about this multi-module Maven project or <product-suite> domain.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run `./mvnw test -pl <module>` and make sure they pass" - step
- "Commit" - step

## Plan Document Header

```markdown
# [Feature Name] Implementation Plan

> **For Copilot:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Modules Affected:** [service, driver-api, drivers/<versions>, feeds, util, ui/<versions>]

**Build Order:** [e.g., driver-api → drivers → service]

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Module:** `<module-path>/` (e.g., `service/`, `drivers/10_0_0_0/`)

**Files:**
- Create: `exact/path/to/File.java`
- Modify: `exact/path/to/Existing.java:123-145`
- Test: `exact/path/to/FileTest.java`

**Step 1: Write the failing test**

```java
@Test
void should_specificBehavior_when_condition() {
    // Arrange
    var input = SomeInput.builder().field("value").build();

    // Act
    var result = service.doSomething(input);

    // Assert
    assertThat(result).isEqualTo(expected);
}
```

**Step 2: Run test to verify it fails**

Run: `./mvnw test -pl service -Dtest="SomeServiceTest#should_specificBehavior_when_condition"`
Expected: FAIL with "cannot find symbol" or assertion failure

**Step 3: Write minimal implementation**

```java
public Result doSomething(SomeInput input) {
    return expected;
}
```

**Step 4: Run test to verify it passes**

Run: `./mvnw test -pl service -Dtest="SomeServiceTest#should_specificBehavior_when_condition"`
Expected: PASS

**Step 5: Commit**

```bash
git add service/src/
git commit -m "CYCON-XXXXX: Add specific feature"
```
```

## Module Dependency Order

When plan touches multiple modules, order tasks by Maven build dependency:

```
1. <root-bom> (if dependency changes)
2. driver-api (if contract changes)
3. drivers/<version> (all affected versions, can be parallel)
4. util (if shared utility changes)
5. service (backend logic)
6. feeds (if feed changes)
7. ui/<version> (frontend changes)
```

## Remember
- Exact file paths always (with module prefix)
- Complete code in plan (not "add validation")
- Exact Maven commands with expected output
- Module-aware task ordering
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Architect (PEplan)** | Primary user — creates comprehensive implementation plans |
| **Developer** | References plans during execution |
| **SquadLeader** | Uses plans to orchestrate agent execution |
| **Reviewer** | Reviews plan completeness before execution starts |

## Decision Heuristics

- **Always write a plan** for features touching 2+ modules or requiring 5+ code changes
- **Skip plans** for single-file fixes, config changes, or obvious one-step tasks
- **Combine with `brainstorming`** — brainstorm first, then formalize into plan
- Example: "Add new driver method across all versions" → plan (13 modules affected)
- Example: "Fix NPE on line 42" → skip, use `systematic-debugging` directly
- Example: "Redesign feeds API with new endpoints" → plan (multi-module, multi-step)

## Quick Start

1. Read requirements/spec/brainstorming output
2. Identify affected modules and build order
3. Break into bite-sized tasks (2-5 min each) with TDD steps
4. Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`
5. Offer execution choice: subagent-driven or parallel session

## Prompt Template

```
Create an implementation plan for: [feature description]
Requirements: [spec/design doc reference]
Use the writing-plans skill to produce a detailed, executable plan.
```

## Performance Guidelines

- Each task should be 2-5 minutes of work — break larger tasks into subtasks
- Include exact file paths (with module prefix) — don't make the implementer search
- Include complete code snippets — "add validation" is too vague
- Include exact Maven commands with expected output for each verification step

## Inter-Skill References

- **Before planning** → `brainstorming` to validate design and approach
- **For execution** → `executing-plans` or `subagent-driven-development`
- **For workspace** → `using-git-worktrees` to isolate feature work
- **TDD integration** → `test-driven-development` — plans include Red-Green-Refactor steps
