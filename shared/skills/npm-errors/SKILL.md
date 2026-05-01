---
name: npm-errors
description: Use when encountering npm install, build, or test failures in the UI project — covers wrong working directory, ERESOLVE conflicts, MODULE_NOT_FOUND, stale dist/, local .tgz package issues, and the two-terminal dev workflow
---

# npm Errors

## Activation Rule

**Triggers:**
- Any `npm install`, `npm start`, `npm test`, or `npm run build` failure in `ui/` directories
- `ERESOLVE`, `MODULE_NOT_FOUND`, `ENOENT`, `EINTEGRITY` errors in terminal output
- Example app fails to start or `dist/` directory missing/empty
- User reports UI build or dev server issues

> **Override Directive:** This skill overrides default behavior when its conditions are met. Always check working directory first — most npm errors are caused by running commands in the wrong directory.

## Overview

The the frontend is split into multiple **independent** npm projects. Each `ui/<frontend-app>-<version>/` is its own package — errors often stem from running npm in the wrong directory or from the two-step build requirement before the example app can start.

## When to Use

**Symptoms:**
- `npm install` fails with `ERESOLVE`, `ETARGET`, or `404`
- `Cannot find module` / `MODULE_NOT_FOUND` at test or start time
- Example app fails to start (`dist/` not found or empty)
- Local `.tgz` package install errors (`@<org>/policy-lib`)
- `ENOENT` on `node_modules/.bin/react-scripts` or similar
- `webui-design-system` version not found in registry

## Step 1: Verify Working Directory (Most Common Cause)

Always run npm from **inside** the specific versioned app folder:

```bash
# WRONG — will not work
cd <repo-root> && npm install
cd ui && npm install

# CORRECT
cd <frontend-app-dir> && npm install
cd <frontend-app-dir> && npm install
```

For the **example (dev) app**, run npm from within `example/`:
```bash
cd <frontend-app-dir>/example && npm install
```

## Step 2: Two-Terminal Dev Workflow

The library build (`dist/`) **must exist** before the example app can start. Violating this order causes `MODULE_NOT_FOUND` in the example.

```
Terminal 1 — library (keep running):
  cd ui/<frontend-app>-<version>
  npm install
  npm start           # builds dist/ and watches for changes

Terminal 2 — app (starts after dist/ exists):
  cd ui/<frontend-app>-<version>/example
  npm install
  npm run dev         # proxied to live backend
  # OR
  npm start           # mock data only
```

**Never start Terminal 2 before `dist/` is populated by Terminal 1.**

## Common Error → Fix Table

| Error | Likely Cause | Fix |
|---|---|---|
| `ERESOLVE` / peer dep conflict | React/styled-components version mismatch | Use `npm install --legacy-peer-deps` |
| `Cannot find module '../../dist'` | Library not built yet | Run `npm start` in the library folder first |
| `404 Not Found: webui-design-system@dev-latest` | Registry unreachable or tag missing | Check VPN/registry access; try `npm install --prefer-offline` |
| `ENOENT .../react-scripts/bin/react-scripts.js` | `node_modules` missing in lib folder | Run `npm install` in `ui/<frontend-app>-<version>/`, NOT in `example/` |
| `Cannot find module '@<org>/policy-lib'` | Local `.tgz` not resolved | Run `npm install` from the lib folder where `policy-lib-*.tgz` lives |
| `EINTEGRITY` | Corrupt cache | `npm cache clean --force && npm install` |
| Tests fail: `Cannot find module 'react'` | Peer deps not installed | Run `npm install` in the lib folder, not the example |

## Local `.tgz` Package (`@<org>/policy-lib`)

The `@<org>/policy-lib` dependency is a **local file reference**:
```json
"@<org>/policy-lib": "file:./policy-lib-<version>.tgz"
```

This means `npm install` **must be run from `ui/<frontend-app>-<version>/`** — the directory where the `.tgz` file lives. Running from a parent directory will fail with `ENOENT` on the tarball.

If the `.tgz` file itself is missing:
```bash
ls ui/<frontend-app>-<version>/policy-lib-*.tgz
# If absent, ask team for the correct artifact or check the build artifacts
```

## Resolving `ERESOLVE` (Peer Dependency Conflicts)

This project pins `react@16`, `react-dom@16`, `styled-components@5.3.3` as **peer dependencies** (not direct). Conflicts arise when another package requires different versions.

```bash
# Option 1 — use legacy resolution (preferred for this project)
npm install --legacy-peer-deps

# Option 2 — inspect the conflict tree
npm install --verbose 2>&1 | grep -A5 "peer dep"
```

## Forced Clean Install

When errors persist after fixes:

```bash
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

For the full dev setup from scratch:
```bash
# Step 1 — library
cd ui/<frontend-app>-<version>
rm -rf node_modules dist
npm install --legacy-peer-deps
npm start &   # background watch

# Step 2 — example
cd example
rm -rf node_modules
npm install
npm run dev
```

## Proxy Configuration

`npm run dev` (in example/) routes API calls through `ui/dev-server/config.js`. If backend calls fail (404, auth errors), set the target there:

```js
// ui/dev-server/config.js
TARGET: 'https://YOUR_SERVER_IP'
```

Restart the dev server after any `config.js` change.

## Diagnostic Commands

```bash
# What node/npm versions are active?
node -v && npm -v

# Is dist/ built?
ls ui/<frontend-app>-<version>/dist/

# What does the registry see for a package?
npm view webui-design-system dist-tags

# Check for lock file conflicts
git diff package-lock.json | head -40
```

## Performance Guidelines

- Always check working directory FIRST — saves 90% of investigation time
- Use `--legacy-peer-deps` as default for this project (React 16 + styled-components 5)
- Don't `rm -rf node_modules` unless simpler fixes fail — it's slow to reinstall

## Agent Integration

| Agent | Usage |
|-------|-------|
| **DevOps** | Primary user — resolves npm build and dependency issues |
| **Developer** | Uses when UI development setup fails |
| **Debugger** | Uses when investigating frontend test failures |
| **Reviewer** | Not typically used |

## Decision Heuristics

- **Always use this skill** for ANY npm error in the UI modules
- **Don't use** for Java/Maven build errors — use `systematic-debugging` instead
- **Combine with `cross-repo-exploration`** if error relates to the shared UI library
- Example: "`Cannot find module '../../dist'`" → use this skill (two-terminal issue)
- Example: "`ERESOLVE peer dep conflict`" → use this skill (`--legacy-peer-deps`)
- Example: "`./mvnw test` fails in service module" → don't use this skill

## Quick Start

1. Verify working directory: `pwd` — must be inside `ui/<frontend-app>-<version>/`
2. Check the error against the Common Error → Fix Table
3. If `dist/` missing → start Terminal 1 first (`npm start` in lib folder)
4. If peer dep conflict → `npm install --legacy-peer-deps`
5. Nuclear option: `rm -rf node_modules package-lock.json && npm install --legacy-peer-deps`

## Prompt Template

```
I'm getting this npm error in [ui directory]:
[paste error]
Use the npm-errors skill to diagnose and fix.
```

## Inter-Skill References

- **For shared UI library issues** → `cross-repo-exploration` to check the shared UI library repo
- **For build pipeline issues** → `systematic-debugging` for Maven/CI failures
- **After fixing** → `verification-before-completion` to confirm UI builds correctly
