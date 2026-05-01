# Customer Case RCA Workflow

End-to-end, subagent-driven workflow for investigating customer field escalations (RSEG-/SC-/INC-/JIRA- tickets with support bundles). Generic across all repos and products — no product-specific assumptions.

> **Entry point:** the `case-investigator` agent. Paste the prompt at [`../prompts/investigate-customer-case.md`](../prompts/investigate-customer-case.md) into Copilot Chat from any linked repo.

---

## How to start an investigation

### 1. (One-time, per repo) Pick up the new agent

```cmd
%COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\refresh-agents.cmd %COPILOT_WORKSPACE_ROOT%\<repo>
```

The skills, instruction, and prompt are already live via junctions — only the agent file needs copying.

### 2. Paste the kickoff prompt

Minimal form:

```
Investigate customer case <CASE-ID>.

Bundle path:  <ABSOLUTE PATH to support directory or zip>
Product:      <product name | "auto-detect">
Versions:     <component>: <x.y.z>; …  (or "unknown — extract from bundle")
Topology:     <HA pair | single node | cluster of N>
Severity:     <P1 | P2 | P3 | P4>

Symptom (one line):
<exact UI/CLI/log output the customer reported>

Use the case-investigator agent.
```

The orchestrator classifies the task (signals: `RSEG-/SC-/INC-/JIRA-`, "support bundle", "RCA", "customer logs", "field escalation") and routes it to `case-investigator`.

---

## Phase map

| # | Phase | Skill | Output | Gate |
|---|-------|-------|--------|------|
| 0   | Living MD scaffold + auto-unzip | [`customer-case-intake`](../skills/customer-case-intake/SKILL.md) | `.agent_work/<id>/investigation.md`, `_inventory.md`, `_extraction.log` | — |
| 0.5 | Prior-case lookup | [`case-archive`](../skills/case-archive/SKILL.md) (lookup mode) | top-3 prior matches with confidence % | user decides: apply prior / fresh |
| 1   | Problem framing | `customer-case-intake` | symptom, trigger, hypotheses appended to MD | — |
| 2   | Evidence triage (parallel ×9) | [`support-file-triage`](../skills/support-file-triage/SKILL.md) + [`dispatching-parallel-agents`](../skills/dispatching-parallel-agents/SKILL.md) | unified `§Findings` table | — |
| 3   | Code-path mapping | [`rca-evidence-mapping`](../skills/rca-evidence-mapping/SKILL.md) (+ [`cross-repo-exploration`](../skills/cross-repo-exploration/SKILL.md)) | `§Code Evidence` rows: `repo / file / method / line` + changelog hits | — |
| 4   | Field-vs-code validation | `rca-evidence-mapping` | `§Field-vs-Code Validation` | — |
| 5–6 | RCA doc + commit message | [`rca-document`](../skills/rca-document/SKILL.md) | `rca-<id>.md` (10 sections, draft commit msg) | **user accepts RCA** |
| 7   | Archive | `case-archive` (write mode) | `.copilot-shared/cases/<id>/{rca,fix,signature}` + `_index.md` row | — |
| 8   | Fix hand-off | — | `developer` agent applies fix via [`commit-push`](../skills/commit-push/SKILL.md) | **user approves code edit** |

---

## Iron laws

1. **No grep before scaffolding.** Phase 0 always runs first. The investigation MD is the persistent context.
2. **No triage before archive lookup.** Phase 0.5 may match a prior case in seconds.
3. **No claims without evidence.** Every finding cites: exact log line + timestamp + source file path.
4. **Investigator never edits product code.** It drafts; the `developer` agent edits.
5. **No case is "closed" without archiving.** Solved cases must persist to `.copilot-shared/cases/`.

---

## File map

```
shared/
├── instructions/
│   ├── customer-case-rca.instructions.md   # process-only, generic
│   └── customer-case-rca.README.md          # this file
├── prompts/
│   └── investigate-customer-case.md         # kickoff template
└── skills/
    ├── customer-case-intake/SKILL.md        # Phase 0 — scaffold + auto-unzip
    ├── support-file-triage/SKILL.md         # Phase 2 — 9 categories, parallel
    ├── rca-evidence-mapping/SKILL.md        # Phase 3 — file:method:line + CHANGES.txt
    ├── rca-document/SKILL.md                # Phase 5/6 — 10-section RCA + commit msg
    └── case-archive/SKILL.md                # Phase 0.5 lookup + Phase 7 write

agent-templates/
└── case-investigator.agent.md               # the orchestrating agent

cases/                                        # local-only solved-case archive
                                              # at %COPILOT_WORKSPACE_ROOT%\.copilot-shared\cases\
├── README.md
├── _index.md
├── _template/signature.yml
└── <case-id>/
    ├── rca.md
    ├── fix.md
    └── signature.yml
```

---

## Where artefacts land

