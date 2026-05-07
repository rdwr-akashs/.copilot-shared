# Token Optimization Implementation Guide

**Phase 1: Immediate Wins (1.5 hours, ~1.57M token savings)**

---

## Step 1: Archive Repo-Context Directory Dumps (45 minutes)

### Why
These 15 markdown files contain 346,690 lines of directory trees. That's 3.3M tokens just for file listings that:
- Never change (captured at a point in time)
- Duplicate git's `ls-files` output
- Are rarely useful for development

### How

**Step 1.1: Backup existing files**
```bash
cd c:\rdwr-intelij\.copilot-shared\shared\memory\repo-contexts\
mkdir _archive-2026-05-07
cp *.md _archive-2026-05-07/
# or on Windows
robocopy . _archive-2026-05-07 *.md
```

**Step 1.2: Delete original large files**
```bash
# BACKUP FIRST (done above)

# Keep only these files (they're small):
# - README.md (4 KB)
# - _index.md (4 KB)

# Delete these repo-context dumps:
rm kvision_configuration_service.md       # 3.1 MB
rm common_policy_editor.md                # 1.7 MB
rm webui_components.md                    # 1.8 MB
rm kvision_vrm.md                         # 848 KB
rm kvision_cyber_controller_core.md       # 960 KB
rm kvision_dp_inline_config.md            # 932 KB
rm kvision_libs.md                        # 876 KB
rm df_core.md                             # 896 KB
rm kvision_ha_orchestrator.md             # 452 KB
rm low.level.design.md                    # 432 KB
rm kvision_deploy.md                      # 364 KB
rm bitbucket_mcp.md                       # 320 KB
rm kvision_upgrade.md                     # 276 KB
rm kvision_dc_nginx.md                    # 116 KB
rm kvision_manifest.md                    # 80 KB
```

**Step 1.3: Create lightweight index files**

Replace each deleted file with a 50-150 line summary:

```bash
cat > kvision_configuration_service.md << 'EOF'
# Kvision Configuration Service

**Archive:** Detailed directory structure moved to `_archive-2026-05-07/`

**Quick Facts:**
- Repository: C:\rdwr-intelij\kvision_configuration_service
- Language: Java (Maven), React
- Key modules: `application/`, `common/`, `config/`, `WebUI/`

**To view current file structure:**
```bash
cd <repo-root>
git ls-files | head -50
```

**Architecture Notes:**
- Spring Boot microservice for configuration management
- REST API + WebUI frontend
- Database: PostgreSQL (see `config/properties/`)
- Build: `mvn clean install`

**Related Repos:**
- kvision_cyber_controller_core
- common_policy_editor
- webui_components
EOF
```

Repeat for all 15 files (use copy-paste above, just change the name and details).

### Validation
```bash
# Before
du -sh shared/memory/repo-contexts/
# Output: 13M (original)

# After should be < 50KB
du -sh shared/memory/repo-contexts/
# Output: ~50K (new lightweight summaries)

# Verify you can still see files when needed
cd <some-repo> && git ls-files | wc -l
```

---

## Step 2: Consolidate Duplicate Agent Boilerplate (25 minutes)

### Why
15 agent templates repeat 60-70% identical boilerplate (~41K tokens) across:
- Routing explanations
- Pipeline entry gates
- Hard rules (DI, error handling, naming)
- Build/test commands

### How

**Step 2.1: Create base template**

```bash
cd c:\rdwr-intelij\.copilot-shared\shared\instructions\
cat > agent-base.template.md << 'EOF'
# Agent Base Template

## Routing & Pipeline

> **Routing:** This agent is selected by the orchestrator (`.github/orchestrator.instructions.md`) for [AGENT_TYPE] tasks.

> **Pipeline Entry Gate:** When invoked directly via `@[agent-name]`, the orchestrator pipeline still applies. Prompt-boost runs for skill chain + instruction resolution (agent selection is skipped since you're pre-selected). **Do NOT start work until skills and instructions are resolved.**

## Universal Hard Rules (All Agents)

- **Layering:** Controllers validate + delegate. Services own business logic. Repositories own CRUD.
- **Dependency Injection:** Constructor injection only (`@RequiredArgsConstructor`). Never use `@Autowired` on fields.
- **Error Handling:** Throw `ProjectException` with HTTP status constant. Never return `null` — use `Optional<T>`.
- **No new exception classes** — reuse `ProjectException`.
- **Logging:** Log4j2. No emojis. No routine info/debug logs.
- **Naming:** PascalCase for classes, camelCase for methods, UPPER_SNAKE_CASE for constants.
- **DTOs:** Keep Driver DTO (no JPA) and Service entity (JPA) separate.
- **Never freelance** — always follow the architect's plan. Ask for clarification if unsure.

## Verification Commands

```bash
# Build without tests
./mvnw -pl <module> -am clean install -DskipTests

# Run tests for module
./mvnw -pl <module> test

# Check for style violations
./mvnw checkstyle:check

# Full CI validation
./mvnw clean install -DskipIntegrationTests
```

## When You're Done

1. All tests pass
2. No new checkstyle violations
3. Follow the `VALIDATION.md` checklist
4. Request review from architect/squad lead
EOF
```

