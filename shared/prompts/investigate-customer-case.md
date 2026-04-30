# Investigate Customer Case

Use this prompt to kick off any customer / field-escalation investigation. The orchestrator will route it to the **case-investigator** agent.

---

## Copy-paste template

```
Investigate customer case <CASE-ID>.

Bundle path:  <ABSOLUTE PATH to support directory or zip>
Product:      <product name | "auto-detect">
Versions:     <component>: <x.y.z>; …  (or "unknown — extract from bundle")
Topology:     <e.g. HA pair (active+standby), single node, cluster of N>
Customer:     <name | "internal">
Severity:     <P1 | P2 | P3 | P4>
Reported:     <YYYY-MM-DD>

Symptom (one line):
<exact UI/CLI/log output the customer reported>

Trigger conditions:
<when does it happen — after restart? under load? always?>

What works vs. what breaks:
<one or two lines>

Use the case-investigator agent.
```

---

## What happens next

1. **Phase 0** — agent scaffolds `.agent_work/<CASE-ID>/investigation.md` and **auto-unzips** every archive in the bundle.
2. **Phase 0.5** — agent looks up prior solved cases in `.copilot-shared/cases/` and surfaces top-3 matches with confidence %.
3. **Phase 1** — agent restates the problem and seeds initial hypotheses in the MD.
4. **Phase 2** — agent dispatches **9 triage subagents in parallel**, one per evidence category. Returns quantitative findings.
5. **Phase 3** — agent maps each finding to `repo / file / method / line` and grep `CHANGES.txt` / `CHANGELOG*` / `RELEASE_NOTES*` for prior known issues.
6. **Phase 5** — agent writes `rca-<CASE-ID>.md` (10 sections) including a **draft commit message** in §6.
7. **Phase 7** — after you accept the RCA, agent archives the case to `.copilot-shared/cases/<CASE-ID>/`.
8. **Phase 8** — fix is handed off to the **developer** agent (you confirm before any code edit).

The investigator is **read-only on product code**. It only writes to `.agent_work/<CASE-ID>/` and `.copilot-shared/cases/<CASE-ID>/`.

---

## Operating rule (every interaction)

> At the end of every interaction, summarize what we learned today into the investigation MD, and note what's still missing. After the fix is accepted, run the `case-archive` skill to persist this case so the next investigation can match its signature.

---

## Per-product hint (optional)

If the active workspace's repo has `.github/instructions-local/triage-rules.instructions.md`, the triage skill will use those concrete file paths and grep patterns automatically. If not, it falls back to generic keyword grep over the entire bundle. To improve future cases for a product, add a `triage-rules.instructions.md` to that product's repo.

---

## Example invocations

### DefenseFlow HA pair

```
Investigate customer case SC-17669.

Bundle path:  C:\Users\AkashS\OneDrive - Radware LTD\customer cases\SC-17669\dfc_support_2026-04-01_01-36-55
Product:      DefenseFlow
Versions:     auto-detect from bundle
Topology:     HA pair (active + standby)
Customer:     internal
Severity:     P2
Reported:     2026-04-01

Symptom: BGP peers stuck in IDLE on standby after failover; UI shows
"No connection to Vision" errors.

Use the case-investigator agent.
```

### Single-node service

```
Investigate customer case INC-4421.

Bundle path:  /tmp/support-bundle-2026-04-29.tgz
Product:      auto-detect
Versions:     unknown — extract from bundle
Topology:     single node
Customer:     ACME Corp
Severity:     P1

Symptom: Service returns 500 on every POST /api/v2/policy after a restart.

Use the case-investigator agent.
```
