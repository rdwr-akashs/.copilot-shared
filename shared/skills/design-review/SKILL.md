---
name: design-review
description: 'Use BEFORE writing non-trivial code. Forces a 5-minute design check against SOLID, performance, and edge cases. Triggered by "design review", "is this design ok", or automatically before any task estimated > 50 LOC. Output is a short go/no-go with concrete change suggestions.'
---

# Design Review (Pre-Implementation)

A 5-minute structured review BEFORE coding. Catches the bugs you'd otherwise
write. Run this on the proposed approach, not on existing code.

## When to use

✅ Use when:
- Adding a new class, service, or module
- Changing a public API or interface
- Touching > 50 LOC across multiple files
- Introducing a new dependency
- Modifying anything in a hot code path

❌ Skip when:
- One-line fix
- Test-only change
- Renaming, formatting, doc-only

## The 7 questions

Answer each with one sentence. If any answer is "I don't know" or "it depends",
go research before writing code.

### 1. Single Responsibility
> What is the ONE thing this class/function does? Can I describe it without "and"?

If the description has "and", split it now — splitting later costs 10x.

### 2. Boundary
> Where does input enter, and where is it validated?

Validation happens once, at the boundary. Internal code assumes valid input.
If input is validated in three places, two are wrong.

### 3. Failure mode
> When this fails, what does the caller see, and how do they recover?

- Throw with context (what was the input, what was expected)
- No silent `catch + log + return null`
- No new exception type if an existing one fits

### 4. Edge cases (the killer four)
> What happens if the input is: empty? null? max-size? concurrent?

For each, one of: documented as "not supported" + asserted, OR handled.

### 5. Algorithmic cost
> How does runtime grow with input size N? What's the worst N in production?

If runtime is O(N²) and N can be 10,000, redesign now.

### 6. I/O
> How many remote calls / DB queries does this do per invocation?

- > 1 per item in a loop → batch it
- No timeout → add one
- No retry deadline → add one

### 7. Test seam
> How will this be unit-tested without spinning up a database / network?

If the answer requires Spring context / Testcontainers for a piece of business
logic, the dependencies are wrong — push I/O to the edge.

## Output format

```
DESIGN REVIEW — <feature>

GO / NO-GO: <go | no-go | go with changes>

Top concerns (max 3):
1. <concern> → <change to make>
2. ...

Cleared:
- SRP: ✓
- Boundary: ✓
- ...
```

## Examples

### Example 1 — caught a bug before coding

> Task: "Add an endpoint to return a user's last 30 days of orders."

Q1 SRP ✓ — one thing.
Q2 Boundary — userId from path, validated by `@PathVariable + @Valid`.
Q3 Failure — user not found → `NotFoundException`. Empty list → return `[]`.
Q4 Edge cases:
   - empty: returns `[]` ✓
   - null userId: 404 from validator ✓
   - **max-size: a power user could have 50,000 orders → must paginate**
   - concurrent: read-only, no concern ✓
Q5 O(N) where N = orders in 30d, capped by page size after fix.
Q6 I/O — 1 DB query (good).
Q7 Mockable repository ✓.

GO with changes: **add `Pageable` parameter, default page size 50, max 200.**
Without this, an admin viewing a power user crashes the service.

### Example 2 — caught a performance bug

> Task: "When listing policies, also show the name of the user who created each."

Q6 I/O — current proposal does `userService.findById(p.getCreatorId())` per
   policy in a loop. **N+1.**

NO-GO. Fix: batch-fetch users via `findAllByIdIn(creatorIds)`, build a map,
look up by id in the loop.
