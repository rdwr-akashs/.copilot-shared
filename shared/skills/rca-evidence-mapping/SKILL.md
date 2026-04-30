---
name: rca-evidence-mapping
description: Use when mapping triage findings to exact source code locations and historical changelog entries — Phase 3 of customer case investigation
---

# RCA Evidence Mapping

## Activation Rule

**Triggers:**
- Phase 3 of a customer case (Findings table populated by Phase 2)
- A code-evidence subagent is dispatched
- User says "map these findings to code" / "where in the code does this happen"

> **Override Directive:** This skill overrides default behavior when its conditions are met. Replaces any static known-bugs table — known issues are discovered fresh per case by grepping CHANGES.txt / CHANGELOG* / RELEASE_NOTES* / HISTORY* / NEWS* across candidate repos.

## Overview

For each finding from Phase 2, locate the **exact `file:method:line`** that produces the symptom in the relevant source repo, then check whether it's a known issue by scanning that repo's changelog files. No static bug catalogue is maintained — every case re-discovers known issues against the customer's exact version.

## When to Use

- After `support-file-triage` has produced a Findings table.
- One subagent runs sequentially over all findings (it shares the investigation MD — do **not** parallelise).

**Don't use for**: writing the RCA narrative (that's `rca-document`).

## Procedure

### Step 1 — Discover candidate repos

Scan sibling directories under the parent of the active workspace. Match candidates by:
- Repo name contains the product/component name from Phase 1.
- Or the repo's `copilot-instructions.md` mentions the product.
- Or build-manifest hints (`pom.xml`/`package.json`/`Cargo.toml`/`go.mod`/`pyproject.toml`) reference matching artifacts.

Example (Windows):
```cmd
dir /b /ad "C:\<parent-of-cwd>"
```
For each candidate, record the abs path. Use `cross-repo-exploration` skill for any actual file reads in sibling repos (IDE file tools are workspace-restricted).

### Step 2 — For each finding, locate file:method:line

For each row in `investigation.md §Findings`:

1. Extract the symptom keyword(s) and any error code/identifier.
2. In each candidate repo, grep for the keyword/identifier:
   ```bash
   git --no-pager grep -nIE "<keyword>" -- '*.java' '*.ts' '*.tsx' '*.py' '*.go' '*.rs' '*.cs' '*.kt' '*.scala' '*.cpp'
   ```
3. Open the top hits, identify the **method** that emits the log line / error / behavior.
4. Capture: repo, file (relative), method name, line number, **before-snippet** (5–10 lines around the relevant code).

If multiple candidate locations exist, pick the one whose call-graph is consistent with the runtime conditions in §Findings.

### Step 3 — Changelog scan (replaces known-bugs table)

For each candidate repo, search known changelog filenames under root + `docs/`:

```bash
# Find changelog files (case-insensitive, common names)
find <repo> -maxdepth 3 -type f -iregex '.*\(CHANGES\|CHANGELOG\|HISTORY\|RELEASE.NOTES\|NEWS\).*' \
  ! -path '*/node_modules/*' ! -path '*/target/*' ! -path '*/.git/*'

# Search for symptom keywords in those files
grep -nIE -i "<keyword1>|<keyword2>|<error-code>" <changelog-files>
```

If **no changelog files exist**, fall back to git history:
```bash
git --no-pager log --grep="<keyword>" -i --since="2 years ago" --pretty=format:"%h %ad %s" --date=short
```

Capture for each match:
- File / line in the changelog (or commit hash).
- Reported version where the issue was fixed (or "fix found in commit `<hash>` not yet released").
- One-line summary of the matched entry.

### Step 4 — Field-vs-code validation

For each finding, decide:
- **Confirmed**: code path matches the runtime evidence; the bug is reproducible from the captured snippet.
- **Mismatch**: code expects something the field data doesn't provide (e.g. config flag missing, schema drift). Highlight in §Field-vs-Code Validation.
- **Inconclusive**: code path is consistent but evidence is too thin. Mark for follow-up question to user.

### Step 5 — Append to investigation MD

Append a `## Code Evidence` section. Schema:

```markdown
| # | Finding ref | Repo | File | Method | Line | Before-snippet | Changelog match | Fixed-in | Status |
|---|-------------|------|------|--------|------|----------------|-----------------|----------|--------|
```

Each `Before-snippet` cell links to a fenced code block placed below the table to keep rows readable.

## Subagent Prompt Template

```
You are a code-evidence subagent.

Investigation MD: <ABS-PATH>
Active workspace: <PATH>
Sibling repos to consider: <list or "auto-discover">

For EACH row in §Findings:
1. Discover candidate repos (Step 1).
2. Locate file:method:line (Step 2). Use cross-repo-exploration for sibling repos.
3. Run the changelog scan (Step 3) for the matched keywords.
4. Decide field-vs-code status (Step 4).
5. Append/update §Code Evidence (Step 5).

Do NOT edit any product code. Do NOT propose fixes. Output only the appended
section content + a one-line summary per finding.
```

## Common Mistakes

- **Skipping the changelog scan** — known fixes save the customer an upgrade cycle of guessing.
- **Hard-coding repo names** — discovery is dynamic; what's a "sibling repo" depends on the user's workspace.
- **Editing source code while exploring** — this skill is read-only on product code.
- **Using IDE file tools on sibling repos** — they are workspace-restricted and will fail. Use `run_in_terminal` + `cross-repo-exploration`.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **case-investigator** | Dispatches a single sequential code-evidence subagent for Phase 3 |
| **cross-repo-exploration** | Used as the read mechanism for sibling repos |
