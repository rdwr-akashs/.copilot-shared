# Multi-Repo Token Optimization Strategy

**Purpose:** Leverage the shared space across multiple repositories while preventing token bloat and duplication

---

## The Multi-Repo Challenge

When you have multiple repos using this shared space:

```
/.copilot-shared/
├── shared/
│   ├── instructions/
│   ├── skills/
│   └── memory/

C:\repos\
├── df_core/
│   └── .github/instructions/ ← needs to reference /.copilot-shared/
├── kvision_configuration_service/
│   └── .github/instructions/ ← needs to reference /.copilot-shared/
├── vision_core/
│   └── .github/instructions/ ← needs to reference /.copilot-shared/
└── ... (10+ more repos)
```

**Problem:** Each repo might have its own copy of instructions/skills, OR each repo might load the shared space separately, causing:
- Duplication across repos
- Inconsistent versions of rules
- Token bloat when switching between repos
- Maintenance nightmare (fix in one place, must update 10+ others)

**Solution:** Central shared space + lightweight per-repo customization

---

## Architecture: Hub-and-Spoke Model

```
                    /.copilot-shared/ (THE HUB)
                    ├─ shared/instructions/
                    │  ├─ 00-core-instructions.md
                    │  ├─ agent-base.template.md
                    │  ├─ java-conventions.instructions.md
                    │  └─ react-conventions.instructions.md
                    ├─ shared/skills/
                    └─ shared/memory/

                           ↑ ↑ ↑
         ┌─────────────────┼─┼─┴──────────────────┐
         ↓                 ↓ ↓                     ↓

    df_core/          kvision_*/          webui_components/
    .github/          .github/            .github/
    ├─ .copilot-instructions.md (THIN)   ├─ .copilot-instructions.md (THIN)
    └─ Link to /.copilot-shared/         └─ Link to /.copilot-shared/
```

**Benefits:**
- ✅ Single source of truth for all repos
- ✅ No duplication (20-30% token savings)
- ✅ Easy to update rules globally
- ✅ Per-repo customizations possible (java-specific, react-specific)
- ✅ New repos auto-get best practices

---

## Setup Strategy for Each Repo

### Strategy 1: Symlink Instructions (Recommended)

**In each repo's `.github/` directory:**

```bash
# From within df_core/.github/
ln -s ../../.copilot-shared/shared/instructions instructions-shared

# Now in .copilot-instructions.md you can reference:
# See ../instructions-shared/00-core-instructions.md
```

**Advantages:**
- Always points to latest shared content
- Works across Windows/Mac/Linux (with git config)
- Clear that it's a link, not a copy

**Windows Setup:**
```bash
# In df_core\.github\
mklink /d instructions-shared ..\..\..\.copilot-shared\shared\instructions
```

### Strategy 2: Git Submodule

Add the shared space as a submodule to each repo:

```bash
# In df_core root
git submodule add https://github.com/yourorg/.copilot-shared.git .copilot-shared

# Then reference in .github/.copilot-instructions.md
# See ../../.copilot-shared/shared/instructions/00-core-instructions.md
```

**Advantages:**
- Official git integration
- Version control (pin shared space to specific commit)
- Easier for external contributors

### Strategy 3: Direct URL References

In `.copilot-instructions.md` files across repos, directly reference the absolute path:

```markdown
# [Repo Name] Instructions

> **Shared Rules:** See c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md

## Repo-Specific Context

[Only unique content here]
```

**Advantages:**
- Simple setup (no symlinks needed)
- Works immediately on Windows
- Clear path references

---

## Per-Repo Customization Pattern

Each repo can override or extend shared rules with minimal overhead:

### Template: `.github/.copilot-instructions.md`

