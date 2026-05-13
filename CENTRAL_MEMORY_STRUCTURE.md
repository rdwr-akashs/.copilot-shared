# Central Memory Directory Reference

**Quick index:** Where does each type of documentation live?

---

## 📍 Shared (Accessible from ALL Repos)

These folders are **shared across all repositories** via filesystem junctions. When you write to any repo's `.github/` folder, it appears everywhere.

### Cases: Customer Issues & Resolutions

```
.copilot-shared/shared/cases/
├── customer-cases/
│   ├── RSEG-2024-001.md          ← Customer case: symptom, root cause, fix
│   ├── SC-2024-045.md
│   ├── INC-2024-789.md
│   └── <case-id>.md
│
└── root-cause-analysis/
    ├── rca-RSEG-2024-001.md      ← Deep RCA with logs, code evidence
    ├── rca-SC-2024-045.md
    └── rca-<case-id>.md
```

**Who uses it?**
- Support engineers investigating customer issues
- DevOps responding to incidents
- Developers building features to fix known problems

**How to contribute:**
```powershell
# From any repo:
New-Item -ItemType Directory -Path ".github/cases/customer-cases" -Force
"# Case RSEG-2024-001..." | Out-File ".github/cases/customer-cases/RSEG-2024-001.md"
```

---

### Learning: Best Practices & Patterns

```
.copilot-shared/shared/learning/
├── best-practices/
│   ├── java-patterns.md          ← Design patterns in Java
│   ├── performance-tuning.md     ← How to optimize components
│   ├── security-hardening.md     ← Security best practices
│   ├── ha-failover.md            ← HA/failover patterns
│   └── <topic>.md
│
├── design-patterns/
│   ├── event-driven.md           ← Event-driven architecture
│   ├── state-management.md       ← State machine patterns
│   ├── cache-invalidation.md     ← Caching strategies
│   └── <pattern>.md
│
└── troubleshooting/
    ├── common-errors.md          ← "Error X means Y, fix with Z"
    ├── debugging-guide.md        ← How to debug common issues
    ├── performance-bottlenecks.md
    └── <issue>.md
```

**Who uses it?**
- New team members learning codebase
- Developers avoiding known pitfalls
- Architects designing new features
- Copilot agents filling knowledge gaps

**How to contribute:**
```powershell
# From any repo:
"## Topic Name

Problem statement...

**Pattern:** ...

**Example:**
...
" | Out-File ".github/learning/best-practices/<topic>.md"
```

---

## 📍 Shared (Global, Not Repo-Specific)

These are **global knowledge files** maintained by the team, not individual repos.

### Known Bugs Registry

```
.copilot-shared/shared/memory/known-bugs.md
```

**Structure:**
```markdown
## Bug ID: DE-12345
**Title:** BGP peers fail to sync after standby failover
**Affected Versions:** DF < 4.7.1.0
**Fixed In:** DF 4.7.1.0
**Workaround:** [steps]
**Root Cause:** [explanation]
**Link:** [JIRA ticket]
```

**Who updates it?**
- QA after confirming bug
- Developers after shipping fix
- Support when they encounter known issue

---

### Customer Cases Patterns

```
.copilot-shared/shared/memory/customer-cases.md
```

**Structure:**
```markdown
## Pattern: HA Failover Stability

**Symptoms:**
- BGP peers disappear after failover
- Config not synced to standby
- Intermittent connectivity loss

**Common Root Causes:**
1. PostgreSQL replication broken (check recovery.conf)
2. HA sync missing BGP subsystem
3. NTP skew causing TTL timeouts

**Solutions:**
1. Verify pg_hba.conf has replication entry
2. Check HaSyncHandler includes BgpPeer table
3. Sync NTP across both nodes
```

---

### Tech Discoveries & Architecture Map

```
.copilot-shared/shared/memory/tech-discoveries.md
.copilot-shared/shared/memory/architecture-map.md
```

**Maintained by:** `bin/workspace-scan.ps1` (auto-generated weekly)

**Contains:**
- List of all repos and their tech stacks
- Service relationships (which service calls which)
- Data flow diagrams
- API dependencies

---

### Cross-Repo Learnings

```
.copilot-shared/shared/memory/cross-repo/
├── architecture-patterns.md      ← Patterns used across multiple repos
├── deployment-learnings.md       ← How we deploy across services
└── incident-retrospectives.md    ← What we learned from incidents
```

**Maintained by:** Team leads and architects

---

## 📍 Repo-Specific (Accessible from That Repo Only)

These folders are **not shared** — each repo has its own copy.

### Repository Memory

```
.copilot-shared/shared/memory/<repo-name>/
├── memory.md                     ← Current focus, ongoing work
├── architecture.md               ← Repo-specific architecture notes
├── performance-notes.md          ← Performance optimization learnings
├── bugs-and-patterns.md          ← Bugs specific to this repo
└── <custom-notes>.md
```

**Example:**
```
.copilot-shared/shared/memory/df_core/
├── memory.md                     ← "Currently refactoring HA module"
├── architecture.md               ← "DF Core uses ExaBGP for BGP distribution"
├── performance-notes.md          ← "HA sync threshold tuned to 100ms"
└── ha-module-refactor.md         ← Ongoing refactor notes
```

**Who uses it?**
- Developers in that repo
- Copilot agents working in that repo
- Not shared with other repos

**How to contribute:**
```powershell
# From df_core:
"Performance note: BGP peer sync slower after 10K prefixes" `
  | Add-Content ".github/copilot-memory/performance-notes.md"
