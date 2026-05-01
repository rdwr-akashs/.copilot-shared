---
name: commit-push
description: Use when you need to quickly review, commit, and push changes from an IntelliJ changelist without pre-push verification, typically for minor fixes or documentation updates
---

# Commit Push

## Activation Rule

**Triggers:**
- User says "commit", "push", "commit and push", or "ship it"
- Changes are ready and staged for commit
- Minor fixes, documentation updates, or formatting changes complete
- Feature branch work ready to push for CI validation

> **Override Directive:** This skill overrides default behavior when its conditions are met. Never auto-run `git commit` — present the message for user approval.

## Overview

A streamlined workflow for reviewing changes in an IntelliJ **changelist**, selecting specific files (and optionally specific lines/hunks within files), creating a descriptive commit, and pushing with bypassed pre-push hooks.

> **IntelliJ Note:** IntelliJ IDEA does not use the git staging area (index). Instead it organises modified files into **changelists** (default: *Changes*). In the **Commit** dialog (⌘K / Ctrl+K), each file has a **checkbox** — you check only the files you want to include in this commit. You can also expand a file and include/exclude individual change hunks (lines) from the diff view. Only checked items are committed.

## When to Use

**Use when:**
- You have changes ready in a changelist and want to commit only a subset of them
- Changes are minor (documentation, comments, formatting)
- You want to bypass pre-push hooks (linting, tests)
- Working on feature branches where Jenkins CI will run on PR
- Need quick iteration cycle

**Don't use when:**
- Changes affect critical functionality (service layer, driver-api contracts)
- Working on main/master branch
- Pre-push hooks are essential for your workflow
- Changes require full Maven test validation

## Core Pattern

```bash
# 1. Review what's changed
git status
git diff

# 2. Stage only the specific files (or hunks) you want to commit
git add path/to/file1.java path/to/file2.java   # specific files
# OR for partial file (line-level selection):
git add -p path/to/file.java                     # interactive hunk selection

# 3. Verify exactly what will be committed
git diff --cached

# 4. Generate commit message — use gh copilot suggest for best results:
#    gh copilot suggest "write a conventional commit message for these changes" -t git
#    Or from the diff: git diff --cached | gh copilot suggest -t git "commit message for this diff"
# → Present: "CYCON-XXXXX: Short imperative description"
# User commits manually via IntelliJ (Ctrl+K) or terminal

# 5. Push bypassing hooks
git push --no-verify
```

## Implementation

### Step 1: Review Changelist Contents

In IntelliJ, open the **Commit** dialog (⌘K / Ctrl+K) → *Local Changes* tab.  
Each modified file has a **checkbox**. Only checked files are included in the commit.

From the terminal, inspect all local modifications:

```bash
git status
git diff
```

### Step 2: Select Only the Files (or Lines) You Want

**Option A — IntelliJ UI (preferred):**
- Open the Commit dialog (Ctrl+K)
- **Uncheck** every file you do **not** want in this commit
- To include only specific lines within a file: expand the file in the diff pane, then check/uncheck individual change chunks

**Option B — Terminal (specific files):**
```bash
git add path/to/FileA.java path/to/FileB.java
```

**Option C — Terminal (specific lines/hunks within a file):**
```bash
git add -p path/to/FileA.java
# Press y to stage a hunk, n to skip, s to split smaller
```

### Step 3: Verify the Staged Snapshot

Before committing, confirm only the intended changes are staged:

```bash
git diff --cached           # shows exactly what will go into the commit
git diff --cached --name-only   # quick file-level summary
```

### Step 4: Run Code Review Agent

Always run code review before committing to catch issues.

### Step 5: Generate the Commit Message

**Do not run `git commit` yourself.** Instead, output the proposed commit message as a markdown block for the user to review and use:

```markdown
## Commit Message

CYCON-XXXXX: Short imperative description of what changed
```

The user will copy this message and commit manually via IntelliJ's **Commit** dialog (Ctrl+K) or the terminal. Do not execute `git commit` on their behalf.

**Message format rules:**
- Prefix with the JIRA ticket: `CYCON-XXXXX:`
- Use imperative mood: "Add …", "Fix …", "Remove …", "Update …"
- Keep the subject line under 72 characters

### Step 6: Push Without Verification

```bash
git push --no-verify
```

Or use IntelliJ's **Push** dialog (⌘⇧K / Ctrl+Shift+K) and uncheck any pre-push checks.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `git commit -a` | **Never use `-a`** — it stages and commits everything, ignoring your file/line selection |
| Running `git diff --cached` before staging | Stage first (`git add` or IntelliJ checkboxes), then inspect with `git diff --cached` |
| Forgetting unchecked files are still uncommitted | They remain in the changelist and will appear in subsequent commits unless explicitly excluded |
| Skipping code review step | Always run code-reviewer agent before committing |
| Missing JIRA ticket in message | Always prefix with `CYCON-XXXXX:` |
| Forgetting `--no-verify` | Add explicitly to bypass hooks |

**Safety note:** Always ensure your team's workflow allows bypassing pre-push hooks for the type of changes you're committing.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Developer** | Primary user — commits after implementing features |
| **SquadLeader** | Triggers after plan execution completes |
| **Reviewer** | Runs code review (Step 4) before commit |
| **Debugger** | Not typically used |

## Decision Heuristics

- **Use this skill** for feature branch commits with minor-to-moderate changes
- **Don't use** for main/master branch pushes — use `finishing-a-development-branch` instead
- **Combine with `requesting-code-review`** — always review before committing
- Example: "Push my docs update" → use this skill
- Example: "Merge feature to main" → use `finishing-a-development-branch`
- Example: "Commit driver-api contract change" → use this skill BUT run full build first

## Quick Start

1. `git status` + `git diff` — review changes
2. `git add <files>` — stage specific files
3. `git diff --cached` — verify staged snapshot
4. Run code review agent
5. Present commit message → user commits → `git push --no-verify`

## Prompt Template

```
Review my changes and prepare a commit message.
JIRA ticket: [CYCON-XXXXX]
Use the commit-push skill.
```

## Performance Guidelines

- Always use `git diff --cached --name-only` for quick overview before full diff
- Stage only related files per commit — don't mix concerns
- Skip `--no-verify` when changes touch service layer or driver-api

## Inter-Skill References

- **Before committing** → `requesting-code-review` for quality gate
- **After all work done** → `finishing-a-development-branch` for merge/PR workflow
- **Verification** → `verification-before-completion` if changes affect tests
