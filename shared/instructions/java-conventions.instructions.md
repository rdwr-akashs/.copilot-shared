---
description: "Java coding conventions for Radware backend services. Spring Boot, constructor injection, exception hierarchy, logging, package structure."
applyTo: "**/*.java"
---

# Java Conventions — Radware

## Package Structure

```
com.radware.<product>.<module>/
  api/           — REST controllers (@RestController)
  application/   — Application services (orchestration, use-case layer)
  domain/        — Domain entities, value objects, domain services
  infrastructure/ — Repository implementations, external clients, adapters
  config/        — Spring @Configuration classes
  dto/           — Request/response DTOs (records preferred)
  exception/     — Custom exception classes
```

## Dependency Injection

**Constructor injection always. Field injection never.**

```java
// CORRECT
@Service
public class ItemService {
    private final ItemRepository repository;
    private final ItemMapper mapper;

    public ItemService(ItemRepository repository, ItemMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }
}

// WRONG — never use @Autowired on a field
@Service
public class ItemService {
    @Autowired
    private ItemRepository repository;  // ← forbidden
}
```

## No Null Returns

Methods must never return `null`. Use `Optional<T>` for absence.

```java
// CORRECT
public Optional<Item> findById(UUID id) {
    return repository.findById(id);
}

// WRONG
public Item findById(UUID id) {
    return repository.findById(id).orElse(null);  // ← forbidden
}
```

Callers must handle the Optional explicitly:
```java
service.findById(id)
    .orElseThrow(() -> new ItemNotFoundException(id));
```

## Exception Hierarchy

All domain exceptions extend a base exception class per module.

```java
// Base exception (per module)
public class ItemException extends RuntimeException {
    public ItemException(String message) { super(message); }
    public ItemException(String message, Throwable cause) { super(message, cause); }
}

// Specific exceptions
public class ItemNotFoundException extends ItemException {
    public ItemNotFoundException(UUID id) {
        super("Item not found: " + id);
    }
}

public class DuplicateItemException extends ItemException {
    public DuplicateItemException(String name) {
        super("Item already exists: " + name);
    }
}
```

Map to HTTP status in `@ControllerAdvice`:
```java
@ExceptionHandler(ItemNotFoundException.class)
@ResponseStatus(HttpStatus.NOT_FOUND)
public ErrorResponse handleNotFound(ItemNotFoundException ex) {
    return new ErrorResponse(ex.getMessage());
}
```

## Logging

Use SLF4J. Never `System.out.println`. Never `printStackTrace()`.

```java
private static final Logger log = LoggerFactory.getLogger(ItemService.class);

// Level guide:
log.debug("Processing item: id={}, type={}", item.getId(), item.getType()); // diagnostic
log.info("Item created: id={}", item.getId());                               // business event
log.warn("Item processing slow: id={}, elapsed={}ms", id, elapsed);          // degraded
log.error("Failed to create item: id={}", id, exception);                    // always include exception

// WRONG — no string concatenation
log.info("Item created: " + item.getId());  // ← allocates string even when debug is off
```

## DTOs — Use Records

```java
// Request DTO
public record CreateItemRequest(
    @NotBlank @Size(max = 128) String name,
    @NotNull ItemStatus type,
    @Size(max = 1024) String description
) {}

// Response DTO
public record ItemResponse(
    UUID id,
    String name,
    ItemStatus type,
    Instant createdAt
) {}
```

Records are immutable by default — prefer over classes for DTOs.

## Spring Boot Controller Conventions

```java
@RestController
@RequestMapping("/api/v1/items")
@Validated
public class ItemController {

    private final ItemService service;

    public ItemController(ItemService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ItemResponse create(@RequestBody @Valid CreateItemRequest request) {
        return service.createItem(request);
    }

    @GetMapping("/{id}")
    public ItemResponse getById(@PathVariable UUID id) {
        return service.findById(id)
            .orElseThrow(() -> new ItemNotFoundException(id));
    }
}
```

- Controllers are thin — no business logic
- All validation via `@Valid` on request body
- `@ResponseStatus` on methods, not thrown exceptions

## Immutability

- Prefer `final` fields everywhere
- Prefer `record` over `class` for value objects and DTOs
- Collections: return `List.copyOf()` or `Collections.unmodifiableList()` from getters

## Testing Conventions

- One test class per production class
- Test class in `src/test/java` mirroring the `src/main/java` package
- `@MockBean` only in `@WebMvcTest` — use Mockito `@Mock` for unit tests
- See `tdd.instructions.md` and the `tdd-java` skill

## Forbidden Patterns

- `@Autowired` on fields
- `null` return from public methods
- `System.out` or `e.printStackTrace()`
- Business logic in controllers
- Catching and swallowing exceptions (`catch (Exception e) {}`)
- `Optional.get()` without `isPresent()` check (use `orElseThrow`)
- Static mutable state

## Boundary Validation Rule

Validate input **once**, at the inbound boundary. Trust your own code past that line.

```
[ External / Untrusted Input ] ──► VALIDATE HERE (controllers, message handlers, config)
[ Internal calls between services ] ──► Trust the contract (@NonNull, Optional, etc.)
[ Outbound calls: HTTP, DB, files ] ──► Wrap in timeout + handle specific exceptions
```

If you find the same null-check in 3 places, the boundary is wrong — push validation outward.

**Error propagation rule** — every `catch` must do exactly one of:
1. Handle the failure (safe fallback, documented why)
2. Translate to a more meaningful exception (original as `cause`)
3. Re-throw

`catch (Exception e) { log.error(...); }` with no rethrow is always wrong.
