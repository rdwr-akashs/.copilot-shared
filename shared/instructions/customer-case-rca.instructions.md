---
applyTo: '**/cases/**,**/.agent_work/**'
---

# Customer Case RCA — Process Instruction

This instruction governs every customer-case / field-escalation investigation, regardless of product or repo. It encodes the **process only**. Product-specific paths, log filenames, and grep patterns belong in each repo's `.github/instructions-local/triage-rules.instructions.md`.

The `case-investigator` agent is the entry point. The orchestrator routes any task with these signals to it:
- Ticket prefixes: `RSEG-`, `SC-`, `INC-`, `JIRA-`, etc.
- Phrases: "support bundle", "support file", "customer logs", "RCA", "field escalation", "customer escalation".

---

## Iron Laws

1. **No grep before scaffolding.** The first action on any case is to create `.agent_work/<case-id>/investigation.md`. The MD is the persistent context across interactions.
2. **No triage before archive lookup.** Phase 0.5 always runs — a prior solved case may already match.
3. **No fixes proposed without evidence.** Every claim cites: exact log line + timestamp + source file path.
4. **No agent edits product code.** The investigator drafts; the developer agent edits.
5. **No case is "closed" without archiving.** Solved cases must be persisted to `.copilot-shared/cases/<case-id>/` so future investigations benefit.

---

## Phase Map

| # | Phase | Output |
|---|-------|--------|
| 0 | Living MD scaffold | `.agent_work/<case-id>/investigation.md` + `_inventory.md` + `_extraction.log` |
| 0.5 | Prior-case lookup | top-3 matches with confidence % (or "no prior match") |
| 1 | Problem framing | symptom, trigger, scope, hypotheses (in MD) |
| 2 | Evidence triage (parallel) | structured findings table per category |
| 3 | Code-path mapping | `file:method:line` evidence rows |
| 4 | Field-vs-code validation | mismatch / confirmation rows |
| 5 | Fix direction + RCA doc | `rca-<case-id>.md` (10 sections) |
| 6 | Minimal fix + commit msg | RCA §6 — fix snippet + draft commit message |
| 7 | Archive | `.copilot-shared/cases/<case-id>/{rca,fix,signature}` |
| 8 | Hand-off | developer agent applies the fix |

---

## Phase 0 — Living Investigation MD

Path: `.agent_work/<case-id>/investigation.md`.

Mandatory header:

```markdown
# Investigation: <case-id>

| Field | Value |
|-------|-------|
| Case ID | <id> |
| Customer | <name or "internal"> |
| Product | <name> |
| Versions | <component>: <x.y.z>; … |
| Topology | <one line: HA pair, single node, cluster size> |
| Reported | <YYYY-MM-DD> |
| Bundle path | <abs path> |
| Analyst | <user> |
| Status | open / in-progress / resolved / archived |

## Symptom (one line)

## Trigger Conditions

## What works vs. what breaks

## Hypotheses (initial)

## Findings (filled in Phase 2)

## Code Evidence (filled in Phase 3)

## Field-vs-Code Validation (filled in Phase 4)

## Open Questions

## Decisions

## Next Steps
```

**Update the MD at the end of every chat turn.** Per Methodology: *"Summarize what we learned today into the investigation MD, and note what's still missing."*

---

## Phase 0.5 — Prior Case Lookup

Always run before triage. See `.github/skills/case-archive/SKILL.md` (lookup mode).

Match dimensions (descending priority):
1. Error codes / message strings (highest signal)
2. Symptom keywords + log signatures
3. Product + version range overlap
4. Topology

If a prior case matches ≥80%: surface to user and ask whether to short-circuit (apply prior fix verbatim) or run a fresh investigation. **Default: confirm with user.**

---

## Phase 2 — Triage Categories (generic)

Each category is independent → dispatched in parallel.

