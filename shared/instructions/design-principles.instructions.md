---
applyTo: '**'
---
# Design Principles — Universal Rules

Apply these to every code change. They are NOT optional. If a rule conflicts
with `project-rules.instructions.md` in the current repo, the repo rule wins.

## SOLID (apply at class/module level)

- **S — Single Responsibility:** One reason to change per class. If you can describe
  the class with "and", split it.
- **O — Open/Closed:** Extend through new types/strategies, not by modifying
  existing code that has tests passing.
- **L — Liskov Substitution:** Subtypes must honour the base contract. If
  overriding makes a method throw or no-op, the inheritance is wrong.
- **I — Interface Segregation:** Many small interfaces > one fat interface.
  Clients should not depend on methods they don't use.
- **D — Dependency Inversion:** High-level modules depend on abstractions.
  Inject dependencies; don't `new` them inside business logic.

## DRY / KISS / YAGNI

- **DRY:** Extract duplication ONLY after the third occurrence (rule of three).
  Premature abstraction is worse than duplication.
- **KISS:** Choose the boring solution. A loop beats a clever fold. A switch
  beats reflection. Optimise for the next reader, not the cleverness budget.
- **YAGNI:** Build only what the current task requires. No "while we're here"
  features, no speculative parameters, no flags for hypothetical use cases.

## Boundary discipline

- **Fail fast at the edges:** Validate input at the system boundary (controller,
  CLI, message handler). Internal code assumes valid input.
- **Errors travel up, not sideways:** Throw / propagate. Don't log-and-continue
  unless the caller explicitly opted in.
- **Pure core, imperative shell:** Business logic is testable without I/O.
  I/O lives at the edges (repos, HTTP clients, file system).

## Naming

- Names express intent, not type. `users` over `userList`. `isExpired()` over
  `checkExpiry()`.
- A name needing a comment to explain it is the wrong name.
- Booleans read as questions: `isReady`, `hasAccess`, `canRetry`.
- Avoid abbreviations except for established domain terms (`http`, `id`, `url`).

## Function shape

- Do one thing. If you describe a function with "and", split it.
- ≤ 20 lines is a target, not a rule. ≤ 4 parameters is a strong rule.
- Return early. Avoid deep nesting. Guard clauses > pyramid of doom.
- No output parameters. Return values, immutable structures, or named tuples.

## Code review smell list

Reject any of these on sight:
- A new exception type when the project already has one
- `null` returned from a service method (use `Optional` / domain-specific empty)
- Catching `Exception` / `Throwable` without rethrowing
- Field injection (`@Autowired` on fields) — use constructor injection
- Static singletons holding mutable state
- A "Util" or "Helper" class with > 5 methods (it's hiding a missing domain concept)
- Comments that paraphrase the code
- Magic numbers/strings outside a `constants` location
- Methods named `process`, `handle`, `manage`, `do` — too vague
- `if (x == true)` / `if (list.size() > 0)` — write `if (x)` / `if (!list.isEmpty())`

## When in doubt

Pick the option that is **easier to delete**. Code that is easy to delete is
code that has clear seams. That alone covers most of SOLID.
