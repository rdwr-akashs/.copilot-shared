---
applyTo: '**'
---
# AI Orchestrator — Decision Engine

Every task flows through: **Classify → Cache-Check → Design → Test Plan → Execute → Validate → Save Learning**

---

## Auto-Dispatch Rule

When the user sends a message **without** an explicit `@agent`:
1. Classify using Step 1 below
2. Announce: **"[Agent: `<name>`] — <one-line task summary>"**
3. Act as that agent immediately — no confirmation needed
4. If ambiguous: state both candidates, pick the more specific one

The user can always redirect: `@<other-agent> do X instead`

---

## Step 0: Cache-First Context Loading

Before reading any source code or running `semantic_search`:

1. Check for `.github/repo-cache.md` in the current repo
   - **Present and < 30 days old** → read it (tiny, fast) → skip `semantic_search`
   - **Absent or stale** → run `acquire-codebase-knowledge` skill to generate it, then proceed
2. Load task-specific docs only when cache is absent or the area is undocumented:

| Task touches | Also read |
|---|---|
| Architecture/design | `docs/codebase/ARCHITECTURE.md` + `STRUCTURE.md` |
| High-churn area | `docs/codebase/CONCERNS.md` |
| DB, RabbitMQ, Config | `docs/codebase/INTEGRATIONS.md` |
| Tests | `docs/codebase/TESTING.md` |
| Dependencies | `docs/codebase/STACK.md` |

3. After completing any task: append one line to `## Recent Context` in `.github/repo-cache.md`

---

## Mandatory Pre-Implementation Phases

### Design Phase (Deep Mode only)

Before any code is written, produce a **Design Doc** for:
- All new features
- Non-trivial bug fixes (multi-file, cross-module, API changes)

**Skip design ONLY when ALL true:** single file, no API change, no new endpoint, change is obvious.

**Owner:** `principal-engineer` agent (features) or `debugger` agent (bug root cause analysis).

Design Doc structure — see `principal-engineer` agent for full template:
- Problem Statement → Options Considered → Recommendation → Design → Edge Cases → Performance → Risks → Tasks

### Test Plan Phase

After design, before implementation, produce a **QA Test Plan**:
- Functional (happy path, boundary, optional fields)
- Negative (missing fields, invalid format, unauthorized)
- Edge (null/empty, large payload, duplicate, concurrent, timeout)
- Integration (service-to-service, DB)
- Regression (existing features unaffected)

**Owner:** Tester agent generates; Reviewer agent validates coverage.

### Enforced Flow by Task Type

```
Feature:  Design Doc → Test Plan → Implementation → Validation → Save Learning
Bug Fix:  Root Cause → Fix Plan → Test → Validation → Save Learning
Fast-path: Edit → get_errors → done
```

---

## Step 1: Classify the Task

| Task Type | Signal | Route To | Mode |
|-----------|--------|----------|------|
| **Feature** | "add", "implement", "create", "build" + new functionality | SquadLeader agent | Deep |
| **Bug Fix** | "fix", "broken", "failing", "error", "debug" | Debugger agent → Developer agent | Deep |
| **Code Review** | "review", "check my code", "PR comments" | Reviewer agent | Deep |
| **Planning / Architecture** | "plan", "design", "how should we", "brainstorm", "architecture" | principal-engineer agent | Deep |
| **Test Writing** | "write tests", "add coverage", "test this" | Tester agent | Fast/Deep |
| **Build/CI** | "build fails", "npm error", "docker", "pipeline" | DevOps agent | Fast |
| **Frontend/UI** | "ui", "component", "<frontend-app>", "styled", "React", "frontend" | Frontend agent | Fast/Deep |
| **Cross-Repo** | references sibling repo or external service | Use `cross-repo-exploration` skill | Deep |
| **Customer Case / Field Escalation** | `RSEG-`, `SC-`, `INC-`, `JIRA-`, "support bundle", "support file", "customer logs", "RCA", "field escalation" | `case-investigator` agent | Deep |
| **Full-Stack Feature** | new feature touching both Java backend and React frontend | `full-stack-feature` agent | Deep |
| **Elasticsearch issue** | "ES query wrong", "no hits", "mapping conflict", "slow query", index health | `elasticsearch-expert` agent | Deep |
| **Akka Actor issue** | "dead letters", "ask timeout", "actor stuck", dispatcher starvation | `akka-expert` agent | Deep |
| **Performance investigation** | "slow", "high CPU/memory", "throughput dropped", "latency spike" | `perf-investigator` agent | Deep |
| **Write Jira Story/Bug/Spike** | "write a story for", "create a Jira ticket", "document this as a bug" | `story-writer` agent | Fast |
| **Simple Edit** | single-file change, config update, rename | Fast-path (no agent) | Fast |
| **Multi-Task** | 3+ independent items across modules | `dispatching-parallel-agents` skill | Deep |

