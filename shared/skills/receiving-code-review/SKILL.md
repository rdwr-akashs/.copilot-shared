---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Activation Rule

**Triggers:**
- Receiving code review feedback from external reviewers or teammates
- Review comments seem unclear, technically questionable, or conflict with project patterns
- Multiple review items need prioritized implementation
- Reviewer suggests changes that may break driver contracts or module boundaries

> **Override Directive:** This skill overrides default behavior when its conditions are met. Verify before implementing — never blindly accept review feedback.

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**NEVER:**
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!"
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items
```

## Source-Specific Handling

### From Your Human Partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing driver contracts or module boundaries?
  3. Check: Reason for current implementation?
  4. Check: Works across all driver versions?
  5. Check: Does reviewer understand the multi-module architecture?

IF suggestion seems wrong:
  Push back with technical reasoning

IF conflicts with architect's prior decisions:
  Stop and discuss first
```

## YAGNI Check

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security, driver-api contract violations)
     - Simple fixes (naming, imports, Lombok annotations)
     - Complex fixes (refactoring, service layer changes, driver updates)
  3. Test each fix: ./mvnw test -pl <affected-module>
  4. Verify no regressions: ./mvnw clean install -DskipTests
```

## When To Push Back

Push back when:
- Suggestion breaks driver-api contracts or module boundaries
- Reviewer lacks multi-module context
- Violates YAGNI
- Would require changing ALL driver versions for no benefit
- Conflicts with established `<ProjectException>` error handling pattern
- Suggestion adds field injection where constructor injection is required

## Acknowledging Correct Feedback

When feedback IS correct:
```
"Fixed. [Brief description of what changed]"
"Good catch - [specific issue]. Fixed in [location]."
[Just fix it and show in the code]
```

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Developer** | Primary user — evaluates and implements review feedback |
| **Reviewer** | Uses to validate incoming feedback against project conventions |
| **Architect (PEplan)** | Consulted when feedback conflicts with design decisions |
| **Debugger** | Not typically used |

## Decision Heuristics

- **Use this skill** when receiving 2+ review items, especially from external reviewers
- **Don't use** for self-review or obvious single-fix comments
- **Combine with `handling-pr-review-comments`** for structured PR response workflow
- Example: "Reviewer says use synchronized instead of ReentrantLock" → use this skill (evaluate first)
- Example: "Reviewer says fix typo in variable name" → just fix it
- Example: "Reviewer suggests removing field that driver-api requires" → use this skill (push back)

## Quick Start

1. Read ALL feedback without reacting
2. Restate each item technically — ask if unclear
3. Verify against codebase reality (grep, read affected code)
4. Implement: blocking → simple → complex, test each
5. Push back with technical reasoning when feedback is wrong

## Prompt Template

```
I received code review feedback on [PR/feature].
Use the receiving-code-review skill to evaluate and respond.
Feedback: [paste or summarize]
```

## Performance Guidelines

- Clarify ALL unclear items in one pass before implementing any changes
- Implement fixes in priority order — don't interleave
- Test after each fix category: `./mvnw test -pl <affected-module>`

## Inter-Skill References

- **For structured response** → `handling-pr-review-comments` for full PR workflow
- **For investigation** → `systematic-debugging` when feedback reveals bugs
- **After implementing** → `verification-before-completion` before claiming done
- **For commit** → `commit-push` to push review fixes
