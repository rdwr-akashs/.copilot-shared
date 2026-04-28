# Pre-Code Checklist

Paste-ready prompt to run BEFORE any non-trivial implementation. Forces a 60-second
review against design, performance, and defensive-coding rules.

---

Before writing code for this task, run this checklist and answer each item in one
sentence. If any answer is unclear, research before coding.

## Design (SOLID)
- **What is the ONE responsibility of the new class/function?** (no "and")
- **Does any existing class already do this?** (don't duplicate)
- **Will this code be easy to delete in 6 months?** (clear seams = yes)

## Boundary
- **Where does input enter, and where is it validated exactly once?**
- **What does the caller see when this fails?** (specific exception type, with context)

## Edge cases (must answer all four)
- **Empty input** → behaviour: ___
- **Null input** → disallowed (assert) OR handled: ___
- **Max-size input** → bounded by: ___
- **Concurrent calls** → race? lost update? lock?

## Performance
- **Algorithmic cost vs production input size:** O(?)  N_max = ?
- **External calls per invocation:** ? (any > 1 in a loop = batch it)
- **Timeouts on every external call?** yes / no
- **Hot-path logging?** none at info level

## Test seam
- **Can the business logic be unit-tested without DB / network?** yes / no
- **What are the 3 test cases I'll write?** happy / boundary / failure

## Reuse / consistency
- **Existing exception type to reuse?** ___
- **Existing helper / utility?** ___
- **Existing pattern in the codebase to follow?** ___

---

Once every box is answered, proceed to implementation. Reference the relevant
skills as needed:
- `design-review` — full pre-implementation gate (for > 50 LOC)
- `defensive-coding` — null/error/edge handling rules
- `test-driven-development` — write the test first
- `context-map` — find every file that needs to change
