# Customer Case Memory
# Shared team knowledge. Append new findings via the `save-learning` skill or `case-archive` skill.
# Format: one row per distinct root-cause pattern. Multiple case IDs may share one row.
# NEVER include customer names, IPs, or credentials. Pattern descriptions only.
#
# This file is gitignored — share it via your internal Bitbucket repo, not GitHub.
# Initialised by bin/setup-local.ps1 from shared/memory/templates/customer-cases.md.

## How to Use

Before diagnosing a new case, grep this file for keywords from the symptom:
```bash
grep -i "<symptom-keyword>" shared/memory/customer-cases.md
```

If you find a match, you already have the root cause and fix. Skip to "Immediate Fix".

---

## Case Patterns

| ID | Symptom Keywords | Root Cause | Immediate Fix | Long-term Fix | Affected Versions | Case IDs |
|----|-----------------|------------|---------------|---------------|-------------------|---------|
| _(no patterns yet — populate via save-learning skill after resolving cases)_ | | | | | | |

---
<!-- Add new rows above this line using save-learning skill -->
<!-- Increment ID: CP-001, CP-002, ... -->
