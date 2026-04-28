---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Activation Rule

**Triggers:**
- Starting feature work that needs isolation from current workspace
- Before executing an implementation plan (to avoid polluting main branch)
- User says "create worktree", "isolate this work", or "new branch for feature"
- Need to work on multiple branches simultaneously

> **Override Directive:** This skill overrides default behavior when its conditions are met. Always verify .gitignore before creating worktree — committed worktree directories break the repo.

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Selection Process

### 1. Check Existing Directories

```bash
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check copilot-instructions.md

```bash
grep -i "worktree.*director" .github/copilot-instructions.md 2>/dev/null
```

### 3. Ask User

If no directory exists and no preference found, ask.

## Safety Verification

**MUST verify .gitignore before creating worktree:**

```bash
grep -q "\.worktrees" .gitignore && echo "OK" || echo "MISSING — add before proceeding"
grep -q "worktrees" .gitignore && echo "OK" || echo "MISSING — add before proceeding"
```

**If NOT in .gitignore:** Add both entries and commit before creating the worktree:

```bash
echo "" >> .gitignore
echo "# Git worktrees" >> .gitignore
echo ".worktrees/" >> .gitignore
echo "worktrees/" >> .gitignore
git add .gitignore && git commit -m "chore: add worktree directories to .gitignore"
```

## Creation Steps

### 1. Create Worktree

```bash
git worktree add ".worktrees/$BRANCH_NAME" -b "$BRANCH_NAME"
cd ".worktrees/$BRANCH_NAME"
```

### 2. Run Project Setup

```bash
# Java/Maven project
./mvnw clean install -DskipTests

# If UI changes involved
cd ui/policy-app-<version> && npm install
```

### 3. Verify Clean Baseline

```bash
./mvnw test
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

### 4. Report Location

```
Worktree ready at <full-path>
Build passes (./mvnw clean install)
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify .gitignore) |
| Neither exists | Check copilot-instructions.md → Ask user |
| Directory not in .gitignore | Add it immediately + commit |
| Maven build fails | Report and ask |
| Tests fail during baseline | Report failures + ask |

## Common Mistakes

- Skipping .gitignore verification
- Not running `./mvnw clean install -DskipTests` after creating worktree
- Proceeding with failing baseline tests
- Not verifying all Maven modules compile in new worktree

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Developer** | Triggers before starting feature implementation |
| **SquadLeader** | Creates worktree as first step of feature development workflow |
| **Architect (PEplan)** | Not typically used directly |
| **Debugger** | May use to isolate debugging work |

## Decision Heuristics

- **Use worktrees** for feature work lasting 2+ days or spanning multiple sessions
- **Don't use** for quick bug fixes or single-commit changes
- **Combine with `executing-plans`** — create worktree before executing plan
- Example: "Implement feeds API redesign" → create worktree (multi-day work)
- Example: "Fix typo in error message" → don't need worktree
- Example: "Execute plan for new endpoint" → create worktree first

## Quick Start

1. Check for existing `.worktrees/` or `worktrees/` directory
2. Verify `.gitignore` includes the worktree directory
3. `git worktree add ".worktrees/$BRANCH" -b "$BRANCH"`
4. `./mvnw clean install -DskipTests` in the worktree
5. Report location and build status

## Prompt Template

```
Create an isolated worktree for: [feature description]
Branch name: [feature/CYCON-XXXXX-description]
Use the using-git-worktrees skill.
```

## Performance Guidelines

- Always run `./mvnw clean install -DskipTests` immediately after creating worktree
- Don't run full tests during worktree creation — just verify compilation
- Report any existing test failures as baseline before starting work

## Inter-Skill References

- **After worktree created** → `executing-plans` or `subagent-driven-development` to implement
- **When done** → `finishing-a-development-branch` to merge/PR/cleanup
- **For brainstorming** → `brainstorming` happens before creating worktree
