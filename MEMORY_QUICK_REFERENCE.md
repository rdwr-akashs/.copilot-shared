# Quick Reference: Centralized Memory

**Fast lookup for accessing and maintaining centralized memory, learning, and case docs.**

---

## 📍 Quick Navigation

### Central Location
```
/.copilot-shared/
├── shared/memory/              ← All memory (repo-specific + cross-repo)
├── shared/learning/            ← Learning docs & best practices
├── shared/cases/               ← Customer cases & RCA documents
```

### From Individual Repos
```
<repo>/.github/
├── copilot-memory/ (symlink)   → /.copilot-shared/shared/memory/<repo>/
├── learning/ (symlink)         → /.copilot-shared/shared/learning/
├── cases/ (symlink)            → /.copilot-shared/shared/cases/
```

---

## 🚀 Quick Start

### I want to add memory to my repo

**Option 1: Direct access** (from Copilot or terminal)
```bash
# Navigate directly
cd /.copilot-shared/shared/memory/df_core/
echo "New learning" >> memory.md

# Or via symlink
cd /c/repos/df_core/.github/copilot-memory
echo "New learning" >> memory.md
```

**Option 2: Via Git from individual repo**
```bash
cd /c/repos/df_core
cat > .github/copilot-memory/memory.md << 'EOF'
## New Pattern Discovered
...
EOF
git add .github/copilot-memory/memory.md
git commit -m "docs: add memory"
git push
```

### I want to access learning docs

```bash
# Via symlink (from any repo)
cd /c/repos/df_core
cat .github/learning/best-practices/java-patterns.md

# Or directly
cat /.copilot-shared/shared/learning/best-practices/java-patterns.md
```

### I want to view case documentation

```bash
# Via symlink
cd /c/repos/df_core
ls .github/cases/customer-cases/RSEG-*/

# Or directly
ls /.copilot-shared/shared/cases/customer-cases/RSEG-*/
```

---

## 📁 What's Where

| Type | Location | Access | Purpose |
|------|----------|--------|---------|
| Repo memory | `shared/memory/<repo>/` | Symlink `.github/copilot-memory/` | Repository-specific findings |
| Cross-repo | `shared/memory/cross-repo/` | Symlink `.github/copilot-memory/` | Shared patterns & learnings |
| Learning | `shared/learning/` | Symlink `.github/learning/` | Best practices & patterns |
| Cases | `shared/cases/` | Symlink `.github/cases/` | Customer cases & RCA |

---

## 📝 File Templates

### Adding Repository Memory
**File**: `shared/memory/<repo>/memory.md`

```markdown
## [Pattern Name]

**Discovered**: [Date]  
**Repository**: [repo name]  
**Confidence**: [High/Medium/Low]

### Description
What this is and why it matters.

### Example
\`\`\`java
// Code snippet
\`\`\`

### Related Issues
- TICKET-123
- Affects: [other patterns]

### Last Updated
[Date] by [who]
```

### Adding Learning Doc
**File**: `shared/learning/best-practices/<category>.md`

```markdown
## [Learning Topic]

**Category**: [Java/React/DevOps/etc]  
**Difficulty**: [Beginner/Intermediate/Advanced]

### When to Use
Context and conditions for applying this learning.

### How to
Step-by-step implementation or explanation.

### Example
\`\`\`code
// Implementation example
\`\`\`

### Pitfalls to Avoid
Common mistakes and how to prevent them.

### References
- Related docs
- Stack Overflow/articles
- Internal tickets
```

### Adding Customer Case
**File**: `shared/cases/customer-cases/RSEG-12345/notes.md`

```markdown
# RSEG-12345: [Case Title]

**Customer**: [Name]  
**Priority**: [P0/P1/P2/P3]  
**Status**: [Open/In Progress/Resolved]  
**Repository**: [affected repo]

## Symptom
What the customer observed.

## Investigation
What we found.

## Root Cause
Why it happened.

## Resolution
How it was fixed.

## Artifacts
- support-bundle.zip
- logs/
```

---

## ✅ Common Tasks

