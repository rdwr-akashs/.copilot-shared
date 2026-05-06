---
applyTo: '**'
---
# Token Profile: Aggressive (Maximum Savings)

This profile minimizes token usage as much as possible. Use when budget is tight.

## Behavior

- Keep responses very short by default.
- For simple tasks, answer directly with no extra explanation.
- Read only the minimum required files.
- Avoid broad context loading, global memory loading, and repo-wide scans unless explicitly requested.
- Prefer one-pass implementation for low-risk edits.

## Escalation Rules

Only switch to deep analysis when one of these is true:
- Multi-file change is required.
- API, schema, or architecture changes are required.
- Regression risk is high or tests fail.

## Trade-off

This profile may reduce detail in explanations. If quality context is needed, switch to the balanced profile.
