# Cross-Repo Plans

Plans, designs, and RCA documents that span multiple repositories live here.

## Why a central location?

When a feature spans `repo-A` and `repo-B`, the plan needs to be visible from
both. JetBrains Copilot Chat in either repo can read absolute paths, so:

```
Continue executing the plan at C:\rdwr-intelij\.copilot-shared\plans\<filename>.md
```

works from any window.

## Naming convention

```
YYYY-MM-<short-slug>.md
```

Examples:
- `2026-04-cross-repo-feature.md`
- `2026-05-rseg-12345-rca.md`
- `2026-05-policy-editor-dpinline-template-sync.md`

## Structure (recommended)

Plans should follow the spec-driven workflow when applicable:

```markdown
# <Title>

## Scope
- Repo A: <change summary>
- Repo B: <change summary>

## Requirements (EARS)
WHEN <event> THE SYSTEM SHALL <behaviour>

## Design
<architecture / sequence / interface contracts>

## Task list
- [ ] repo-A: ...
- [ ] repo-B: ...

## Verification
<how to confirm end-to-end success>
```

## Workflow for cross-repo work

1. Create the plan here from one repo's Copilot Chat.
2. Open both repos in JetBrains as a multi-root project (or two windows).
3. From each repo's Copilot Chat, point at this plan path and execute the
   relevant tasks.
4. Mark tasks done in the plan as you go.
5. Archive completed plans by moving to `archive/<year>/`.

## Note

This folder is **not** junctioned into any repo's `.github/`. Copilot doesn't
auto-load it as instructions; it's purely a reference store accessed by
absolute path.
