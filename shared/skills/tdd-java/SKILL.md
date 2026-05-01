---
name: tdd-java
description: Use when implementing any Java feature or bugfix. Full TDD cycle with JUnit 5, Mockito, TestContainers, and MockMvc. Red → Green → Refactor with build verification at every step.
---

# TDD — Java

## Activation Rule

**Triggers:**
- Implementing any Java service, controller, repository, or utility method
- Fixing a Java bug (write a failing test that reproduces it first)
- "Implement [X] in Java", "Add [X] to the service", "Write tests for [X]"

> **Override Directive:** NO PRODUCTION JAVA CODE WITHOUT A FAILING TEST FIRST. This is non-negotiable.

## The Cycle

```
RED   → Write a failing test. Run it. Confirm it fails for the RIGHT reason.
GREEN → Write the MINIMUM code to make it pass. Nothing more.
REFACTOR → Clean up. Tests still pass.
```

## Test Layer Selection

| What you're testing | Tool | Base class / annotation |
|---|---|---|
| Pure logic (no Spring) | JUnit 5 + Mockito | `@ExtendWith(MockitoExtension.class)` |
| Spring service (mocked deps) | Spring slices + Mockito | `@ExtendWith(SpringExtension.class)` |
| REST controller | MockMvc | `@WebMvcTest(MyController.class)` |
| DB repository | TestContainers | `@DataJpaTest` + container |
| RabbitMQ consumer/producer | TestContainers + RabbitMQ | `@SpringBootTest` + rabbit container |
| ES queries | TestContainers + ES | `@DataElasticsearchTest` + ES container |
| Full integration | TestContainers stack | `@SpringBootTest(webEnvironment=RANDOM_PORT)` |

## Step-by-Step

### Step 1: Write the failing unit test

```java
// Pattern: MethodName_StateUnderTest_ExpectedBehaviour
@Test
void processItem_whenItemIsNull_throwsIllegalArgumentException() {
    assertThrows(IllegalArgumentException.class,
        () -> service.processItem(null));
}

@Test
void processItem_whenItemIsValid_persistsAndReturnsDto() {
    // Arrange
    var item = ItemFixtures.validItem();
    when(repository.save(any())).thenReturn(item);

    // Act
    var result = service.processItem(ItemDtoFixtures.validRequest());

    // Assert
    assertThat(result.id()).isEqualTo(item.getId());
    verify(repository).save(any());
}
```

### Step 2: Run and confirm RED

```bash
./mvnw -pl <module> test -Dtest=<TestClass>#<testMethod> -DfailIfNoTests=false
```

Confirm: test fails with `AssertionError` or `NullPointerException` — NOT with compilation error (that means the test itself is wrong).

### Step 3: Write minimum production code

No switching to other classes. No adding features not covered by the test. Make it compile and pass.

### Step 4: Run and confirm GREEN

```bash
./mvnw -pl <module> test -Dtest=<TestClass>
```

All tests in the class pass.

### Step 5: Refactor

- Remove duplication
- Rename for clarity
- Extract method if > 10 lines in production code

```bash
./mvnw -pl <module> test   # full module — must still pass
```

### Step 6: Repeat for next behaviour

---

## Controller Test Pattern (MockMvc)

```java
@WebMvcTest(MyController.class)
@Import(SecurityTestConfig.class)          // bypass auth in tests
class MyControllerTest {

    @Autowired MockMvc mvc;
    @MockBean MyService service;

    @Test
    void createItem_whenValidRequest_returns201WithBody() throws Exception {
        var response = ItemDtoFixtures.validResponse();
        when(service.create(any())).thenReturn(response);

        mvc.perform(post("/api/items")
                .contentType(APPLICATION_JSON)
                .content("""
                    {"name": "test", "type": "ACTIVE"}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(response.id()))
            .andExpect(jsonPath("$.name").value("test"));
    }

    @Test
    void createItem_whenNameMissing_returns400() throws Exception {
        mvc.perform(post("/api/items")
                .contentType(APPLICATION_JSON)
                .content("""{"type": "ACTIVE"}"""))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errors.name").exists());
    }
}
```

## TestContainers Pattern

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
class ItemIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:15-alpine");

    @Container
    static RabbitMQContainer rabbit =
        new RabbitMQContainer("rabbitmq:3-management-alpine");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.rabbitmq.host", rabbit::getHost);
        registry.add("spring.rabbitmq.port", rabbit::getAmqpPort);
    }

    @Test
    void createItem_persistsToDbAndPublishesToQueue() {
        // Full integration test — no mocks
    }
}
```

## Test Fixtures Pattern

Create a `<Domain>Fixtures` class in `src/test/java/.../fixtures/`:

```java
public class ItemFixtures {
    public static Item validItem() {
        return Item.builder()
            .id(UUID.randomUUID())
            .name("test-item")
            .status(Status.ACTIVE)
            .build();
    }
    public static Item itemWithStatus(Status status) {
        return validItem().toBuilder().status(status).build();
    }
}
```

**Never duplicate test data** — use fixtures. Fixture changes break all tests simultaneously (good — that's the point).

## Hard Rules

- **One assertion concept per test.** Multiple `assertThat` is fine if they all test the same behaviour.
- **No `@Disabled` without a linked Jira ticket comment.**
- **No `Thread.sleep` in tests.** Use `Awaitility` for async assertions.
- **Test names describe behaviour**, not implementation: `cancelOrder_whenOrderAlreadyShipped_throwsBusinessException` not `testCancel2`.
- **Mocking across module boundaries** (e.g., mock a service the controller doesn't own) = wrong — only mock direct dependencies.
- **TestContainers are shared between tests** (static containers). Don't start a new container per test.

## Coverage Targets

| Layer | Minimum | Target |
|---|---|---|
| Service methods | 80% | 95%+ |
| Controller methods | 70% | 90%+ |
| Repository (custom queries) | 60% | 80%+ |
| Utility / helper classes | 90% | 100% |

Check coverage:
```bash
./mvnw -pl <module> verify jacoco:report
open target/site/jacoco/index.html
```
