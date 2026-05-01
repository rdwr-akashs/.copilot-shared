---
name: java-test-coverage
description: Use when you need to improve test coverage on a Java module. Analyses Jacoco coverage reports, identifies uncovered branches, and writes targeted tests to close gaps.
---

# Java Test Coverage

## Activation Rule

**Triggers:**
- "Improve test coverage for [module]"
- "Jacoco shows [X]% coverage, need to get to [Y]%"
- "Which methods have no tests?"
- "Coverage check failed in CI"
- "Find untested branches in [class]"

> **Override Directive:** Don't add tests for getters/setters/constructors blindly. Target uncovered business logic branches — conditions, exception paths, edge cases.

## The Flow

```
1. Generate the Jacoco report
2. Read the report — identify low-coverage classes
3. Open each class — find uncovered branches (yellow lines)
4. Write targeted tests for each uncovered branch
5. Regenerate report and confirm coverage improvement
6. Stop when you hit the agreed target (don't over-test boilerplate)
```

## Step 1: Generate Jacoco Report

```bash
# Run tests with coverage
./mvnw test -pl <module>

# Generate HTML report
./mvnw jacoco:report -pl <module>

# Report location
open <module>/target/site/jacoco/index.html
```

Or in CI, look for the `jacoco.xml` report:
```bash
find . -name "jacoco.xml" -path "*/target/*"
```

## Step 2: Read Coverage from XML

```bash
# Overall coverage
grep -A2 "<counter type=\"LINE\"" target/site/jacoco/jacoco.xml | tail -3

# Find classes with low branch coverage
grep -B1 "<counter type=\"BRANCH\"" target/site/jacoco/jacoco.xml \
  | awk '/class name/{name=$0} /BRANCH/{print name, $0}' \
  | awk -F'"' '{missed=$4; covered=$6; total=missed+covered; if(total>0) pct=(covered/total)*100; if(pct<80) print pct"% ", $2}' \
  | sort -n | head -20
```

## Step 3: Identify Uncovered Branches

For each class flagged as low coverage, find what's not tested:

```bash
# Count branches in a class
grep -n "if\|switch\|?.*:" src/main/java/com/<org>/<path>/<Class>.java | wc -l

# Find methods with no @Test referencing them
grep -rn "<ClassName>" src/test/ --include="*.java"
```

In the Jacoco HTML report:
- **Red line** = not executed at all
- **Yellow diamond** = branch partially covered (one side of if/else not tested)
- **Green** = fully covered

## Step 4: Write Targeted Tests

### Pattern: Uncovered exception path

```java
// Source: ItemService.createItem() throws if name already exists
public ItemResponse createItem(CreateItemRequest request) {
    if (repository.existsByName(request.name())) {
        throw new DuplicateItemException(request.name());  // ← not tested
    }
    // ...
}

// Test for the uncovered branch:
@Test
void createItem_throwsDuplicateItemException_whenNameAlreadyExists() {
    when(repository.existsByName("existing")).thenReturn(true);

    assertThatThrownBy(() -> service.createItem(new CreateItemRequest("existing", ACTIVE, null)))
        .isInstanceOf(DuplicateItemException.class)
        .hasMessageContaining("existing");
}
```

### Pattern: Uncovered null/empty guard

```java
// Source
public Optional<ItemResponse> findByName(String name) {
    if (name == null || name.isBlank()) {  // ← null branch not tested
        return Optional.empty();
    }
    return repository.findByName(name).map(mapper::toResponse);
}

// Tests
@Test
void findByName_returnsEmpty_whenNameIsNull() {
    assertThat(service.findByName(null)).isEmpty();
}

@Test
void findByName_returnsEmpty_whenNameIsBlank() {
    assertThat(service.findByName("  ")).isEmpty();
}
```

### Pattern: Uncovered enum switch branch

```java
// Source
public String describeStatus(ItemStatus status) {
    return switch (status) {
        case ACTIVE -> "Running";
        case INACTIVE -> "Stopped";
        case PENDING -> "Starting";   // ← PENDING branch not tested
    };
}

// Test using @ParameterizedTest
@ParameterizedTest
@EnumSource(ItemStatus.class)
void describeStatus_coversAllStatuses(ItemStatus status) {
    assertThat(service.describeStatus(status)).isNotBlank();
}
```

### Pattern: Uncovered conditional business logic

```java
// Source
public ItemResponse updateItem(UUID id, UpdateItemRequest request) {
    Item item = repository.findById(id).orElseThrow(...);
    if (request.name() != null) {
        item.setName(request.name());     // ← partial update not tested
    }
    if (request.status() != null) {
        item.setStatus(request.status()); // ← partial update not tested
    }
    return mapper.toResponse(repository.save(item));
}

// Tests for each conditional branch
@Test
void updateItem_updatesOnlyName_whenStatusIsNull() {
    // Only name in request, status should be unchanged
}

@Test
void updateItem_updatesOnlyStatus_whenNameIsNull() {
    // Only status in request, name should be unchanged
}
```

## Coverage Targets by Layer

| Layer | Target | What to test |
|---|---|---|
| Domain / Service | 85%+ branch | Business logic, error paths, conditional flows |
| Controller | 80%+ line | All endpoints, happy path + validation failures |
| Repository | Skip or 60% | Integration tested; don't unit-test Spring Data proxies |
| Config / DTOs | Skip | No logic; boilerplate |
| Exception classes | Skip | No logic |

## What NOT to Test (Exclude from Coverage)

Add to `pom.xml` Jacoco exclusions:

```xml
<configuration>
  <excludes>
    <exclude>**/config/**</exclude>
    <exclude>**/*Config.class</exclude>
    <exclude>**/*Application.class</exclude>
    <exclude>**/dto/**</exclude>
    <exclude>**/*Exception.class</exclude>
    <exclude>**/generated/**</exclude>
  </excludes>
</configuration>
```

## Hard Rules

- **Don't write tests just to hit a number.** Untested exception-path tests have real value; tested-getter tests have none.
- **One test per uncovered branch.** Name the test after what it covers: `methodName_effect_whenCondition`.
- **Tests must assert something meaningful.** Not just "doesn't throw" — verify the actual outcome.
- **If a branch can't be tested**, it may be dead code. Consider removing it.
- **Don't mock what you're testing.** If testing the service, don't mock the service.
