---
name: policy-editor-figma-to-code
description: Use when implementing or updating UI from Figma in common_policy_editor, especially versioned policy-apps that consume the design system only through the webui-design-system package root.
---

# Policy Editor Figma to Code

## Overview

Build Policy Editor UI from Figma using the patterns already established in `ui/policy-app-*` and `ui/common`. This repo is an **external consumer** of the design system. It does **not** import DS internals. The authoritative DS surface is the `webui-design-system` package plus `DESIGN_SYSTEM_REFERENCE.md`.

Prefer `webui-design-system` components directly. Use local Policy Editor components only when they add domain-specific behavior as thin wrappers around DS primitives.

## Required References

Read these before planning or implementing:

- `DESIGN_SYSTEM_REFERENCE.md` — authoritative `webui-design-system` export surface for Policy Editor
- `.github/copilot-instructions.md` — repo architecture, UI constraints, and DS consumption rules
- `ui/common/components/` — existing local wrappers and reusable Policy Editor UI patterns

## Critical Rules

> **HUMAN IN THE LOOP — NON-NEGOTIABLE**
> Ask the user only for decisions that remain ambiguous after checking the Figma file, existing Policy Editor code, and surrounding app structureAsk the user only for decisions that remain ambiguous after checking the Figma file, existing Policy Editor code, and surrounding app structure.

1. **Do not inspect DS internals as an implementation target** — Policy Editor imports from `webui-design-system`, not from `design-system/components/...`.
2. **Import from the package root only** — use patterns like `import { Button, Tooltip, styledTokens, textStyle, icons } from 'webui-design-system';`.
3. **Match Policy Editor file conventions** — default to `.js` and `.style.js`. Do not introduce `.tsx`, `.types.ts`, or generic feature-folder splits unless the target area already uses them.
4. **Prefer DS components directly** — use `webui-design-system` exports first. Use PE shared components from `ui/common/components/` only when they add domain-specific logic as thin wrappers around DS primitives. When creating new PE wrappers, build them on top of DS components, not from scratch.
5. **Stay inside the existing architecture** — styled-components for styling, local state/context for UI state, validator functions in `src/util/validation.js` when needed.
6. **No hardcoded visual values when a token already exists** — map colors and typography to `styledTokens`, `textStyle`, or existing local theme helpers.

## When to Use

Use this skill when:

- Figma work targets `common_policy_editor`
- The feature lives in `ui/policy-app-*` or `ui/common`
- You need to choose between local shared components and package exports
- You need to map Figma values to the Policy Editor DS package surface
- You need to preserve the Policy Editor micro-frontend and form-section patterns

Do not use this skill when:

- You are editing the design-system source itself
- You are working in `webui_components` rather than the Policy Editor consumer
- The task is backend-only

## Workflow

### Phase 0: Discover the Policy Editor Surface

**Do this before touching Figma output.**

#### 1. Load the authoritative DS surface

- Read `DESIGN_SYSTEM_REFERENCE.md`
- Read the target `ui/policy-app-*/package.json`
- Confirm the DS dependency is `webui-design-system`
- Confirm real imports in the target app use package-root imports only

This repo consumes the DS as a package. Treat the package root exports and the reference document as authoritative. Do not plan around deep imports or DS source files.

#### 2. Check DS coverage, then local PE components

First, check whether `webui-design-system` already exports a component that satisfies the need. Use DS components directly whenever possible.

Only then check local PE locations for domain-specific wrappers:

- `ui/common/components/`
- `ui/common/CommonComponent.js`
- `ui/common/layout/`
- the target app's existing `src/form/` sections

Use an existing PE wrapper only when it adds meaningful domain logic (validation wiring, policy-specific defaults, form integration) on top of a DS primitive. If a PE component duplicates DS functionality without adding value, prefer the DS component directly.

#### 3. Identify the actual coding pattern

Read 2-3 real components from the target app and one shared component from `ui/common`.

Record:

- `.js` + `.style.js` split
- styled-components usage
- whether styling uses `styledTokens`, `textStyle`, `styled-theming`, or local `ThemeColors.js`
- prop naming and handler patterns such as `setValue(key)` factories
- whether validation is local or routed through `src/util/validation.js`

#### 4. Determine the correct placement

Decide whether the UI belongs in:

- `ui/common/` for reuse across versions, or
- a single `ui/policy-app-<version>/src/` app

Ask the user if this is not already explicit.

### Phase 1: Analyze the Figma Design

1. Use `mcp_figma_get_screenshot` to view the target design
2. Use `mcp_figma_get_design_context` to extract layout, spacing, colors, typography, borders, shadows, and states
3. Map each value to one of:
   - `styledTokens`
   - `textStyle`
   - existing local theme helpers such as `ThemeColors.js`
   - an existing local shared component prop

If the design requires a DS component, confirm it is exported from `webui-design-system`. If it is not exported, do not plan to import it indirectly from DS internals.

### Phase 2: Resolve Ambiguities, Then Present the Plan

**Stop before coding.**

#### Step 1: Ask the user the missing implementation decisions

