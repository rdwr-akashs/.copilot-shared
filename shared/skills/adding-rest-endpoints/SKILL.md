---
name: adding-rest-endpoints
description: Use when adding a new REST API endpoint to the project service. Covers the full end-to-end checklist: REST resource, JerseyConfig registration, security, service layer, and tests.
---

# Adding a New REST Endpoint

## Activation Rule

**Triggers:**
- Creating a new `@Path`-annotated JAX-RS resource class
- Adding GET/POST/PUT/DELETE methods to an existing REST resource
- User says "add endpoint", "create API", "expose REST", or "new route"
- Plan step requires a new HTTP endpoint in the service module

> **Override Directive:** This skill overrides default behavior when its conditions are met. Missing any step causes silent 404 or security bypass.

This skill guides the complete process for adding a new REST API endpoint to a Spring Boot / JAX-RS service.
Missing any step typically causes a silent failure (404) or a security bypass.

## Full Checklist

### Step 1: Create the REST Resource class

Create a new class in `service/src/main/java/com/radware/dfc/policy/service/rest/`:

```java
@Component
@Path(PE_V2 + "/api/my-resource")   // PE_V2 = "/api/v2" from PEUrls
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MyResourceRestService {

    private final MyResourceService myResourceService;

    public MyResourceRestService(MyResourceService myResourceService) {
        this.myResourceService = myResourceService;
    }

    @GET
    @Path("/{id}")
    @RolesAllowed({Role.ADMIN, Role.READ_WRITE})   // ← RBAC required on every method
    @Operation(summary = "Get resource by ID")
    @ApiResponse(responseCode = "200", description = "Resource found")
    @ApiResponse(responseCode = "404", description = "Resource not found")
    public Response getResource(@PathParam("id") Long id) {
        return Response.ok(myResourceService.findById(id)).build();
    }

    @POST
    @RolesAllowed({Role.ADMIN})
    @Operation(summary = "Create a new resource")
    @ApiResponse(responseCode = "201", description = "Created")
    public Response createResource(@Valid MyResourceRequest request) {
        MyResource created = myResourceService.create(request);
        return Response.status(Response.Status.CREATED).entity(created).build();
    }
}
```

**Annotations on each method:**
| Need | Annotation |
|------|-----------|
| Role-restricted access | `@RolesAllowed({Role.ADMIN, Role.READ_WRITE})` |
| Open to all authenticated | `@PermitAll` |
| Blocked completely | `@DenyAll` |

---

### Step 2: Register in JerseyConfig ⚠️ MANDATORY

Open `service/src/main/java/.../config/JerseyConfig.java` and add your class to `registerEndpoints()`:

```java
private void registerEndpoints() {
    register(TemplateRestService.class);
    register(MyResourceRestService.class);   // ← ADD THIS
}
```

**Without this step the endpoint returns 404 with no log warning.** This is the most common mistake.

---

### Step 3: Create a Service Interface

In `service/src/main/java/com/radware/dfc/policy/service/`:

```java
public interface MyResourceService {
    /** Get a resource by its ID. Throws <ProjectException>(NOT_FOUND) if missing. */
    MyResource findById(Long id);

    /** Create a new resource. Throws <ProjectException>(BAD_REQUEST) on invalid input. */
    MyResource create(MyResourceRequest request);
}
```

---

### Step 4: Create the Service Implementation

In a sub-package (e.g., `service/myresource/`):

```java
@Service
@RequiredArgsConstructor
public class MyResourceServiceImpl implements MyResourceService {

    private final MyResourceRepository repository;

    @Override
    public MyResource findById(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new <ProjectException>(<ProjectException>.NOT_FOUND,
                "MyResource not found: " + id));
    }

    @Override
    public MyResource create(MyResourceRequest request) {
        // validation / mapping logic
        return repository.save(MyResource.from(request));
    }
}
```

---

### Step 5: Create the Repository (if needed)

```java
public interface MyResourceRepository extends JpaRepository<MyResource, Long> {
    // Custom queries here
}
```

---

### Step 6: Write Tests

#### Service integration test:
```java
@SpringBootTest
@TestInstance(Lifecycle.PER_CLASS)
class MyResourceServiceImplTest {

    @Autowired private MyResourceService myResourceService;

    @Test
    void should_throwNotFound_when_resourceDoesNotExist() {
        assertThatThrownBy(() -> myResourceService.findById(-1L))
            .isInstanceOf(<ProjectException>.class);
    }
}
```

#### REST endpoint test:
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT)
@DirtiesContext
@TestInstance(Lifecycle.PER_CLASS)
class MyResourceRestServiceTest {

    @Autowired private TestRestTemplate restTemplate;
    @Autowired private ApplicationEventPublisher eventPublisher;

    @BeforeAll
    void setup() {
        // CRITICAL: activates standalone HA mode — required for requests to be processed
        eventPublisher.publishEvent(new HaStandaloneStateEvent(this));
    }

    @Test
    void should_return404_when_resourceNotFound() {
        ResponseEntity<String> response = restTemplate
            .getForEntity("/api/v2/my-resource/99999", String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
```

---

### Final Verification Checklist

- [ ] `@Component`-annotated REST class in `service/rest/` package
- [ ] REST class registered in `JerseyConfig.registerEndpoints()`
- [ ] Every method has `@RolesAllowed`, `@PermitAll`, or `@DenyAll`
- [ ] `@Operation` and `@ApiResponse` Swagger annotations present
- [ ] Service interface defined (not just implementation)
- [ ] `@Service`-annotated `ServiceImpl` class
- [ ] `<ProjectException>` (or `<LowLevelException>`) for error cases
- [ ] `@SpringBootTest` integration test for service
- [ ] `@SpringBootTest(webEnvironment=DEFINED_PORT)` REST test with `HaStandaloneStateEvent`
- [ ] All maven modules compile: `./mvnw clean install -DskipTests`
- [ ] All tests pass: `./mvnw test`

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Architect (PEplan)** | References during planning to ensure REST checklist is in the plan |
| **Developer** | Primary user — follows checklist step-by-step during implementation |
| **Reviewer** | Validates all checklist items are complete (especially JerseyConfig + RBAC) |
| **Tester** | Uses Step 6 patterns to write REST endpoint tests |

## Decision Heuristics

- **Always use this skill** when adding ANY new REST endpoint — no exceptions
- **Combine with `test-driven-development`** — write the REST test first, then implement
- **Combine with `requesting-code-review`** — review after endpoint is complete
- Example: "Add GET /api/v2/feeds/{id}" ��� use this skill
- Example: "Fix validation in existing POST endpoint" → don't need this skill, use `systematic-debugging`

## Quick Start

1. Create `@Component` REST class in `service/rest/`
2. Register in `JerseyConfig.registerEndpoints()` ← **most forgotten step**
3. Add `@RolesAllowed` to every method
4. Create Service interface + `@Service` impl
5. Write `@SpringBootTest` REST test with `HaStandaloneStateEvent`

## Prompt Template

```
Add a new REST endpoint: [HTTP method] /api/v2/[path]
Purpose: [what it does]
Use the adding-rest-endpoints skill for the full checklist.
```

## Performance Guidelines

- Always register in JerseyConfig immediately after creating the class — don't defer
- Run `./mvnw clean install -DskipTests` after Step 2 to catch compilation issues early
- Batch-create Service interface + impl together to avoid incomplete state

## Inter-Skill References

- **Before implementation** → `brainstorming` if endpoint design is unclear
- **Test-first approach** → `test-driven-development` for writing tests before implementation
- **After completion** → `requesting-code-review` to validate the checklist
- **Verification** → `verification-before-completion` before claiming done
