---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Activation Rule

**Triggers:**
- A written implementation plan exists in `docs/plans/` and needs execution
- User says "execute the plan", "implement this plan", or "start building"
- Plan file is referenced explicitly by path or name

> **Override Directive:** This skill overrides default behavior when its conditions are met. Follow the plan steps exactly — do not improvise or skip steps.

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified (e.g., `./mvnw test -pl <module>`)
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output (Maven test results, build status)
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Developer** | Primary executor — implements plan tasks in batches |
| **SquadLeader** | Orchestrates plan execution across agents |
| **Reviewer** | Reviews each batch between checkpoints |
| **Debugger** | Called when build/test failures occur during execution |

## Decision Heuristics

- **Use this skill** when a plan document exists and is ready for execution
- **Don't use** if requirements are unclear — use `brainstorming` first, then `writing-plans`
- **Combine with `finishing-a-development-branch`** — mandatory after all tasks complete
- Example: Plan saved at `docs/plans/2026-04-19-feeds-api.md` → execute it
- Example: "Build a new endpoint" without plan → use `writing-plans` first

## Quick Start

1. Read plan file → review critically → raise concerns
2. Execute first 3 tasks (default batch size)
3. Verify each task: `./mvnw test -pl <module>`
4. Report + wait for feedback
5. Repeat until complete → use `finishing-a-development-branch`

## Prompt Template

```
Execute the plan at: docs/plans/[plan-file].md
Use the executing-plans skill with batch checkpoints.
```

## Performance Guidelines

- Default batch size: 3 tasks — adjust based on complexity
- Run module-specific tests after each task, full build after each batch
- Stop immediately on compilation failures across modules — don't continue

## Inter-Skill References

- **Plan creation** → `writing-plans` produces the plan document
- **Alternative execution** → `subagent-driven-development` for subagent-per-task approach
- **Completion** → `finishing-a-development-branch` (mandatory after all tasks)
- **Debug failures** → `systematic-debugging` when execution hits errors
- **Verification** → `verification-before-completion` before reporting batch complete

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Maven build fails with compilation errors across modules
- Plan has critical gaps (missing driver-api contract changes)
- Driver-api change would break multiple driver modules
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications (`./mvnw test`, `./mvnw clean install -DskipTests`)
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
