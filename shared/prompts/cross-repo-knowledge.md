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
Repository: kvision_dp_inline_config
```
```
Generate cross-repo knowledge for Cyber Controller.
Repository: kvision_cyber_controller_core
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
How does <service> call PE's <endpoint/feature>?
Check memory-bank/cross-repo/ first, explore only if not cached.
```

