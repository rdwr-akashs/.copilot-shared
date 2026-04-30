# Customer Case Archive

Solved-case knowledge base. Every customer / field escalation investigated by the **case-investigator** agent ends here once the user accepts the RCA.

---

## Why

Field issues recur. The same root cause shows up across customers, versions, and time. Without an archive, every investigation starts from zero. With it, **Phase 0.5** of every new case greps this directory for prior signatures and surfaces matches with a confidence score — sometimes saving hours of triage.

---

## Layout

```
cases/
├── README.md             # this file
├── _index.md             # one row per archived case (lookup table)
├── _template/
│   └── signature.yml     # schema reference
└── <case-id>/
    ├── rca.md            # full Root Cause Analysis (10-section format)
    ├── fix.md            # before/after snippet + commit message + target version
    └── signature.yml     # searchable index entry (product, versions, keywords, codes, regexes)
```

---

## ⚠️ Customer data warning

These files **contain internal customer data** — customer names, IPs, internal bug IDs, log excerpts, infrastructure detail. They are stored in the **local-only** `.copilot-shared` git repo (no remote, per the top-level [README.md](../README.md)).

**Do not:**
- Add a remote to `.copilot-shared` and push.
- Copy contents to any repository that has a remote.
- Share `cases/` over public channels.

If a remote is ever added, an additional redaction layer must be introduced first (the `case-archive` skill is the chokepoint where this would be implemented).

---

## How cases get here

The **case-investigator** agent runs the `case-archive` skill in **write mode** at Phase 7 of every solved case:

1. RCA passes the Output Checklist in `shared/skills/rca-document/SKILL.md`.
2. User accepts the RCA (and optionally the fix).
3. `case-archive` skill copies the RCA, distils a `fix.md`, generates a `signature.yml`, and appends a row to `_index.md`.

See [shared/skills/case-archive/SKILL.md](../shared/skills/case-archive/SKILL.md) for the full procedure and `signature.yml` schema.

---

## How cases get matched

The same skill in **lookup mode** runs at Phase 0.5 of every **new** case:

1. Loads `_index.md` for a quick product+topology prefilter.
2. Reads each candidate `signature.yml`.
3. Scores match across error codes (35), symptom keywords (25), log signatures (20), product (10), version range (10).
4. Returns top-3 with confidence %.

If a match is ≥80%, the agent surfaces it before doing any new triage.

---

## Manual usage

You can also grep the archive directly:

```cmd
findstr /S /I "M_00301" cases\*\signature.yml
findstr /S /I "BGP.*IDLE" cases\*\signature.yml
```

```bash
grep -ril "M_00301" cases/*/signature.yml
grep -ril "BGP.*IDLE" cases/*/signature.yml
```
