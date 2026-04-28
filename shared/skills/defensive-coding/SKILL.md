---
name: defensive-coding
description: 'Use when writing or reviewing code that handles input, errors, concurrency, or external calls. Provides a checklist of common defects (null-safety, edge cases, error propagation, resource leaks) and how to write code that fails loudly at the right boundary.'
---

# Defensive Coding — Catch Bugs at Compile Time, Not in Production

The goal is not paranoia (defensive code everywhere) — it's **picking the right
boundary** to validate, then trusting your own code past that line.

## The Boundary Principle

```
[ External World ] -- HARD VALIDATION --> [ Your System ]
[ Your System    ] -- TRUST CONTRACTS --> [ Your System ]
[ Your System    ] -- HARD VALIDATION --> [ External World ]
```

- **Inbound boundary** (controllers, message handlers, CLI args, config files):
  validate everything. Type, format, range, business invariants.
- **Internal calls**: trust the contract. If the called method declares
  `@NonNull`, don't `if (x != null)` in the caller. The signature is the contract.
- **Outbound boundary** (HTTP, DB, file I/O): validate that the response matches
  expectations before consuming it. Wrap in timeout + retry + circuit breaker.

If you find yourself doing the same null check in 5 places, **the boundary is
wrong**. Push validation outward.

## Null safety

| Situation | Rule |
|---|---|
| Method may return absent value | `Optional<T>` (Java) / nullable type (Kotlin/TS) — never bare `null` |
| Collection result | Empty collection, never `null` |
| Method parameter | `@NonNull` by default; `@Nullable` only when explicitly allowed |
| Fields | Initialise at construction. No nullable fields without a documented reason |
| External JSON | Treat every field as nullable until validated by a schema |

If your IDE shows a "potential NPE" warning, fix it — never suppress.

## Error propagation

```
RIGHT:  throw new DomainException("user " + id + " not found", NOT_FOUND);
WRONG:  catch (Exception e) { log.error("...", e); return null; }
WRONG:  catch (Exception e) { throw new RuntimeException(e); }   // loses context
WRONG:  catch (Exception e) { /* swallow */ }
```

Every `catch` must do exactly one of:
1. Handle the failure (log + safe fallback, with the fallback documented)
2. Translate to a more meaningful exception (with the original as `cause`)
3. Re-throw

Catching `Exception` or `Throwable` is almost always wrong. Catch the specific
type you can handle.

## Edge cases — the killer four

For every function processing input, deliberately think:

1. **Empty** — `""`, `[]`, `{}`. What's the contract?
2. **Null** — disallowed (preferred) or handled (documented).
3. **Max-size** — what if N = 10⁶? Pagination, streaming, rejection?
4. **Concurrent** — two callers at once. Race? Lost update? Deadlock?

Add a unit test for each of the four cases that applies. If a case is "not
supported", assert it (`Objects.requireNonNull`, `Preconditions.checkArgument`)
so it fails loudly.

## Resource discipline

- Every resource (file, socket, connection, lock, transaction) acquired must
  be released. Use try-with-resources / `using` / RAII. Never finally-with-null-check.
- Streams must be closed even on exception.
- Locks must have a timeout. `lock.tryLock(5, SECONDS)` over `lock.lock()`.
- Transactions must have a defined isolation level and timeout.

## Concurrency

- Default to immutable. If you need mutation, the type is `AtomicX`,
  `Concurrent*`, or wrapped in a single-writer model.
- Volatile is for visibility, not atomicity. `volatile int counter` and
  `counter++` is a bug.
- Don't spawn threads in business logic. Use the application's executor.
- Cancellation: long operations check `Thread.interrupted()` periodically and
  bail out cleanly.

## External calls

- **Timeout** on every call. No exceptions. Default: 5–10s for HTTP, 1–3s for
  cache, 10–30s for batch DB.
- **Retry** with backoff for idempotent operations only. Max attempts + total
  deadline.
- **Circuit breaker** for any call to a service that has a history of being
  slow or unavailable.
- **Validate response** — schema, expected fields, status code. Don't trust
  upstream to keep its contract.

## Logs as evidence

A good log line lets you reconstruct what happened from production logs alone:

```
log.warn("retry attempt {} of {} for orderId={} after {}: {}",
         attempt, maxAttempts, orderId, elapsedMs, errorClass);
```

- Include identifiers (orderId, userId, requestId)
- Include quantity (count, size, elapsed)
- Include the failure class, not just the message
- No stack traces at `info`. Stack traces at `warn`/`error` only.

## The defect catalog (review trigger list)

When reviewing code, scan for these — they account for ~80% of production bugs:

- [ ] `null` returned from a method that could just return `Optional.empty()`
- [ ] `catch (Exception e)` without rethrow
- [ ] Loop that fetches related data inside (N+1)
- [ ] Mutation of a parameter
- [ ] String concat in a hot loop
- [ ] No timeout on external call
- [ ] Reading the whole result into memory
- [ ] Logging at `info` inside a tight loop
- [ ] `equals` without `hashCode`
- [ ] Compare `BigDecimal` with `equals` (use `compareTo` for numeric equality)
- [ ] `==` on boxed wrappers (`Integer`, `Long`)
- [ ] `Date`/`Calendar` use (use `java.time.*`)
- [ ] Single-letter variable names outside trivial loops
- [ ] Magic number / magic string
- [ ] TODO / FIXME without an issue link
- [ ] Mutable static field
- [ ] Method > 50 lines
- [ ] Class > 500 lines
- [ ] Cyclomatic complexity > 10 in one method
