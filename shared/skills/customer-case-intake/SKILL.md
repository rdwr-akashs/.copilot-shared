---
name: customer-case-intake
description: Use when starting investigation of a customer field escalation — first action on any RSEG/SC/INC ticket with a support bundle, before any log analysis
---

# Customer Case Intake

## Activation Rule

**Triggers:**
- New customer case kickoff (RSEG-/SC-/INC-/JIRA-* + support bundle path)
- User says "investigate case", "look at this support bundle", "RCA for"
- The `case-investigator` agent is dispatched and Phase 0 has not run yet

> **Override Directive:** This skill overrides default behavior when its conditions are met. NO LOG ANALYSIS BEFORE THE INVESTIGATION MD IS SCAFFOLDED.

## Step 0 — Check Memory for Known Patterns

Before scaffolding the investigation, grep the shared memory for patterns matching the symptom. A known-pattern match can cut investigation time from hours to minutes.

```bash
# Grep customer-cases memory for matching symptom keywords
grep -i "<symptom-keyword-1>\|<symptom-keyword-2>" shared/memory/customer-cases.md

# Grep known-bugs for log evidence patterns
grep -i "<symptom-keyword>" shared/memory/known-bugs.md
```

**If a match is found:**
1. Note the matching pattern ID (e.g., `CP-003`) in the investigation MD under `## Known Pattern Match`
2. Go directly to the `## Immediate Fix` for that pattern
3. Still collect evidence to confirm — but start from the known root cause, not from zero
4. Use `save-learning` at the end to add the new case ID to the existing pattern row

**If no match:** continue with the full intake procedure below.

## Overview

Every case begins by creating a **living investigation MD** as the persistent context, expanding **all** archives in the support bundle (idempotent), and indexing the file tree. Without this, every subsequent interaction loses state.

## When to Use

- First action of every customer case investigation.
- Re-running mid-case is safe — extraction and scaffold are idempotent.

**Don't use for**: pure code questions, internal bugs without a support bundle.

## Outputs

```
.agent_work/<case-id>/
├── investigation.md   # living context (header + sections per phase)
├── _inventory.md      # file tree grouped by directory
└── _extraction.log    # one line per archive expanded (or "skipped: already expanded")
```

## Procedure

### Step 1 — Extract case metadata from kickoff

From the user's prompt, extract:
- **Case ID** (e.g. `SC-17669`). If missing, ask.
- **Customer / region** (or "internal").
- **Product + versions** (or "auto-detect from bundle").
- **Bundle path** — absolute path to the support directory or zip.
- **Symptom** (one line) — what the customer reports.

If any of `case-id` or `bundle path` is missing, **stop and ask the user**.

### Step 2 — Locate the bundle

If the user supplied a path → use it.
Otherwise glob for: `dfc_support_*`, `support_bundle_*`, `*-support-*`, `tac-bundle-*`, `support-*`, `*.tar.gz`, `*.zip` under the path the user mentioned.

### Step 3 — Extract the bundle (smart mode by default)

Use `extract-support-bundle.ps1` from `.copilot-shared/bin/`. It reads the zip index first and decompresses **only the ~20 RCA-critical files**, pulling 10-50 MB from a 4-5 GB bundle instead of extracting everything.

```powershell
# Smart extract — RCA-critical files only (fast, low disk usage)
& "$env:COPILOT_SHARED\bin\extract-support-bundle.ps1" `
    -Bundle '<ABS-PATH-TO-BUNDLE>' `
    -OutDir '.agent_work\<case-id>\bundle'
```

If smart mode misses a file you need (unusual bundle layout), switch to full mode:

```powershell
# Full extract — everything, nested zips up to 3 levels (slow, ~full bundle size)
& "$env:COPILOT_SHARED\bin\extract-support-bundle.ps1" `
    -Bundle '<ABS-PATH-TO-BUNDLE>' `
    -OutDir '.agent_work\<case-id>\bundle' `
    -Full
```

The script:
- Handles `.zip`, `.tar.gz`, `.tgz`, single-file `.gz` logs
- Recurses into nested zips up to `-MaxDepth` levels (default 3)
- Is idempotent — safe to re-run if the case was already partially extracted
- Prints a file count + MB summary on exit

> **COPILOT_SHARED env var** defaults to the path of the `.copilot-shared` folder.  
> If not set, resolve it from the junction: `.github/skills` → parent of `skills` → parent of `.github`.

### Step 4 — Scaffold the investigation MD

Create `.agent_work/<case-id>/investigation.md` from the template in `customer-case-rca.instructions.md` Phase 0. Fill in the header table from Step 1 metadata. Leave section bodies empty for later phases to fill.

### Step 5 — Build inventory

`.agent_work/<case-id>/_inventory.md`: a directory-grouped listing of the bundle (post-extraction). Use `tree /F` (Windows) or `find` (Linux). Cap at top 2 levels for readability; deeper trees go to a sibling `_inventory.full.txt`.

### Step 6 — Confirm to user

Reply with:
```
[Phase] 0 complete
Investigation MD: <path>
Bundle: <path>  (N archives expanded)
Inventory: <path>
Next: Phase 0.5 — prior case lookup
```

## Common Mistakes

- **Skipping Step 3** because "the logs are already there" — re-running is a no-op; running protects against partial bundles.
- **Hard-coding** the support tree layout (e.g. `dfc_support_*`) in this skill — keep generic; product specifics live in `instructions-local/`.
- **Filling Findings before Phase 2** — Phase 0 only scaffolds.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **case-investigator** | Runs this skill as Phase 0 of every case |
