# Design-First Prompt Templates

Copy the relevant block, replace `<placeholders>`, and paste as your prompt.

---

## For Features (design + test plan only)

```
Design and plan before implementation.

Task: <describe the feature>

Requirements:
- Follow design-first and test-first approach
- Generate a Design Document covering:
  problem, scope, approach, API design, step flow, data model,
  edge cases, failure scenarios, performance, security,
  backward compatibility, observability, files to change
- Generate a QA Test Plan (functional, edge, negative, integration, E2E, regression)

Do NOT implement yet — design and test plan only.
```

## For Bug Fixes (analysis + test plan only)

```
Investigate and plan before fixing.

Bug: <describe the symptom, error message, or reproduction steps>

Requirements:
- Root cause analysis (exact file:method)
- Impacted areas (which callers/modules are affected)
- Fix plan (minimal change in correct layer)
- Regression test cases (prove the bug is fixed + no regressions)
- Validation steps

Do NOT implement yet — analysis and test plan only.
```

## For Full End-to-End (design + implement)

```
Design, plan, and implement.

Task: <describe the feature or bug>

Requirements:
- Design Doc first
- QA Test Plan second
- Then implement following the plan
- Verify with build + tests before claiming done
```

---

## Design Doc Sections (14 total)

| # | Section | Required? |
|---|---------|-----------|
| 1 | Problem Statement | Always |
| 2 | Scope (in/out) | Always |
| 3 | High-Level Approach | Always |
| 4 | API Design (method, URL, request, response, validation) | If API changes |
| 5 | Step Flow (numbered, through all layers) | Always |
| 6 | Data Model / DB Changes | If DB changes |
| 7 | Edge Cases | Always |
| 8 | Failure Scenarios | Always |
| 9 | Performance Considerations | If load/query concerns |
| 10 | Security (RBAC, input sanitization) | If new endpoints |
| 11 | Backward Compatibility | If API/DTO changes |
| 12 | Observability (logs, metrics) | If new error paths |
| 13 | Files to Change | Always |
| 14 | Risks and Open Questions | Always |

Mark non-applicable sections "N/A" — don't omit them silently.

---

**Expected output format** (enforced by orchestrator):

```
[Design]       — 14 sections (see PEplan agent)
[Test Plan]    — 9 sections: functional, negative, edge, integration, E2E,
                 regression, performance, QA steps, observability
[Plan]         — task type, agents, skills, steps
[Execution]    — only if implementation was requested
[Assumptions]  — inferred context stated explicitly
[Confidence]   — High / Medium / Low with reason
```