### Verify Symlinks Are Working

```bash
cd /c/repos/df_core/.github

# Test memory
ls -la copilot-memory/
cat copilot-memory/memory.md

# Test learning
ls -la learning/
cat learning/best-practices/java-patterns.md

# Test cases
ls -la cases/
```

### Update Memory Across All Repos (Simultaneously)

Since all repos symlink to same location, **edit once = updates all**:

```bash
# Edit central memory (updates all repos immediately)
cd /.copilot-shared/shared/memory/cross-repo
echo "New cross-repo insight" >> architecture-patterns.md

# Each repo can now see it via symlink
cd /c/repos/df_core && cat .github/copilot-memory/../cross-repo/architecture-patterns.md
```

### Search Memory Across All Repos

```bash
# Find all memory files mentioning "database"
grep -r "database" /.copilot-shared/shared/memory/

# Find in specific repo memory
grep -r "performance" /.copilot-shared/shared/memory/df_core/
```

### Commit Memory Changes to Git

```bash
cd /c/repos/df_core

# Symlinks are tracked as special git objects (mode 120000)
git add .github/copilot-memory
git status  # Shows "modified: .github/copilot-memory"

git commit -m "docs: update memory via central location"
git push
```

### Archive Old Cases

```bash
# Move old case to archive folder
cd /.copilot-shared/shared/cases
mkdir -p archive/2025-Q1
mv customer-cases/RSEG-old/ archive/2025-Q1/

# Still searchable if needed
grep -r "symptom" archive/2025-Q1/
```

---

## 🔗 Symlink Format Reference

### Windows PowerShell
```powershell
cmd /c mklink /d "target-name" "C:\path\to\source"
```

### Git Bash / Linux
```bash
ln -s ../../../.copilot-shared/shared/memory/df_core copilot-memory
```

### Test Symlink
```bash
# Should show "symlink" marker and target path
ls -la .github/copilot-memory

# Should display actual content
cat .github/copilot-memory/memory.md
```

---

## 🚨 Troubleshooting Quick Fixes

| Issue | Fix |
|-------|-----|
| Can't create symlink (Windows) | Run PowerShell as Admin, enable `core.symlinks` in git |
| Git shows symlink as "modified" | Run `git add .github/copilot-memory` and commit |
| Copilot doesn't see central memory | Reload Copilot context: `Ctrl+Shift+P` → "Copilot: Reset context" |
| Symlink broken after merge | Run `git checkout --theirs .github/copilot-memory` |
| "File not found" via symlink | Verify source exists: `ls -la /.copilot-shared/shared/memory/df_core/` |

---

## 📊 Storage Stats

**Centralized Structure Size**: ~500 KB (growing as memory accumulates)

**Per-Repo Overhead**: 0 KB (symlinks are tiny pointers)

**Total Saved**: ~5-10 MB (compared to duplicate memory in each of 15+ repos)

---

## 📚 Full Documentation

- **[CENTRALIZED_MEMORY_SETUP.md](../CENTRALIZED_MEMORY_SETUP.md)** — Architecture & detailed setup
- **[CENTRALIZATION_CHECKLIST.md](../CENTRALIZATION_CHECKLIST.md)** — Step-by-step migration
- **[shared/memory/README.md](../shared/memory/README.md)** — Memory organization
- **[shared/learning/README.md](../shared/learning/README.md)** — Learning materials
- **[cases/README.md](../cases/README.md)** — Case documentation

---

## 💡 Pro Tips

✅ **Symlinks are read-only from individual repos** — Edit at central location  
✅ **Git tracks symlinks** — They stay in sync across branches  
✅ **Cross-repo memory is powerful** — Use `shared/memory/cross-repo/` for org-wide learnings  
✅ **Update once, use everywhere** — Central edit = instant update for all repos  
✅ **Search across all repos** — `grep -r` in `/.copilot-shared/shared/memory/`  
✅ **Organize by type** — Separate memory, learning, and cases for clarity

---

**Last Updated**: [Auto-updated]  
**Maintained By**: [Your Team]
