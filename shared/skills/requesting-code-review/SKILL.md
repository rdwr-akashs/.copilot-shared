---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets Java/Spring Boot best practices and project conventions
---

# Requesting Code Review

## Activation Rule

**Triggers:**
- About to commit staged changes
- Major feature implementation complete
- Before creating a PR or merging to main
- After refactoring or driver-api contract changes
- User says "review my code", "check this", or "ready to commit"

> **Override Directive:** This skill overrides default behavior when its conditions are met. Never commit without running this review checklist first.

# Requesting Code Review

Automated code review against <current-repo> best practices before commits.

**Core principle:** Catch issues before they become technical debt.

## When to Request Review

**Mandatory:**
- Before committing staged changes
- After completing major feature
- Before creating PR or merging to main
- After refactoring existing code
- After driver-api contract changes

**Optional but valuable:**
- When stuck (fresh perspective)
- After fixing complex bug
- When touching legacy driver code

## How to Perform Review

### 1. Check Staged Changes

```bash
git diff --staged --name-only
git diff --staged
```

### 2. Run Automated Checks

**Build Verification:**

⚡ **Optimization Rule:** Always use **targeted builds** on changed modules only — never build the full project unless cross-module impact is confirmed.

```bash
# EFFICIENT — Only compile the changed module (fast ✓)
cd <changed-module> && ../mvnw compile -q
# OR
./mvnw compile -q -pl <changed-module>

# EXAMPLE: Refactoring only service module
cd service && ../mvnw compile -q

# Full project build ONLY if:
# - driver-api contract changed (affects all 13 drivers)
# - Root pom.xml or BOM changed
# - Multi-module dependency impact suspected
# THEN use:
./mvnw clean install -DskipTests   # Full compilation + unit tests (slow ⚠)
./mvnw test                         # Full test suite (very slow ⚠)
```

**Static Analysis (if configured):**
```bash
./mvnw sonar:sonar                  # SonarQube analysis
```

### 3. Manual Quality Checks

Review each staged file against these criteria:

#### **CRITICAL Issues (Fix immediately):**

- [ ] **No field injection** - Use constructor injection only
  ```java
  // WRONG
  @Autowired private <DomainRepository> repository;

  // CORRECT
  @RequiredArgsConstructor
  public class <DomainService> {
      private final <DomainRepository> repository;
  }
  ```

- [ ] **No business logic in controllers** - Delegate to service classes
  ```java
  // WRONG - logic in controller
  @GET
  public Response get(@PathParam("id") Long id) {
      var template = repository.findById(id).orElse(null);
      if (template == null) return Response.status(404).build();
      // 20 lines of transformation logic...
  }

  // CORRECT - thin controller
  @GET
  public Response get(@PathParam("id") Long id) {
      return Response.ok(service.findById(id)).build();
  }
  ```

- [ ] **No null returns from services** - Use `Optional<T>` or throw `<ProjectException>`

- [ ] **Driver-api changes implemented in ALL driver modules** - Build will fail otherwise

- [ ] **No hardcoded credentials/URLs** - Use configuration properties

#### **IMPORTANT Issues (Fix before committing):**

- [ ] **Lombok annotations used** - `@Data`, `@Builder`, `@RequiredArgsConstructor` to reduce boilerplate

- [ ] **Correct exception handling** - Throw `<ProjectException>` (or `<LowLevelException>` for lower-level errors) with status codes, don't create new exception classes

- [ ] **Tests use `@SpringBootTest` for services/repos** - Only use `@ExtendWith(MockitoExtension.class)` for pure utilities or driver classes with no Spring dependencies

- [ ] **New REST resource registered in `JerseyConfig`** - Every new `@Component` JAX-RS class must be added to `JerseyConfig.registerEndpoints()`; missing registration = silent 404

- [ ] **RBAC annotations on REST methods** - Each method needs `@RolesAllowed({Role.X})`, `@PermitAll`, or `@DenyAll`; unannotated methods bypass security

- [ ] **Service follows interface+Impl pattern** - New services must have an interface (`PolicyXService`) and a separate `@Service`-annotated implementation (`PolicyXServiceImpl`)

