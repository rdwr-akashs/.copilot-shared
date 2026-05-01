---
name: remote-repo-exploration
description: Use when you need to search, read, or understand code across ALL Bitbucket repos (90+) without local clones — uses Bitbucket API and shallow git clones for fast remote exploration with parallel subagent dispatch
---

# Remote Repo Exploration

> **⚡ Speed-first design for 90+ repos.** Filter → shallow clone → grep → read. Never clone all repos. Never explore aimlessly.

## Activation Rule

**Triggers:**
- Need to find code, patterns, or usages across multiple Bitbucket repos (not just locally cloned ones)
- Searching for who calls a specific API, uses a DTO, or depends on a library
- Tracing a feature or bug across 3+ services that aren't all locally available
- User asks "which repos use X?" or "find all usages of Y across all services"
- Cross-repo exploration skill failed because the repo isn't cloned locally

> **Override Directive:** This skill overrides `cross-repo-exploration` when the target repo is NOT available locally under `%COPILOT_WORKSPACE_ROOT%\`. Use `cross-repo-exploration` for locally available repos (faster). Use THIS skill for remote-only repos or broad multi-repo searches.

## Overview

The <product-suite> ecosystem has 90+ repos in Bitbucket (<your-bb-workspace> workspace). Most are NOT cloned locally. This skill provides fast remote exploration using three tools:

1. **Bitbucket MCP API** (`mcp_bitbucket-mcp_get_file_content`) — read any file from any repo without cloning
2. **Shallow git clones** — `git clone --depth 1` to a temp dir for `grep` across a repo's code
3. **Parallel subagents** — dispatch 3-4 agents to explore repo batches simultaneously

**Core principle:** Filter aggressively first, then explore only relevant repos. Never explore all 90+ repos.

## When to Use

**Use when:**
- Target repo is NOT locally available under `%COPILOT_WORKSPACE_ROOT%\`
- Searching across 3+ repos for a pattern, class, endpoint, or dependency
- Need to find "who uses X" across the entire ecosystem
- Investigating a cross-service integration with remote-only repos
- Mapping dependencies or API contracts across the platform

**Don't use when:**
- Target repo IS locally cloned — use `cross-repo-exploration` skill instead (faster, no network)
- Only need one specific file from one known repo — use `mcp_bitbucket-mcp_get_file_content` directly
- Exploring only within the current repo — use standard IDE tools

## Strategy: Filter → Clone → Grep → Read

### Phase 1: Filter Repos (eliminate 80%+ immediately)

**Never search all 90 repos.** Use the repo category table to select only relevant repos:

> See [repo-categories.md](./references/repo-categories.md) for the full categorized list of all repos.

**Quick filter by question type:**

| Question Type | Relevant Repo Categories | Typical Count |
|---|---|---|
| Who calls this project's API? | `service`, `orchestration` | 5-8 repos |
| Who uses this DTO/library? | `service`, `libs` | 8-12 repos |
| Where is this UI component used? | `ui` | 4-6 repos |
| How is this deployed? | `infra`, `deploy` | 5-8 repos |
| Where is this config set? | `service`, `infra`, `deploy` | 8-10 repos |

**Programmatic filter — list matching repos:**
```bash
# Quick discovery: list all repos via Bitbucket MCP
# Use mcp_bitbucket-mcp_list_repositories to get the full list
# Then filter by name pattern
```

### Phase 2: Shallow Clone to Temp Dir

For repos that pass the filter, shallow-clone them to a temp directory:

```bash
# Create temp workspace (Git Bash)
TEMP_DIR="/tmp/repo-scan-$(date +%s)"
mkdir -p "$TEMP_DIR"

# Shallow clone ONE repo (fast — only latest commit, no history)
git clone --depth 1 --single-branch \
  "https://bitbucket.org/<bb-workspace>/<REPO>.git" \
  "$TEMP_DIR/<REPO>" 2>/dev/null

# Shallow clone MULTIPLE repos in parallel (up to 4 at a time)
for repo in repo1 repo2 repo3 repo4; do
  git clone --depth 1 --single-branch \
    "https://bitbucket.org/<bb-workspace>/$repo.git" \
    "$TEMP_DIR/$repo" 2>/dev/null &
