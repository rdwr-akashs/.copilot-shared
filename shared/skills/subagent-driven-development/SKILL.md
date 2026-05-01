---
name: subagent-driven-development
description: Use when implementing a multi-task plan by spinning up one Copilot subagent per task and running them concurrently. Covers task decomposition, subagent prompt design, result integration, and conflict prevention. Use instead of sequential execution when tasks are independent and context is bounded per task.
---

# Subagent-Driven Development

## Activation Rule

**Triggers:**
- A plan has 3+ independent tasks that do not share mutable state
- User says "implement this in parallel", "use subagents", "work on these simultaneously"
- `writing-plans` or `dispatching-parallel-agents` recommends this skill
- Sequential execution would be too slow for the scope

> **Override Directive:** Only parallelise tasks that are truly independent. Tasks that write to the same file or share in-memory state must remain sequential. Use `executing-plans` instead when tasks have dependencies.

---

## When to Use vs. Alternatives

| Scenario | Use |
|----------|-----|
| 3+ independent tasks, separate files | **subagent-driven-development** (this skill) |
| Tasks with ordering dependencies | `executing-plans` (sequential) |
| Many tasks, coordination needed | `dispatching-parallel-agents` (orchestration layer) |
| Single complex task | No parallelism — focus the main agent |

---

## Step 1: Verify Independence

Before launching any subagent, confirm each task:

```
[ ] Operates on different source files
[ ] Does NOT write to a shared mutable data structure
[ ] Has no ordering dependency on another parallel task
[ ] Can be tested in isolation
[ ] Its context (files to read) is bounded — < ~20 files per task
```

If any check fails, move that task to a sequential slot.

---

## Step 2: Decompose the Plan Into Subagent Prompts

Each subagent gets its own focused prompt. A good subagent prompt has:

```
1. Role: "You are implementing task N of M: [task title]"
2. Goal: exactly what must be produced (file name, class, function)
3. Context: which files to READ (give exact paths)
4. Constraints: what NOT to change (other modules, shared config)
5. Completion signal: how to signal "done" (e.g., print "TASK-N COMPLETE")
6. Handoff: what artefact to produce for the integrator
```

**Example subagent prompt:**
```
You are implementing Task 2 of 4: Add the ItemValidator class.

Goal: Create `service/src/main/java/com/<org>/<product>/service/ItemValidator.java`

Read these files for context:
- service/src/main/java/com/<org>/<product>/domain/Item.java
- service/src/main/java/com/<org>/<product>/exception/ItemException.java

Constraints:
- Do NOT modify ItemService or ItemController
- Do NOT add Spring annotations — pure validation logic only

When done, print: TASK-2 COMPLETE
Produce: the new ItemValidator.java file
```

---

## Step 3: Launch Subagents

Use the `dispatching-parallel-agents` skill to actually launch and monitor subagents.

Key rules for this step:
- Launch all independent subagents before waiting on any
- Set a task timeout (default: 5 minutes per task)
- Capture each subagent's output artefacts separately

---

## Step 4: Integration

After all subagents complete:

1. **Collect artefacts** — gather all generated files
2. **Check for conflicts** — same import, same constant, overlapping test setup
3. **Wire together** — update the root file, module index, or test suite that spans tasks
4. **Build once** — run the full build to catch integration failures missed per-task
5. **Run tests** — run the full test suite, not just per-task tests

```bash
# Build after integration
./mvnw clean test -q

# Or for npm
npm test --prefix ui/<frontend-app>
```

---

## Step 5: Conflict Resolution

Common integration conflicts and how to resolve:

| Conflict | Resolution |
|----------|-----------|
| Two subagents added the same import | Keep one, remove duplicate |
| Two subagents modified the same `@Configuration` class | Merge both `@Bean` methods |
| Two subagents wrote overlapping test data | Namespace test data by task (e.g., `TASK2_`, `TASK3_`) |
| Subagent missed a dependency | Add it manually; document why in a comment |

---

## Performance Guidelines

- Ideal task size: 1–3 files per subagent
- Maximum concurrent subagents: 4–6 (context budget)
- If a task needs > 20 files of context, split it further or run sequentially
- Always run the integration build — per-task builds miss cross-cutting issues

---

## Checklist Before Declaring Done

```
[ ] All subagent tasks completed without error
[ ] Integration build passes (./mvnw test or npm test)
[ ] No duplicate code introduced across subagents
[ ] Each new file has at least one test (see tdd-java / tdd-react skill)
[ ] verification-before-completion run on the full set of changes
```

---

## Inter-Skill References

- **Before decomposing** → `writing-plans` to create the plan subagents will execute
- **For launching subagents** → `dispatching-parallel-agents`
- **For sequential execution** → `executing-plans`
- **After integration** → `verification-before-completion`
- **For TDD within each subagent** → `tdd-java` or `tdd-react`
