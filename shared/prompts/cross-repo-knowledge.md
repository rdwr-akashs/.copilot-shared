# Cross-Repo Knowledge Generation

Use these prompts to generate or refresh knowledge files for sibling services.

---

## Generate Knowledge for a Service

```
Generate cross-repo knowledge for <service name>.
Repository: <repo name>

Explore the API surface, DTOs, connection config, and business rules.
Store findings in memory-bank/cross-repo/<repo>.md.
```

**Examples:**
```
Generate cross-repo knowledge for DP Inline Configurator.
Repository: <sibling-repo>
```
```
Generate cross-repo knowledge for <orchestrator-service>.
Repository: <orchestrator-repo>
```

---

## Refresh Existing Knowledge

```
Refresh cross-repo knowledge for <service name>.
Something changed in their <API/DTO/config>.
Check memory-bank/cross-repo/<repo>.md and update stale sections.
```

---

## Targeted Question (uses cached knowledge first)

```
How does <service> call this project's <endpoint/feature>?
Check memory-bank/cross-repo/ first, explore only if not cached.
```

