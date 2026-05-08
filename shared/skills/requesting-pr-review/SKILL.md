---
name: requesting-pr-review
description: Use when asked to review a Bitbucket pull request — fetches PR context, analyzes diff against project conventions, and presents structured findings in chat. Does NOT post comments to Bitbucket.
---

# Requesting PR Review

## Activation Rule

**Triggers:**
- User says "review PR #N", "review this PR", "do a PR review", "check PR #N"
- User provides a Bitbucket PR URL and asks for a review

> **Override Directive:** This skill overrides default behavior when its conditions are met. Always fetch the full PR context before analyzing — never comment based on assumptions about what changed.
> **Important:** Present all findings in chat only. Do NOT post comments to Bitbucket or call any Bitbucket write APIs (no `post_review_comments`, `approve`, `request_changes`, etc.).

---

## When To Use This Skill

Use this skill when:
- You are asked to act as a reviewer on a teammate's PR
- You need to produce structured review findings presented in chat
- You need a repeatable, thorough PR review workflow

**Trigger phrases:** "review PR", "do a PR review", "review pull request", "check PR #N", "give feedback on PR"

> **Do NOT** post comments to Bitbucket. All findings are presented in the chat response only.

---

## The Workflow

```
1. LOAD CONTEXT
   └─> mcp_bitbucket-mcp_get_pr_context  (metadata + diff + comments + metrics + history)

2. ANALYZE THE DIFF
   └─> Read changed files where needed
   └─> Check against project conventions (CONVENTIONS.md)
   └─> Check architecture rules (ARCHITECTURE.md)
   └─> Apply the review checklist (see below)

3. CATEGORIZE FINDINGS
   └─> Critical  — bugs, security, data loss, race conditions
   └─> Major     — convention violations, missing RBAC, wrong layer, N+1 queries
   └─> Minor     — logging noise, naming, style, unused imports

4. PRESENT FINDINGS IN CHAT
   └─> Output structured review report (see Output Format)
   └─> ⚠️ Do NOT call post_review_comments, approve, or request_changes
```

---

## Step 1: Load PR Context

### Primary: MCP Tools (always use these first)

The `bitbucket-mcp` server is configured in `C:/Users/AkashS/AppData/Roaming/Code/User/mcp.json`
with credentials injected automatically — **just call the tools directly, no setup needed**.

Always start with the combined context call — it returns diff, diffstat, comments, metrics, and memory patterns in one shot:

```
mcp_bitbucket-mcp_get_pr_context(pr_id, repo_slug, workspace="rdwr")
```

If you need the raw unified diff for deeper inspection:
```
mcp_bitbucket-mcp_get_pull_request_diff(pr_id, repo_slug, workspace="rdwr")
```

Check historical patterns for this repo before reviewing:
```
mcp_bitbucket-mcp_get_repo_patterns(repo="rdwr/common_policy_editor")
```

### Fallback: REST API via curl (only if MCP tools throw an error)

If MCP tools fail, read credentials from `mcp.json` at:
```
C:/Users/AkashS/AppData/Roaming/Code/User/mcp.json
→ .servers["bitbucket-mcp"].env.BITBUCKET_USERNAME / BITBUCKET_PASSWORD
```

Then fetch via curl (use `-L` to follow the 302 redirect on the diff endpoint):
```bash
BB_USER=$(python -c "import json; d=json.load(open('C:/Users/AkashS/AppData/Roaming/Code/User/mcp.json')); print(d['servers']['bitbucket-mcp']['env']['BITBUCKET_USERNAME'])")
BB_PASS=$(python -c "import json; d=json.load(open('C:/Users/AkashS/AppData/Roaming/Code/User/mcp.json')); print(d['servers']['bitbucket-mcp']['env']['BITBUCKET_PASSWORD'])")

curl -sL -u "$BB_USER:$BB_PASS" \
  "https://api.bitbucket.org/2.0/repositories/rdwr/<repo>/pullrequests/<pr_id>/diff" > /tmp/pr.diff
```

**Never ask the user to paste credentials in chat.**

**Key data to note:**
- PR title, description, source → destination branch
- Files changed (diffstat): which modules are touched
- Size rating (XS / S / M / L / XL) — calibrate review depth accordingly
- Whether test files changed (if not, flag it)
- Existing comments (avoid duplicate feedback)

---

## Step 2: Analyze the Diff

### Read Changed Files When Needed

