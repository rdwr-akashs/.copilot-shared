---
name: log-analysis
description: Use when analysing application logs to find errors, trace request flows, identify patterns, or correlate events across services. Systematic log investigation workflow.
---

# Log Analysis

## Activation Rule

**Triggers:**
- "Analyse the logs for [feature/error]"
- "Find what went wrong at [timestamp]"
- "Why did [component] fail?"
- Attaching log files to a support case
- Diagnosing intermittent errors from log evidence

> **Override Directive:** Parse logs with structured queries before drawing conclusions. Correlate across services before blaming one component.

## Checklist

```
[ ] 1. Identify log files and time window
[ ] 2. Extract error/exception lines
[ ] 3. Find stack traces and root cause exceptions
[ ] 4. Correlate by request ID / correlation ID / thread
[ ] 5. Find the first error in the sequence (not just the last visible one)
[ ] 6. Check other services at the same timestamp
[ ] 7. Identify if the error is persistent or intermittent
[ ] 8. Count occurrences and establish frequency
```

## Step-by-Step

### Step 1: Find error volume and types

```bash
# Count ERRORs and WARNs
grep -c "ERROR" app.log
grep -c "WARN"  app.log

# List unique error messages (deduplicate stack traces)
grep "ERROR" app.log | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*ERROR/ERROR/' | sort | uniq -c | sort -rn | head -20

# Error timeline (first and last occurrence)
grep "ERROR" app.log | head -1
grep "ERROR" app.log | tail -1
```

### Step 2: Extract stack traces

```bash
# Show 30 lines after each ERROR (to capture full stack trace)
grep -A 30 "ERROR" app.log | head -200

# Find specific exception class
grep -n "NullPointerException\|IllegalStateException\|RuntimeException" app.log

# Extract caused-by chain
grep -E "Caused by:|at com\.<org>" app.log | head -50
```

### Step 3: Correlate by request ID / correlation ID

Most services log a request or transaction ID. Use it to reconstruct the full request flow:

```bash
# Find the request ID from an error line
grep "ERROR" app.log | grep "requestId\|correlationId\|txId" | head -5

# Trace all log lines for a specific request
grep "abc123-request-id" app.log

# Multiple files — cross-service correlation
grep "abc123-request-id" service-a.log service-b.log | sort -k1
```

### Step 4: Find the root cause (first failure in chain)

```bash
# Find the first ERROR in a time window
awk '/2025-01-15T10:30/,/2025-01-15T10:35/' app.log | grep "ERROR" | head -5

# Find what was happening just BEFORE the first error
grep -B 20 "FIRST_ERROR_MESSAGE" app.log | head -40
```

### Step 5: Pattern detection — intermittent vs persistent

```bash
# Extract timestamps of error occurrences
grep "ERROR.*TargetErrorMessage" app.log | awk '{print $1}' | cut -c1-16 | sort | uniq -c

# Check if errors correlate with a time pattern (every N minutes?)
grep "ERROR" app.log | awk '{print $1}' | cut -c12-16 | sort | uniq -c

# Are errors clustered (burst) or steady rate?
grep -c "ERROR" app.log   # total
wc -l app.log             # total lines → ratio
```

---

## Log Format Patterns

### One-line log format (DefenseFlow `one.line.problems.log`)

```bash
# Count specific problem codes
grep -c "M_00301" one.line.problems.log    # Vision unavailable
grep -c "M_00201" one.line.problems.log    # Memory high

# Extract timestamps for M_00301
grep "M_00301" one.line.problems.log | awk '{print $1, $2}' | head -20

# Find the first and last occurrence of a problem code
grep "M_00301" one.line.problems.log | head -1
grep "M_00301" one.line.problems.log | tail -1
```

### Spring Boot / Logback format

```
YYYY-MM-DDTHH:mm:ss.SSS  LEVEL [thread] class - message
2025-01-15T10:30:45.123  ERROR [http-nio-8080-exec-1] c.r.ItemService - Failed to create item
```

```bash
# Errors with thread context
grep "ERROR \[http-nio" app.log | head -20

# Scheduled/async task errors
grep "ERROR \[scheduler\|task-" app.log | head -20
```

### HA log format (DefenseFlow `ha.log`)

```bash
# Find incomplete operations (started but no matching done)
grep "starting" ha.log | while read line; do
    operation=$(echo "$line" | grep -oP '(?<=HA )\w+(?= starting)')
    if ! grep -q "HA $operation done\|HA $operation complete" ha.log; then
        echo "INCOMPLETE: $line"
    fi
done

# Find failover events
grep -E "failover|promote|elected|dormant" ha.log | head -30
```

---

## Multi-Service Correlation

When the same request touches multiple services:

```bash
# Collect logs from all services into one file with labels
paste -d'\n' \
    <(sed 's/^/[SERVICE-A] /' service-a.log) \
    <(sed 's/^/[SERVICE-B] /' service-b.log) \
| sort -k2 > combined.log

# Now grep for correlation ID across both
grep "correlationId=abc123" combined.log
```

---

## Reporting Format

When summarising log findings:

```
## Log Analysis Summary

**Time Window**: 2025-01-15 10:30 – 10:45 UTC
**Log Files**: service-a.log, service-b.log, ha.log
**Total Errors**: 143 ERROR lines across 3 files

### Error Frequency
| Error | Count | First Seen | Last Seen |
|-------|-------|-----------|----------|
| NullPointerException in ItemService | 12 | 10:31:05 | 10:44:57 |
| Vision connection timeout | 87 | 10:30:01 | 10:45:00 |
| HA delete starting (no matching done) | 1 | 10:32:45 | — |

### Root Cause Chain
1. **10:30:01** — Vision connection lost (M_00301 x87)
2. **10:31:05** — ItemService failed: NPE because Vision state was null
3. **10:32:45** — HA delete triggered, never completed
4. **10:45:00** — All errors stop after service restart

### Smoking Gun
[10:32:45.123] HA delete starting → no "HA delete done" found in log
→ HA delete left system in inconsistent state
```

---

## Hard Rules

- **Never paraphrase log lines in an RCA.** Copy exact text with timestamp.
- **Count before concluding.** "Lots of errors" is not evidence. "317 M_00301 errors over 15 minutes" is.
- **Find the FIRST error, not the most obvious one.** The obvious error is often a symptom.
- **Always check the timestamp gap.** An error at 10:30 and another at 11:30 may be unrelated.
- **Cross-reference active and standby** logs before concluding which node caused the failure.
