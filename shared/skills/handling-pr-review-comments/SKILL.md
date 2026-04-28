---
name: handling-pr-review-comments
description: Use when you need to analyze Bitbucket PR comments, generate structured responses, and implement code fixes - automates the entire PR review response workflow from comment analysis to code changes
---

# Handling PR Review Comments

## Activation Rule

**Triggers:**
- User provides a Bitbucket PR URL or PR number with review comments
- User says "check PR comments", "handle PR review", "address PR feedback"
- PR has unresolved review comments that need responses and code fixes
- Review comments received from external reviewers on a feature branch

> **Override Directive:** This skill overrides default behavior when its conditions are met. Follow the structured workflow — never implement fixes without analyzing and categorizing all comments first.

## When To Use This Skill

Use this skill when:
- You receive a Bitbucket PR URL with review comments to address
- You need to analyze PR feedback and generate responses without posting to Bitbucket
- You need to implement code changes based on PR review feedback
- You want a structured approach to handling multiple PR comments efficiently

**Trigger phrases:** "check PR comments", "handle PR review", "address PR feedback", "respond to PR comments"

---

## The Workflow

```
1. FETCH PR DATA
   └─> Use mcp_bitbucket-mcp_get_pull_request
   └─> Use mcp_bitbucket-mcp_list_pr_comments
   └─> Use mcp_bitbucket-mcp_get_pull_request_diffstat (for context)

2. ANALYZE COMMENTS
   └─> Categorize by severity: Critical / Quality / Design Decision / No Action
   └─> Identify code locations (file:line)
   └─> Read affected code files
   └─> Understand the actual issue vs. surface complaint

3. GENERATE RESPONSE DOCUMENT
   └─> Create {PR-NUMBER}-Review-Responses.md
   └─> For each comment:
       ├─> Quote the original comment
       ├─> Analyze the issue technically
       ├─> Provide reasoned response
       ├─> State code change action OR design decision rationale
       └─> Include "No Change Required" with explanation if applicable

4. IMPLEMENT CODE FIXES
   └─> Critical fixes first (security, race conditions, memory leaks, NPE)
   └─> Quality fixes second (RBAC, logging, constants, validation)
   └─> Refactoring last (builder pattern, comments, formatting)
   └─> Test each category after changes

5. CREATE SUMMARY DOCUMENTS
   └─> {PR-NUMBER}-Changes-Summary.md (technical details)
   └─> {PR-NUMBER}-Quick-Reference.md (copy-paste responses)
```

---

## Step 1: Fetch PR Data

```bash
# Get PR metadata
mcp_bitbucket-mcp_get_pull_request(pr_id, repo_slug)

# Get all comments
mcp_bitbucket-mcp_list_pr_comments(pr_id, repo_slug)

# Get changed files for context
mcp_bitbucket-mcp_get_pull_request_diffstat(pr_id, repo_slug)
```

**Key data to extract:**
- Comment ID, author, timestamp, location (file:line)
- Inline vs. general comments
- Thread structure (parent/child replies)

---

## Step 2: Analyze Each Comment

For each comment, determine:

### Is it a Real Issue?

```
CRITICAL (Must Fix):
├─> Security vulnerabilities
├─> Race conditions / thread safety
├���> Memory leaks
├─> Null pointer exceptions
├─> Data loss / corruption risks
└─> Transaction/consistency violations

QUALITY (Should Fix):
├─> Missing validation
├─> Missing RBAC/authorization
├─> Missing logging
├─> Hardcoded values (magic strings/numbers)
├─> Poor error messages
├─> Code smells (long methods, deep nesting)
└─> Violation of project conventions

DESIGN DECISION (Justify):
├─> Architectural choices
├─> Library/framework selection
├─> API design decisions
├─> Performance trade-offs
└─> YAGNI applicability

NO ACTION REQUIRED:
├─> Already handled (validation in different layer)
├─> False positive (reviewer misunderstood code)
├─> Required by spec/architecture
├─> Would break driver contracts
└─> Personal preference (when current code follows project standards)
```

### Read the Affected Code