For files where the diff alone lacks context (e.g., a partial method change), read the full file:

```
read_file(absolute_path_to_file)
```

Use `grep_search` to verify usage of changed symbols across the codebase:

```
grep_search(query="ClassName or methodName")
```

### Project Conventions Checklist

Before writing findings, verify each changed Java file against these rules from `docs/codebase/CONVENTIONS.md`:

#### CRITICAL — Flag as `critical` severity

- [ ] **Field injection used** — `@Autowired` on fields instead of constructor injection
  ```java
  // WRONG
  @Autowired private <DomainRepository> repo;
  // CORRECT — constructor injection via @RequiredArgsConstructor
  ```

- [ ] **Business logic in controller** — DB queries, transformations, or conditional logic outside the service layer

- [ ] **Null returned from service** — services must return `Optional<T>` or throw `<ProjectException>` / `<LowLevelException>`

- [ ] **New exception class created** — project uses `<ProjectException>` / `<LowLevelException>` only; no new exception types

- [ ] **Driver-api change missing driver implementations** — if `driver-api/` interface changed, ALL active `drivers/<version>/Driver.java` files must implement it

- [ ] **Hardcoded credentials, URLs, or version strings** — must use `@Value` or configuration properties

- [ ] **Race condition** — existsByName / findByName check outside a lock; shared mutable state accessed without synchronization

#### MAJOR — Flag as `major` severity

- [ ] **Missing `@RolesAllowed` on REST method** — every JAX-RS method needs `@RolesAllowed`, `@PermitAll`, or `@DenyAll`

- [ ] **New REST `@Component` not registered in `JerseyConfig.registerEndpoints()`** — silent 404

- [ ] **No Swagger `@Operation` or `@ApiResponse`** on a new public endpoint

- [ ] **Service lacks interface+Impl pattern** — new services must have a `PolicyXService` interface and `PolicyXServiceImpl`

- [ ] **New dependency declared with version in child pom** — versions belong in `<root-bom>/pom.xml`

- [ ] **N+1 query pattern** — loading a collection then iterating and querying per element

- [ ] **Missing input validation** — no null/empty/range checks on user-supplied data before passing to service

- [ ] **Lombok not used** — new entity/DTO classes with manual getters/setters instead of `@Data`, `@Builder`, `@RequiredArgsConstructor`

- [ ] **`@SpringBootTest` missing for service/repository tests** — pure `@ExtendWith(MockitoExtension.class)` used for classes that need Spring context; or vice versa

#### MINOR — Flag as `minor` severity

- [ ] **Info/debug log spam** — logging every routine DB read or successful no-op

- [ ] **Magic strings/numbers not extracted to constants** — `"unknown.txt"`, `500`, etc. inline in logic

- [ ] **Unused imports** — IDE auto-imports not cleaned up

- [ ] **Test method not following naming convention** — should be `should_X_when_Y()`

- [ ] **Comment on obvious code** — inline comments that restate the code

- [ ] **Long method / deep nesting** — methods > 30 lines or nesting > 3 levels

---

## Step 3: Categorize and Write Findings

For each finding, structure it as:

```
severity:         critical | major | minor
category:         e.g. "field-injection", "rbac", "race-condition", "null-check", "logging"
problem:          One-line description of the specific problem
why_it_matters:   Concrete risk if left unfixed
suggested_fix:    Corrected code snippet (markdown code fence) or prose fix
inline_path:      File path (for inline comments)
inline_to:        Line number (for inline comments)
```

### Finding Severity Guide

| Severity | When | Review Outcome |
|----------|------|----------------|
| `critical` | Bug, security flaw, data loss risk, race condition | Request Changes |
| `major` | Convention violation, missing security, wrong layer | Request Changes |
| `minor` | Style, logging, naming, minor clean-up | Approve with comments |

---

## Step 4: Present Findings in Chat

> ⚠️ **Never call Bitbucket write APIs.** Do not use `post_review_comments`, `approve_pull_request`, `request_changes`, or any other mutating Bitbucket MCP tool. All output goes to chat only.

Format the review report in chat using the Output Format below. Group findings by severity: Critical → Major → Minor.

For each finding include:
- **File and line** (from the diff)
- **Problem** — one-line description
- **Why it matters** — concrete risk
- **Suggested fix** — code snippet or prose

---

## Common Finding Templates

