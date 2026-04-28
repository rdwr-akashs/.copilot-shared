# Common Fix Patterns — PR Review Comments

Quick reference for the most frequent code fix patterns encountered in PR reviews.

## Pattern: Extract Constants
```java
// BEFORE
String fileName = fileDetail != null ? fileDetail.getFileName() : "unknown.txt";
return sanitized.isEmpty() ? "UntitledFeed" : sanitized;

// AFTER
private static final String DEFAULT_FILE_NAME = "unknown.txt";
private static final String DEFAULT_FEED_NAME = "UntitledFeed";

String fileName = fileDetail != null ? fileDetail.getFileName() : DEFAULT_FILE_NAME;
return sanitized.isEmpty() ? DEFAULT_FEED_NAME : sanitized;
```

## Pattern: Add RBAC
```java
// BEFORE
@GET
@Produces(MediaType.APPLICATION_JSON)
public Response getAllFeeds() {

// AFTER
@GET
@Produces(MediaType.APPLICATION_JSON)
@RolesAllowed({Role.SYSTEM_USER, Role.SYS_ADMIN, Role.SEC_ADMIN})
public Response getAllFeeds() {
```

## Pattern: Add Logging
```java
// BEFORE
public Response createResource(...) {
    ResourceDTO created = service.createResource(...);

// AFTER
private static final Logger logger = LoggerFactory.getLogger(ThisClass.class);

public Response createResource(...) {
    logger.info("POST /endpoint - Creating resource");
    ResourceDTO created = service.createResource(...);
```

## Pattern: Null Safety
```java
// BEFORE
JsonNode excluded = parseExcludedAddresses(formPart.getValue());

// AFTER
JsonNode excluded = formPart != null 
    ? parseExcludedAddresses(formPart.getValue()) 
    : null;
```

## Pattern: Fix Race Condition
```java
// BEFORE
public void create(String name, ...) {
    if (repository.existsByName(name)) {
        throw new ConflictException();
    }
    Lock lock = getLock(name);
    lock.lock();
    try {
        // ... create logic
    } finally {
        lock.unlock();
    }
}

// AFTER
public void create(String name, ...) {
    Lock lock = getLock(name);
    lock.lock();
    try {
        if (repository.existsByName(name)) {
            throw new ConflictException();
        }
        // ... create logic
    } finally {
        lock.unlock();
        locks.remove(name); // prevent memory leak
    }
}
```

## Pattern: Builder Pattern
```java
// BEFORE
Entity entity = new Entity();
entity.setName(name);
entity.setCreator(creator);
entity.setCount(count);
entity.setHash(hash);
entity.setCreatedTime(now);
entity.setUpdateTime(now);

// AFTER
Entity entity = Entity.builder()
    .name(name)
    .creator(creator)
    .count(count)
    .hash(hash)
    .createdTime(now)
    .updateTime(now)
    .build();

// Don't forget to add @Builder, @NoArgsConstructor, @AllArgsConstructor to entity
```

