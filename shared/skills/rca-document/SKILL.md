---
name: rca-document
description: Use when authoring the final Root Cause Analysis document for a customer case — Phase 5/6, after triage and code-evidence are complete
---

# RCA Document

## Activation Rule

**Triggers:**
- Phases 2 + 3 are complete; `investigation.md` has §Findings + §Code Evidence populated
- An rca-author subagent is dispatched
- User says "write the RCA" / "summarise the case"

> **Override Directive:** This skill overrides default behavior when its conditions are met. The 10-section structure and the Output Checklist are mandatory — no shortcuts, no missing sections.

## Overview

Authors `.agent_work/<case-id>/rca-<case-id>.md` — the customer-deliverable Root Cause Analysis. 10 sections. Every claim cites evidence (log line + timestamp + source file). Section 6 includes a **draft commit message** in conventional-commit format.

## When to Use

- Phase 5 of every case, after Phases 2 + 3 are complete.
- Re-running on the same case is allowed and replaces the prior RCA file (the investigation MD is the source of truth).

**Don't use for**: drafting the investigation MD itself (that's `customer-case-intake`).

## RCA Structure (mandatory 10 sections)

```markdown
# RCA: <case-id> — <one-line title>

## 1. Header

| Field | Value |
|-------|-------|
| Case ID | <id> |
| Customer | <name or "internal"> |
| Severity / Priority | <P1..P4> |
| Product | <name> |
| Versions | <component>: <x.y.z> ; … |
| Topology | <one line> |
| Bundle path | <abs path> |
| Analyst | <user> |
| Date | <YYYY-MM-DD> |

## 2. Environment Summary

| Node | Role | Version | Build | Uptime | RAM | CPU | Notable |
|------|------|---------|-------|--------|-----|-----|---------|
| …    | …    | …       | …     | …      | …   | …   | …       |

## 3. The Smoking Gun

The single piece of evidence that proves the failure. Side-by-side when topology
has a peer node. Include exact log lines with timestamps and source file paths.

## 4. Root Cause Chain

```
PRIMARY TRIGGER: <description>
Evidence: <exact log line @ timestamp> [source: <file>]
    ↓
CONTRIBUTING FACTOR: <description>
Evidence: <exact log line @ timestamp> [source: <file>]
    ↓
CRITICAL EVENT: *** <operation that caused the broken state> ***
Evidence: <"starting" with no "done" — timestamps t1..t2> [source: <file>]
    ↓
RESULT: <permanent broken state>
Evidence: <config diff / CLI output> [source: <file>]
    ↓
ONGOING SYMPTOM: <what customer sees>
Evidence: <latest log line confirming current state> [source: <file>]
```

## 5. Evidence Sections

One subsection per finding. Each MUST include:
- Quantitative count (e.g. "317 errors matching `<regex>`")
- Exact log lines with timestamps (verbatim)
- Source file path (relative to bundle root)
- Code reference (`repo / file / method / line` from §Code Evidence)
- Why this matters (one paragraph linking field data to code path)

## 6. Code-Level Fixes

For each fix:

```
Gap:        <what the code currently does that produces the symptom>
File:       <path relative to repo root>
Method:     <method name, line number>
Impact:     <what fails because of this gap>
Fix:        <description of the required change>
Risk:       <what could break, or "low — read-only / additive">
Tracking:   <existing bug ID if any, or "to be filed">
```

### Suggested Commit Message

Conventional Commits format:

```
<type>(<scope>): <imperative one-line summary, ≤72 chars>

<body — root cause + evidence summary, wrap at 72 chars>

Refs: <case-id>
```

`<type>` ∈ `fix`, `feat`, `refactor`, `perf`, `docs`, `chore`, `test`.
`<scope>` = component / module name.

Example:
```
fix(ha): rollback on partial standby delete to prevent dangling config

When sendDeleteToStandby() failed, HaConfiguration.delete() left the
active node with the new config and the standby with the old config,
causing replication rank delta to grow indefinitely. Wrap the delete
in a try/catch and restore the prior HaConfiguration on any failure.

Evidence: ha.log @ 2026-03-12T04:17:33 — "HA delete starting" with no
matching "HA delete complete"; pg_hba.conf diverged thereafter.

Refs: SC-17669
```

## 7. Immediate Customer Fix

Step-by-step CLI commands the customer can run in a maintenance window. Include
verification commands after each step. Be explicit about pre-conditions and
rollback steps.

## 8. Long-Term Productization

| Gap | Evidence | Fix Needed | Target Version |
|-----|----------|------------|----------------|
| …   | …        | …          | …              |

## 9. Confidence Assessment

| Finding | Confidence % | Basis |
|---------|--------------|-------|
| …       | …            | …     |

## 10. File Reference Index

Table mapping every claim to the exact support file that proves it.

| Claim # | Section | Evidence file (relative to bundle) |
|---------|---------|-------------------------------------|
| …       | …       | …                                  |
```

## Output Checklist (gate before delivery)

The RCA is **not complete** until all are true:

- [ ] All 10 sections present (no `TBD` / `TODO`).
- [ ] Every Evidence Section has: count + exact log line + timestamp + source file + code reference.
- [ ] §6 includes a draft commit message in Conventional Commits format.
- [ ] Confidence % assigned to every finding (§9).
- [ ] §10 maps every claim back to a support file.
- [ ] Active-vs-standby comparison present where topology has a peer.
- [ ] Any "starting" operation in §4 has its matching "done" lookup result (or absence noted).
- [ ] No paraphrased log lines — all verbatim with timestamps.
- [ ] Customer-facing steps (§7) include verification commands.
- [ ] Archive entry queued for Phase 7 (`case-archive` skill).

## Subagent Prompt Template

```
You are an rca-author subagent.

Source: .agent_work/<case-id>/investigation.md
Output: .agent_work/<case-id>/rca-<case-id>.md

Author per .github/skills/rca-document SKILL — all 10 sections.
§6 must include a draft commit message in Conventional Commits format.
Pass the Output Checklist before returning.

Do NOT edit product code. Do NOT run git commit. Return the path to the
written file plus the Output Checklist with each item ticked or noted.
```

## Common Mistakes

- **Skipping the commit-message draft** — even if the fix is one-line, draft it.
- **Paraphrasing log lines** — copy them verbatim, with timestamps.
- **No code reference** — every Evidence Section must point at `repo / file / method / line`.
- **Missing §10 index** — without it, future readers cannot reproduce the analysis.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **case-investigator** | Dispatches the rca-author subagent in Phase 5 |
| **case-archive** | Consumes the resulting RCA in Phase 7 |
| **developer** | Receives §6 fix + commit message at hand-off |
