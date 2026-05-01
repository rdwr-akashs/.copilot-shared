# Review Request

Use this before opening a PR. Runs a self-review using the `reviewer` agent and `requesting-code-review` skill. Catch issues before asking teammates.

---

## Fill in the blanks, then send to Copilot

```
@reviewer

## PR Self-Review: <Feature/Fix Name>

### Jira Story / Bug
<KVISION-XXXX | DEFFLOW-XXXX | INC-XXXX>

### What changed
<1-3 sentences describing the change. What did you add/change/remove?>

### Affected Files (key ones)
- <path/to/changed/file.java>
- <path/to/changed/component.tsx>

### Branch
<feature/KVISION-1234-my-feature>

### Checklist before review
- [ ] Tests written BEFORE production code (TDD followed)
- [ ] All new tests green locally
- [ ] No `System.out` / `console.log` left in
- [ ] No hardcoded IPs, secrets, or user-specific paths
- [ ] OpenAPI spec updated (if endpoint changed)
- [ ] Conventional commit messages used
```

---

## What the reviewer agent will do

1. Read all changed files
2. Check against `java-conventions`, `react-conventions`, and `tdd.instructions`
3. Verify test coverage for new logic
4. Flag security concerns (OWASP Top 10)
5. Check for breaking changes in the API
6. Produce a severity-ordered review (Critical → Major → Minor → Nit)

---

## Severity Guide

| Level | Meaning | Must fix before merge? |
|---|---|---|
| Critical | Security issue, data loss risk, breaks prod | Yes |
| Major | Bug, missing test for business logic, bad abstraction | Yes |
| Minor | Style issue, missing comment, minor perf | Recommended |
| Nit | Cosmetic, personal preference | Optional |