done
wait  # Wait for all background clones to finish
```

**Size estimates for shallow clones:**
- Small service repo: ~5-20 MB, ~5 seconds
- Medium repo with UI: ~50-100 MB, ~15 seconds  
- 4 parallel clones: ~15-20 seconds total

### Phase 3: Grep Across Cloned Repos

```bash
# Search across ALL cloned repos at once
grep -rn "pattern" "$TEMP_DIR"/*/src --include="*.java" -l

# Search with context
grep -rn -B3 -A3 "<DomainEntity>\|<domainEntity>" \
  "$TEMP_DIR"/*/src --include="*.java" | head -50

# Find all REST endpoints
grep -rn "@Path\|@RestController\|@RequestMapping" \
  "$TEMP_DIR"/*/src --include="*.java" -l
```

### Phase 4: Read Specific Files via Bitbucket API

Once you know which file to read, use the MCP tool (no clone needed):

```
mcp_bitbucket-mcp_get_file_content:
  workspace: <bb-workspace>
  repo_slug: <repo_name>
  file_path: src/main/java/com/radware/.../MyClass.java
  ref: HEAD  (or a specific branch)
```

**This is the fastest way to read individual files** — no cloning, instant response.

### Phase 5: Clean Up Temp Clones

```bash
rm -rf "$TEMP_DIR"
```

## Parallel Subagent Dispatch Pattern

For broad searches across many repos (10+), dispatch subagents to explore in parallel batches.

### When to Parallelize

| Repos to Search | Strategy |
|---|---|
| 1-3 | Sequential — single agent, no parallelism needed |
| 4-10 | 2 subagents, ~5 repos each |
| 11-20 | 3-4 subagents, ~5-6 repos each |
| 20+ | Re-filter! You're probably searching too broadly |

### Subagent Prompt Template

Each subagent gets a focused batch of repos and a specific question:

```markdown
Search these repos for [PATTERN/QUESTION]:

Repos (clone all to temp dir):
- <bb-workspace>/repo_a
- <bb-workspace>/repo_b
- <bb-workspace>/repo_c
- <bb-workspace>/repo_d
- <bb-workspace>/repo_e

Steps:
1. Create temp dir: TEMP_DIR="/tmp/scan-batch-N-$(date +%s)" && mkdir -p "$TEMP_DIR"
2. Shallow clone all repos in parallel:
   for repo in repo_a repo_b repo_c repo_d repo_e; do
     git clone --depth 1 "https://bitbucket.org/<bb-workspace>/$repo.git" "$TEMP_DIR/$repo" 2>/dev/null &
   done
   wait
3. Grep across all: grep -rn "[PATTERN]" "$TEMP_DIR"/*/src --include="*.java" | head -40
4. For each match, read the relevant file with Bitbucket MCP:
   mcp_bitbucket-mcp_get_file_content(workspace=<bb-workspace>, repo_slug=<repo>, file_path=<path>)
5. Clean up: rm -rf "$TEMP_DIR"

Return: A table of findings:
| Repo | File | Line | Relevant Code Snippet |
|------|------|------|-----------------------|

Constraints:
- Do NOT modify any files
- Do NOT clone repos to the workspace dir — use /tmp/ only
- Limit output — use head/tail to cap grep results
- If a repo fails to clone, skip it and note the failure
```

### Dispatch via run_subagent

```
run_subagent(agentName="developer", task="[subagent prompt above for batch 1]")
run_subagent(agentName="developer", task="[subagent prompt above for batch 2]")
run_subagent(agentName="developer", task="[subagent prompt above for batch 3]")
```

### Merge Results

After all subagents return:
1. Combine all finding tables
2. Deduplicate (same class found in multiple repos = likely a shared library)
3. Rank by relevance to the original question
4. Produce a summary finding

## Bitbucket API Tools — Quick Reference

| Task | Tool | Key Params |
|---|---|---|
| List all repos | `mcp_bitbucket-mcp_list_repositories` | `workspace: <bb-workspace>` |
| Read a file remotely | `mcp_bitbucket-mcp_get_file_content` | `repo_slug`, `file_path`, `ref` |
| Get repo info | `mcp_bitbucket-mcp_get_repository` | `repo_slug` |
| List recent commits | `mcp_bitbucket-mcp_list_commits` | `repo_slug`, `branch`, `limit` |
| Check file history | `mcp_bitbucket-mcp_get_file_history` | `repo_slug`, `file_path` |
| Search PRs | `mcp_bitbucket-mcp_search_prs` | `repo_slug`, `title_contains` |

**Prefer `get_file_content` over cloning** when you already know the file path. Cloning is for searching (grep).

## Common Exploration Patterns

### Pattern 1: "Who calls this project's REST API?"

```
1. Filter: service repos (<sibling-repo>, <orchestrator-repo>, 
   <config-service-repo>, <reporter-repo>, etc.)
