---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Activation Rule

**Triggers:**
- All implementation tasks complete and tests pass
- User says "done", "finish", "merge", "create PR", or "wrap up"
- Plan execution reaches final step
- `executing-plans` or `subagent-driven-development` completes all tasks

> **Override Directive:** This skill overrides default behavior when its conditions are met. Never proceed without fresh `./mvnw clean install` verification.

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
./mvnw clean install
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
./mvnw clean install    # Verify tests on merged result
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>

# Create PR with JIRA ticket reference
gh pr create --title "<JIRA-ticket>: <title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Modules Affected
- [ ] service/
- [ ] driver-api/
- [ ] drivers/<version>/
- [ ] feeds/
- [ ] util/
- [ ] ui/

## Test Plan
- [ ] `./mvnw clean install` passes
- [ ] <specific verification steps>
EOF
)"
```

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

#### Option 4: Discard

**Confirm first.** Wait for exact "discard" confirmation before deleting.

### Step 5: Cleanup Worktree

For Options 1, 2, 4 — remove worktree if applicable.
For Option 3 — keep worktree.

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying `./mvnw clean install` on merged result
- Delete work without confirmation
- Force-push without explicit request

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Developer** | Triggers after completing implementation |
| **SquadLeader** | Triggers as final phase of feature development workflow |
| **Reviewer** | Not directly used — review happens before this skill |
| **Debugger** | Called if tests fail during Step 1 verification |

## Decision Heuristics

- **Always use this skill** when claiming work is complete — no exceptions
- **Don't use** if tests are still failing — fix first
- **Combine with `verification-before-completion`** — runs as part of Step 1
- Example: "All 5 plan tasks done, tests pass" → use this skill
- Example: "3 of 5 tasks done" → don't use yet, continue executing

## Quick Start

1. `./mvnw clean install` — verify all tests pass
2. Determine base branch (`main`/`master`)
3. Present 4 options (merge/PR/keep/discard)
4. Execute user's choice
5. Clean up worktree if applicable

## Prompt Template

```
Implementation is complete. Use the finishing-a-development-branch skill to wrap up.
```

## Performance Guidelines

- Always run full `./mvnw clean install` (not just `-DskipTests`) before presenting options
- For Option 2 (PR), include modules affected checklist in PR body
- Never force-push without explicit user request

## Inter-Skill References

- **Called by** → `executing-plans` and `subagent-driven-development` at completion
- **Before this skill** → `verification-before-completion` to ensure tests pass
- **Before this skill** → `requesting-code-review` for final quality check
- **For commit** → `commit-push` if just pushing without merge/PR