### Field Injection
```java
// problem: Field injection detected — use constructor injection
// WRONG
@Autowired
private <DomainService> service;

// CORRECT — use @RequiredArgsConstructor + final field
@RequiredArgsConstructor
public class MyController {
    private final <DomainService> service;
}
```

### Missing RBAC
```java
// Add @RolesAllowed to the endpoint:
@GET
@Produces(MediaType.APPLICATION_JSON)
@RolesAllowed({Role.SYSTEM_USER, Role.SYS_ADMIN, Role.SEC_ADMIN, Role.USR_ADMIN, Role.DEV_ADMIN, Role.DEVICE_OPERATOR})
public Response getAll() {
```

### Business Logic in Controller
```
Move the transformation/query logic to a service method.
Controller should only call service.doThing() and return Response.ok(result).build().
```

### Null Return from Service
```java
// WRONG
public <DomainEntity> findById(Long id) {
    return repository.findById(id).orElse(null);
}

// CORRECT
public <DomainEntity> findById(Long id) {
    return repository.findById(id)
        .orElseThrow(() -> new <ProjectException>("Not found: " + id, <ProjectException>.NOT_FOUND));
}
```

### Race Condition
```java
// WRONG — check outside lock allows duplicate creation
if (repository.existsByName(name)) throw conflict;
lock.lock();
try { ... create ... } finally { lock.unlock(); }

// CORRECT — check inside lock
lock.lock();
try {
    if (repository.existsByName(name)) throw conflict;
    ... create ...
} finally {
    lock.unlock();
}
```

### Missing Test File
```
No test file was added or modified in this PR.
If the changed logic has side effects, add unit tests covering:
- Happy path
- Not-found / invalid input
- Concurrent or boundary scenarios
```

---

## Positive Observations

Good code deserves acknowledgment. In the general summary comment, briefly note:
- Well-applied patterns (builder, constructor injection, proper layering)
- Good test coverage
- Helpful logging or Swagger docs

Keep it brief — one line per strength. Don't pad.

---

## Output Format

Present the review as a structured report in chat:

```
## PR #N Review

**PR:** {Title}
**Branch:** {source} → {destination}
**Size:** {XS/S/M/L/XL} — {lines added} added / {lines removed} removed
**Verdict:** APPROVED ✅ | CHANGES NEEDED 🔴 | MINOR NOTES 🟡

---

### 🔴 Critical ({N})

#### 1. {Problem title} — `{File.java:{line}}`
**Problem:** {One-line description}
**Risk:** {Concrete impact if left unfixed}
**Fix:**
```java
{corrected code snippet}
```

---

### 🟠 Major ({N})

#### 1. {Problem title} — `{File.java:{line}}`
...

---

### 🟡 Minor ({N})

#### 1. {Problem title} — `{File.java:{line}}`
...

---

### ✅ Strengths
- {One-liner on something done well}

---

**Summary:** {N} findings — {N} critical, {N} major, {N} minor.
{Verdict sentence: "Ready to merge after fixing critical issues." or "Looks good — only minor notes."}
```

---

## Validation Checklist

Before declaring the review complete:

```
✓ Every changed file was examined (not just the diff header)
✓ All findings include file + line reference from the diff
✓ Design decisions are justified (not just "looks wrong")
✓ No Bitbucket write APIs were called
✓ Full review report presented in chat
```

---

## Performance Guidelines

- Use `mcp_bitbucket-mcp_get_pr_context` first — it batches metadata + diff + history
- Read full files only when the diff lacks enough context
- Focus on Critical → Major → Minor; don't over-invest in Minor issues on large PRs
- For XL PRs (> 500 lines changed): focus on architecture and Critical issues; note that the PR is too large for line-by-line review
- **Never call any Bitbucket write API** — read-only MCP tools only

---

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Reviewer** | Primary user — performs this entire workflow |
| **SquadLeader** | Triggers reviewer as a quality gate before completion |
| **PEplan** | Consulted when a design-level question needs deeper analysis |
| **Debugger** | Called if a PR comment reveals a hidden bug to investigate |

---

## Inter-Skill References

- **For incoming feedback on your own code** → `receiving-code-review`
- **For responding to reviewer comments on your PR** → `handling-pr-review-comments`
- **For verifying fixes compile before posting** → `verification-before-completion`
- **For committing after addressing feedback** → `commit-push`

---

## Prompt Template

```
Review PR #[NUMBER] in [repo_slug].
Use the requesting-pr-review skill.
Focus on: [optional — e.g., "service layer", "test coverage", "security"]
```

