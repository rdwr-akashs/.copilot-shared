# Complete File Reference: Where Everything Points

**Quick lookup:** Which files point where? Comprehensive mapping of all agents, instructions, and scripts.

---

## 🎯 Agent Routing & References

| Agent | File | References These | Status |
|-------|------|---|---|
| **Case Investigator** | `agent-templates/case-investigator.agent.md` | `shared/memory/known-bugs.md` | ✅ Correct |
| | | `shared/memory/customer-cases.md` | ✅ Correct |
| | | `shared/memory/repo-contexts/<repo>.md` | ✅ Correct |
| | | `.copilot-shared/cases/<case-id>/` (write) | ✅ Correct |
| **Developer** | `agent-templates/developer.agent.md` | `shared/memory/repo-contexts/<repo>.md` | ✅ Correct |
| | | `shared/memory/known-bugs.md` | ✅ Correct |
| | | `shared/memory/cross-repo-learnings.md` | ✅ Correct |
| | | `save-learning` skill → `shared/memory/*.md` | ✅ Correct |
| **Debugger** | `agent-templates/debugger.agent.md` | `shared/memory/known-bugs.md` | ✅ Correct |
| | | `shared/memory/tech-discoveries.md` | ✅ Correct |
| **Perf Investigator** | `agent-templates/perf-investigator.agent.md` | `shared/memory/<repo>/performance-notes.md` | ✅ Correct |
| **Tester** | `agent-templates/tester.agent.md` | `save-learning` skill → `shared/memory/*.md` | ✅ Correct |
| **All others** | All remaining agents | `shared/memory/*.md` (context) | ✅ Correct |

---

## 📋 Instruction File References

| Instruction File | ApplyTo | References These | Status |
|---|---|---|---|
| **memory-bank.instructions.md** | `**` | `.copilot-shared/shared/memory/` | ✅ Correct |
| | | `memory-bank/` junction → central | ✅ Correct |
| | | `.github/learning/` junction → central | ✅ Correct |
| | | `.github/cases/` junction → central | ✅ Correct |
| **orchestrator.instructions.md** | `**` | `shared/memory/active-context.md` | ✅ Correct |
| | | `shared/memory/repo-contexts/<repo>.md` | ✅ Correct |
| | | `shared/memory/known-bugs.md` | ✅ Correct |
| | | `shared/memory/customer-cases.md` | ✅ Correct |
| **customer-case-rca.instructions.md** | `**/cases/**,**/.agent_work/**` | `.agent_work/<case-id>/investigation.md` (write) | ✅ Correct |
| | | `.copilot-shared/cases/<case-id>/` (write) | ✅ Correct |
| **design-principles.instructions.md** | `**` | `shared/memory/cross-repo-learnings.md` | ✅ Correct |
| **java-conventions.instructions.md** | `**` | `shared/memory/<repo>/architecture.md` | ✅ Correct |
| **react-conventions.instructions.md** | `**` | `shared/memory/<repo>/architecture.md` | ✅ Correct |

---

## 🔧 Setup & Linking Scripts

| Script | What It Does | References | Status |
|--------|---|---|---|
| **link-copilot.cmd** | Creates junctions in `.github/` | `shared/skills/` | ✅ Creates junction |
| | | `shared/instructions/` | ✅ Creates junction |
| | | `shared/prompts/` | ✅ Creates junction |
| | | `shared/plans/` | ✅ Creates junction |
| **setup-repo.ps1** | Full repo setup | Reads from `shared/memory/tech-discoveries.md` | ✅ Correct |
| | | Creates `.copilot-shared/shared/memory/<repo>/` | ✅ Creates directory |
| | | Calls `link-copilot.cmd` | ✅ Correct |
| **centralize-memory.ps1** | Consolidates memory | Creates `shared/learning/` dirs | ✅ Creates directories |
| | | Creates `shared/cases/` dirs | ✅ Creates directories |
| | | Creates `shared/memory/<repo>/` dirs | ✅ Creates directories |
| | | Junctions `memory-bank/` → central | ✅ Creates junction |
| | | Junctions `.github/learning/` → central | ✅ Creates junction |
| | | Junctions `.github/cases/` → central | ✅ Creates junction |
| | | Copies existing memory to central | ✅ Consolidates content |
| **verify-central-memory.ps1** | Audits repo linkage | Checks for junctions | ✅ Verifies |
| | | Reports status | ✅ Reports |
| | | Auto-repairs with `-Repair` flag | ✅ Can fix |