2. Shallow clone 5-8 repos
3. grep -rn "<api-keyword>\|<api-path>\|<rest-base>" */src --include="*.java" -l
4. Read matching files via Bitbucket MCP
```

### Pattern 2: "Which repos depend on this Maven artifact?"

```
1. No clone needed — just read pom.xml files via Bitbucket MCP
2. For each candidate repo:
   mcp_bitbucket-mcp_get_file_content(repo_slug=<repo>, file_path=pom.xml)
3. Check for the dependency
```

### Pattern 3: "Find all implementations of this interface"

```
1. Filter: service + library repos
2. Shallow clone relevant batch
3. grep -rn "implements InterfaceName\|extends InterfaceName" */src --include="*.java"
4. Read implementations via Bitbucket MCP
```

### Pattern 4: "What repos use RabbitMQ / Kafka / Redis?"

```
1. Shallow clone in batches (service repos first)
2. grep -rn "RabbitTemplate\|@RabbitListener\|KafkaTemplate\|RedisTemplate" */src --include="*.java" -l
3. Read config files: get_file_content(file_path=src/main/resources/application.yml)
```

## Decision Tree

```
Need to explore repos?
├── Is repo cloned locally under %COPILOT_WORKSPACE_ROOT%\? 
│   ├── YES → Use `cross-repo-exploration` skill (faster, no network)
│   └── NO → Continue below
├── Do you know the exact file path?
│   ├── YES → Use `mcp_bitbucket-mcp_get_file_content` directly (instant)
│   └── NO → Continue below
├── How many repos to search?
│   ├── 1-3 → Shallow clone + grep sequentially
│   ├── 4-10 → Shallow clone + grep, consider 2 subagents
│   └── 10+ → Filter harder first! Then dispatch 3-4 subagents
└── Is this a recurring question?
    ├── YES → Cache results in memory-bank/cross-repo/<repo>.md
    └── NO → Produce summary, don't cache
```

## Performance Rules

1. **Filter before cloning** — never clone more than 10 repos at once
2. **Clone to /tmp/, not workspace** — avoid polluting the IDE workspace
3. **Parallel clones** — use `&` + `wait` for up to 4 concurrent clones
4. **Prefer Bitbucket MCP over clones** for reading known files — zero disk usage
5. **Cap grep output** — always pipe through `| head -N` 
6. **Clean up temp dirs** — `rm -rf "$TEMP_DIR"` when done
7. **Cache findings** — write to `memory-bank/cross-repo/<repo>.md` for recurring questions
8. **Max 4 subagents** — more creates merge overhead without speed gain

## Common Mistakes

**Cloning all 90 repos:** Disk, time, and context waste. Filter to <10 relevant repos first.

**Cloning to workspace dir:** Pollutes IDE indexes. Always use `/tmp/`.

**Using IDE file tools on cloned repos:** `read_file`, `grep_search`, etc. only work within the workspace. Use `run_in_terminal` with `cat`/`grep` for temp clones, or `mcp_bitbucket-mcp_get_file_content` for remote reads.

**No output limits on grep:** 90+ repos × java files = massive output. Always use `| head -N` or `-l` flag.

**Forgetting to clean up:** Temp clones eat disk space. Always `rm -rf "$TEMP_DIR"`.

**Not caching results:** If you'll ask the same cross-repo question again, write findings to memory bank.

## Knowledge Persistence

Same as `cross-repo-exploration` — store findings in `memory-bank/cross-repo/<repo>.md`.

**Before exploring remotely:** Check if `memory-bank/cross-repo/<repo>.md` already has the answer.

**After exploring:** Persist key findings (API contracts, DTOs, dependencies) to avoid re-exploring.

## Agent Integration

| Agent | Usage |
|---|---|
| **PEplan** | Dispatches remote exploration during design phase to map cross-service contracts |
| **Developer** | Used as subagent for parallel repo batch exploration |
| **SquadLeader** | Orchestrates multi-repo exploration with subagent dispatch |
| **Debugger** | Traces cross-service bugs through remote repos |

## Inter-Skill References

- **For locally available repos** → `cross-repo-exploration` (faster, no network)
- **For parallel dispatch** → `dispatching-parallel-agents` (coordination pattern)
- **After exploration** → `brainstorming` or `writing-plans` to design the integration
- **For persisting patterns** → `remember` skill to save cross-repo knowledge

