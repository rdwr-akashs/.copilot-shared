---
name: api-contract-first
description: Use when designing a new REST endpoint or modifying an existing API. Define the OpenAPI spec first, get agreement, then implement. Prevents backend/frontend drift.
---

# API Contract First

## Activation Rule

**Triggers:**
- Adding a new REST endpoint
- Modifying request/response shape of an existing endpoint
- Frontend needs to call an API that doesn't exist yet
- "Design the API for [X]", "What should the endpoint look like?", "Add endpoint to get [X]"

> **Override Directive:** No implementation until the OpenAPI spec is written, reviewed, and agreed. This is the contract — both backend and frontend derive from it.

## Why Contract-First

Without a spec:
- Backend implements one shape, frontend expects another → runtime integration failures
- Breaking changes discovered in code review, not design
- No single source of truth for validation rules

With a spec:
- Frontend can mock with MSW before backend exists
- Backend validates against the spec automatically (Spring validation)
- Breaking changes are visible in the diff

## The Flow

```
1. Write OpenAPI spec (YAML)
2. Review with frontend AND backend developers
3. Generate TypeScript types for frontend
4. Generate Java DTO / validation annotations (or write manually)
5. Implement backend (derives from spec)
6. Implement frontend (derives from types)
7. Integration test validates spec compliance
```

## Step 1: Write the OpenAPI Spec

Location: `src/main/resources/openapi/<resource>.yaml` or a shared `api-spec/` folder.

```yaml
openapi: "3.0.3"
info:
  title: <Product> API
  version: "1.0"

paths:
  /api/v1/items:
    post:
      summary: Create a new item
      operationId: createItem
      tags: [Items]
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateItemRequest'
            examples:
              valid:
                value:
                  name: "My Item"
                  type: "ACTIVE"
      responses:
        '201':
          description: Item created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ItemResponse'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '409':
          $ref: '#/components/responses/Conflict'

    get:
      summary: List items with optional filters
      operationId: listItems
      tags: [Items]
      parameters:
        - name: status
          in: query
          schema:
            $ref: '#/components/schemas/ItemStatus'
        - name: page
          in: query
          schema:
            type: integer
            default: 0
        - name: size
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Paginated item list
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ItemPage'

  /api/v1/items/{id}:
    get:
      operationId: getItem
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ItemResponse'
        '404':
          $ref: '#/components/responses/NotFound'

components:
  schemas:
    CreateItemRequest:
      type: object
      required: [name, type]
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 128
          example: "My Item"
        type:
          $ref: '#/components/schemas/ItemStatus'
        description:
          type: string
          maxLength: 1024

    ItemResponse:
      type: object
      required: [id, name, type, createdAt]
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        type:
          $ref: '#/components/schemas/ItemStatus'
        createdAt:
          type: string
          format: date-time

    ItemStatus:
      type: string
      enum: [ACTIVE, INACTIVE, PENDING]

    ItemPage:
      type: object
      properties:
        content:
          type: array
          items:
            $ref: '#/components/schemas/ItemResponse'
        totalElements:
          type: integer
        totalPages:
          type: integer
        page:
          type: integer
        size:
          type: integer

  responses:
    ValidationError:
      description: Request validation failed
      content:
        application/json:
          schema:
            type: object
            properties:
              errors:
                type: object
                additionalProperties:
                  type: string
    NotFound:
      description: Resource not found
    Unauthorized:
      description: Authentication required
    Conflict:
      description: Resource already exists

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
```

## Step 2: Design Review Checklist

Before agreement, verify:

- [ ] All endpoints have auth (`security:` block) or explicitly mark as public
- [ ] All 4xx error codes are listed (don't only document 200)
- [ ] Request required fields vs optional are explicit
- [ ] Response fields use consistent naming (camelCase)
- [ ] Pagination follows the same shape as existing endpoints
- [ ] No business logic leaking into the API (internal IDs, internal states)
- [ ] Breaking changes identified and versioned (bump to v2 if breaking)

## Step 3: Generate TypeScript Types (Frontend)

```bash
# Using openapi-typescript
npx openapi-typescript src/main/resources/openapi/items.yaml -o src/api/types/items.ts

# Or using openapi-generator
npx @openapitools/openapi-generator-cli generate \
  -i src/main/resources/openapi/items.yaml \
  -g typescript-fetch \
  -o src/api/generated/
```

Generated types prevent shape drift between backend and frontend.

## Step 4: Java DTOs from Spec

```java
// CreateItemRequest — matches spec properties
public record CreateItemRequest(
    @NotBlank @Size(max = 128) String name,
    @NotNull ItemStatus type,
    @Size(max = 1024) String description
) {}

// ItemResponse — matches spec properties
public record ItemResponse(
    UUID id,
    String name,
    ItemStatus type,
    Instant createdAt
) {}
```

**Validation annotations must match spec constraints** (`minLength` → `@Size(min=)`, `required` → `@NotNull`/`@NotBlank`).

## Step 5: Spec Compliance Test

```java
@Test
void createItem_requestMatchesOpenApiSpec() throws Exception {
    // Use a library like AtlasmanSwaggerRequestResponseValidator or
    // SpringDoc's own validation to assert response matches spec
    mvc.perform(post("/api/v1/items").contentType(APPLICATION_JSON).content("{}"))
       .andExpect(status().isBadRequest())  // required fields missing → 400
       .andExpect(jsonPath("$.errors.name").exists())
       .andExpect(jsonPath("$.errors.type").exists());
}
```

## Hard Rules

- **Spec lives in the repo** — not in a wiki, not in Confluence, not in someone's head.
- **Version the API** (`/api/v1/`). Don't break existing callers — add v2 for breaking changes.
- **Response must include all required fields.** Optional fields can be absent; required ones never.
- **Enum values in the spec = the only valid values.** No undocumented magic strings.
- **No raw `Object` or `Map<String, Object>` in request/response.** Every field is typed and documented.
