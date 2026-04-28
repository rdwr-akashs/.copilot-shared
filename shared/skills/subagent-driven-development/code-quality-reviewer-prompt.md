# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (use requesting-code-review/code-reviewer.md template):

  WHAT_WAS_IMPLEMENTED: [from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
```

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

**Additional Java/Spring checks:**
- Constructor injection used (no @Autowired on fields)?
- Lombok annotations applied (`@Data`, `@Builder`, `@RequiredArgsConstructor`)?
- `<ProjectException>` with status codes (no new exception classes)?
- `Optional<T>` returns, never null?
- Tests use `@ExtendWith(MockitoExtension.class)` not `@SpringBootTest` for unit tests?
- Dependencies managed in `<root-bom>/` (no version declarations in child pom)?
- `should_X_when_Y()` test naming?