---

## 📁 Directory Structure: Write Locations

| Content Type | Where It Lives | Who Writes | Who Reads |
|---|---|---|---|
| **Customer Cases** | `.copilot-shared/shared/cases/customer-cases/` | Case Investigator Agent | All agents |
| **RCA Documents** | `.copilot-shared/shared/cases/root-cause-analysis/` | Case Investigator Agent | Support/DevOps |
| **Best Practices** | `.copilot-shared/shared/learning/best-practices/` | Developers via agents | All engineers |
| **Design Patterns** | `.copilot-shared/shared/learning/design-patterns/` | Architects via agents | All engineers |
| **Troubleshooting** | `.copilot-shared/shared/learning/troubleshooting/` | Developers via agents | Debuggers |
| **Known Bugs** | `.copilot-shared/shared/memory/known-bugs.md` | QA/DevOps via agents | Debuggers/Devs |
| **Customer Cases Patterns** | `.copilot-shared/shared/memory/customer-cases.md` | Case investigators | All agents |
| **Repo-Specific Memory** | `.copilot-shared/shared/memory/<repo-name>/` | Agents in that repo | That repo's agents |
| **Active Context** | `.copilot-shared/shared/memory/active-context.md` | Any agent | All agents |
| **Architecture Map** | `.copilot-shared/shared/memory/architecture-map.md` | `workspace-scan.ps1` | Architects |

---

## 🔗 Junction Map: What Points Where

### In Every Repo (Created by `link-copilot.cmd` or `setup-repo.ps1`)

```
<repo>/.github/
├── skills/              → .copilot-shared/shared/skills/
├── instructions/        → .copilot-shared/shared/instructions/
├── prompts/             → .copilot-shared/shared/prompts/
├── plans/               → .copilot-shared/shared/plans/
├── learning/            → .copilot-shared/shared/learning/
└── cases/               → .copilot-shared/shared/cases/

<repo>/
└── memory-bank/         → .copilot-shared/shared/memory/<repo-name>/
```

**Result:** Writing to any of these locations writes directly to central. All repos see the same files.

---

## 📖 Template Files: What They Contain

| Template | What It Specifies | References | Status |
|----------|---|---|---|
| **copilot-instructions.template.md** | Project overview | `orchestrator.instructions.md` for routing | ✅ Correct |
| | | `.github/personal-instructions.md` | ✅ Correct |
| | | `.github/instructions-local/project-rules.md` | ✅ Correct |
| **COPILOT-SETUP.template.md** | Onboarding guide | Explains junction structure | ✅ Correct |
| | | Links to `.copilot-shared/bin/` scripts | ✅ Correct |
| | | Explains memory location | ✅ Correct |

---

## 🎓 Data Flow Examples

### Case Investigation Flow
```
1. New ticket: RSEG-2024-001
2. Route to: Case Investigator Agent
3. Agent reads: shared/memory/known-bugs.md
4. Agent reads: shared/memory/customer-cases.md
5. Agent reads: shared/memory/repo-contexts/df_core.md
6. Agent writes: .agent_work/RSEG-2024-001/investigation.md
7. Agent writes: .copilot-shared/cases/RSEG-2024-001/rca.md
8. Agent updates: .copilot-shared/cases/_index.md
9. Next case investigator reads: .copilot-shared/cases/_index.md
10. Finds prior case match → short-circuits investigation
```

**All reads/writes to central** ✅

### Learning Contribution Flow
```
1. Developer in df_core fixes BGP issue
2. Developer writes: .github/learning/troubleshooting/bgp-failover.md
3. Junction redirects: write to shared/learning/troubleshooting/bgp-failover.md
4. Developer in kvision_collector reads: .github/learning/troubleshooting/
5. Sees bgp-failover.md (via central)
6. Applies same fix pattern
```

