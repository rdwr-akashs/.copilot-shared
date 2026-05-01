---
name: prompt-boost
description: 'Rewrites vague, incomplete, or ambiguous user prompts into structured, actionable requests before routing to agents. Activates automatically when a prompt lacks clear intent, scope, or actionable detail. Triggers: unclear request, vague prompt, missing context, ambiguous task, "do something with", "fix stuff", "make it work", "improve this", single-word requests.'
---

# Prompt Boost — Intelligent Prompt Refinement

Transforms unclear user input into a structured, actionable prompt that agents can execute precisely. This is NOT a conversational clarification loop — it is a single-pass rewrite that preserves the user's intent while adding structure.

## When This Skill Activates

The orchestrator triggers prompt-boost **before classification** when the user's message matches **2 or more** of these vagueness signals:

| Signal | Examples |
|--------|----------|
| **No verb or action word** | "the login page", "BGP config" |
| **No scope boundary** | "fix everything", "improve the code", "make it better" |
| **Ambiguous referent** | "it doesn't work", "this is broken", "do that thing" |
| **Single-word or ultra-short** | "refactor", "tests", "performance" |
| **No success criteria** | "make it faster" (how fast?), "clean this up" (what's dirty?) |
| **Mixed concerns in one sentence** | "fix the bug and also add pagination and maybe update the docs" |

**Do NOT activate for prompt refinement when:**
- The prompt is already clear and actionable (has verb + object + scope)
- The prompt is a follow-up in an ongoing conversation with established context
- The prompt is a simple question ("what does this function do?")

**When user names an `@agent` explicitly:**
- **Skip agent resolution** — the user has pre-selected the agent
- **Still run skill chain + instruction resolution** — the agent needs its tools
- **Still refine the prompt** if it's vague (2+ signals) — `@debugger fix it` is still vague

## Rewrite Process (Single-Pass — No User Round-Trip)

### Phase 1: Extract Intent

Parse the raw prompt and identify:

```
INTENT:    What does the user want? (build / fix / investigate / review / plan / test / explore)
OBJECT:    What thing? (file, module, endpoint, feature, bug, service)
SCOPE:     How much? (single file, module, cross-module, cross-repo)
CONTEXT:   What's the current state? (error message, file open in editor, recent changes)
CRITERIA:  What does "done" look like? (compiles, tests pass, PR-ready, design doc)
```

### Phase 2: Infer Missing Pieces

For each missing element, infer from available context:

| Missing | Inference Source |
|---------|-----------------|
| **Object** | Current file open in editor, recent terminal output, conversation history |
| **Scope** | If object is a single file → Fast mode. If object is a module/feature → Deep mode |
| **Context** | Check `get_errors` output, recent git diff, `.github/repo-cache.md` |
| **Criteria** | Default: "compiles, passes existing tests, follows project conventions" |

### Phase 3: Rewrite

Produce a **boosted prompt** in this format:

```
[Boosted Prompt]
ACTION:   <verb> — what to do
TARGET:   <specific file/module/feature>
SCOPE:    <boundary — what's in, what's out>
CONTEXT:  <current state — errors, recent changes, relevant background>
CRITERIA: <definition of done>
AGENT:    <best-fit agent from routing table>
SKILLS:   <ordered list of skills to chain>
INSTRUCTIONS: <instruction files to load>
ORIGINAL: <user's raw prompt, preserved verbatim>
```

### Phase 3.5: Auto-Attach Resources

After rewriting, automatically resolve the agent, skills, and instructions the task needs. **Do not leave this to downstream classification — pre-compute it here.**

#### Agent Resolution

Match the boosted ACTION + TARGET against the orchestrator routing table:

| Intent Pattern | Agent | Mode |
|----------------|-------|------|
| Build / implement / create new feature | `squadleader` | Deep |
| Fix / debug / error / broken | `debugger` → `developer` | Deep |
| Review code / PR | `reviewer` | Deep |
| Plan / design / architecture | `principal-engineer` | Deep |
| Write tests / coverage | `tester` | Fast/Deep |
| Build failure / CI / Docker | `devops` | Fast |
| UI / React / frontend component | `expert-react-frontend-engineer` | Fast/Deep |
| Full-stack (Java + React) | `full-stack-feature` | Deep |
| Customer case / support bundle / RCA | `case-investigator` | Deep |
| ES query / mapping / index | `elasticsearch-expert` | Deep |
| Akka actor / dead letters | `akka-expert` | Deep |
| Performance / slow / latency | `perf-investigator` | Deep |
| Write story / Jira ticket | `story-writer` | Fast |
| Simple single-file edit | Fast-path (no agent) | Fast |
| 3+ independent tasks | `dispatching-parallel-agents` | Deep |

#### Skill Chain Resolution

Based on the resolved intent, attach the skill chain in execution order:

| Intent | Skill Chain (in order) |
|--------|----------------------|
| **New feature** | `brainstorming` → `writing-plans` → `adding-rest-endpoints` (if API) → `tdd-java` or `tdd-react` → `verification-before-completion` → `commit-push` |
| **Bug fix** | `systematic-debugging` → `log-analysis` (if logs involved) → `verification-before-completion` → `commit-push` |
| **Code review** | `requesting-code-review` or `receiving-code-review` → `handling-pr-review-comments` → `verification-before-completion` |
| **Test writing** | `tdd-java` or `tdd-react` → `java-test-coverage` (if coverage gap) → `verification-before-completion` |
| **Customer case** | `customer-case-intake` → `case-archive` (lookup) → `support-file-triage` → `rca-evidence-mapping` → `rca-document` → `case-archive` (write) → `save-learning` |
| **Cross-repo investigation** | `cross-repo-exploration` or `remote-repo-exploration` → `systematic-debugging` → `verification-before-completion` |
| **Dependency upgrade** | `dependency-upgrade` → `verification-before-completion` → `commit-push` |
| **Performance issue** | `systematic-debugging` → `log-analysis` → `verification-before-completion` |
| **ES / RabbitMQ / Akka** | `elasticsearch-debug` / `rabbitmq-debug` / `akka-debug` → `verification-before-completion` |
| **Planning / design** | `brainstorming` → `writing-plans` |
| **Multi-task (3+)** | `dispatching-parallel-agents` → `subagent-driven-development` |
| **Any task finishing** | Always append `verification-before-completion` as the final skill |

#### Instruction Resolution

Attach the instruction files the agent needs to read based on what the task touches:

| Task touches | Instructions to load |
|--------------|---------------------|
| Any code change | `instructions-local/cli-commands.instructions.md` + `instructions-local/project-rules.instructions.md` |
| Java backend | `instructions/java-conventions.instructions.md` |
| React frontend | `instructions/react-conventions.instructions.md` |
| Architecture / design | `instructions/design-principles.instructions.md` |
| Performance concern | `instructions/performance-awareness.instructions.md` |
| TDD / testing | `instructions/tdd.instructions.md` |
| Customer case / RCA | `instructions/customer-case-rca.instructions.md` |
| Memory / learning | `instructions/memory-bank.instructions.md` |
| Terminal / shell commands | `instructions/shell.instructions.md` |
| Skill creation | `instructions/agent-skills.instructions.md` |
| Cross-repo | `instructions/copilot-local.instructions.md` (for workspace context) |

### Phase 4: Announce and Proceed

Display to the user:

> **[Prompt Boost]** I interpreted your request as:
> *<one-sentence rewrite>*
>
> **Agent:** `<agent>` | **Skills:** `<skill1>` → `<skill2>` → ... | **Instructions:** `<list>`
>
> Say "no, I meant..." to correct.

Then immediately proceed with the boosted prompt — do NOT wait for confirmation unless confidence is below 50%.

## Rewrite Examples

### Example 1: Ultra-vague
**Raw:** "fix it"
**Boosted:**
```
ACTION:   Fix the compilation/runtime error
TARGET:   <current file from editor context>
SCOPE:    Single file (Fast mode)
CONTEXT:  get_errors shows: <actual errors>
CRITERIA: File compiles, no errors in get_errors output
AGENT:    debugger → developer
SKILLS:   systematic-debugging → verification-before-completion
INSTRUCTIONS: instructions-local/cli-commands.instructions.md, instructions-local/project-rules.instructions.md
```

### Example 2: Broad scope, no specifics
**Raw:** "improve performance"
**Boosted:**
```
ACTION:   Investigate and fix performance bottlenecks
TARGET:   <module inferred from repo-cache.md recent context>
SCOPE:    Current module — profile before optimising
CONTEXT:  No specific error reported; start with profiling
CRITERIA: Measurable improvement with before/after metrics
AGENT:    perf-investigator
SKILLS:   systematic-debugging → log-analysis → verification-before-completion
INSTRUCTIONS: instructions/performance-awareness.instructions.md, instructions-local/cli-commands.instructions.md
```

### Example 3: Mixed concerns
**Raw:** "fix the bug and add pagination and update docs"
**Boosted:** Split into 3 independent tasks → route to `dispatching-parallel-agents`:
```
AGENT:    dispatching-parallel-agents (meta-skill)
SKILLS:   dispatching-parallel-agents → subagent-driven-development

Task 1: Fix bug — <inferred from recent errors>
  AGENT: debugger | SKILLS: systematic-debugging → verification-before-completion
Task 2: Add pagination — <inferred from context>
  AGENT: developer | SKILLS: adding-rest-endpoints → tdd-java → verification-before-completion
Task 3: Update documentation — <scope TBD after tasks 1-2>
  AGENT: developer | SKILLS: verification-before-completion → commit-push
```

### Example 4: Jargon shorthand
**Raw:** "BGP standby"
**Boosted:**
```
ACTION:   Investigate BGP peer state on standby node
TARGET:   BGP subsystem (ExaBGP config, BgpPeer table, PeersUpdateWorker)
SCOPE:    HA standby behaviour — cross-reference active vs standby support files
CONTEXT:  Likely customer case or debugging scenario
CRITERIA: Root cause identified with evidence from logs/config
AGENT:    case-investigator
SKILLS:   customer-case-intake → support-file-triage → rca-evidence-mapping → rca-document → save-learning
INSTRUCTIONS: instructions/customer-case-rca.instructions.md, instructions/memory-bank.instructions.md
```

### Example 5: Terse test request
**Raw:** "tests for UserService"
**Boosted:**
```
ACTION:   Write unit tests for UserService
TARGET:   UserService.java (service layer)
SCOPE:    All public methods — happy path + edge cases
CONTEXT:  Existing test file: UserServiceTest.java (check coverage gaps)
CRITERIA: All tests green, branch coverage ≥80%
AGENT:    tester
SKILLS:   tdd-java → java-test-coverage → verification-before-completion
INSTRUCTIONS: instructions/tdd.instructions.md, instructions/java-conventions.instructions.md, instructions-local/cli-commands.instructions.md
```

## Confidence Scoring

After rewriting, self-assess:

| Confidence | Behaviour |
|------------|-----------|
| **High (>80%)** | Announce rewrite, proceed immediately |
| **Medium (50-80%)** | Announce rewrite with "Say 'no, I meant...' to correct", proceed |
| **Low (<50%)** | Ask ONE clarifying question (max), then proceed with best guess |

**Never ask more than one question.** The goal is to unblock, not interrogate.

## Integration with Orchestrator

This skill runs as **Step 0.5** in the orchestrator pipeline:

```
User message → Step 0 (Cache) → Step 0.5 (Prompt Boost, if needed) → Step 1 (Classify) → ...
```

The boosted prompt replaces the raw prompt for all downstream steps (classification, agent selection, skill selection).

## Anti-Patterns — Do NOT

- ❌ Turn a clear prompt into a longer one (no boost needed)
- ❌ Add requirements the user didn't ask for
- ❌ Change the user's intent — only add structure
- ❌ Ask multiple clarifying questions — one max, then proceed
- ❌ Activate on follow-up messages in an ongoing conversation