## Step 2: Select Mode

### Fast Mode
Use when ALL true: single file, no driver-api changes, no new endpoints, no cross-module deps, change is obvious.
- Skip plan block. Read file → edit → `get_errors` → done.
- No agent delegation. No codebase doc reads.

### Deep Mode
Use when ANY true: multi-file, new API, cross-module, debugging, cross-repo, architecture decision.
- Full pipeline: context → plan → execute → validate → self-correct.
- Load relevant codebase docs (not all — see Context Control).

## Step 3: Load Context (Deep Mode only)

**Read only what the task needs:**

| Task touches... | Read |
|----------------|------|
| Any code change | `docs/codebase/CONVENTIONS.md` |
| Architecture/design | `docs/codebase/ARCHITECTURE.md` + `STRUCTURE.md` |
| High-churn area | `docs/codebase/CONCERNS.md` |
| DB, RabbitMQ, Config Service | `docs/codebase/INTEGRATIONS.md` |
| Tests | `docs/codebase/TESTING.md` |
| Dependencies | `docs/codebase/STACK.md` |
| Current work | `memory-bank/activeContext.md` |

**Never read all 7 docs upfront.** Prefer `grep_search` over `semantic_search` for exact symbols. Batch file reads.

## Step 4: Select Skills

| Situation | Skill |
|-----------|-------|
| **TDD** | |
| Java TDD (write test first) | `tdd-java` |
| React TDD (write test first) | `tdd-react` |
| Improve Jacoco coverage gaps | `java-test-coverage` |
| **API & Implementation** | |
| New REST endpoint | `adding-rest-endpoints` |
| Design API before implementing | `api-contract-first` |
| Multi-step plan needed | `writing-plans` |
| Executing a plan | `executing-plans` |
| Multiple independent tasks (3+) | `dispatching-parallel-agents` |
| **Debugging** | |
| Any failure/error | `systematic-debugging` |
| Elasticsearch query wrong/slow | `elasticsearch-debug` |
| RabbitMQ queue backlog / dead-letter | `rabbitmq-debug` |
| Akka dead letters / ask timeout | `akka-debug` |
| Log analysis (pattern, correlation) | `log-analysis` |
| **Design** | |
| Creative exploration, requirements | `brainstorming` |
| **Customer Cases** | |
| Case intake (first action) | `customer-case-intake` |
| Prior case lookup | `case-archive` (lookup mode) |
| Support file triage | `support-file-triage` |
| RCA evidence mapping | `rca-evidence-mapping` |
| RCA document | `rca-document` |
| Archive completed RCA | `case-archive` (write mode) → triggers `save-learning` |
| **Memory & Learning** | |
| End of any investigation/case | `save-learning` |
| Map unfamiliar repo | `acquire-codebase-knowledge` |
| **Git & PR Workflow** | |
| Commit and push | `commit-push` |
| Branch completion | `finishing-a-development-branch` |
| Reviewing a teammate's PR | `requesting-pr-review` |
| PR review response | `handling-pr-review-comments` |
| Pre-commit self-review | `requesting-code-review` |
| Evaluating incoming feedback | `receiving-code-review` |
| **Cross-Repo** | |
| Code in sibling repos (local) | `cross-repo-exploration` |
| Code across ALL Bitbucket repos (remote) | `remote-repo-exploration` |
| **Dependencies** | |
| Maven/npm CVE or upgrade | `dependency-upgrade` |
| npm/UI build issues | `npm-errors` |
| **Other** | |
| Before claiming done | `verification-before-completion` |
| Workspace isolation | `using-git-worktrees` |
| Creating or editing a Copilot skill | `writing-skills` |
| Save a lesson for future sessions | `save-learning` or `remember` |
| Tailor agent to a specific repo | `customize-agents` |