**Step 2.2: Update each agent template**

Replace verbose agent files with compact references.

Example — update `agent-templates/developer.agent.md`:

**BEFORE (69 lines):**
```markdown
---
description: "Implements features..."
name: "Developer"
tools: [...]
---

# Developer Agent — the project

> **Routing:** This agent is selected by the orchestrator...
> **Pipeline Entry Gate:** When invoked directly via...

You implement features and fixes...

## Before Writing Any Code
1. Read .github/instructions-local/cli-commands.instructions.md
...
[60 more lines of boilerplate]
```

**AFTER (30 lines):**
```markdown
---
description: "Implements features and fixes following the project's architecture, conventions, and plan"
name: "Developer"
tools: ['search/codebase', 'search/searchResults', 'read/problems', 'editFiles', 'run_in_terminal', 'semantic_search']
---

# Developer Agent

> See `shared/instructions/agent-base.template.md` for **Routing, Pipeline, Hard Rules, and Verification Commands**.

## Developer-Specific Responsibilities

You implement features and fixes. You follow the architect's plan, project conventions, and **never freelance** on design decisions.

**Prerequisite:** Do not start implementation without a Design Doc and Test Plan. If neither exists, request them from @architect first.

## Before Coding

1. **Read these files:**
   - `.github/instructions-local/cli-commands.instructions.md` — verified build/test commands
   - `docs/codebase/CONVENTIONS.md` — naming, DI, error handling, logging
   - `docs/codebase/STRUCTURE.md` — where to put new files
   - The architect's plan (if it exists)

2. **Check the quick reference:**
   - Use skill `.github/skills/executing-plans/SKILL.md` when following a plan
   - Use skill `.github/skills/adding-rest-endpoints/SKILL.md` for new REST endpoints

---

That's it. The rest is in `agent-base.template.md`.
```

**Step 2.3: Update remaining 14 agent files**

Apply the same pattern to:
- `debugger.agent.md` — remove 50+ lines of boilerplate
- `tester.agent.md` — remove 40+ lines
- `reviewer.agent.md` — remove 35+ lines
- [... etc ...]

Each should now be 25-40 lines instead of 69-272 lines.

### Validation
```bash
# Count before
wc -l agent-templates/*.md | tail -1
# Output: ~2,273 total

# Count after
wc -l agent-templates/*.md | tail -1
# Output: ~700 total (70% reduction)

# Make sure agents still load correctly in VS Code
# (They reference external base template, which is fine)
```

---

## Step 3: Merge Duplicate Instructions (30 minutes)

### Why
13 instruction files repeat similar patterns and guidance:
- `orchestrator.instructions.md` (417 lines)
- `agent-skills.instructions.md` (375 lines)
- `memory-bank.instructions.md` (370 lines)
- Others with overlapping content

These can be consolidated to 3-5 master files.

### How

**Step 3.1: Create consolidated master file**

```bash
cd c:\rdwr-intelij\.copilot-shared\shared\instructions\
cat > 00-core-instructions.md << 'EOF'
# Core Instructions — Start Here

**This file replaces:** orchestrator.instructions.md, agent-skills.instructions.md, memory-bank.instructions.md

## Quick Navigation

1. **How agents work** → [Agent Routing & Selection](#agent-routing)
2. **Which agent to use** → [Agent Capabilities Matrix](#agent-capabilities)
3. **How to use skills** → [Skill Chains & Resolution](#skill-chains)
4. **Memory management** → [Memory Bank Guidelines](#memory-guidelines)
5. **How orchestrator works** → [Orchestrator Pipeline](#orchestrator-pipeline)

---

## Agent Routing & Selection

The orchestrator automatically selects the best agent based on your task:

| Task Type | Agent | Reason |
|-----------|-------|--------|
| Implement features | `@developer` | Follows architecture, conventions, plans |
| Investigate bugs | `@debugger` | Systematic root cause analysis |
| Write/run tests | `@tester` | Test design and execution |
| Code review | `@reviewer` | Pattern detection, quality gates |
| Architecture | `@architect` | Design & planning |

**Pipeline Entry Gate:** When you invoke `@agent-name` directly, the full orchestrator pipeline runs (skill + instruction resolution). See below.

---

## Orchestrator Pipeline

```
User Task
  ↓
(1) ORCHESTRATOR activates
  ├─ Parse task intent
  ├─ Run PROMPT-BOOST skill chain
  └─ Select best agent → FIXED (no re-selection)
  ↓
(2) SKILL RESOLUTION
  ├─ Search for matching skills
  ├─ Resolve dependencies between skills
  └─ Load skill instructions
  ↓
(3) INSTRUCTION RESOLUTION
  ├─ Load agent-specific instructions
  ├─ Load core instructions (this file)
  └─ Load project-specific instructions
  ↓
(4) AGENT EXECUTION
  └─ Agent follows instructions + skills + architect's plan