Typical Policy Editor questions:

- Which policy-app version is the target?
- Should this live in `ui/common` or only in one versioned app?
- Use DS component directly or is a PE wrapper justified by domain logic?
- Is the component wired to real policy data, app context, or temporary mock data?
- Does the change need validation logic?
- Does it need to appear inside the standalone example app for verification?

Use `vscode_askQuestions`. Do not bury unanswered questions inside the plan.

#### Step 2: Present a Policy Editor-specific plan

Include these sections:

| Section                        | Purpose                                                               |
| ------------------------------ | --------------------------------------------------------------------- |
| **DS Package Exports to Use**  | Figma element -> `webui-design-system` export -> import form          |
| **PE Wrappers (if justified)** | Figma element -> PE wrapper -> DS primitive it wraps -> justification |
| **Token Mapping**              | Figma value -> `styledTokens` / `textStyle` / local theme helper      |
| **Placement Decision**         | Why code belongs in `ui/common` or a specific `policy-app-*`          |
| **Validation Impact**          | Whether `src/util/validation.js` or existing validators must change   |
| **Files to Touch**             | Exact files to create or update                                       |

Do not proceed until the user approves the plan when the change is ambiguous, architectural, or spans multiple files. For small, localized, low-risk changes, proceed once the implementation path is clear.

### Phase 3: Implement Using Policy Editor Patterns

#### File conventions

Default structure in this repo is:

```text
ComponentName.js
ComponentName.style.js
```

Optional files only when the target area already supports them:

- `constants.js`
- `utils.js`
- `mockData.js`

Do not force a TypeScript-style file split into a JavaScript area.

#### Component rules

- Keep rendering components pure and prop-driven
- Put styles in `.style.js`
- Use named exports when the surrounding code does
- Preserve existing prop names and callback shapes
- Support `debugId` where surrounding controls already use it
- Prefer local context over introducing Redux or new global state

#### Styling rules

- Use `styled-components`
- Prefer `styledTokens` and `textStyle` when the DS already exposes the needed token or mixin
- If the target area already relies on `ui/common/ThemeColors.js` or `ui/common/layout/Layout.style.js`, stay consistent with that local pattern
- Do not hardcode DS internal import paths

#### Validation rules

When adding or changing form fields:

- inspect existing validation in `src/util/validation.js`
- extend local validators instead of adding ad-hoc inline checks
- wire validation output into existing containers such as `ExpandableCard isError={...}` when appropriate

### Phase 4: Verify in the Policy Editor Runtime

Prefer the narrowest available verification:

1. Run `npm run build` in the target `ui/policy-app-*` directory
2. If the app has an `example/` folder, verify there next
3. If Playwright is available, compare the rendered UI against Figma in the example app or target route

Remember that the Policy Editor app is bundled with `microbundle-crl` and post-processed into a host-consumed wrapper. Validate the actual target app, not just isolated JSX.

## Quick Reference

### Correct DS import pattern

```javascript
import {
  Button,
  Tooltip,
  styledTokens,
  textStyle,
  icons,
} from "webui-design-system";
```

### Wrong DS import pattern

```javascript
import Button from "webui-design-system/components/Button";
import { Button } from "../../../design-system/index";
```

### PE wrappers (use only when they add domain logic over DS)

- `ui/common/components/TextField/InputTextField.js` — wraps DS text field with PE validation and `debugId` conventions
- `ui/common/components/card/ExpandableCard.js` — wraps DS card with form-section error state integration
- `ui/common/layout/Layout.style.js` — PE-specific layout mixins
- `ui/common/ThemeColors.js` — local theme mapping (prefer `styledTokens` when equivalent token exists)

### Typical target structure

```text
ui/policy-app-10.13.0.0/src/
  form/
  util/
  globalStyle.js
  context.js
```

## Common Mistakes

| Mistake                                                      | Correct approach                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------- |
| Planning to import DS internals                              | Use only `webui-design-system` root exports                   |
| Building a PE wrapper when DS already covers the need        | Use DS component directly; only wrap when adding domain logic |
| Introducing `.tsx` / `.types.ts` structure into JS form code | Follow `.js` and `.style.js` conventions                      |
| Putting validation logic inline in JSX                       | Extend the app's validator utilities                          |
| Ignoring the target app version                              | Confirm the exact `policy-app-*` target first                 |
| Verifying only an isolated component                         | Build and check the actual policy-app runtime                 |

## Completion Checklist

- [ ] Confirmed the target is `common_policy_editor`
- [ ] Read `DESIGN_SYSTEM_REFERENCE.md`
- [ ] Verified `webui-design-system` root-package imports in real code
- [ ] Used DS components directly where possible; PE wrappers only justified by domain logic
- [ ] Mapped colors and typography to exported tokens or existing local theme helpers
- [ ] Asked the user about app version, placement, and data wiring when unclear
- [ ] Matched `.js` and `.style.js` conventions
- [ ] Updated validation utilities when the UI changed validation behavior
- [ ] Built the target policy-app and verified the rendered result