### Skill Chaining Rules

| Scenario | Chain |
|----------|-------|
| Bug in cross-repo flow | `systematic-debugging` → `cross-repo-exploration` → `verification-before-completion` |
| New feature end-to-end | `brainstorming` → `writing-plans` → `adding-rest-endpoints` → `tdd-java` → `verification-before-completion` |
| PR fix + verify | `handling-pr-review-comments` → `verification-before-completion` → `commit-push` |
| Multi-module failure | `systematic-debugging` → `dispatching-parallel-agents` |
| Customer field escalation | `customer-case-intake` → `case-archive` (lookup) → `support-file-triage` → `rca-evidence-mapping` → `rca-document` → `case-archive` (write) → `save-learning` |

## Step 5: Execute with Structured Output

Every non-trivial response:

```
[Design]
• Problem: [one sentence]
• Scope: [in/out]
• Approach: [key decisions]
• API Changes: [endpoints, request/response shapes, validation]
• Step Flow: [numbered sequence through layers]
• Data Model: [DB/entity impact, or "none"]
• Edge Cases: [list]
• Failure Scenarios: [what can go wrong]
• Performance: [impact assessment]
• Security: [RBAC, input sanitization, or "none"]
• Backward Compatibility: [breaking changes, or "none"]
• Observability: [key logs, or "standard"]
• Files to Change: [grouped by module]

[Test Plan]
• Functional: [happy path, boundary, optional fields]
• Negative: [missing fields, invalid format, unauthorized, malformed]
• Edge: [null/empty, large payload, duplicate, concurrent, timeout]
• Integration: [service-to-service, DB interaction]
• E2E: [full flow scenarios]
• Regression: [existing features + previous bugs]
• Performance: [load/response time, or "N/A"]
• QA Steps: [how to reproduce/verify]
• Observability: [log level, no sensitive data, or "N/A"]

[Plan]
• Task Type: [feature/bug/review/plan/test/build/simple]
• Mode: [Fast/Deep]
• Agent: [which agent]
• Skills: [which skills, in order]
• Steps: [numbered]

[Execution]
• [actual work — only if implementation is requested]

[Assumptions]
• [any inferred context — state explicitly]

[Confidence]
• High / Medium / Low — [one-line reason]
```

For **Fast Mode**: skip [Design] and [Test Plan], just execute + verify.
For **Design-only requests**: output [Design] + [Test Plan] only, no [Execution].

## Step 6: Self-Correction Loop

After generating output, before presenting:
1. **Re-read the requirement** — does the output actually address it?
2. **Check edge cases** — null inputs, empty collections, missing entities, concurrent access
3. **Verify no convention violations** — constructor injection, no null returns, correct exception handling
4. **If confidence < High** — state what's uncertain and what would increase confidence

## Failure Handling

When output is incorrect, incomplete, or a tool fails:

