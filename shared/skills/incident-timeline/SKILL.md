---
name: incident-timeline
description: Use when correlating logs across multiple services to build a unified timeline for incident analysis. Cross-service log correlation with timestamp normalization.
---

# Incident Timeline — Cross-Service Log Correlation

## Activation Rule

**Triggers:**
- "What happened between [time1] and [time2] across services?"
- "Correlate logs from [service-A] and [service-B]"
- "Build a timeline for incident [ID]"
- "Trace a request across microservices"
- Customer escalation with support bundles from multiple nodes

## Step 1: Collect Log Sources

Identify all participating services and their log locations:

```bash
# List available log files with sizes and date ranges
find /path/to/logs -name "*.log" -exec sh -c 'echo "$1: $(wc -l < "$1") lines, $(head -1 "$1" | grep -oP "\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}") → $(tail -1 "$1" | grep -oP "\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}")"' _ {} \;
```

### Common log locations (DefenseFlow/Vision)

| Source | Path | Format |
|--------|------|--------|
| DF Active | `dfc_support_*/logs/one.line.problems.log` | `YYYY-MM-DD HH:mm:ss,SSS` |
| DF Standby | `dfc_support_*/standby_support/logs/one.line.problems.log` | same |
| HA events | `dfc_support_*/logs/ha.log` | `YYYY-MM-DD HH:mm:ss` |
| BGP | `dfc_support_*/logs/bgp.log` | `YYYY-MM-DD HH:mm:ss` |
| REST API | `dfc_support_*/logs/rest.short.log` | `YYYY-MM-DD HH:mm:ss` |
| Vision | `vision_support/logs/server.log` | `YYYY-MM-DD HH:mm:ss,SSS` |

### Microservice log locations (general)

| Source | Path | Format |
|--------|------|--------|
| Spring Boot | `logs/application.log` | ISO 8601 |
| Docker | `docker logs <container>` | RFC 3339 |
| Nginx | `/var/log/nginx/access.log` | CLF / combined |
| Elasticsearch | `/var/log/elasticsearch/*.log` | ISO 8601 |
| RabbitMQ | `/var/log/rabbitmq/rabbit@*.log` | Erlang format |

## Step 2: Normalize Timestamps

**Critical:** All timestamps must be in the same timezone before correlating.

```bash
# Check timezone of each source
grep -m1 -oP "\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}[^\s]*" logfile.log
# Look for timezone suffix: Z, +00:00, +03:00, etc.

# If no timezone → check system time file
cat dfc_support_*/time.txt
```

### NTP Skew Detection

```bash
# Compare time.txt from active and standby
# If delta > 5 seconds, timestamps from different nodes cannot be directly compared
# Adjust by the measured offset
```

## Step 3: Extract Events in Time Window

```bash
# Generic — extract lines between two timestamps
awk '/2024-01-15 14:00:00/,/2024-01-15 14:30:00/' logfile.log

# Grep for error-level events in window
grep -E "ERROR|WARN|FATAL|Exception|failed|timeout" logfile.log | awk '/14:00/,/14:30/'

# Count events per minute (spot bursts)
grep "ERROR" logfile.log | grep -oP "\d{4}-\d{2}-\d{2} \d{2}:\d{2}" | sort | uniq -c | sort -rn | head -20
```

## Step 4: Build Unified Timeline

Merge events from all sources into a single sorted timeline:

```bash
# Tag each source, merge, sort by timestamp
grep -h "ERROR\|WARN\|starting\|done\|failover\|promote\|elected" \
    <(sed 's/^/[ACTIVE] /' active/logs/ha.log) \
    <(sed 's/^/[STANDBY] /' standby/logs/ha.log) \
    <(sed 's/^/[VISION] /' vision/logs/server.log) \
  | sort -t' ' -k2,3 \
  | head -200
```

### Output Format

Produce the timeline as a markdown table:

```markdown
| Time (UTC) | Source | Level | Event | Correlation |
|------------|--------|-------|-------|-------------|
| 14:00:01 | ACTIVE | INFO | HA delete starting | ← trigger |
| 14:00:02 | STANDBY | WARN | Lost connection to active | ← consequence |
| 14:00:05 | VISION | ERROR | M_00301 device unreachable | ← cascade |
| 14:00:15 | ACTIVE | ERROR | HA delete — no response from standby | ← root cause |
| 14:00:15 | ACTIVE | ??? | (no "HA delete done" found) | ← incomplete op |
```

Add a **Correlation** column explaining the causal chain.

## Step 5: Identify Patterns

Look for:
- **Incomplete operations**: "starting" with no matching "done/complete"
- **Cascading failures**: error on node A → error on node B within seconds
- **Periodic patterns**: same error every N minutes → cron job, polling, or retry loop
- **Burst patterns**: sudden spike in errors → external event (failover, deployment, load)
- **Clock skew artifacts**: events that appear out of order across nodes

## Step 6: Produce Correlation Report

```markdown
## Incident Timeline Report — [ID] — [Date]

### Time Window
[start] → [end] ([duration])

### Services Involved
[list with versions]

### Timeline
[table from Step 4]

### Causal Chain
[ASCII flowchart: event → event → event → symptom]

### Key Findings
1. [finding with evidence]
2. [finding with evidence]

### Confidence
[High/Medium/Low with rationale]
```

## Inter-Skill References

- For DefenseFlow/Vision cases → `support-file-triage` + `rca-evidence-mapping`
- For general debugging → `systematic-debugging`
- For log pattern analysis → `log-analysis`
- After building timeline → `save-learning` to record new patterns
