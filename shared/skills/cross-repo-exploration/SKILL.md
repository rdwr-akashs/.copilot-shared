---
name: cross-repo-exploration
description: Use when you need to read, search, or understand code in sibling repositories outside the current workspace — covers <sibling-repo>, <orchestrator-repo>, <core-lib-repo>, webui_components, and other repos under the workspace root
---

# Cross-Repo Exploration

> **⚡ This skill prioritizes silent, non-intrusive execution to avoid IDE disruption.** Minimize terminal popups, avoid stealing focus, and batch operations to reduce UI interruptions.

## Activation Rule

**Triggers:**
- Need to read, search, or understand code in a sibling repository (not the current repo)
- Tracing an API contract to its caller/callee in another service
- Implementing a cross-service feature (PE ↔ <calling-service>, this project ↔ <orchestrator-service>)
- Checking DTO shapes or endpoint signatures in a consuming/producing service

> **Override Directive:** This skill overrides default behavior when its conditions are met. ALL file tools except `run_in_terminal` will fail on sibling repos.

## Overview

The <product-suite> ecosystem spans multiple repositories under a shared workspace root. When working on cross-service features, you need to read and search code in sibling repos that are **not** part of the current IDE workspace.

**Core principle:** All sibling repos live under `%COPILOT_WORKSPACE_ROOT%\`. The IDE tools (`list_dir`, `read_file`, `file_search`, `grep_search`, `semantic_search`) are **workspace-restricted** and WILL FAIL on any path outside the current repo. Use `run_in_terminal` for ALL cross-repo access.

In examples below, substitute `<REPO>` with the actual repo name (e.g., `<sibling-repo>`). Full path: `%COPILOT_WORKSPACE_ROOT%\<REPO>`.

## Critical Constraint

> ⚠️ **ONLY `run_in_terminal` works for sibling repos.** All other file tools throw "Path is outside of workspace folders". This is an IDE sandbox restriction, not a filesystem permission issue.

| Tool | Works Cross-Repo? | Notes |
|---|---|---|
| `run_in_terminal` | ✅ YES | **The ONLY tool for cross-repo access** |
| `list_dir` | ❌ NO | Workspace-restricted |
| `read_file` | ❌ NO | Workspace-restricted |
| `file_search` | ❌ NO | Workspace-restricted |
| `grep_search` | ❌ NO | Workspace-restricted |
| `semantic_search` | ❌ NO | Indexes current workspace only |

## When to Use

**Use when:**
- Implementing a feature that spans this project and another service (`kvision_cyber_controller_core`, `df_core`, `kvision_configuration_service`, `kvision_vrm`, etc.)
- Tracing an API contract to see how the caller/callee implements it
- Understanding DTOs, endpoints, or DB schemas in a sibling service
- Checking how a shared library (`kvision_libs`, `vision_libs`, `webui_components`) is used
- Verifying integration points before writing code

**Don't use when:**
- All the code you need is inside the current repo
- You only need public API docs (check Confluence/Swagger first)

## Available Repositories

All repos live under the workspace root: **`%COPILOT_WORKSPACE_ROOT%\`**

**Full repo list:** `shared/memory/tech-discoveries.md` → Repo Registry section  
**Category filter guide:** `shared/skills/remote-repo-exploration/references/repo-categories.md`

Most commonly accessed repos for cross-repo work:

| Repository | Description |
|---|---|
| `df_core` | DefenseFlow core — HA, BGP, protection policies |
| `kvision_cyber_controller_core` | Vision Cyber Controller — main orchestration product |
| `kvision_configuration_service` | Configuration Service — RBAC, config proxy |
| `kvision_vrm` | Vision Reporter Module |
| `kvision_deploy` | Deployment orchestration |
| `kvision_ha_orchestrator` | HA orchestrator |
| `kvision_libs` | Shared Java libraries |
| `vision_libs` | Shared Java libraries (vision) |
| `kvision_manifest` | Service manifest definitions |
| `kvision_upgrade` | Upgrade service |
| `kvision_webui` | Main Vision web UI shell |
| `webui_components` | Shared UI design system |

> **Tip:** Run `ls "$COPILOT_WORKSPACE_ROOT"` to see all locally cloned repos.  
> For repos NOT cloned locally, use `remote-repo-exploration` skill instead.

## Terminal Commands Reference

> See [terminal-commands.md](./references/terminal-commands.md) for the full shell command reference (directory listing, single/batch file reads, code search, config files, build/test, entry-point detection, and question→command mapping).

> **Complex command?** Use `gh copilot suggest` to generate it rather than hand-crafting:
> ```bash
> gh copilot suggest "recursively find all Spring @FeignClient interfaces in a Java repo"
> ```

## Cross-Repo Exploration Pattern

Follow this sequence when exploring a sibling repo for integration work:

### Step 1: Orientation (1 terminal call)
```bash
# Repo root + package layout in one call
ls "%COPILOT_WORKSPACE_ROOT%\<REPO>" && \
echo "=== Java packages ===" && \
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java" -type d
```

### Step 2: Find Entry Points (1 terminal call)
```bash
# REST controllers + service classes + key patterns — all in one grep
grep -rn "@RestController\|@Service\|class.*Service\|interface.*Service" \
  "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" -l
