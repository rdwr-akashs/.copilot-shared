---
applyTo: '**/*.java,**/*.kt,**/*.js,**/*.jsx,**/*.ts,**/*.tsx,**/*.py,**/*.go,**/*.cs,**/*.rb,**/*.php,**/*.scala,**/*.sql'
---
# Performance Awareness — Default-Fast Coding

Write fast code by default. Don't optimise prematurely, but don't write
obviously-slow code either. The rules below cost nothing at the time of writing
and save expensive rewrites later.

## The N+1 rule (most common bug)

Any loop over entities that fetches related data inside the loop is a bug.

```java
// BAD — N+1
for (Order o : orders) {
    User u = userRepo.findById(o.getUserId());  // 1 query per order
}

// GOOD — single batch
Map<Long, User> users = userRepo.findAllByIdIn(orderIds);
for (Order o : orders) {
    User u = users.get(o.getUserId());
}
```

Applies to: SQL `findById` in a loop, REST calls in a loop, Redis `GET` in a
loop, file reads in a loop. **Always batch.**

## Allocation discipline

- Use `Collection`-typed parameters, not `ArrayList`/`HashMap` — let callers
  pass any implementation.
- Pre-size collections when the count is known: `new ArrayList<>(n)`.
- Don't `String +` in loops — use `StringBuilder`.
- Don't `Stream` over small fixed-size data when a `for` loop is clearer
  AND faster. Streams have non-trivial overhead per element.
- Reuse expensive objects (regex `Pattern`, `ObjectMapper`, `MessageDigest`).
  Construct once, store as `static final`.

## I/O is the bottleneck

- Bound every external call with a timeout (HTTP, DB, message broker).
- Bound every retry loop with a max attempt count AND total deadline.
- Pool connections. Never `new HttpClient()` per request.
- Cache idempotent reads. TTL must match data freshness requirements.
- Stream large payloads — never load a full file/response into memory if it
  could exceed 10MB.

## Algorithmic awareness

| Pattern | When to flag |
|---|---|
| Nested loop over collections both > 100 | Use a map lookup instead |
| `list.contains()` in a loop | Convert to `Set` first |
| Sort-then-search | Use a sorted set / `TreeMap` |
| Recursive call without memoization on overlapping inputs | Cache results |
| `O(n²)` string concat | `StringBuilder` / `String.join` |

## Concurrency

- Default to immutable. Mutation requires a lock or a concurrent collection.
- `synchronized` on long-lived objects is a deadlock waiting to happen.
  Prefer `ReentrantLock` with timeout, or a single-writer queue model.
- Never block in a reactive/async pipeline (`.toFuture().get()` inside
  `Mono`/`CompletableFuture` chains).
- Thread-pool sizing: CPU-bound = `cores`. I/O-bound = `cores * (1 + wait/cpu)`.
  Default `Executors.newFixedThreadPool(N)` is rarely correct.

## Database

- Index every column used in `WHERE`, `ORDER BY`, `JOIN ON`. If you can't, the
  query is wrong.
- Paginate every multi-row read. Default page size: 50–200.
- Avoid `SELECT *`. Project the columns you actually need.
- Avoid `DISTINCT` to paper over a JOIN bug.
- `IN (?, ?, ?, ...)` past ~1000 elements becomes slower than a temp table.

## Logging cost

- Don't log inside hot loops at `info` level.
- Use guarded debug: `if (log.isDebugEnabled())` only if the args are expensive
  to compute. Otherwise `log.debug("...", arg)` is cheap (lazy formatting).
- Never `log.info("processed: " + obj.toString())` — concatenation runs even
  when the log level filters it out.

## When to actually profile

Don't guess. Profile when:
- A request takes > 200ms in a tight path
- Memory usage trends upward over time
- A test that should be fast is slow

Use a real profiler (async-profiler, VisualVM, JFR), not `System.currentTimeMillis()`
sprinkled in code.