- [ ] **Dependencies in <root-bom>** - No version declarations in child module poms

- [ ] **Module boundary respected** - No cross-module shortcuts, use driver-api interfaces

#### **MINOR Issues (Note for improvement):**

- [ ] **Meaningful log messages** - No spam at info/debug level for routine operations

- [ ] **Clean code principles** - DRY, SOLID, meaningful names

- [ ] **Test coverage** - Edge cases, error paths

- [ ] **No unused imports** - Clean up IDE auto-imports

### 4. Document Findings

```markdown
## Code Review Summary

### Strengths:
- [List what's done well]

### Issues Found:

#### CRITICAL:
- [ ] Issue description with file and line

#### IMPORTANT:
- [ ] Issue description with file and line

#### MINOR:
- [ ] Issue description with file and line

### Assessment:
[Ready to commit | Needs fixes | Needs refactoring]
```

### 5. Act on Feedback

- **CRITICAL** - Fix immediately, don't proceed
- **IMPORTANT** - Fix before committing
- **MINOR** - Create task or fix if quick

## Project-Specific Checklist

### Architecture
- [ ] Controller → Service → Repository layering
- [ ] Driver-api contracts honored
- [ ] Module boundaries respected
- [ ] Changes compile across all modules

### Java/Spring Patterns
- [ ] Constructor injection (no `@Autowired` on fields)
- [ ] `<ProjectException>` or `<LowLevelException>` for errors (no new exception classes)
- [ ] `Optional<T>` returns from services
- [ ] Lombok for boilerplate reduction
- [ ] Service interface + `ServiceImpl` pattern followed

### REST / Security
- [ ] New REST `@Component` registered in `JerseyConfig.registerEndpoints()`
- [ ] Every REST method has `@RolesAllowed`, `@PermitAll`, or `@DenyAll`
- [ ] Swagger `@Operation` + `@ApiResponse` on new public endpoints

### Testing
- [ ] `@SpringBootTest` used for services and repositories
- [ ] `@SpringBootTest(webEnvironment=DEFINED_PORT)` + `HaStandaloneStateEvent` for REST tests
- [ ] `@ExtendWith(MockitoExtension.class)` only for pure utilities and driver classes
- [ ] `should_X_when_Y()` naming convention

### Dependencies
- [ ] Versions managed in `<root-bom>/`
- [ ] No version declarations in child poms

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Reviewer** | Primary user — performs the review checklist |
| **Developer** | Triggers before committing changes |
| **SquadLeader** | Triggers as quality gate before completion |
| **Debugger** | Not typically used |

## Decision Heuristics

- **Always use** before any commit to main or PR creation
- **Use** after completing a major feature or refactoring
- **Combine with `commit-push`** — review first, then commit
- Example: "5 files changed, adding new service" → use this skill
- Example: "Updated README typo" → optional, quick glance sufficient

## Quick Start

1. `git diff --staged --name-only` — list changed files
2. Check each file against CRITICAL issues (field injection, business logic in controllers)
3. Verify driver-api compliance if contract changed
4. **Targeted build:** `cd <module> && ../mvnw compile -q` (fast) — only use full build if cross-module impact confirmed
5. Document findings as CRITICAL / IMPORTANT / MINOR

## Prompt Template

```
Review my staged changes before committing.
Use the requesting-code-review skill checklist.
JIRA ticket: [CYCON-XXXXX]
```

## Performance Guidelines

- Start with `git diff --staged --name-only` for file list — don't read all files upfront
- Focus on CRITICAL issues first — skip MINOR issues under time pressure
- **Build optimization (critical for speed):**
  - Default: Use targeted builds `cd <module> && ../mvnw compile -q` (10-15 sec vs 2-5 min)
  - Only do full project build (`./mvnw clean install -DskipTests`) if driver-api or root-pom changed
  - Never do full build for isolated refactoring in single modules
- For driver-api changes, verify all 13 driver modules compile: `./mvnw compile -q` at project root

## Inter-Skill References

- **After review** → `commit-push` to commit and push
- **For fixing issues** → `systematic-debugging` if review reveals bugs
- **For completion** → `finishing-a-development-branch` after review passes
- **Verification** → `verification-before-completion` for build evidence
