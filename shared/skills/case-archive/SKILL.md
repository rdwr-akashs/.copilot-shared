---
name: case-archive
description: Use when persisting a solved customer case to the local archive, or when looking up prior solved cases that match a new symptom signature
---

# Case Archive

## Activation Rule

**Triggers:**
- Phase 0.5 of any new case → **lookup mode**
- Phase 7 (after RCA accepted, optionally fix accepted) → **write mode**
- User says "archive this case" / "have we seen this before"

> **Override Directive:** This skill overrides default behavior when its conditions are met. Two distinct modes — lookup (read) and write (persist). Each invocation runs exactly one mode.

## Overview

Persists every solved customer case to `.copilot-shared/cases/<case-id>/` so future investigations benefit from prior signatures. Companion lookup mode greps the archive for matches before triage runs on a new case. The archive lives in the **local-only** `.copilot-shared` git repo — no remote — so customer data does not leave the workstation.

## Archive Layout

```
.copilot-shared/
└── cases/
    ├── README.md             # warning: contains internal customer data — do not push to remotes
    ├── _index.md             # table: id | date | product | versions | symptom | signature | fixed-in
    ├── _template/
    │   └── signature.yml     # schema reference
    └── <case-id>/
        ├── rca.md            # copy of .agent_work/<case-id>/rca-<case-id>.md
        ├── fix.md            # before/after snippet + commit message + target version
        └── signature.yml     # searchable index entry
```

## signature.yml schema

```yaml
case_id: SC-17669
date: 2026-04-01
analyst: <user>
product: <product-name>
component: <component-or-module>
version_range:
  affected: ">=4.5.0,<4.7.1"
  fixed_in: "4.7.1"
topology: HA-pair  # or single-node, cluster, etc.
symptom_keywords:
  - "<short keyword 1>"
  - "<short keyword 2>"
error_codes:
  - "M_00301"
  - "DE76727"
log_signatures:
  - regex: "HA delete starting.*"
    notes: "no matching 'done' in same window"
  - regex: "Memory utilization [89][0-9]%"
root_cause: |
  <one-paragraph plain-English root cause>
fix_summary: |
  <one-paragraph plain-English fix>
fix_location:
  - repo: <repo-name>
    file: <relative path>
    method: <method-name>
    line: <line-number>
references:
  rca: rca.md
  fix: fix.md
  jira: <ticket if any>
  pr: <PR url if any>
```

---

## Mode A — Write (Phase 7)

### Preconditions
- `.agent_work/<case-id>/rca-<case-id>.md` exists and passes the Output Checklist from `rca-document` SKILL.
- User has accepted the RCA. (If the proposed fix is also accepted, include it; otherwise mark `fix_summary: "proposed, not yet validated"`.)

### Steps

1. **Create the case directory**:
   ```
   .copilot-shared/cases/<case-id>/
   ```
2. **Copy the RCA**:
   ```
   .agent_work/<case-id>/rca-<case-id>.md  →  .copilot-shared/cases/<case-id>/rca.md
   ```
3. **Write `fix.md`**: extract from RCA §6:
   ```markdown
   # Fix — <case-id>

   ## Affected
   - Repo: <repo>
   - File: <path>
   - Method: <name> (line <n>)

   ## Before
   ```<lang>
   <snippet>
   ```

   ## After
   ```<lang>
   <snippet>
   ```

   ## Commit Message
   ```
   <conventional-commit message from RCA §6>
   ```

   ## Target Version
   <version | "next minor" | "TBD">

   ## Validation
   <test commands / manual steps>

   ## Status
   <proposed | applied | merged>
   ```
4. **Write `signature.yml`** per the schema above. Extract:
   - `symptom_keywords`: distilled from RCA §3 + §5 (3–7 short keywords).
   - `error_codes`: every `M_xxx`, `E_xxx`, `DE-xxx`, HTTP status, etc. mentioned in evidence.
   - `log_signatures`: regex patterns for the smoking-gun lines.
