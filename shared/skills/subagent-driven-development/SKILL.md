---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

## Activation Rule

**Triggers:**
- Implementation plan exists with mostly independent tasks
- User says "execute with subagents", "implement per task", or "dispatch agents"
- Tasks span different modules and can be implemented independently
- Want to stay in current session without context switch

> **Override Directive:** This skill overrides default behavior when its conditions are met. Use fresh subagent per task with two-stage review — never implement all tasks in one monolithic pass.

## When to Use

**Use when:**
- Have an implementation plan with mostly independent tasks
- Want to stay in this session (no context switch)
- Tasks span different modules (service, drivers, feeds)

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Two-stage review after each task: spec compliance first, then code quality
- Faster iteration (no human-in-loop between tasks)

## The Process

1. **Read plan** - Extract all tasks with full text, note context, create TodoWrite
2. **Per task:**
   - Dispatch implementer subagent (using `./implementer-prompt.md`)
   - If subagent has questions → answer, re-dispatch
   - Subagent implements, tests (`./mvnw test -pl <module>`), commits, self-reviews
   - Dispatch spec reviewer subagent (using `./spec-reviewer-prompt.md`)
   - If spec issues → implementer fixes → re-review
   - Dispatch code quality reviewer subagent (using `./code-quality-reviewer-prompt.md`)
   - If quality issues → implementer fixes → re-review
   - Mark task complete
3. **After all tasks** - Dispatch final code reviewer for entire implementation
4. **Finish** - Use superpowers:finishing-a-development-branch

## Agent Integration

| Agent | Usage |
|-------|-------|
| **SquadLeader** | Primary orchestrator — dispatches implementer + reviewer subagents |
| **Developer** | Dispatched as implementer subagent per task |
| **Reviewer** | Dispatched as spec reviewer + code quality reviewer per task |
| **Debugger** | Called when subagent implementation fails tests |

## Decision Heuristics

- **Use this skill** when plan has 3+ independent tasks in different modules
- **Use `executing-plans`** instead for sequential tasks with heavy dependencies
- **Combine with `finishing-a-development-branch`** — mandatory after all tasks complete
- Example: "Plan has 5 tasks across service, drivers, and feeds" → use this skill
- Example: "Plan has 2 sequential tasks in service only" → use `executing-plans`

## Quick Start

1. Read plan → extract all tasks
2. Per task: dispatch implementer → spec review → code quality review
3. Fix issues between reviews → mark complete
4. After all tasks: final full-codebase review
5. Use `finishing-a-development-branch` to wrap up

## Prompt Template

```
Execute the plan at docs/plans/[plan-file].md using subagent-driven development.
Dispatch one subagent per task with two-stage review.
```

## Quality Gates

- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation follows Spring Boot conventions

## Red Flags

- Subagent modifying modules outside its task scope
- Driver-api changes without corresponding driver implementations
- Skipping `./mvnw test` verification
- Implementer not following constructor injection or Lombok patterns

## Performance Guidelines

- Fresh subagent per task prevents context pollution from previous tasks
- Don't skip spec review — it catches over/under-building before code quality review
- Run `./mvnw test -pl <module>` per task, `./mvnw clean install` after all tasks

## Inter-Skill References

- **Plan creation** → `writing-plans` produces the plan to execute
- **Alternative** → `executing-plans` for batch execution with human checkpoints
- **Completion** → `finishing-a-development-branch` (mandatory)
- **Parallel independent tasks** → `dispatching-parallel-agents` for concurrent execution
