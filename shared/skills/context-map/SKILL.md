---
name: context-map
description: 'Use before implementing any feature, bugfix, or refactor to identify all files that need changes. Generates a structured map of files to modify, their dependencies, related tests, and risk assessment. Trigger when starting a task, asked to plan changes, or before touching code in an unfamiliar area.'
---

# Context Map

Before writing any code, map every file that will be touched. This prevents missed updates (especially in the multi-module driver pattern) and surfaces cross-cutting risks early.

## When to Use This Skill

- Starting any feature implementation or bug fix
- Asked to "plan" or "what files need to change"
- Working in an unfamiliar module or driver version
- Before touching `driver-api/` (requires changes in ALL active driver modules)

## Instructions

Given the task description, do the following:

### 1. Classify the change layer
Determine which layers are affected:
- **`driver-api/`** — interface change → ALL 13 `drivers/<version>/Driver.java` files must be updated
- **`service/`** — business logic, REST endpoints, JPA entities, repositories
- **`drivers/<version>/`** — version-specific DTO or FTL template change
- **`ui/<frontend-app>-<version>/`** — frontend React component change
- **`feeds/`** — feed management change

### 2. Search the codebase
Use `grep_search` and `semantic_search` to find:
- Classes, methods, or endpoints directly involved
- All callers/implementors of any interface being changed
- Existing tests covering the affected code
- Similar patterns in other drivers or modules to follow

### 3. Produce the Context Map

Output a filled-in map using this structure:

```
## Context Map — [task name]

### Files to Modify
| Module | File | Purpose | Changes Needed |
|--------|------|---------|----------------|
| service/ | path/to/Service.java | Business logic | Add method X |
| driver-api/ | path/to/Interface.java | Contract | Add method signature |
| drivers/10_13_0_0/ | path/to/Driver.java | Implementation | Implement new method |
| ... (repeat for ALL active driver versions if driver-api touched) | | | |

### Dependencies (may need updates)
| File | Relationship |
|------|--------------|
| JerseyConfig.java | Register new REST resource |
| path/to/test/ServiceTest.java | Existing test — verify still passes |

### Test Files to Create/Update
| Test | Type | What to cover |
|------|------|---------------|
| ServiceTest.java | Unit (Mockito) | Happy path + NOT_FOUND case |
| ServiceIT.java | Integration (Testcontainers) | DB round-trip |

### Reference Patterns (existing code to follow)
| File | Pattern |
|------|---------|
| drivers/10_13_0_0/Driver.java | Follow same method structure |
| service/.../<DomainService>.java | Exception handling pattern |

### Risk Assessment
- [ ] `driver-api/` change → all 13 driver modules must implement or build fails
- [ ] New `@Entity` → must wire into `BackupServiceImpl`
- [ ] New REST endpoint → must register in `JerseyConfig`
- [ ] DTO shape change → frontend alignment needed
- [ ] Database schema change → migration script needed
```

### 4. Validation gate
State explicitly: **"Do not write code until this map is confirmed."**

Flag any risk checkboxes that apply with `[x]` and explain the impact.