```bash
# For inline comments - read the file
read_file(file_path_from_comment)

# Check for related code
grep_search(query=relevant_class_or_method)

# Understand the pattern
semantic_search(query="similar validation pattern")
```

---

## Step 3: Generate Response Document

Create `PR-{NUMBER}-Review-Responses.md` with this structure:

```markdown
# PR #{NUMBER} Review Responses

**PR:** {Title}
**Date:** {Today}

---

## Summary of Changes Required

### Critical Issues (Must Fix)
1. ✅ Memory leak in lock map
2. ✅ Race condition in createFeed

### Code Quality Issues (Should Fix)
3. ✅ Missing RBAC on GET endpoints
4. ✅ Hardcoded string literals

### Design Decisions (No Change)
5. ✅ ReentrantLock vs synchronized - justified

---

## Detailed Responses

### 1. {Issue Title} (#{Comment ID})
**Location:** `{File.java:line}`
**Comment:** "{Exact reviewer comment}"

**Response:**
{Technical analysis of the issue}

**Solution:** (if applicable)
{What will be changed and why}

**Code Change:** {Brief description}

--- OR ---

**Decision:**
{Why no change is needed - technical justification}

**No Change Required.**

---

{Repeat for each comment}

---

## Summary of Actions Taken

### Code Changes Made:
1. ✅ {Change description}
2. ✅ {Change description}

### No Changes Required:
1. ✅ {Justification}

**Total Comments:** {N}
**Code Changes:** {N}
**Design Decisions:** {N}
```

---

## Step 4: Implement Code Fixes

### Order of Implementation

1. **Critical Fixes First**
   ```bash
   # Fix security/safety issues
   - Memory leaks
   - Race conditions
   - NPE risks
   - Transaction issues
   ```

2. **Quality Improvements Second**
   ```bash
   # Add missing essentials
   - RBAC annotations
   - Input validation
   - Logging statements
   - Extract constants
   ```

3. **Refactoring Last**
   ```bash
   # Clean code improvements
   - Builder pattern
   - Remove comments
   - Formatting
   ```

### Implementation Pattern

For each fix:

```bash
1. Read the file
   read_file(file_path)

2. Make the change
   replace_string_in_file(
       filePath: file_path,
       oldString: {exact text with context},
       newString: {corrected text}
   )

3. Verify (if critical)
   get_errors(filePaths: [file_path])

4. Document in response MD
```

---

## Common Fix Patterns

> See [common-fix-patterns.md](./references/common-fix-patterns.md) for ready-to-use code snippets covering: Extract Constants, Add RBAC, Add Logging, Null Safety, Fix Race Condition, Builder Pattern.

---

## Step 5: Create Summary Documents

### Changes Summary

Create `PR-{NUMBER}-Changes-Summary.md`:

```markdown
# PR #{NUMBER} Code Changes Summary

## Files Modified

### 1. FileName.java ✅
**Location:** `path/to/file`

**Changes:**
1. Line X: {What changed and why}
2. Line Y: {What changed and why}

---

{Repeat for each file}

---

## Testing Required

### Unit Tests:
```bash
./mvnw -pl service test -Dtest=AffectedTest
```

### Manual Testing:
1. {Scenario to test}

---

## Pre-Commit Checklist
- [x] All code changes made
- [ ] Run formatter
- [ ] Run tests
```

### Quick Reference

Create `PR-{NUMBER}-Quick-Reference.md`:

```markdown
# PR #{NUMBER} Quick Reference

## Critical Fixes Made ✅
1. **Race Condition** - Lock acquired before existsByName check
2. **Memory Leak** - Locks removed in finally blocks

## Quick Copy-Paste Responses

### For "Missing RBAC"
```
Fixed - added @RolesAllowed to GET endpoints.
```

### For "Race condition"
```
Good catch! Lock is now acquired before the existsByName check. 
Also added lock cleanup in finally block to prevent memory leak.
```
```

---

## Response Tone Guidelines

