---
name: support-file-triage
description: Use when extracting evidence from an expanded customer support bundle — produces quantified findings per category for the RCA, dispatched in parallel by the case-investigator agent
---

# Support File Triage

## Activation Rule

**Triggers:**
- Phase 2 of a customer case (intake skill has run; investigation MD exists)
- A triage subagent is dispatched with a category name and bundle path
- User says "triage these logs" / "what do the logs say"

> **Override Directive:** This skill overrides default behavior when its conditions are met. Triage is per-category and parallel — never serialise. Each category returns evidence only, never interpretation.

## Overview

Generic, repo-agnostic triage framework. Defines 9 evidence categories. Each category subagent returns quantitative counts + verbatim log lines + source file paths. Interpretation across categories happens later in the RCA-author phase, not here.

## When to Use

- After `customer-case-intake` has expanded the bundle and scaffolded the MD.
- One subagent per category, dispatched in parallel via `dispatching-parallel-agents`.

**Don't use for**: drawing conclusions, proposing fixes, mapping to code (that's Phase 3).

## Per-Repo Override Hook

Before applying generic patterns, check for `.github/instructions-local/triage-rules.instructions.md` in:
1. The active workspace.
2. Each sibling repo under the parent of the active workspace.

If found, **prefer its concrete patterns** for matched categories. Otherwise fall back to the generic keyword grep below.

## Categories

For each category, the subagent returns rows of:
```
| count | exact log line (with timestamp) | source file (relative to bundle) | active vs standby |
```

### 1. Identity & Version

**What to find:** product version + build, hardware identity, uptime, RAM/CPU specs, hostname.

**Generic search (when no per-repo rules):**
- `find <bundle> -name 'system_info*' -o -name 'version*' -o -name 'environment*' -o -name 'host*' -o -name 'uname*'`
- `grep -E 'version|build|uptime|kernel|model name|MemTotal'` over those files.

### 2. Connectivity / Network

**What to find:** peer/link state, interface counters, route table, DNS, listening ports.

**Generic search:**
- Files: `*peers*`, `*neighbors*`, `*ifconfig*`, `*ip-a*`, `*routes*`, `*netstat*`, `*ss*`, `*resolv*`, `*hosts*`.
- Patterns: `IDLE|DOWN|FLAPPING|UNREACHABLE|TIMEOUT|RX errors|TX errors|dropped`.

### 3. Replication / State Sync

**What to find:** primary↔standby/replica replication state, configuration rank/version delta, sync lag.

**Generic search:**
- Files: `*replication*`, `*sync*`, `*ha*`, `*pg_hba*`, `*recovery*`, `*cluster*`.
- Patterns: `replication|standby|recovery|lag|out.of.sync|stale|drift|diverged|rank`.
- **Compare** active vs. standby copies of the same config file — diffs are signal.

### 4. HA / Failover

**What to find:** node role, dormant flags, failover history, **incomplete operations**.

**Generic search:**
- Files: `*ha*log*`, `*failover*`, `*cluster*log*`, `*role*`, `*election*`.
- Patterns: `dormant|failover|elected|promote|demote|takeover|started|starting|complete|done|delete|abort`.
- **CRITICAL:** any `starting|started` operation **without a matching** `done|complete|finished` in the same time window = corruption point. Capture the timestamp range.

### 5. Resource Exhaustion

**What to find:** CPU/memory/disk pressure, OOM kills, swap usage, file-descriptor leaks.

**Generic search:**
- Files: `*memory*`, `*top*`, `*meminfo*`, `*df*`, `*utilization*`, `*kernel*log*`, `dmesg*`.
- Patterns: `[8-9][0-9]%|9[0-9]%|10[0-9]%|OOM|out of memory|killed process|swap|fd.limit|too many open files`.
- Quantify: `grep -c` to count occurrences over the timeframe.

### 6. External Service Connectivity

**What to find:** errors/timeouts talking to upstream/dependent services (auth servers, mgmt platforms, mail, syslog, monitoring).

**Generic search:**
- Files: `*one.line.problems*`, `*errors*`, `*alerts*`, app log files.
- Patterns: `M_[0-9]+|E_[0-9]+|connection refused|connection reset|timeout|unauthor|forbidden|certificate|ssl|tls|handshake`.
- **Quantify per error code** — per-code counts reveal storms.

### 7. Polling / Load

**What to find:** sustained high request rates, expensive endpoints hit repeatedly.

**Generic search:**
- Files: `*rest*log*`, `*access*log*`, `*api*log*`, `nginx*log*`.
- Patterns: count requests per endpoint over time. Sustained > 1 req/sec on a single endpoint = polling storm signal.
- `wc -l` on the log → divide by elapsed time.

### 8. Container / Process Health

**What to find:** crash loops, exit codes, restart counts, unhealthy containers.

**Generic search:**
- Files: `containers_list*`, `processes*`, `*supervisord*`, `*systemd*log*`, `*docker*log*`.
- Patterns: `Exited|Created|unhealthy|exit\(.*\)|Restarting|killed|SIGKILL|137|255`.
- `exit(137)` = SIGKILL (Docker killed unhealthy). `exit(255)` = error. Multiple `Created`-but-never-`Up` = orchestration couldn't launch.

### 9. Time Sync

**What to find:** NTP skew between nodes (active vs. standby) — > 30 s skew can trigger spurious failovers and TTL timeouts.

**Generic search:**
- Files: `time*`, `*ntp*`, `*chrony*`, `*timedatectl*`.
- Compare timestamps across nodes. Diff > 30 seconds = signal.

## Subagent Prompt Template

The case-investigator dispatches each category with:

```
You are a triage subagent for category: <CATEGORY>.

Bundle root: <ABS-PATH>
Per-repo rules: <path-to-triage-rules.instructions.md or "none">

Apply the patterns in support-file-triage SKILL §<CATEGORY> (or the per-repo
rules if provided). Return ONLY:

| count | exact log line (verbatim, with timestamp) | source file | active vs standby |

DO NOT interpret findings. DO NOT propose fixes. DO NOT search outside your category.
If the bundle contains no relevant files for this category, return "N/A — no
applicable files in bundle".
```

## Aggregation

After all category subagents return, the case-investigator appends a unified `## Findings` section to `investigation.md`, grouped by category, with a quantitative summary at the top.

## Common Mistakes

- **Cross-category interpretation** in a single subagent — keeps boundaries clean.
- **Paraphrasing log lines** — verbatim only, with timestamps.
- **Skipping the active-vs-standby comparison** when topology has standby — config diffs are some of the strongest signals.
- **Hard-coded product file paths** in this skill — they belong in per-repo `instructions-local/`.

## Agent Integration

| Agent | Usage |
|-------|-------|
| **case-investigator** | Dispatches one subagent per category in parallel |
| **dispatching-parallel-agents** | Provides the fan-out mechanism |