```markdown
---
description: "DF Core — DefenseFlow Security Engine"
applyTo: "df_core/**"
---

# DF Core Instructions

> **Shared baseline:** c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md

## DF Core-Specific Rules

### Language: Java 21 + Spring Boot 3.2
- Use `@RequiredArgsConstructor` (DI, not @Autowired)
- Logging: Log4j2 with performance-aware levels
- Async patterns: Virtual threads via Spring TaskExecutor

### Critical Modules
- `security-engine/` — BGP/OSPF route filtering
- `ha-orchestrator/` — Active/Standby coordination
- `policy-engine/` — Policy evaluation at line-rate

### Build & Test
```bash
./mvnw -pl security-engine -am clean install
./mvnw -pl security-engine test
```

### Known Patterns (from memory)
- [Link to repo-specific memory in /.copilot-shared/shared/memory/repo-contexts/df_core-summary.md]
- BGP peer state managed in `PeersUpdateWorker.java`
- HA sync excludes BGP table (known limitation, not a bug)

---

## KVision Submodules

> **Shared baseline:** [same as above]

## KVision-Specific Rules

### Language: Java 21 + Spring Boot 3.2 + Angular 18
- Frontend: TypeScript 5.2+ with strict mode
- State management: NgRx
- REST contracts: OpenAPI 3.0 first

### Critical Modules
- `api-gateway/` — REST API surface
- `policy-ui/` — React-based policy editor
- `config-sync/` — PostgreSQL replication layer

### Build & Test
```bash
# Backend
./mvnw -pl api-gateway -am clean install

# Frontend
npm run build
npm run test:coverage
```

---

## Multi-Repo Memory Strategy

### Shared Memory: `/.copilot-shared/shared/memory/`

Keep **global, cross-repo insights** here:

```
repo-contexts/
├─ _summaries/
│  ├─ df_core-summary.md (100 lines)
│  ├─ kvision_configuration_service-summary.md (100 lines)
│  └─ ... (lightweight, updated quarterly)
├─ cross-repo-learnings.md (patterns found in 2+ repos)
├─ known-bugs.md (bugs affecting multiple repos)
└─ architecture-map.md (how repos interconnect)
```

### Per-Repo Memory: Each repo's own `.github/copilot-memory.md`

```
df_core/.github/
├─ copilot-memory.md (repo-specific findings)
└─ .copilot-instructions.md
```

**Example: df_core/.github/copilot-memory.md**
```markdown
# DF Core Copilot Memory