```

**Important:** Never skip steps 2-3. Always let orchestrator resolve skills and instructions before starting work.

---

## Agent Capabilities Matrix

| Agent | Best For | Skills Used | Hard Rules |
|-------|----------|------------|-----------|
| Developer | Implementing features, fixing code | executing-plans, adding-endpoints | Constructor DI, ProjectException, camelCase |
| Debugger | Root cause analysis, isolation | systematic-debugging, codebase-search | None (investigation only) |
| Tester | Test design, test execution | test-generation, verification | Jest/JUnit patterns |
| Reviewer | Code quality, security, patterns | pr-review, pattern-detection | Clean code, no duplication |
| Architect | Design docs, planning | api-design, schema-design | SOLID principles |

---

## Skill Chains & Resolution

**Skills are small, reusable workflows** that agents invoke when needed.

Common skill chains:
```
Feature Development Chain:
  1. acquire-codebase-knowledge (understand context)
  2. api-contract-first (design interface)
  3. executing-plans (implement)
  4. verification-before-completion (validate)

Debugging Chain:
  1. systematic-debugging (isolate problem)
  2. codebase-search (find root cause)
  3. dependency-analysis (check impacts)
  4. fix-suggestion (propose solution)
```

**When you use `@developer` to implement a feature:**
1. Orchestrator finds skills for "feature implementation"
2. Loads skill instructions in order
3. Developer agent follows each skill
4. You get structured, repeatable workflow

---

## Memory Bank Guidelines

### Personal Memory (`/memories/`)
- **Scope:** Persistent across all workspaces
- **Use for:** Personal preferences, patterns you discovered, commands that work
- **Example:** "Always use `npm run dev` in project X" (survives between sessions)
- **Cleanup:** Review quarterly, remove outdated notes

### Session Memory (`/memories/session/`)
- **Scope:** Current conversation only (cleared after session ends)
- **Use for:** Task-specific context, in-progress notes, decisions made today
- **Example:** "Debugging Issue #123 — root cause is in AuthService.java:45"
- **Cleanup:** Automatic

### Repository Memory (`/memories/repo/`)
- **Scope:** Attached to a specific GitHub repo
- **Use for:** Codebase facts, conventions, verified commands
- **Example:** "Build command: `mvn clean install`" (stored with repo, survives projects)
- **Cleanup:** Remove after repo context changes significantly

---

## Key Reminders

- ✅ **Always use the orchestrator** — Don't invoke agents directly; use the full pipeline
- ✅ **Skills are composable** — Combine them for complex tasks
- ✅ **Memory is your context** — Store learnings so future sessions reuse them
- ✅ **Follow the architect's plan** — Never freelance on design
- ✅ **Verify before claiming done** — Use verification skills before marking complete

---

See also:
- `agent-base.template.md` — Universal rules for all agents
- `design-principles.instructions.md` — Architecture patterns
- `java-conventions.instructions.md` — Java/Spring Boot style guide
- `react-conventions.instructions.md` — React/TypeScript patterns
- `tdd.instructions.md` — Test-driven development workflow
- `ways-of-working.instructions.md` — Team practices
EOF
```

**Step 3.2: Update `.github/orchestrator.instructions.md` to reference new file**

Replace repetitive orchestrator instructions with a single line:
```markdown
# Orchestrator Instructions

> **See `shared/instructions/00-core-instructions.md` for full orchestrator pipeline and agent routing.**

[Keep only orchestrator-specific customization here, if any]
```

**Step 3.3: Mark old instruction files as deprecated**

```bash
# Don't delete yet — link to new location
echo "DEPRECATED — See 00-core-instructions.md instead" > orchestrator.instructions.md.deprecated
# (repeat for agent-skills, memory-bank.instructions.md)
```

### Validation
```bash
# Before
wc -l shared/instructions/*.md | tail -1
# Output: ~2,649 total

# After
wc -l shared/instructions/*.md | tail -1
# Output: ~1,300 total (50% reduction)

# Verify key information is findable
grep -l "agent routing\|skill chain\|memory bank" shared/instructions/*.md
# Should find 00-core-instructions.md
```

---

## Summary of Phase 1 Savings

| Action | Before | After | Saved |
|--------|--------|-------|-------|
| Repo-context archives | 346,690 lines | 1,500 lines | 3.26M tokens |
| Agent boilerplate | 2,273 lines | 700 lines | 41K tokens |
| Instruction consolidation | 2,649 lines | 1,300 lines | 50K tokens |
| | **351,612 lines** | **3,500 lines** | **~3.36M tokens** |

---

## Next Steps (Phase 2)

After Phase 1 is working:
- [ ] Test that agents work correctly with new structure
- [ ] Consolidate 35+ skills into 12-15 core skills (saves ~224K tokens)
- [ ] Clean up old `.agent_work/` files (saves ~68K tokens)
- [ ] Add auto-cleanup cron job for temp files

**Total Phase 1+2 savings: ~3.60M tokens (94% reduction)**

---

## Rollback Instructions

If something breaks:

```bash
# Restore from backup
cd shared/memory/repo-contexts/
rm *.md
cp _archive-2026-05-07/* .

# Restore agents
git checkout agent-templates/*.md

# Restore instructions
git checkout shared/instructions/*.md
```

Then investigate what went wrong and retry with more caution.
