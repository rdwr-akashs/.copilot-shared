---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Activation Rule

**Triggers:**
- Creating a new skill file for a reusable technique or pattern
- Editing an existing skill to improve clarity or coverage
- User says "create a skill", "document this pattern", or "add a skill for"
- A reusable pattern emerges that isn't obvious from the code alone

> **Override Directive:** This skill overrides default behavior when its conditions are met. Test skills with pressure scenarios before deployment — untested skills teach bad habits.

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agent instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious
- You'd reference this again across projects
- Pattern applies broadly
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in copilot-instructions.md)

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

## SKILL.md Structure

**Frontmatter (YAML):**
- Only two fields: `name` and `description`
- Max 1024 characters total
- `name`: Use letters, numbers, and hyphens only
- `description`: Start with "Use when..." — triggering conditions only, NOT workflow summary

```yaml
# BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task with code review between tasks

# GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks in the current session
```

```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern
Before/after code comparison

## Quick Reference
Table or bullets for scanning

## Implementation
Inline code for simple patterns

## Common Mistakes
What goes wrong + fixes
```

## Key Principles

- Rich description field for discovery (triggering conditions only)
- Use words Copilot would search for
- Don't summarize workflow in description
- Test skills with pressure scenarios before deployment

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Architect (PEplan)** | Creates skills when new patterns are discovered during planning |
| **Developer** | Identifies skill-worthy patterns during implementation |
| **Reviewer** | Validates skill accuracy and completeness |
| **SquadLeader** | Ensures skills are referenced correctly in agent workflows |

## Decision Heuristics

- **Create a skill** when a pattern applies across 3+ scenarios and isn't obvious
- **Don't create** for one-off solutions or standard practices well-documented elsewhere
- **Put in copilot-instructions.md** for project-specific conventions (not skills)
- Example: "How to handle JerseyConfig registration" → create skill (common mistake, not obvious)
- Example: "Use camelCase for Java variables" → don't create skill (standard convention)
- Example: "Two-terminal npm dev workflow" → create skill (project-specific, error-prone)

## Quick Start

1. Identify the reusable pattern or technique
2. Create `skills/<name>/SKILL.md` with frontmatter
3. Write Overview, When to Use, Core Pattern, Common Mistakes
4. Test with a pressure scenario (dispatch agent without the skill, then with)
5. Verify agent behavior improves with the skill

## Prompt Template

```
Create a new skill for: [pattern/technique]
Trigger conditions: [when should this activate]
Use the writing-skills skill to structure it properly.
```

## Performance Guidelines

- Keep skills concise — aim for actionable, not exhaustive
- Description field is max 1024 chars — use triggering conditions only, not workflow summary
- Test with at least 2 pressure scenarios before considering the skill complete

## Inter-Skill References

- **For testing skills** → use agent dispatch to verify behavior with/without the skill
- **For project conventions** → put in `copilot-instructions.md`, not in skills
- **Standardized structure** → follow the consistent section ordering defined in this skill