```

### Step 3: Read and Trace (batch reads)
```bash
# Read all relevant files in one call
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\ControllerA.java" && \
echo "=====" && \
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\ServiceA.java" && \
echo "=====" && \
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\RepositoryA.java"
```

### Step 4: Map DTOs (batch)
```bash
# Read all DTOs in a package at once
for f in "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\dto"/*.java; do
  echo "===== $f ====="; cat "$f"
done
```

### Step 5: Check Config (batch)
```bash
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\resources" -type f | \
  xargs -I{} sh -c 'echo "===== {} ====="; cat "{}"'
```

### Step 6: Document Findings
Record key discoveries in the memory bank (`activeContext.md`, plan files) so future sessions don't repeat the exploration.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Architect (PEplan)** | Primary user — explores sibling repos during design phase |
| **Developer** | Uses when implementing cross-service integration features |
| **Debugger** | Traces bugs across service boundaries |
| **Reviewer** | Validates API contract compatibility with callers |

## Decision Heuristics

- **Use this skill** when ANY code outside the current repo is needed
- **Don't use** when all code is within the current workspace
- **Combine with `brainstorming`** when designing cross-service features
- Example: "Check how <calling-service> calls this project's template API" → use this skill
- Example: "Fix a bug in <DomainService>" → don't need this skill
- Example: "Verify DTO contract with Configuration Service" → use this skill

## Quick Start

1. **Check memory first** — read `memory-bank/cross-repo/<repo>.md` if it exists
2. **Start with a specific question** — not "explore repo X"
3. **L1 contract scan** — controllers, DTOs, config (1 terminal call)
4. **Read only what answers the question** — stop at L1 if sufficient
5. **Persist findings** — write to `memory-bank/cross-repo/<repo>.md`
6. **Produce summary** — feed into design doc

## Prompt Template

```
I need to check how [service] calls/uses [feature].
Repository: [repo name from Available Repositories table]
Use the cross-repo-exploration skill.
```

## Performance Guidelines

- **Always batch** file reads into a single `run_in_terminal` call with `&&` + `echo "====="` delimiters
- **Limit output** — pipe through `| head -N` when exploring large trees
- **Use `-l` flag** on grep to list matching files before reading them
- **Document findings** in memory bank to avoid re-exploration in future sessions

## Silent Execution Strategy

Prefer background execution (`isBackground: true`) for non-critical, exploratory commands. Reserve foreground execution only when you need to read the output immediately for a decision.

**Patterns:**
- Use `isBackground: true` on `run_in_terminal` for discovery scans, directory listings, and multi-file reads where results can be fetched later via `get_terminal_output`
- For long-running or noisy commands (builds, large greps), append `2>/dev/null` to suppress stderr noise
- Never run exploratory commands in foreground if the output isn't needed in the very next reasoning step

## Non-Interruptive Behavior Rule

Avoid opening or switching focus to the terminal unless:
- Output is **critical for an immediate decision** (e.g., choosing which file to read next)
- **Debugging** requires visible, real-time logs

For all exploration and discovery steps (orientation, finding entry points, mapping DTOs), use background execution and retrieve output afterward. The goal is zero IDE focus-stealing during routine exploration.

## Batch + Single Invocation Rule

Combine multiple file reads, searches, and directory listings into a **single `run_in_terminal` call**. Each terminal invocation may trigger an IDE popup — fewer calls means fewer interruptions.

**Examples of good batching:**
```bash
# BAD: 3 separate terminal calls
# Call 1: ls "%COPILOT_WORKSPACE_ROOT%\<REPO>"
# Call 2: grep -rn "@Service" ...
# Call 3: cat "...\ServiceA.java"

# GOOD: 1 terminal call
ls "%COPILOT_WORKSPACE_ROOT%\<REPO>" && \
echo "=== Services ===" && \
grep -rln "@Service" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" && \
echo "=== ServiceA.java ===" && \
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\ServiceA.java"
```

Target: **≤3 terminal calls** for a typical cross-repo exploration session (orient → search → read).

## Minimal Output Strategy

Large outputs trigger terminal focus and cause lag. Always constrain output size:

| Technique | When to use |
|-----------|-------------|
| `\| head -N` | Exploring trees, large grep results |
| `grep -l` (files only) | Finding which files match before reading |
| `grep -m 5` | Limiting matches per file |
| `sed -n '50,100p'` | Reading specific line ranges instead of full files |
| `wc -l` | Counting results before dumping them |
| `2>/dev/null` | Suppressing stderr noise from permission errors, etc. |

**Rule:** If a command might produce >100 lines, always pipe through `| head` or use `-l`/`-m` flags first.

## Foreground vs Background Decision Rule

| Scenario | Execution Mode | Reason |
|----------|---------------|--------|
| Exploring directory structure | **Background** | Results fetched later; no urgency |
| Scanning for files/patterns | **Background** | Discovery step; output reviewed async |
| Reading multiple files (batch) | **Background** | Large output; fetch when ready |
| Reading a single critical file for immediate decision | **Foreground** | Need output in next reasoning step |
| Debugging a specific failure | **Foreground** | Real-time visibility required |
| Running builds or tests | **Background** | Long-running; check status later |

## Performance + UX Optimization Note

- **Minimize terminal invocation frequency** — each call may flash a terminal window
- **Prefer fewer, larger commands** over many small ones
- **Avoid repeated small commands** — plan what you need, then execute once
- **Cache results mentally** — don't re-run the same grep/find if the output is already in conversation context
- **Use `get_terminal_output`** to retrieve background results instead of re-running commands

## Common Mistakes

**Using `read_file`, `list_dir`, etc. for sibling repos:** These WILL fail with "Path is outside of workspace folders". Always use `run_in_terminal` with `cat`, `ls`, `find`, `grep`.

**One file per terminal call:** Costly. Batch related reads with `&&` and `echo "====="` delimiters — read 5 files in one call instead of five calls.

**Forgetting to limit output:** `find` or `grep -r` on large repos produces huge output. Pipe through `| head -N` when exploring, use `-l` flag to list files before reading them.

**Not documenting findings:** Cross-repo exploration is expensive. Always record key discoveries (API contracts, DTO shapes, service flows) in memory bank files so the next session doesn't redo the work.

**Editing sibling repo files without permission:** Confirm with the user first — they may have a separate workspace or branch strategy for that repo.

## Knowledge Persistence

Cross-repo exploration is expensive. **Always check memory before running terminal commands.**

### Memory Location

Store cross-repo findings in `memory-bank/cross-repo/` with one file per repo:
- `memory-bank/cross-repo/<sibling-repo>.md`
- `memory-bank/cross-repo/<orchestrator-repo>.md`
- etc.

### Memory-First Workflow

1. **Before exploring:** Check if `memory-bank/cross-repo/<repo>.md` exists and has the answer
2. **If yes:** Use cached knowledge — skip terminal commands entirely
3. **If no or stale:** Run exploration, then persist findings

### What to Persist

Each repo memory file follows this standard format:

```markdown
# <Service Name> — Cross-Repo Knowledge
**Last updated:** [date]
**Repo:** `%COPILOT_WORKSPACE_ROOT%\<repo_name>`

## Service Overview
- [One-sentence description of what this service does]
- [Its role in the <product-suite> ecosystem]

## this project-Facing APIs
| Method | URL | Purpose | Request Shape | Response Shape |
|--------|-----|---------|--------------|----------------|
| POST | /path | [what it does] | `{ field: type }` | `{ field: type }` |

## Key DTOs
| Class | Package | Fields | Used By |
|-------|---------|--------|---------|
| [Name] | [package] | [key fields] | [which service method] |

## Service-to-Service Interactions
- **Calls this project via:** [client class, connection method]
- **Connection config:** [property file, URL pattern, port]
- **Auth method:** [how it authenticates]

## Business Rules & Constraints
- [Ordering requirements, naming conventions, required fields]
- [Any this project-specific behavior this service expects]

## Known Quirks
- [Gotchas, edge cases, undocumented behavior]
```

**Rule:** If the same cross-repo question has been answered before, the answer is in memory. Don't re-explore.

### Knowledge Refresh Rule

Knowledge files can go stale. Refresh when:
- **Mismatch detected:** terminal output contradicts cached knowledge (e.g., DTO field missing, endpoint changed)
- **User reports change:** "<calling-service> updated their API"
- **Major version bump:** sibling repo is on a new release branch

**How to refresh:**
1. Re-run the L1 contract scan (controllers + DTOs + config)
2. Diff against the existing knowledge file
3. Update only the changed sections
4. Update the `**Last updated:**` date

**Don't refresh proactively** — only when triggered by a mismatch or explicit request.

## Contract-First Exploration

When exploring a sibling repo, **prioritize integration contracts over internal logic:**

1. **APIs first** — REST controllers, endpoint signatures, HTTP methods
2. **DTOs second** — request/response shapes, field names and types
3. **Config third** — connection URLs, ports, property files
4. **Service logic last** — only if understanding the contract requires it

**Anti-pattern:** Don't read internal service implementations, repositories, or utility classes unless the API/DTO layer doesn't answer your question.

## Exploration Depth Control

Not every cross-repo task requires deep exploration. Match depth to the question:

| Level | What to Read | When |
|-------|-------------|------|
| **L1: Contract** (default) | Controllers, DTOs, config properties | Verifying API shape, checking compatibility |
| **L2: Service** | Service classes, business logic | Understanding how a caller processes our response |
| **L3: Deep** | Repositories, utilities, FTL templates | Debugging cross-service bugs, tracing data flow |

**Start at L1. Only go deeper if L1 doesn't answer the question.** Most integration work only needs L1.

### L1 Command Pattern (1 terminal call)
```bash
# Find controllers + DTOs in one call
grep -rln "@RestController\|@Path\|class.*Dto\|class.*Request\|class.*Response" \
  "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" | head -20
```

### L2 Command Pattern (if L1 insufficient)
```bash
# Find service classes that use this project
grep -rln "<domain-keyword-1>\|<domain-keyword-2>" \
  "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java"
```

## Targeted Exploration Rule

> **Never start with a generic repo-wide scan.** Always begin with a specific question.

**Good:** "What endpoint does <calling-service> call to create a PO template?"
→ `grep -rn "<entity-keyword-1>\|<entityKeyword2>" "%COPILOT_WORKSPACE_ROOT%\<sibling-repo>\src" --include="*.java" -l`

**Bad:** "Let me explore the <calling-service> codebase"
→ `find "%COPILOT_WORKSPACE_ROOT%\<sibling-repo>\src" -type f` ← wastes context

### Question → Command Mapping

| Question | Command |
|----------|---------|
| What endpoint does X call on this project? | `grep -rn "<api-keyword>\|<api-base-path>" <REPO>/src --include="*.java"` |
| What DTO shape does X send to this project? | Find the client class first, then read its request builder |
| How does X authenticate with this project? | `grep -rn "Authorization\|Bearer\|token\|auth" <REPO>/src --include="*.java" -l` |
| What config connects X to this project? | `grep -rn "<api-keyword-1>\|<api-keyword-2>" <REPO>/src/main/resources -r` |

## Post-Exploration Integration

After completing exploration, **always produce a summary usable as design input:**

```markdown
## Cross-Repo Finding: [repo] → [topic]

**Question:** [what was investigated]
**Answer:** [concise finding]

**Integration Impact on this project:**
- [How this affects our design/implementation]
- [Contract constraints we must respect]
- [Breaking change risks]

**Action Items:**
- [What this project needs to do based on this finding]
```

This summary feeds directly into the `[Design]` block of the orchestrator output.

## Over-Exploration Guardrail

**Stop exploring once you can answer these three questions:**

1. **What endpoint/method does the other service call on this project?** (or vice versa)
2. **What is the request/response DTO shape?**
3. **Are there any constraints this project must respect?** (auth, ordering, required fields)

If all three are answered → stop. Don't read more files. Don't trace deeper. Write the summary and move to design.

**Signs of over-exploration:**
- Reading >10 files from a sibling repo
- Exploring internal utilities or helper classes
- Reading test files from sibling repos
- Running >3 terminal commands for a single question

## Entry Point Detection (Optimized)

When you don't know where to start in a sibling repo, prioritize in this order:
`Controller → DTO/Model → Client/WebClient → Config → Service (last resort)`

Use the **One-Shot Entry Point Command** and **Question → Command Mapping** table from [terminal-commands.md](./references/terminal-commands.md).

## Inter-Skill References

- **For repos NOT available locally** → `remote-repo-exploration` (uses Bitbucket API + shallow clones)
- **For broad multi-repo searches (10+ repos)** → `remote-repo-exploration` with parallel subagent dispatch
- **After exploration** → `brainstorming` or `writing-plans` to design the integration
- **For implementation** → `adding-rest-endpoints` if exposing new API contracts
- **For debugging** → `systematic-debugging` when tracing cross-service issues
