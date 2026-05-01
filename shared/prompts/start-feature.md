# Start Feature

Use this prompt to kick off a new full-stack feature. It triggers the `full-stack-feature` agent and ensures API contract, tests, and design doc are in place before any implementation.

---

## Fill in the blanks, then send to Copilot

```
@full-stack-feature

## Feature: <Feature Name>

### What the user wants to achieve
<Describe the feature from the user's perspective. One paragraph.>

### EARS Acceptance Criteria
WHEN <condition>, THE SYSTEM SHALL <behaviour>
WHEN <condition>, THE SYSTEM SHALL <behaviour>
WHEN <condition>, THE SYSTEM SHALL <behaviour>

### API Contract (draft)
Endpoint: <METHOD /api/v1/resource>
Request: <fields and types>
Response: <fields and types>
Error cases: <404 when, 409 when, 400 when>

### Affected Repos / Modules
- Backend: <repo name, module path>
- Frontend: <repo name, component path>
- Shared: <any shared libs>

### Jira Story
<Story ID, e.g., KVISION-1234 or DEFFLOW-567>

### Non-functional Requirements
- Performance: <e.g., "must complete in < 200ms">
- Permissions: <e.g., "admin role only">
- Compatibility: <e.g., "must work with DF 4.7.x">
```

---

## What the agent will do

1. Design the OpenAPI spec for the endpoint(s) — using the `api-contract-first` skill
2. Write the failing test for the backend service — using the `tdd-java` skill  
3. Implement the backend service and controller
4. Define the TypeScript types from the spec
5. Write the failing test for the React component — using the `tdd-react` skill
6. Implement the React component and hook
7. Run a cross-layer integration smoke test
8. Produce a summary with links to all changed files

---

## Definition of Done

- [ ] OpenAPI spec committed to the repo
- [ ] Backend: unit tests + MockMvc controller test green
- [ ] Backend: Jacoco coverage ≥ 85% on new code
- [ ] Frontend: RTL tests green for all states (loading, success, error, empty)
- [ ] No TypeScript errors (`tsc --noEmit`)
- [ ] Conventional commit: `feat(<scope>): <description>`