5. **Append a row to `_index.md`**:
   ```markdown
   | <case-id> | <date> | <product> | <versions> | <symptom one-liner> | [signature](<case-id>/signature.yml) | <fixed-in> |
   ```
6. **Append to shared memory** — invoke `save-learning` skill to append the pattern to `shared/memory/customer-cases.md` and any relevant `known-bugs.md` entries. This makes the pattern searchable by ALL team members in future sessions, not just via the local `cases/` archive.
7. **Optional commit**: if the user agrees, dispatch `commit-push` skill on `.copilot-shared` (local-only repo per README — no remote, no push needed beyond the local commit).

### Output

Reply:
```
[Phase] 7 complete — case archived
RCA:       .copilot-shared/cases/<case-id>/rca.md
Fix:       .copilot-shared/cases/<case-id>/fix.md
Signature: .copilot-shared/cases/<case-id>/signature.yml
Index row: appended
Commit:    <hash | "not committed">
```

---

## Mode B — Lookup (Phase 0.5)

### Inputs
- `product`, `version`, `topology` (from Phase 1 metadata).
- `symptom_keywords`: 3–7 keywords from the user's symptom line.
- `error_codes`: any explicit codes/IDs in the kickoff prompt.
- `log_signatures` (optional): regex hints from a quick `head logs/*.log` peek.

### Procedure

1. Read `.copilot-shared/cases/_index.md` — quick prefilter on product + topology.
2. For each candidate row, load `<case-id>/signature.yml`.
3. Score the match (max 100):

   | Dimension | Weight | Match rule |
   |-----------|--------|------------|
   | Error codes | 35 | exact intersection / max(set sizes) × 35 |
   | Symptom keywords | 25 | token-overlap ratio × 25 |
   | Log signatures | 20 | any of new hints regex-matches an archived signature |
   | Product | 10 | exact match (else 0) |
   | Version range | 10 | new version ∈ archived `affected` range |

4. Return top 3 with `confidence %`, sorted descending.

### Output

```
[Phase] 0.5 complete — prior case lookup

Top matches:
  1. SC-17669  — 92%  — "BGP standby IDLE + M_00301 storm"  → cases/SC-17669/rca.md
  2. SC-15012  — 47%  — "HA dormant cycle on slow ExaBGP startup"
  3. SC-14188  — 31%  — (low confidence, surfaced for completeness)

Strong match (>=80%) found.
Decision required:
  [a] Apply prior fix verbatim (short-circuit)
  [b] Run a fresh investigation anyway (recommended for new versions)
  [c] Inspect cases/SC-17669/rca.md before deciding
```

If no row scores ≥50%, reply: `no prior match — proceeding to Phase 1`.

---

## Subagent Prompt Templates

**Lookup subagent (Phase 0.5):**
```
Run case-archive skill in LOOKUP mode.

Inputs:
  product:           <name>
  version:           <x.y.z>
  topology:          <one line>
  symptom_keywords:  [<list>]
  error_codes:       [<list>]
  log_signatures:    [<regex hints or empty>]

Return top-3 matches with confidence %, or "no prior match".
```

**Archive subagent (Phase 7):**
```
Run case-archive skill in WRITE mode for case <case-id>.

Preconditions:
  RCA at .agent_work/<case-id>/rca-<case-id>.md (Output Checklist passed).
  User accepted the RCA.

Persist to .copilot-shared/cases/<case-id>/ and append _index.md row.
If user agreed, run commit-push on .copilot-shared (local-only).
```

## Common Mistakes

- **Skipping `signature.yml`** — without it, lookup is useless; the RCA alone is unreadable for matching.
- **Pushing to a remote** — `.copilot-shared` is local-only per README. The archive must never be pushed.
- **Lossy keyword extraction** — symptom keywords should be specific (`"BGP IDLE"`, not `"network issue"`).
- **Forgetting active-vs-standby in topology** — different from single-node; affects matching.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **case-investigator** | Phase 0.5 (lookup) and Phase 7 (write) |
| **commit-push** | Optional commit of archive update (local-only) |