```

---

## 🔍 How to Find Things

### "I want to understand a customer issue"
→ Start here: `.copilot-shared/shared/cases/customer-cases/`
→ Then read: `.copilot-shared/shared/memory/known-bugs.md`

### "I need to debug this error"
→ Check: `.copilot-shared/shared/learning/troubleshooting/`
→ Then search: `.copilot-shared/shared/cases/root-cause-analysis/`

### "How do we handle X pattern?"
→ Look here: `.copilot-shared/shared/learning/design-patterns/`
→ Then see: `.copilot-shared/shared/learning/best-practices/`

### "What does this repo do?"
→ Read: `.copilot-shared/shared/memory/tech-discoveries.md`
→ Or view: `.copilot-shared/shared/memory/architecture-map.md`

### "I need to optimize performance"
→ Check: `.copilot-shared/shared/memory/<repo>/performance-notes.md`
→ Then read: `.copilot-shared/shared/learning/best-practices/performance-tuning.md`

### "What are we currently working on?"
→ See: `.copilot-shared/shared/memory/active-context.md`

---

## 📊 Complete Directory Tree

```
.copilot-shared/shared/
│
├── memory/                           ← GLOBAL KNOWLEDGE
│   ├── active-context.md             ← Current work focus
│   ├── architecture-map.md           ← Auto-generated service map
│   ├── customer-cases.md             ← Case patterns & learnings
│   ├── known-bugs.md                 ← Bug registry
│   ├── tech-discoveries.md           ← Repo registry
│   ├── cross-repo-learnings.md       ← Architecture decisions
│   │
│   ├── cross-repo/                   ← SHARED PATTERNS
│   │   ├── architecture-patterns.md
│   │   ├── deployment-learnings.md
│   │   └── incident-retrospectives.md
│   │
│   ├── df_core/                      ← DF CORE (REPO-SPECIFIC)
│   │   ├── memory.md
│   │   ├── architecture.md
│   │   ├── performance-notes.md
│   │   └── bugs-and-patterns.md
│   │
│   ├── kvision_collector/            ← KVISION COLLECTOR (REPO-SPECIFIC)
│   │   └── ...
│   │
│   ├── repo-contexts/                ← AUTO-GENERATED CONTEXT PACKS
│   │   ├── _index.md
│   │   ├── df_core.md
│   │   └── kvision_collector.md
│   │
│   └── logs/                         ← SETUP LOGS
│       └── centralize-memory-*.log
│
├── cases/                            ← SHARED CASE DOCUMENTATION
│   ├── customer-cases/               ← Customer issues (one file per case)
│   │   ├── RSEG-2024-001.md
│   │   ├── SC-2024-045.md
│   │   └── INC-2024-789.md
│   │
│   └── root-cause-analysis/          ← Deep RCA documents
│       ├── rca-RSEG-2024-001.md
│       └── rca-<case-id>.md
│
└── learning/                         ← SHARED KNOWLEDGE BASE
    ├── best-practices/               ← How we do things
    │   ├── java-patterns.md
    │   ├── performance-tuning.md
    │   ├── security-hardening.md
    │   ├── ha-failover.md
    │   └── ...
    │
    ├── design-patterns/              ← Common patterns
    │   ├── event-driven.md
    │   ├── state-management.md
    │   └── ...
    │
    └── troubleshooting/              ← How to fix things
        ├── common-errors.md
        ├── debugging-guide.md
        ├── performance-bottlenecks.md
        └── ...
```

---

## 🔄 How Data Flows

```
Developer writes in any repo:
  .github/cases/customer-cases/RSEG-2024-001.md
            ↓
File is at that location via junction
            ↓
File is simultaneously at:
  .copilot-shared/shared/cases/customer-cases/RSEG-2024-001.md
            ↓
All other repos can read it via their junctions:
  kvision_collector/.github/cases/customer-cases/RSEG-2024-001.md
  df_core/.github/cases/customer-cases/RSEG-2024-001.md
  vision_core/.github/cases/customer-cases/RSEG-2024-001.md
            ↓
Copilot agents in all repos see the same file
```

---

## 🎯 Content Guidelines

| Type | File | Audience | Frequency | Owner |
|------|------|----------|-----------|-------|
| Customer case | `cases/customer-cases/*.md` | Support/Ops | As needed | Case lead |
| RCA document | `cases/root-cause-analysis/*.md` | Engineering | Post-incident | Lead engineer |
| Best practice | `learning/best-practices/*.md` | All engineers | Ongoing | Team |
| Design pattern | `learning/design-patterns/*.md` | Architects/leads | As discovered | Architect |
| Troubleshooting | `learning/troubleshooting/*.md` | All engineers | As needed | Discoverer |
| Known bugs | `memory/known-bugs.md` | All engineers | With each fix | QA/Dev |
| Repo architecture | `memory/<repo>/architecture.md` | That repo team | Monthly | Lead dev |
| Performance notes | `memory/<repo>/performance-notes.md` | That repo team | As optimized | Perf team |

---

**See also:**
- [CENTRAL_MEMORY_SYNC_GUIDE.md](CENTRAL_MEMORY_SYNC_GUIDE.md) — Setup and maintenance
- [CENTRAL_MEMORY_QUICK_START.md](CENTRAL_MEMORY_QUICK_START.md) — Quick reference
- [shared/memory/README.md](shared/memory/README.md) — Memory store details