| Artefact | Path | Lifecycle |
|----------|------|-----------|
| Living investigation MD | `<repo>\.agent_work\<case-id>\investigation.md` | Per-case working file (gitignored) |
| File inventory | `<repo>\.agent_work\<case-id>\_inventory.md` | Per-case |
| Extraction log | `<repo>\.agent_work\<case-id>\_extraction.log` | Per-case |
| Final RCA | `<repo>\.agent_work\<case-id>\rca-<case-id>.md` | Per-case |
| Persisted post-mortem | `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\cases\<case-id>\` | Permanent, **local-only** |
| Lookup index | `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\cases\_index.md` | Permanent, **local-only** |

---

## The triage fan-out (Phase 2)

Each category is dispatched as an independent subagent — no shared state between them. Results are merged into a single `§Findings` table.

| # | Category | Looks for |
|---|----------|-----------|
| 1 | Identity & Version | product version, build, uptime, hardware |
| 2 | Connectivity / Network | peer state, interface counters, routing, DNS |
| 3 | Replication / State Sync | DB replication, configuration rank, sync lag |
| 4 | HA / Failover | role, dormant flags, **incomplete operations** (`starting` without `done`) |
| 5 | Resource Exhaustion | CPU/memory/disk, OOM, swap |
| 6 | External Service Connectivity | upstream errors (`M_xxx`, timeouts, auth failures) |
| 7 | Polling / Load | sustained request rate, expensive endpoints |
| 8 | Container / Process Health | crash loops, exit codes (`137`, `255`) |
| 9 | Time Sync | NTP skew between nodes |

Each subagent returns: `count | exact log line + timestamp | source file | active vs standby`. No interpretation, no fixes — that's the RCA-author's job.

---

## Per-product triage rules (optional but recommended)

To make Phase 2 sharper for a specific product, drop a `triage-rules.instructions.md` in that product's repo:

```
<product-repo>/.github/instructions-local/triage-rules.instructions.md
```

Example shape (from [`customer-case-rca.instructions.md`](../instructions/customer-case-rca.instructions.md)):

```markdown
---
applyTo: '**'
---
# Triage rules — <product>

## Bundle layout
Active:  dfc_support_*/
Standby: dfc_support_*/standby_support/

## Category overrides
### HA / Failover
- cli/ha_list.txt
- logs/ha.log — grep "dormant|failover|delete|starting|done|elected|promote"

### Replication / State Sync
- postgresql/config/pg_hba.conf — must contain "host replication ..."
- postgresql/config/recovery.conf — must exist on standby (not .orig)
```

When this file is present, the triage skill prefers it. When absent, it falls back to generic keyword grep over the entire bundle (still works — just less precise).

---

## Known-issues lookup (no static table)

Phase 3 does **not** maintain a hard-coded bug catalogue. Instead, for every finding it greps each candidate repo's:

```
{CHANGES,CHANGELOG,HISTORY,RELEASE_NOTES,NEWS}*    (case-insensitive, root + docs/)
```

for symptom keywords + error codes scoped to the customer's exact version. If no changelog files exist, it falls back to:

```bash
git --no-pager log --grep="<keyword>" -i --since="2 years ago"
```

This is **self-updating** — every release of every product gets the latest known-fix data without any manual catalogue maintenance.

---

## The persistent archive (`cases/`)

Every solved case ends up in `.copilot-shared/cases/<case-id>/` with:

| File | Content |
|------|---------|
| `rca.md` | Full 10-section RCA |
| `fix.md` | Before/after snippet + suggested commit message + target version |
| `signature.yml` | Searchable index entry — product, versions, keywords, error codes, log regexes |

Phase 0.5 of every **future** case scores incoming symptoms against every `signature.yml`:

| Dimension | Weight |
|-----------|-------:|
| Error codes | 35 |
| Symptom keywords | 25 |
| Log signatures (regex) | 20 |
| Product | 10 |
| Version range overlap | 10 |

Top-3 matches with confidence % are surfaced before any new triage runs.

> ⚠️ **The archive contains internal customer data.** It lives in the local-only `.copilot-shared` git repo (no remote, per the top-level `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\README.md`). Never push it. See `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\cases\README.md` for the full warning.

---

## Commit messages

The RCA-author drafts a Conventional Commits message in `§6` of every RCA:

```
<type>(<scope>): <imperative one-line summary, ≤72 chars>

<body — root cause + evidence summary, wrap at 72 chars>

Refs: <case-id>
```

The investigator **does not** run `git commit`. The message is handed to the `developer` agent at Phase 8, which owns the actual edit + build + test + commit + push (via [`verification-before-completion`](../skills/verification-before-completion/SKILL.md) and [`commit-push`](../skills/commit-push/SKILL.md)).

---

## Operating rule (every interaction)

> At the end of every interaction, summarize what we learned today into the investigation MD, and note what's still missing. After the fix is accepted, run the `case-archive` skill to persist this case so the next investigation can match its signature.

---

## Quick reference

| I want to… | Do this |
|------------|---------|
| Start a new case | Paste [`investigate-customer-case.md`](../prompts/investigate-customer-case.md) into chat |
| See if a similar case was solved before | Phase 0.5 runs automatically; or `findstr /S /I "<keyword>" %COPILOT_WORKSPACE_ROOT%\.copilot-shared\cases\*\signature.yml` |
| Make triage sharper for one product | Add `<product-repo>/.github/instructions-local/triage-rules.instructions.md` |
| Re-run an investigation | Re-paste the kickoff prompt; intake is idempotent |
| Hand the fix to a developer | Approve the RCA; the agent dispatches the `developer` agent |
| Browse archived cases | Open `%COPILOT_WORKSPACE_ROOT%\.copilot-shared\cases\_index.md` |