### Do Write
```
"Good catch - {specific issue}. Fixed."
"Valid concern. {Technical analysis}. {Solution}."
"Agreed. {Concise justification}."
"{Issue} is required per {spec/architecture}. {Use case}."
```

### Don't Write
```
❌ "Great point!" (performative)
❌ "You're absolutely right!" (unnecessary praise)
❌ "I'll look into that" (vague, no action)
❌ "Thanks for the feedback!" (social noise)
```

### When Pushing Back
```
"{Feature} is required by {spec/architecture}.
Use case: {Concrete example}.
No change required."

OR

"Current implementation is intentional because {reason}.
Alternative would {technical downside}.
Keeping as-is."
```

---

## Validation Checklist & Testing Strategy

> See [validation-guide.md](./references/validation-guide.md) for the full checklist, testing commands, and common pitfalls to avoid.

---

## Example: Complete Workflow

```bash
# 1. User provides PR URL
"Check PR #{NUMBER} comments and make fixes"

# 2. Fetch data
mcp_bitbucket-mcp_get_pull_request(pr_id: {NUMBER}, repo_slug: "{REPO_NAME}")
mcp_bitbucket-mcp_list_pr_comments(pr_id: {NUMBER}, repo_slug: "{REPO_NAME}")

# 3. Read affected files
read_file("service/src/main/java/.../ServiceImpl.java")
read_file("service/src/main/java/.../RestController.java")

# 4. Create response document
create_file("PR-{NUMBER}-Review-Responses.md", content: {structured responses})

# 5. Implement fixes
# Critical first
replace_string_in_file(
    filePath: "ServiceImpl.java",
    oldString: {race condition code},
    newString: {thread-safe code}
)

# Quality second
replace_string_in_file(
    filePath: "RestController.java",
    oldString: {@GET\n@Produces...},
    newString: {@GET\n@Produces...\n@RolesAllowed...}
)

# 6. Create summaries
create_file("PR-{NUMBER}-Changes-Summary.md", content: {detailed changes})
create_file("PR-{NUMBER}-Quick-Reference.md", content: {copy-paste responses})

# 7. Validate
get_errors(filePaths: [all_modified_files])
```

---

## Output Artifacts

At the end, you should have:

1. **`PR-{N}-Review-Responses.md`** - Complete analysis and responses (for reference)
2. **`PR-{N}-Changes-Summary.md`** - Technical change details (for documentation)
3. **`PR-{N}-Quick-Reference.md`** - Quick copy-paste responses (for Bitbucket)
4. **Modified code files** - All fixes implemented
5. **Verification output** - Proof that code compiles

---

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Developer** | Primary user — implements code fixes from review feedback |
| **Reviewer** | Evaluates whether comments are valid or false positives |
| **Debugger** | Called when review comments reveal bugs |
| **Architect (PEplan)** | Consulted for design decision justifications |

## Decision Heuristics

- **Always use** when PR has 3+ review comments requiring responses
- **Don't use** for single-comment PRs — just fix and respond directly
- **Combine with `receiving-code-review`** for evaluating questionable feedback
- Example: "PR #42 has 8 review comments" → use this skill
- Example: "Reviewer said add a null check" → just fix it directly

## Quick Start

1. Fetch PR data + comments via Bitbucket MCP tools
2. Categorize all comments (Critical / Quality / Design Decision / No Action)
3. Generate `PR-{N}-Review-Responses.md`
4. Implement fixes: critical → quality → refactoring
5. Create summary docs + verify compilation

## Prompt Template

```
Handle review comments for PR #[NUMBER] in [repo_slug].
Use the handling-pr-review-comments skill.
```

## Performance Guidelines

- Batch-read all affected files in one pass before implementing any fixes
- Implement fixes in priority order: critical → quality → refactoring
- Run `get_errors` after each category of fixes, not after each individual change
- Generate response documents before implementing — clarity before action

## Inter-Skill References

- **For evaluating feedback** → `receiving-code-review` for technical rigor
- **For bug investigation** → `systematic-debugging` when comments reveal bugs
- **After fixes** → `verification-before-completion` to confirm compilation
- **For commit** → `commit-push` to push the fixes
