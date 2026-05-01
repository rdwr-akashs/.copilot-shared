# Tech Discoveries
# Patterns discovered in real repos. Avoids re-investigating known structures.
# Append via `save-learning` skill after any investigation.
#
# This file is gitignored — share it via your internal Bitbucket repo, not GitHub.
# Initialised by bin/setup-local.ps1 from shared/memory/templates/tech-discoveries.md.
# The Repo Registry section below is auto-populated when you run setup-local.ps1
# with Bitbucket credentials. Without credentials, add repos manually.

## How to Use

```bash
# Find a repo by name or purpose
grep -i "<repo-name>" shared/memory/tech-discoveries.md

# Find tech patterns
grep -i "elasticsearch\|rabbitmq\|akka\|postgres" shared/memory/tech-discoveries.md
```

---

## Repo Registry

All repos in your Bitbucket workspace.
Run `bin/setup-local.ps1 -Force` with Bitbucket credentials to auto-populate this section.
Full category filter: `shared/skills/remote-repo-exploration/references/repo-categories.md`

_(empty — run bin/setup-local.ps1 to populate from Bitbucket API, or add rows manually)_

---

## Elasticsearch

| Repo | Index / Alias | Shards | Key Mapping Notes | Last Verified |
|------|--------------|--------|------------------|--------------|
| _(populate via save-learning after investigating ES issues)_ | | | | |

**Common patterns to document:**
- Index naming convention, alias strategy
- Key mapping types (`keyword` sub-fields, nested objects)

---

## RabbitMQ

| Repo | Exchange | Queue | DLQ | Prefetch | Binding Key | Last Verified |
|------|---------|-------|-----|---------|------------|--------------|
| _(populate via save-learning after investigating RabbitMQ issues)_ | | | | | | |

**Common patterns to document:**
- DLQ naming convention, prefetch settings, listener config

---

## Akka

| Repo | Actor Hierarchy Root | Dispatcher Config | Key Message Types | Last Verified |
|------|---------------------|------------------|------------------|--------------|
| _(populate via save-learning after investigating Akka issues)_ | | | | |

**Common patterns to document:**
- Actor hierarchy root, dispatcher name, blocking I/O actor isolation

---

## PostgreSQL / Replication

| Repo | DB | Replication User | Key Tables | HA Config Notes | Last Verified |
|------|----|-----------------|-----------|--------------  |--------------|
| _(populate via save-learning after investigating PG/HA issues)_ | | | | | |

---

## Build & Test Commands

| Repo | Build | Test All | Test Module | Run |
|------|-------|---------|------------|-----|
| _(populated by acquire-codebase-knowledge skill — run it on each repo)_ | | | | |

---
<!-- Add new sections or rows using save-learning skill -->