**Automatic sharing via junctions** ✅

### Memory Bank Context Flow
```
1. Agent in df_core writes: memory-bank/performance-notes.md
2. Junction redirects: write to shared/memory/df_core/performance-notes.md
3. Agent in kvision_collector needs cross-repo context
4. Reads: shared/memory/df_core/performance-notes.md
5. Gets DF Core's performance insights
```

**Single source of truth** ✅

---

## ✅ Verification Checklist

After setup, verify:

- [ ] `.github/skills/` is a junction (not real folder)
- [ ] `.github/instructions/` is a junction (not real folder)
- [ ] `.github/prompts/` is a junction (not real folder)
- [ ] `.github/plans/` is a junction (not real folder)
- [ ] `.github/learning/` is a junction (points to central)
- [ ] `.github/cases/` is a junction (points to central)
- [ ] `memory-bank/` is a junction (points to `shared/memory/<repo-name>/`)
- [ ] `.gitignore` includes entries for all junctions
- [ ] Can read files from `memory-bank/` in another repo's junction location
- [ ] Writing to `<repo>/.github/cases/` appears in `.copilot-shared/shared/cases/` instantly
- [ ] All agents see `.github/learning/` files via junctions

**Run:** `powershell -File .copilot-shared\bin\verify-central-memory.ps1`

---

## 🔍 Reference Lookup Table

**"Where does X save/read from?"**

| Question | Answer |
|----------|--------|
| Case Investigator saves RCAs | `.copilot-shared/cases/<case-id>/rca.md` |
| Developer saves learnings | `shared/memory/*.md` (via `save-learning` skill) |
| Agents read known bugs | `shared/memory/known-bugs.md` |
| Agents read case patterns | `shared/memory/customer-cases.md` |
| Agents read cross-repo context | `shared/memory/repo-contexts/<repo>.md` |
| Agents read cross-repo patterns | `shared/memory/cross-repo-learnings.md` |
| Agents read repo-specific notes | `shared/memory/<repo-name>/` |
| Agents read best practices | `.github/learning/best-practices/` (via junction) |
| Agents read troubleshooting | `.github/learning/troubleshooting/` (via junction) |
| Agents read cases | `.github/cases/customer-cases/` (via junction) |
| Team reads active focus | `shared/memory/active-context.md` |
| Team reads service map | `shared/memory/architecture-map.md` |
| New team member gets repo info | `shared/memory/tech-discoveries.md` |

---

## 🚀 Quick Commands

```powershell
# Check status of all repos
powershell -File .copilot-shared\bin\verify-central-memory.ps1

# Auto-fix broken repos
powershell -File .copilot-shared\bin\verify-central-memory.ps1 -Repair

# Setup a new repo
.copilot-shared\bin\setup-repo.ps1 C:\path\to\new\repo

# Link a repo that already has .github
.copilot-shared\bin\link-copilot.cmd C:\path\to\repo

# Centralize existing memory from multiple repos
powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\rdwr-intelij" `
  -Repos "df_core,kvision_collector,webui_components" `
  -CreateSymlinks 1 `
  -DeleteLocal 0 `
  -Verify 1
```

---

## 📚 Documentation Index

| Document | Purpose | Audience |
|----------|---------|----------|
| [CENTRAL_MEMORY_SYNC_GUIDE.md](CENTRAL_MEMORY_SYNC_GUIDE.md) | Complete setup & maintenance | DevOps/Admins |
| [CENTRAL_MEMORY_QUICK_START.md](CENTRAL_MEMORY_QUICK_START.md) | Quick reference | All engineers |
| [CENTRAL_MEMORY_STRUCTURE.md](CENTRAL_MEMORY_STRUCTURE.md) | Directory reference | All engineers |
| [AUDIT_CENTRAL_MEMORY_INTEGRATION.md](AUDIT_CENTRAL_MEMORY_INTEGRATION.md) | System verification | Leads/Architects |
| [WHERE_EVERYTHING_POINTS.md](WHERE_EVERYTHING_POINTS.md) | This file | Lookup reference |

---

**Last Updated:** May 11, 2026
**Status:** ✅ All systems operational — Zero manual changes needed
