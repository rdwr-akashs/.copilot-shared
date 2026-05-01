---
applyTo: '**'
---
# Copilot Instructions — <REPO NAME>

## Auto-Agent Dispatch

When the user sends any message **without** an explicit `@agent` prefix:

1. Classify the request using the routing table in `orchestrator.instructions.md`
2. Announce: **"[Agent: `<agent-name>`] — <one-line task summary>"**
3. Act as that agent immediately — no confirmation required
4. If classification is ambiguous, state both candidates and pick the more specific one

Examples of announcements:
- `[Agent: debugger] — Investigating why the RabbitMQ consumer stopped processing`
- `[Agent: developer] — Adding pagination to the items endpoint`
- `[Agent: case-investigator] — Starting RCA for SC-17669`

The user can redirect at any time: `@<other-agent> actually do X instead`.

## Context-First Rule

Before writing any code, check `.github/repo-cache.md` if it exists:
- If present and **< 30 days old**: read it instead of running `semantic_search` — it contains the module map, patterns, and commands already
- If absent or stale: run `acquire-codebase-knowledge` skill to generate it, then proceed
- After every completed task: append one line to `## Recent Context` in the cache

> **Task Routing:** See `.github/instructions/orchestrator.instructions.md` for the routing layer that selects agents, skills, and execution flow.
>
> **Project rules:** See `.github/instructions-local/project-rules.instructions.md` for repo-specific conventions (exception types, dependency management, build commands).
>
> **Personal preferences:** See `.github/personal-instructions.md` (if present) for developer-specific overrides.

## Project Overview

<!-- One paragraph: what this service does, who calls it, what it depends on. -->

## Tech Stack

- **Language(s):**
- **Framework(s):**
- **Database:**
- **Build:**
- **Test:**
- **CI:**

## Project Structure

```
<!-- Top-level module/folder layout with one-line descriptions -->
```

## Coding Conventions

<!-- Naming conventions, error-handling pattern, key dos/don'ts.
     Detailed rules belong in .github/instructions-local/project-rules.instructions.md -->

## Architecture Notes

<!-- Anything an agent must know to make sound design decisions. -->
