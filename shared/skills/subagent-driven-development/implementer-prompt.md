# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: which module(s), dependencies, architectural context]
    [Maven module: service / driver-api / drivers/<version> / feeds / util]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Module boundaries or driver-api contracts
    - Dependencies or assumptions

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements:
    1. Implement exactly what the task specifies
    2. Write tests (JUnit 5 + Mockito, TDD if task says to)
    3. Verify: ./mvnw test -pl <module>
    4. Commit your work: <JIRA-ticket>: description
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.

    ## Project Conventions

    - Constructor injection (no @Autowired on fields)
    - Lombok (@Data, @Builder, @RequiredArgsConstructor)
    - PolicyTemplateException with status codes for errors
    - Optional<T> returns, never null from services
    - Controller → Service → Repository layering
    - Test naming: should_expectedBehavior_when_condition()

    ## Before Reporting Back: Self-Review

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - If driver-api changed, did I update ALL driver modules?

    **Quality:**
    - Constructor injection used? Lombok annotations?
    - Is the code clean and maintainable?
    - Module boundaries respected?

    **Testing:**
    - Do tests verify behavior (not mocks)?
    - did I follow should_X_when_Y() naming?
    - ./mvnw test -pl <module> passes?

    ## Report Format

    When done, report:
    - What you implemented
    - What you tested and test results
    - Files changed (with module paths)
    - Self-review findings (if any)
    - Any issues or concerns
```
