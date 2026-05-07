# Token Usage Best Practices & Prevention

**Effective date:** May 7, 2026

---

## Understanding Token Cost

Every file loaded into a Copilot session consumes tokens. Think of it like RAM usage — more loaded files = slower context, higher cost.

### Token Math

```
1 token ≈ 4 characters

Example:
- 1 KB file = ~256 tokens
- 1 MB file = ~262,144 tokens
- Your entire workspace = ~3.7M tokens

Current state:
- Average session load: 3.7M tokens (way too high)
- After optimization: 230K tokens (much better)
```

**Implication:** When you use an agent, every loaded file competes for attention. Large files (repo-contexts) crowd out useful context.

---

## Rule 1: Separate "Reference" from "Active"

### ❌ Wrong Pattern
```
shared/instructions/
  ├─ orchestrator.instructions.md (800 lines)
  ├─ agent-skills.instructions.md (700 lines)
  ├─ memory-bank.instructions.md (600 lines)
  └─ [... 10 more files ...]

Result: 3,000+ lines of instructions all loaded every session
```

### ✅ Right Pattern
```
shared/instructions/
  ├─ 00-core-instructions.md (1,000 lines, ACTIVE)
  │   └─ Links to: agent routing, skills, memory guidelines
  └─ _reference/
      ├─ deprecated-orchestrator.md (archived)
      ├─ deprecated-agent-skills.md (archived)
      └─ README.md ("For historical reference only")

Result: Only ~1,000 lines loaded; others available but not active
```

**Apply this:** When you have > 5 similar documents, consolidate.

---

## Rule 2: Lightweight Summaries > Full Dumps

### ❌ Wrong Pattern: Full Directory Trees
```markdown
# Repository Context

## Complete File Tree
| Module | Files |
|--------|-------|
| src/main/java/ | [5,000 rows of directory tree] |
| src/test/java/ | [2,000 rows of directory tree] |
| resources/ | [1,000 rows of directory tree] |

Total: 8,000 lines (2 MB), 90% is irrelevant directory paths
```

### ✅ Right Pattern: Architecture Summary
```markdown
# Repository Context

## Key Facts
- **Language:** Java (Maven)
- **Modules:** `src/main/`, `src/test/`, `config/`
- **Entry point:** `application/src/main/java/Application.java`

## To view current files:
```bash
git ls-files | head -50  # See top files
find . -name "*.java" | wc -l  # Count Java files
```

## Architecture
[1-2 paragraphs about the system's design]

Total: 150 lines, all actionable
```

**Apply this:** When a file exceeds 200 lines, check if 80% is "tree-like" (lists, tables of directories). If yes, replace with summary.

---

## Rule 3: DRY (Don't Repeat Yourself) for Documentation

### ❌ Wrong Pattern: Boilerplate in Every File

Each of 15 agent files repeats:
```markdown
> **Routing:** This agent is selected by the orchestrator...
> **Pipeline Entry Gate:** When invoked directly...

## Hard Rules
- Constructor injection only
- Use ProjectException
- PascalCase classes
- camelCase methods
...
```

**Repeated 15 times = 15 × 60 lines = 900 lines of duplicate boilerplate**

### ✅ Right Pattern: Single Source of Truth

```markdown
# shared/instructions/agent-base.template.md
[All hard rules, routing, pipeline gate — 200 lines ONE TIME]

# agent-templates/developer.agent.md
---
name: "Developer"
---
# Developer Agent

> See `shared/instructions/agent-base.template.md` for routing and rules.

## Developer-Specific Context
[Only unique content here: 20 lines]
```

**Result: 200 + (15 × 20) = 500 lines instead of 1,400**

### How to Detect Duplication

```bash
# Find highly similar files
diff shared/instructions/agent-skills.instructions.md \
     shared/instructions/orchestrator.instructions.md
# If > 50% of lines are identical → consolidate

# Check for repeated sections
grep -h "^#" shared/instructions/*.md | sort | uniq -d
# If many duplicate section headers → consolidate
```

---

## Rule 4: Archive Historical Documentation