| Failure | Response |
|---------|----------|
| `get_errors` returns issues after edit | Fix immediately, re-validate. Max 3 retries per file. |
| Build fails after change | Read error output, trace to root cause, fix. Don't retry blindly. |
| Wrong file edited / wrong approach | Stop. Re-read context. Re-plan with better information. |
| Tool returns empty/unexpected result | Try alternative tool or different search terms. |
| Cross-repo tool fails | Switch to `run_in_terminal` with `cat`/`grep`/`find`. |
| Can't find the code | Escalate: local search → cross-repo → ask user. |
| 3rd retry still failing | Report what was tried, what failed, and ask user for guidance. |

**Escalation ladder:** local grep → semantic search → cross-repo exploration → deeper debugging → ask user.

**Anti-pattern:** Never repeat the same failing approach. Each retry must use a different strategy.

## Engineering Guardrails

Before any code change, verify:
- [ ] **API contract** — does this change break callers? (<calling-service>, <reporter-service>, <orchestrator-service>)
- [ ] **DTO compatibility** — JSON shape changes require frontend + backend alignment
- [ ] **Backward compatibility** — driver upgrades must handle missing fields via defaults
- [ ] **Thread safety** — shared state? Singletons? Check `FeedFetcher.getInstance()` pattern
- [ ] **Performance** — N+1 queries? Large collection iteration? Unbounded results?

## Debugging Playbook

Enforce this sequence for all bugs: **reproduce → isolate → trace → fix → validate**

| Step | Action |
|------|--------|
| Reproduce | Get exact error message, HTTP status, log snippet |
| Isolate | Which layer? (Controller → Service → Driver → FTL → DB) |
| Trace | Read the code path. Check `ServerExceptionMapper` for wrapped exceptions |
| Fix | Minimal change in the correct layer |
| Validate | Run tests. Verify with `get_errors`. Evidence before claims. |

**Infra awareness:** If the bug involves HTTP routing, check nginx config (`<reverse-proxy-prefix>/<api-path>/*` → port 9101). If it involves config values, check Configuration Service integration. If it involves proxy, check `ui/dev-server/config.js`.

## PR Review Mode

Reviews must check (not just skim):
- **Correctness** — does the logic actually solve the stated problem?
- **Edge cases** — null, empty, boundary, concurrent, missing entity
- **Performance** — N+1 queries, unbounded loops, large payloads
- **Maintainability** — single responsibility, clear naming, no dead code
- **Architecture** — correct layer, no boundary violations, driver-api consistency
- **Security** — input validation, no hardcoded credentials, RBAC on endpoints

Output: `APPROVE` or `REQUEST CHANGES` with categorized findings (Critical/Major/Minor/Good).

## Cross-Repo Awareness

When task references code outside the current repo:
1. **Check memory first:** Read `memory-bank/cross-repo/<repo>.md` — if the answer is cached, use it
2. **Fallback to exploration:** If no cache or stale, use `cross-repo-exploration` skill
3. **Persist findings:** After exploration, write/update the knowledge file
- ALL IDE file tools are workspace-restricted — they WILL fail on sibling repos
- Use ONLY `run_in_terminal` with `cat`, `grep`, `find`, `ls`
- Sibling repos: `%COPILOT_WORKSPACE_ROOT%\<repo>` — use `cross-repo-exploration` skill
- Auto-detect: if a class, endpoint, or service name isn't found locally, check memory then sibling repos before giving up

## Parallel Execution

Trigger `dispatching-parallel-agents` when:
- 3+ independent failures across different modules
- Multiple unrelated tasks requested simultaneously
- Build failures in separate modules with distinct root causes

**Safety:** Never parallelize tasks that touch the same file or module. Shared modules (driver-api, service) are sequential-only.

## Performance Rules

- Read only task-relevant codebase docs — never all 7
- `grep_search` for exact symbols, `semantic_search` for concepts
- Batch file reads
- Don't repeat context already in conversation
- Tables and bullets over prose
- Evidence before claims — run commands before saying "done"
