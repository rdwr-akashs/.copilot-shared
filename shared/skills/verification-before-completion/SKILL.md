---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Activation Rule

**Triggers:**
- About to claim work is complete, fixed, or passing
- About to commit, create PR, or mark task as done
- About to express satisfaction or success ("Done!", "Fixed!", "All tests pass!")
- Moving to next task after finishing current one
- Delegating to agents and trusting their success claims

> **Override Directive:** This skill overrides default behavior when its conditions are met. NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE — this is non-negotiable.

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | `./mvnw test` output: 0 failures | Previous run, "should pass" |
| Build succeeds | `./mvnw clean install` exit 0 | Tests passing, compilation untested |
| Bug fixed | Test original symptom passes | Code changed, assumed fixed |
| All modules compile | `./mvnw clean install -DskipTests` | Single module tested |
| Driver contract met | All driver modules compile | Only tested one version |
| Integration works | `./mvnw verify` passes | Unit tests only |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Done!")
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification (one module, not all)
- "Just this once"
- **ANY wording implying success without having run verification**

## Key Patterns

**Tests:**
```
./mvnw test -pl service
[See: Tests run: 34, Failures: 0, Errors: 0]
"All service tests pass (34/34)"

NOT: "Should pass now"
```

**Full Build:**
```
./mvnw clean install
[See: BUILD SUCCESS]
"Full build passes across all modules"

NOT: "Linter passed" or "Tests passed" (build != tests)
```

**Multi-module verification:**
```
./mvnw clean install -DskipTests
[See: BUILD SUCCESS for all modules]
"All modules compile successfully"

NOT: "service compiles" (what about drivers?)
```

**Driver contract compliance:**
```
./mvnw clean install -DskipTests
[See: All driver modules compile against updated driver-api]
"All 13 driver modules compile with updated contract"

NOT: "Tested with 10_0_0_0" (what about the other 12?)
```

## When To Apply

**ALWAYS before:**
- ANY success/completion claims
- ANY expression of satisfaction
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents
- Reporting status

## Agent Integration

| Agent | Usage |
|-------|-------|
| **All agents** | EVERY agent must use this before claiming completion |
| **Developer** | Runs verification after implementing features |
| **SquadLeader** | Enforces verification between workflow phases |
| **Reviewer** | Validates that verification evidence exists |

## Decision Heuristics

- **Always use** before ANY completion claim — no exceptions
- **Use for every agent** — even trusted subagent results must be re-verified
- **Combine with every other skill** — this is the final gate before any claim
- Example: "Tests should pass now" → STOP, run `./mvnw test` first
- Example: "Build succeeded in subagent" → STOP, re-run `./mvnw clean install`

## Quick Start

1. Identify what command proves the claim
2. Run the FULL command (fresh, complete)
3. Read full output — check exit code and failure count
4. State claim WITH evidence (or state actual status)

## Prompt Template

```
Before claiming completion, run verification.
Command: [./mvnw clean install]
Use the verification-before-completion skill.
```

## Performance Guidelines

- Always run the FULL verification command — never rely on partial checks
- For multi-module projects: `./mvnw clean install -DskipTests` verifies ALL modules compile
- `./mvnw clean install` (with tests) is the gold standard — use it before PRs and merges

## Inter-Skill References

- **Used by ALL skills** as final gate before completion claims
- **Especially critical with** → `executing-plans`, `subagent-driven-development`, `finishing-a-development-branch`
- **After debugging** → `systematic-debugging` phase 4 requires this
- **Before commit** → `commit-push` should run this first