### ❌ Wrong Pattern: Keep Everything Forever
```
shared/memory/repo-contexts/
  ├─ kvision_configuration_service.md (3.1 MB, generated May 2026)
  ├─ kvision_cyber_controller_core.md (960 KB, generated May 2026)
  ├─ common_policy_editor.md (1.7 MB, generated May 2026)
  └─ [... 12 more files ...]

Total: 13 MB of snapshots never updated, always loaded
```

### ✅ Right Pattern: Archive Aged Snapshots
```
shared/memory/repo-contexts/
  ├─ _index.md (current, 4 KB)
  └─ _archive-2026-05/
      ├─ kvision_configuration_service.md.20260506 (archived)
      ├─ kvision_cyber_controller_core.md.20260506 (archived)
      └─ [... stored but NOT loaded ...]

# Create lightweight replacements
cat > kvision_configuration_service.md << 'EOF'
# Kvision Configuration Service

**Archive:** Full directory tree at `_archive-2026-05/kvision_configuration_service.md.20260506`

[Summary: 50 lines instead of 3.1 MB]
EOF
```

**When to archive:**
- File hasn't been updated in 30+ days
- File contains generated directory trees (git ls-files output)
- File is > 500 KB and purely informational

---

## Rule 5: Use Git Commands, Not Copied Files

### ❌ Wrong Pattern: Commit Full Directory Dumps
```bash
# Copy current repo state into documentation
find /repo -type f -name "*.java" | sort > shared/memory/repo-contexts/myrepo.md
git add shared/memory/repo-contexts/myrepo.md
git commit -m "Add repo context"

# Problem: This never updates. Repo changes, file doesn't.
```

### ✅ Right Pattern: Document How to Get Current State
```markdown
# MyRepo Context

**To see current file structure:**
```bash
cd /path/to/myrepo
git ls-files | grep "\.java$" | head -50
```

**To analyze code:**
```bash
find . -name "*.java" | xargs wc -l | sort -rn | head -20
```

**To check recent changes:**
```bash
git log --oneline -20
```
EOF
```

**Benefit:** Documentation stays current without manual updates.

---

## Rule 6: Organize by Frequency of Access

### Access Tiers

| Tier | Load Pattern | Examples | Max Size |
|------|-------------|----------|----------|
| **Frequent** | Always loaded, in context | core-instructions.md, agent-base.template.md | 500 lines |
| **Regular** | Loaded per-task type | java-conventions.md, react-conventions.md | 200 lines each |
| **Occasional** | Rarely loaded, user requests | Design docs, architecture | 500 lines each |
| **Reference** | Almost never loaded | Historical notes, archived docs | Unlimited (archived) |

### Folder Structure to Reflect Tiers

```
shared/instructions/
  ├─ 00-core-instructions.md (FREQUENT)
  ├─ agent-base.template.md (FREQUENT)
  ├─ java-conventions.instructions.md (REGULAR)
  ├─ react-conventions.instructions.md (REGULAR)
  ├─ tdd.instructions.md (REGULAR)
  └─ _reference/
      ├─ deprecated-orchestrator.md (REFERENCE)
      ├─ old-design-principles.md (REFERENCE)
      └─ historical-decisions.md (REFERENCE)
```

---

## Rule 7: Document Decisions, Not Exhaustive Details

### ❌ Wrong Pattern: Include All Details
```markdown
# Design Decision: API Error Handling

## Overview
Errors can occur at many layers...

## Layer 1: Database Errors
If SELECT fails on connection pool exhaustion...
If UPDATE fails due to constraint violation...
If DELETE fails due to referential integrity...
[... 50 lines of exhaustive cases ...]

## Layer 2: Network Errors
[... 40 more lines ...]

## Layer 3: Validation Errors
[... 30 more lines ...]

[Total: 500 lines, 90% is "could happen" not "what we do"]
```

### ✅ Right Pattern: Decision + Consequence
```markdown
# Decision: API Error Handling

**Decision:** Always throw `ProjectException(status, message)`

**Why:** 
- Centralized error handling (1 place to change)
- Consistent HTTP status codes
- Testable error scenarios

**What this means:**
- No `null` returns (use `Optional<T>`)
- No custom exception classes (reuse ProjectException)
- All layers catch and re-throw as ProjectException

**Reference:** See `common/exception/ProjectException.java` for implementation

[Total: 20 lines, 100% relevant]
```

