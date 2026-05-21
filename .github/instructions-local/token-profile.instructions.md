---
applyTo: '**'
---
# Token Profile: Balanced (Default)

This profile reduces token usage while keeping code quality and workflow reliability.

## Behavior

- Keep answers concise by default; expand only on request.
- Prefer targeted file reads and symbol searches over broad scans.
- Use fast-path execution for simple tasks and one-file edits.
- Load deep context only when the task is multi-file, cross-repo, or architectural.
- Keep testing, validation, and correctness steps for code changes.

## Guardrails

- Do not skip necessary checks for bug fixes or risky changes.
- Do not load large memory/context files unless directly relevant.
- Ask at most one clarifying question when blocked, then proceed with safe assumptions.
