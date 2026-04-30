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

### Step 3 — Auto-unzip everything (eager, idempotent)

Run a recursive expansion loop until no archives remain. Use the appropriate command for the OS.

**Windows PowerShell:**

```powershell
# Run from inside the bundle root.
$bundle = '<ABS-PATH>'
$logFile = '<.agent_work-path>\_extraction.log'

# Loop until no archives remain
do {
  $found = $false

  Get-ChildItem -Path $bundle -Recurse -File -Include *.zip | ForEach-Object {
    $dest = Join-Path $_.DirectoryName ($_.BaseName + '_extracted')
    if (-not (Test-Path $dest)) {
      Expand-Archive -LiteralPath $_.FullName -DestinationPath $dest -Force
      Add-Content $logFile "expanded: $($_.FullName) -> $dest"
      $found = $true
    } else {
      Add-Content $logFile "skipped (already expanded): $($_.FullName)"
    }
  }

  Get-ChildItem -Path $bundle -Recurse -File -Include *.tar.gz, *.tgz | ForEach-Object {
    $dest = Join-Path $_.DirectoryName ($_.BaseName + '_extracted')
    if (-not (Test-Path $dest)) {
      New-Item -ItemType Directory -Path $dest | Out-Null
      tar -xzf $_.FullName -C $dest
      Add-Content $logFile "expanded: $($_.FullName) -> $dest"
      $found = $true
    }
  }

  # Single-file .gz (e.g. container.health.log.1.gz) — decompress in place
  Get-ChildItem -Path $bundle -Recurse -File -Include *.gz |
    Where-Object { $_.Name -notmatch '\.tar\.gz$|\.tgz$' } | ForEach-Object {
      $out = $_.FullName -replace '\.gz$', ''
      if (-not (Test-Path $out)) {
        & 'C:\Windows\System32\tar.exe' -xzf $_.FullName -C $_.DirectoryName 2>$null
        if (-not (Test-Path $out)) {
          # Fallback: use .NET GzipStream
          $in  = [System.IO.File]::OpenRead($_.FullName)
          $gz  = New-Object System.IO.Compression.GzipStream($in, [System.IO.Compression.CompressionMode]::Decompress)
          $outStream = [System.IO.File]::Create($out)
          $gz.CopyTo($outStream)
          $outStream.Close(); $gz.Close(); $in.Close()
        }
        Add-Content $logFile "expanded: $($_.FullName) -> $out"
        $found = $true
      }
    }
} while ($found)
```

**Linux / WSL / Git-Bash:**

```bash
bundle="<ABS-PATH>"
log="<.agent_work-path>/_extraction.log"

while true; do
  changed=0
  while IFS= read -r -d '' z; do
    dest="${z%.zip}_extracted"
    if [[ ! -d "$dest" ]]; then
      mkdir -p "$dest" && unzip -q "$z" -d "$dest"
      echo "expanded: $z -> $dest" >> "$log"; changed=1
    fi
  done < <(find "$bundle" -type f -name '*.zip' -print0)

  while IFS= read -r -d '' t; do
    dest="${t%.tar.gz}_extracted"; dest="${dest%.tgz}_extracted"
    if [[ ! -d "$dest" ]]; then
      mkdir -p "$dest" && tar -xzf "$t" -C "$dest"
      echo "expanded: $t -> $dest" >> "$log"; changed=1
    fi
  done < <(find "$bundle" -type f \( -name '*.tar.gz' -o -name '*.tgz' \) -print0)

  while IFS= read -r -d '' g; do
    out="${g%.gz}"
    if [[ ! -f "$out" ]]; then
      gunzip -k "$g" && echo "expanded: $g -> $out" >> "$log"; changed=1
    fi
  done < <(find "$bundle" -type f -name '*.gz' ! -name '*.tar.gz' -print0)

  [[ $changed -eq 0 ]] && break
done
```

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