---

## Rule 8: Automate Cleanup

### Prevent Token Bloat Over Time

Add to `bin/maintenance.sh`:
```bash
#!/bin/bash
# Monthly token cleanup

# Remove temp files older than 30 days
find .agent_work -type f -mtime +30 -delete

# Remove archived docs older than 90 days
find shared/memory/repo-contexts/_archive* -type f -mtime +90 -delete

# Report on largest files
echo "=== Largest files (potential optimization targets) ==="
find shared -type f -name "*.md" -size +200k -exec ls -lh {} \; | awk '{print $9, $5}'

# Check for duplicate content
echo "=== Checking for duplicate patterns ==="
grep -h "^#" shared/instructions/*.md | sort | uniq -d | wc -l
if [[ $? -gt 5 ]]; then
  echo "WARNING: Multiple duplicate section headers found. Consider consolidation."
fi
```

**Schedule:** Run monthly or quarterly

---

## Checklist: Before Committing New Documentation

**For every new documentation file:**

- [ ] **Is it> 300 lines?** If yes, can it be shortened?
- [ ] **Does it repeat content?** Check for similar files with `grep` or `diff`
- [ ] **Is it time-sensitive?** Will it become stale? If so, use commands instead.
- [ ] **Where should it live?** Put in appropriate tier (Frequent/Regular/Reference)
- [ ] **Is the name descriptive?** Avoid generic names ("config.md"). Use "spring-boot-conventions.md"
- [ ] **Does it reference other docs?** Add links to related files for discovery
- [ ] **Can it be a skill instead?** If it's a workflow, make it a SKILL.md
- [ ] **Is it truly needed?** Can the team find this info elsewhere (README, code comments)?

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| **Copy-paste code examples** | Gets outdated | Link to actual file + line number |
| **Full directory trees** | 90% waste | Use summary + git commands |
| **One big file** | Hard to navigate | Split into focused files per topic |
| **Duplicate rules in every agent** | 15 copies of same text | Single base template + reference |
| **Generated snapshots** | Never update | Git commands instead |
| **"Just in case" docs** | Bloat without benefit | Delete if unused for 6 months |
| **Mixing concerns** | Hard to find | Separate architecture vs. implementation |

---

## Monitoring: Token Usage Dashboard

Add to `.github/workflows/monitor-tokens.yml`:

```yaml
name: Monitor Token Usage
on:
  schedule:
    - cron: '0 0 * * MON'  # Weekly Monday check

jobs:
  check-bloat:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Scan for token bloat
        run: |
          echo "=== Workspace Size ==="
          du -sh shared/memory shared/instructions agent-templates
          
          echo "=== Files > 200 KB ==="
          find shared -type f -name "*.md" -size +200k
          
          echo "=== Duplicate Headers ==="
          grep -h "^##" shared/instructions/*.md | sort | uniq -d
          
          echo "=== Archived Files Older Than 90 days ==="
          find shared/memory -name "_archive*" -type d -mtime +90
```

**Use this to:** Trigger alerts when bloat is detected.

---

## Summary: Token-Conscious Practices

| Practice | Impact | Effort |
|----------|--------|--------|
| Consolidate boilerplate | ~100K tokens | 2 hours |
| Archive directory dumps | ~3.3M tokens | 1 hour |
| Use summaries not dumps | ~50K tokens | 30 min per file |
| Link instead of copy-paste | ~10K tokens | Per doc |
| Regular cleanup | ~20K tokens/month | 15 min/month |
| **Total First Pass** | **~3.46M tokens** | **~4 hours** |

---

## Next Review: 30 Days

Revisit this guide in 30 days to:
- [ ] Check if token usage stayed low
- [ ] Identify new bloat patterns
- [ ] Update guidelines based on learnings
- [ ] Archive any new old documentation

**Goal:** Maintain token usage < 300K per session sustainably.