## Known Issues
- BGP peer table not in HA sync (DE#12345) — fixed in 4.8.0
- Memory leaks in ExaBGP wrapper — monitor with jcmd

## Verified Commands
```bash
mvn -pl security-engine test       # Always works
mvn -pl ha-orchestrator test       # 2-3 min runtime
```

## Code Patterns
- PeersUpdateWorker: handles BGP state machine
- VisionWitnessApiImpl: manages Vision failover logic
EOF
```

---

## File Organization Across Repos

### Minimum Setup (Small Teams)

```
/.copilot-shared/                    (SHARED)
├─ shared/instructions/
│  ├─ 00-core-instructions.md       ✅ All repos use this
│  ├─ java-conventions.instructions.md
│  └─ react-conventions.instructions.md
├─ shared/skills/
├─ shared/memory/repo-contexts/_summaries/
└─ README.md

df_core/.github/                     (REPO-SPECIFIC)
├─ .copilot-instructions.md         ✅ Imports shared + DF-specific rules
└─ copilot-memory.md                ✅ DF-specific findings

kvision_configuration_service/.github/   (REPO-SPECIFIC)
├─ .copilot-instructions.md         ✅ Imports shared + KVision-specific rules
└─ copilot-memory.md                ✅ KVision-specific findings
```

### Comprehensive Setup (Large Teams)

```
/.copilot-shared/
├─ shared/instructions/
│  ├─ 00-core-instructions.md
│  ├─ java-conventions.instructions.md
│  ├─ react-conventions.instructions.md
│  ├─ orchestrator.instructions.md
│  └─ _team-onboarding/
│     ├─ new-dev-checklist.md
│     └─ debugging-workflow.md
├─ shared/skills/
│  ├─ SKILL.md
│  └─ _templates/
│     └─ skill-template.md
├─ shared/memory/
│  ├─ repo-contexts/_summaries/
│  ├─ known-bugs.md
│  ├─ cross-repo-learnings.md
│  └─ architecture-map.md
└─ README.md (with setup instructions for new repos)

df_core/.github/
├─ .copilot-instructions.md
├─ orchestrator.instructions.md     (df-specific overrides if needed)
└─ copilot-memory.md

kvision_configuration_service/.github/
├─ .copilot-instructions.md
└─ copilot-memory.md

... (12+ more repos, all lightweight)
```

---

## Implementation: Adding a New Repo

### Checklist for Each New Repo

```bash
# 1. Create .github directory if needed
mkdir -p <repo>/.github

# 2. Create .copilot-instructions.md (copy template below)
cat > <repo>/.github/.copilot-instructions.md << 'EOF'
---
description: "[Repo Name] — [Brief description]"
applyTo: "[repo-name]/**"
---

# [Repo Name] Instructions

> **Shared baseline:** c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md

## Repo-Specific Rules

### Language & Framework
- [Language] [Version]
- [Framework] [Version]

### Critical Modules
- [Module 1]
- [Module 2]

### Build & Test
```bash
# Build
[build command]

# Test
[test command]
```

---
EOF

# 3. Create copilot-memory.md
cat > <repo>/.github/copilot-memory.md << 'EOF'
# [Repo Name] Copilot Memory

## Known Issues
- [Issue 1]

## Verified Commands
```bash
[verified build/test command]
```

## Code Patterns
- [Pattern 1]
EOF

# 4. Optional: Create symlink to shared instructions
ln -s ../../.copilot-shared/shared/instructions instructions-shared

# 5. Commit
git add .github/
git commit -m "add: Copilot instructions (linked to /.copilot-shared)"
```

---

## Token Calculation: Multi-Repo Impact

### Before (Duplicated Across 15 Repos)

```
Each repo has its own copy:
├─ instructions/ (130 KB)
├─ skills/ (564 KB)
├─ memory/ (1-5 MB per repo)

15 repos × 700 KB average = 10.5 MB total
Tokens: ~2.7M per repo load
```

### After (Shared Hub)

```
Shared space (used by all 15 repos):
├─ instructions/ (50 KB, consolidated)
├─ skills/ (200 KB, consolidated)
├─ memory/_summaries/ (150 KB)
Total: ~400 KB

Each repo adds only:
├─ .copilot-instructions.md (5 KB)
└─ copilot-memory.md (5 KB)
Per-repo total: 10 KB × 15 = 150 KB

Grand total: 400 KB + 150 KB = 550 KB (vs 10.5 MB)
Tokens per session: ~140K (vs 2.7M)
Savings: 95% across entire multi-repo system
```

---

## Navigation & Discovery: Multi-Repo

### Central Index: `/.copilot-shared/README.md`

```markdown
# Shared Copilot Space — Multi-Repo Hub

**Workspace location:** c:\rdwr-intelij\.copilot-shared\
**Used by:** 15+ repositories
**Maintained by:** [Team Name]

## Quick Links

### Instructions (All Repos Use These)
- [Core Instructions](shared/instructions/00-core-instructions.md) — Routing, agents, skills
- [Java Conventions](shared/instructions/java-conventions.instructions.md) — Java/Spring Boot
- [React Conventions](shared/instructions/react-conventions.instructions.md) — React/TypeScript

### Repo-Specific Setup
Each repo's `.github/.copilot-instructions.md` extends core rules:

| Repo | Setup | Status |
|------|-------|--------|
| [df_core](../df_core/.github/.copilot-instructions.md) | ✅ Setup | Active |
| [kvision_configuration_service](../kvision_configuration_service/.github/.copilot-instructions.md) | ✅ Setup | Active |
| [webui_components](../webui_components/.github/.copilot-instructions.md) | ✅ Setup | Active |

### Shared Memory & Insights
- [Cross-Repo Learnings](shared/memory/cross-repo-learnings.md) — Patterns found in 2+ repos
- [Known Bugs](shared/memory/known-bugs.md) — Bugs affecting multiple repos
- [Architecture Map](shared/memory/architecture-map.md) — How repos interconnect
- [Repo Summaries](shared/memory/repo-contexts/_summaries/) — Quick facts per repo

### Onboarding New Repos

To add a new repo to this shared space:

1. Copy `.copilot-instructions.md` template from an existing repo
2. Customize repo-specific sections
3. Create `.github/copilot-memory.md` for findings
4. Commit and open PR
5. Add repo to the table above

---

## Maintenance Schedule

| Task | Frequency | Effort | Owner |
|------|-----------|--------|-------|
| Update core instructions | Quarterly | 30 min | Architect |
| Consolidate cross-repo patterns | Monthly | 30 min | Team |
| Archive old memory files | Quarterly | 15 min | DevOps |
| Review repo-specific customizations | Quarterly | 1 hour | Squad leads |
| Onboard new repos | As needed | 30 min | DevOps |

---
EOF
```

### Per-Repo Index: `df_core/.github/README.md`

```markdown
# DF Core — Copilot Instructions

**Quick start:** See `.copilot-instructions.md`

## What's Linked

- ✅ Shared instructions: `../../.copilot-shared/shared/instructions/`
- ✅ Shared skills: `../../.copilot-shared/shared/skills/`
- ✅ Repo memory: `copilot-memory.md`

## When to Use Each

| Need | Where | Link |
|------|-------|------|
| How agents work | Shared | [core-instructions.md](../../.copilot-shared/shared/instructions/00-core-instructions.md) |
| Java rules | Shared | [java-conventions.instructions.md](../../.copilot-shared/shared/instructions/java-conventions.instructions.md) |
| DF-specific rules | Local | [.copilot-instructions.md](.copilot-instructions.md) |
| Known issues | Local | [copilot-memory.md](copilot-memory.md) |
| Cross-repo patterns | Shared | [cross-repo-learnings.md](../../.copilot-shared/shared/memory/cross-repo-learnings.md) |
```

---

## Updating Rules Across All Repos

### Scenario: Change Java conventions globally

**Before (update 15 repos):**
```bash
# In each repo, manually update .github/.copilot-instructions.md
# Repeat 15 times with risk of inconsistency
```

**After (single update in shared space):**
```bash
# In /.copilot-shared/shared/instructions/java-conventions.instructions.md
# Make change once
# All 15 repos automatically use new rules on next session
```

### Scenario: Share a new skill across all repos

**Before:**
```bash
# Create skill in df_core/.github/skills/
# Copy to kvision_configuration_service/.github/skills/
# Copy to webui_components/.github/skills/
# ... (repeat 12+ times)
```

**After:**
```bash
# Create skill in /.copilot-shared/shared/skills/
# All repos reference it automatically
```

---

## Security & Access Control

### Who Can Modify Shared Space

```markdown
| Role | Can Modify | Approval |
|------|-----------|----------|
| Individual contributor | ❌ No | — |
| Squad lead | ✅ Yes (own repo rules) | Self |
| Architect | ✅ Yes (shared) | PR review |
| Platform/DevOps | ✅ Yes (skills, memory) | Consensus |
```

### Approval Workflow for Shared Changes

```bash
# 1. Create PR in /.copilot-shared
git checkout -b feature/update-java-conventions

# 2. Update file
vim shared/instructions/java-conventions.instructions.md

# 3. Request review
# CC: @architect, @platform-team

# 4. Merge after approval
git merge --no-ff feature/update-java-conventions

# 5. All repos see change automatically
```

---

## Troubleshooting Multi-Repo Setup

### Problem: Repo doesn't see shared instructions

**Diagnosis:**
```bash
# Check if symlink exists
ls -la df_core/.github/instructions-shared
# Should show: instructions-shared -> ../../.copilot-shared/shared/instructions

# Check if .copilot-instructions.md references shared path
grep "\.copilot-shared" df_core/.github/.copilot-instructions.md
```

**Fix:**
```bash
# Recreate symlink
cd df_core/.github/
rm instructions-shared
ln -s ../../.copilot-shared/shared/instructions instructions-shared
```

### Problem: Each repo has its own copy of instructions

**Diagnosis:**
```bash
# Check file sizes across repos
du -sh */. github/instructions/ | sort -h
# If each is 130 KB → they're copies, not linked
```

**Fix:**
```bash
# Replace with symlinks
cd df_core/.github/
rm -rf instructions/
ln -s ../../.copilot-shared/shared/instructions instructions

# Repeat for all repos
```

### Problem: Memory files are duplicated

**Diagnosis:**
```bash
# Find duplicate memory files across repos
find . -name "cross-repo-learnings.md" -o -name "known-bugs.md"
# Should only exist in /.copilot-shared/shared/memory/
```

**Fix:**
```bash
# Delete repo-local copies
rm df_core/.github/cross-repo-learnings.md
# Repos should reference shared version
```

---

## Best Practices for Multi-Repo Setup

| Practice | Why | How |
|----------|-----|-----|
| **Shared = Global** | Avoid duplication | Store rules, skills, cross-repo memory in /.copilot-shared/ |
| **Local = Specific** | Enable customization | Each repo has .copilot-instructions.md with its own rules |
| **Symlinks > Copies** | Stay in sync | Use symlinks for instructions/skills, not file copies |
| **Version by convention** | Predictable updates | Update shared space monthly, repo-local files as needed |
| **Memory per level** | Organized insights | Shared memory (cross-repo) + local memory (repo-specific) |
| **Document dependencies** | Clear relationships | README.md in both shared and per-repo .github/ |
| **Onboard systematically** | Consistent quality | Use template + checklist for every new repo |

---

## Migration Path: Existing Repos

### If repos currently have duplicate instructions:

**Phase 1: Audit (30 min)**
```bash
find . -name ".copilot-instructions.md" -o -name "*instructions.md"
# Count: how many repos have copies?
```

**Phase 2: Create central shared space** (already done)

**Phase 3: Consolidate per-repo (2 hours)**
```bash
# For each repo:
# 1. Keep only .copilot-instructions.md (repo-specific parts)
# 2. Reference /.copilot-shared/ for shared parts
# 3. Remove duplicate files
# 4. Create symlink to shared instructions
# 5. Commit
```

**Phase 4: Verify (30 min)**
```bash
# For each repo, check:
# - Agents work correctly
# - Instructions load
# - Memory accessible
```

---

## Summary: Multi-Repo Architecture

```
ONE SHARED SPACE (/.copilot-shared/)
├─ Core instructions (00-core-instructions.md)
├─ Skills (consolidated, 12-15 core skills)
├─ Memory (cross-repo insights)
└─ Used by 15+ repositories

15+ REPOS (each lightweight)
├─ .github/.copilot-instructions.md (repo-specific rules)
├─ .github/copilot-memory.md (repo-specific findings)
└─ Reference shared space for global guidelines

RESULT:
✅ No duplication (400 KB shared + 150 KB per-repo = 550 KB total)
✅ Single source of truth
✅ Easy to update globally
✅ Per-repo customization possible
✅ 95% token savings across system
```

---

**Next Step:** Apply this architecture to each of your 15+ repos!

See: TOKEN_OPTIMIZATION_IMPLEMENTATION.md for Phase 1-2 setup of the shared space, then use this guide to link all repos to it.