| # | Category | Looks for |
|---|----------|-----------|
| 1 | Identity & Version | product version, build, uptime, hardware/RAM/CPU |
| 2 | Connectivity / Network | peer/link state, interface counters, routing, DNS |
| 3 | Replication / State Sync | DB replication state, configuration rank, sync lag |
| 4 | HA / Failover | role, dormant flags, failover history, incomplete operations |
| 5 | Resource Exhaustion | CPU/memory/disk pressure alerts, OOM, swap |
| 6 | External Service Connectivity | upstream/dependent service errors, timeouts, auth failures |
| 7 | Polling / Load | request rate, expensive endpoints, sustained load |
| 8 | Container / Process Health | crash loops, exit codes, restart cycles |
| 9 | Time Sync | NTP skew between nodes |

For each category, the triage subagent must return:
- **Quantitative count** (e.g., "317 errors matching `<regex>`")
- **Exact log lines** with timestamps (verbatim, not paraphrased)
- **Source file path** (relative to bundle root)
- **Active-vs-standby comparison** (when topology has standby)

Generic fallback when no per-repo `triage-rules.instructions.md` exists: keyword-grep over the entire bundle using the symptom keywords from Phase 1.

---

## Phase 3 — Code-Path Mapping

For each Phase-2 finding:

1. **Repo discovery**: scan sibling directories under the parent of the active workspace for repos matching the product/component name (look for `pom.xml`, `package.json`, `Cargo.toml`, `go.mod`, `copilot-instructions.md`).
2. **Locate** `file:method:line` that produces the symptom. Use `cross-repo-exploration` skill for sibling repos.
3. **Changelog scan** (replaces any static known-bugs table): in each candidate repo, grep `{CHANGES,CHANGELOG,HISTORY,RELEASE_NOTES,NEWS}*` (case-insensitive) under repo root + `docs/` for symptom keywords + error codes. If none of those files exist, fall back to:
   ```
   git --no-pager log --grep="<keyword>" -i --since="2 years ago"
   ```
4. Record: repo, file, method, line, before-snippet, matched-changelog-entry (if any), version-of-fix-if-known.

---

## Phase 5 — RCA Document Structure

See `.github/skills/rca-document/SKILL.md` for the 10-section template and the Output Checklist gate.

Hard requirements:
- Every section has either evidence rows or "N/A — <one-line reason>".
- Confidence % per finding.
- §6 includes a **Suggested Commit Message** in conventional-commit format:
  ```
  <type>(<scope>): <imperative one-line summary>

  <body: root cause + evidence summary, ≤72 chars per line>

  Refs: <case-id>
  ```

---

## Phase 7 — Archive

After the user accepts the RCA (and optionally the proposed fix), persist the case via `.github/skills/case-archive/SKILL.md` (write mode):

```
.copilot-shared/cases/<case-id>/
├── rca.md         # copy of .agent_work/<case-id>/rca-<case-id>.md
├── fix.md         # before/after snippet + commit message + target version
└── signature.yml  # searchable index
```

Append a row to `.copilot-shared/cases/_index.md`.

The archive lives in the **local-only** `.copilot-shared` git repo (per README — no remote). Customer data does not leave the workstation.

---

## Hand-Off Contract

When the user approves the fix, summarise for the developer agent:

```
File:        <path>
Method:      <name>
Before:      <snippet>
After:       <snippet>
Commit msg:  <full message>
Validation:  <test commands>
References:  <case-id>, <RCA path>
```

The developer agent owns: edit → build → test (`verification-before-completion` skill) → commit + push (`commit-push` skill).

The investigator does **not** run any of these steps.

---

## Per-Repo Override Hook

Each product repo may add `.github/instructions-local/triage-rules.instructions.md` with concrete patterns. Example shape:

```markdown
---
applyTo: '**'
---
# Triage rules — <product>

## Bundle layout
Active:  dfc_support_*/
Standby: dfc_support_*/standby_support/

## Category overrides
### Identity & Version
- cli/system_info.txt — DF version, build, uptime
- vision_version.txt  — Vision version

### HA / Failover
- cli/ha_list.txt
- logs/ha.log — grep "dormant|failover|delete|starting|done|elected|promote"

### Replication / State Sync
- postgresql/config/pg_hba.conf — must contain "host replication ..."
- postgresql/config/recovery.conf — must exist on standby (not .orig)

…etc…
```

When this file is present, the triage skill **prefers** it. When absent, the skill falls back to keyword-only grep.
