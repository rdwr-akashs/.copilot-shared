---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Activation Rule

**Triggers:**
- 3+ independent failures across different modules or test classes
- Multiple unrelated tasks that can be worked on concurrently
- Build failures in separate modules with distinct root causes
- User says "fix all these" with multiple independent issues

> **Override Directive:** This skill overrides default behavior when its conditions are met. Dispatch one agent per independent problem domain instead of sequential investigation.

## Overview

When you have multiple unrelated failures (different test files, different modules, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

**Use when:**
- 3+ test classes failing with different root causes across different modules
- Multiple modules broken independently (e.g., driver-api change broke service AND feeds)
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures are related (fix one might fix others, e.g., driver-api contract change)
- Need to understand full multi-module state
- Agents would interfere with each other (editing same files)

## The Pattern

### 1. Identify Independent Domains

Group failures by module and root cause:
- Module A (service): PolicyTemplateService validation logic
- Module B (drivers/10_0_0_0): FreeMarker template rendering
- Module C (feeds): Feed sync scheduling

Each domain is independent — fixing service validation doesn't affect feed sync.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One module or test class
- **Clear goal:** Make these tests pass
- **Constraints:** Don't change code in other modules
- **Expected output:** Summary of what you found and fixed

### 3. Dispatch in Parallel

```
Agent 1 → Fix PolicyTemplateServiceTest failures (service module)
Agent 2 → Fix Driver10_0_0_0Test failures (drivers/10_0_0_0 module)
Agent 3 → Fix FeedSyncServiceTest failures (feeds module)
```

### 4. Review and Integrate

When agents return:
- Read each summary
- Verify fixes don't conflict (especially driver-api contract changes)
- Run full build: `./mvnw clean install`
- Integrate all changes

## Agent Prompt Structure

Good agent prompts are:
1. **Focused** - One clear problem domain (one module or component)
2. **Self-contained** - All context needed to understand the problem
3. **Specific about output** - What should the agent return?

```markdown
Fix the 3 failing tests in service/src/test/.../PolicyTemplateServiceTest.java:

1. "should_returnTemplate_when_idExists" - Expected template not found
2. "should_validateAllProfiles_when_structuredTemplate" - NPE in driver call
3. "should_handleUpgrade_when_versionChanges" - Upgrade path returns null

These are likely related to the recent driver-api changes. Your task:

1. Read the test file and understand what each test verifies
2. Trace the failure through Service → Driver flow
3. Fix by updating service logic or test expectations as appropriate

Do NOT change driver-api interfaces or other driver modules.

Return: Summary of root cause and what you fixed.
```

## Common Mistakes

**Too broad:** "Fix all the tests" - agent gets lost
**Specific:** "Fix PolicyTemplateServiceTest in service module" - focused scope

**No constraints:** Agent might refactor driver-api
**Constraints:** "Do NOT change driver-api interfaces"

## Verification

After agents return:
1. **Review each summary**
2. **Check for conflicts** - especially in shared modules (driver-api, util)
3. **Run full build** - `./mvnw clean install`
4. **Spot check** - Agents can make systematic errors

## Agent Integration

| Agent | Usage |
|-------|-------|
| **SquadLeader** | Primary orchestrator — dispatches and coordinates parallel agents |
| **Debugger** | Dispatched as individual agent per failure domain |
| **Developer** | Dispatched as individual agent per implementation task |
| **Reviewer** | Reviews all agent outputs after integration |

## Decision Heuristics

- **Use parallel agents** when problems are in 3+ different modules with no shared state
- **Don't use** when failures cascade from a single root cause (e.g., driver-api contract break)
- **Combine with `systematic-debugging`** — each dispatched agent should follow systematic debugging
- Example: Service test + feed test + driver test failing independently → dispatch 3 agents
- Example: All driver modules failing after driver-api change → sequential fix, don't parallelize
- Example: Two UI apps + one backend module need changes → dispatch 3 agents

## Quick Start

1. Group failures by module and root cause
2. Verify independence (no shared state between groups)
3. Create focused agent task per group with scope + constraints
4. Dispatch in parallel
5. Review + integrate + full build verification

## Prompt Template

```
I have [N] independent failures across [modules]. 
Use the dispatching-parallel-agents skill to fix them concurrently.
Failures: [list each with module and symptom]
```

## Performance Guidelines

- Max 3-4 parallel agents — more creates merge conflicts and review overhead
- Each agent prompt must include "Do NOT change code in other modules"
- Always run `./mvnw clean install` after integrating all agent results

## Inter-Skill References

- **Each agent should use** → `systematic-debugging` for investigation
- **After integration** → `verification-before-completion` for full build
- **Alternative approach** → `subagent-driven-development` for plan-based parallel execution
