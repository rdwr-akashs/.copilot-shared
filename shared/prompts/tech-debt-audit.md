# Tech Debt Audit

Scans the current repo for common tech debt patterns and produces a prioritized report.

---

## Send this to Copilot Chat

```
@reviewer

## Tech Debt Audit: <Module or Repo Name>

### Scope
<!-- Mark what to audit -->
- [ ] Java backend (src/main/java)
- [ ] React frontend (ui/)
- [ ] Both
- [ ] Specific module: <module-name>

### What to check

**Code Quality:**
- [ ] Field injection (`@Autowired` on fields instead of constructor injection)
- [ ] Null returns from service methods (should be `Optional<T>` or throw)
- [ ] Business logic in controllers
- [ ] Hardcoded strings/magic numbers
- [ ] Commented-out code
- [ ] Methods > 30 lines
- [ ] Missing `@RolesAllowed` on REST endpoints

**Dependencies:**
- [ ] Outdated Maven/npm dependencies with known CVEs
- [ ] Version declarations in child poms (should be in root-bom only)
- [ ] Unused dependencies

**Testing:**
- [ ] Classes with zero test coverage
- [ ] Tests using `@SpringBootTest` when `@ExtendWith(MockitoExtension.class)` suffices
- [ ] Missing edge case tests (null, empty, boundary values)

**Documentation:**
- [ ] Missing or stale `repo-cache.md` (>30 days old)
- [ ] `copilot-instructions.md` still has placeholder text
- [ ] Missing `cli-commands.instructions.md` entries

### Output format

Produce a prioritized table:

| # | Severity | Category | File:Line | Issue | Suggested Fix | Effort |
|---|----------|----------|-----------|-------|---------------|--------|

Group by severity (Critical → Major → Minor).
Include total counts per category at the bottom.
```

---

## What it triggers

| Agent | Skill | What it does |
|-------|-------|-------------|
| `reviewer` | `requesting-code-review` | Convention checklist scan |
| `reviewer` | `java-test-coverage` | Jacoco gap analysis |
| `devops` | `dependency-upgrade` | CVE + outdated version check |
