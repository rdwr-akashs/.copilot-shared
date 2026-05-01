---
name: db-migration
description: Use when creating, reviewing, or debugging database schema migrations with Flyway or Liquibase. Covers writing migration scripts, rollback strategies, and safe deployment practices.
---

# Database Migration

## Activation Rule

**Triggers:**
- "Add a new column / table / index"
- "Write a Flyway / Liquibase migration"
- "Schema change needed for feature X"
- "Migration failed on deploy"
- "Database rollback needed"
- "Review this migration script"

> **Override Directive:** Every schema change MUST go through a versioned migration script. Never use `spring.jpa.hibernate.ddl-auto=update` in production.

## Pre-Migration Checklist

```
[ ] Current schema version identified (flyway_schema_history / DATABASECHANGELOG)
[ ] Migration tested on a local DB copy first
[ ] Rollback script written (or reversibility confirmed)
[ ] Data migration handled separately from schema migration
[ ] No breaking changes to running application (backward-compatible)
[ ] Index impact assessed (large table? online index?)
```

## Flyway Workflow

### Naming Convention

```
V<version>__<description>.sql     — versioned migration (runs once)
U<version>__<description>.sql     — undo migration (Flyway Teams only)
R__<description>.sql              — repeatable migration (views, procedures)
```

Example: `V2024.01.15.1__add_device_status_column.sql`

### Step 1: Write the Migration

```sql
-- V2024.01.15.1__add_device_status_column.sql
-- Description: Adds status column to device table for tracking health state
-- Backward compatible: YES (nullable column, no app changes required to deploy)

ALTER TABLE device
    ADD COLUMN status VARCHAR(20) DEFAULT 'UNKNOWN';

-- Index for queries filtering by status
CREATE INDEX idx_device_status ON device(status);
```

### Step 2: Write the Rollback

```sql
-- U2024.01.15.1__add_device_status_column.sql
DROP INDEX IF EXISTS idx_device_status;
ALTER TABLE device DROP COLUMN IF EXISTS status;
```

### Step 3: Validate Locally

```bash
# Check pending migrations
./mvnw flyway:info

# Run migrations
./mvnw flyway:migrate

# Verify
./mvnw flyway:validate
```

### Step 4: Verify in Application

```bash
# Start application — Flyway runs automatically on boot
./mvnw spring-boot:run

# Check flyway_schema_history
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;
```

## Liquibase Workflow

### Naming Convention

```
db/changelog/
  db.changelog-master.xml          — master changelog (includes all)
  changes/
    2024-01-15-add-device-status.xml
```

### Step 1: Write the Changeset

```xml
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="2024-01-15-add-device-status" author="developer">
        <comment>Add status column to device table</comment>
        <addColumn tableName="device">
            <column name="status" type="VARCHAR(20)" defaultValue="UNKNOWN"/>
        </addColumn>
        <createIndex tableName="device" indexName="idx_device_status">
            <column name="status"/>
        </createIndex>
        <rollback>
            <dropIndex tableName="device" indexName="idx_device_status"/>
            <dropColumn tableName="device" columnName="status"/>
        </rollback>
    </changeSet>
</databaseChangeLog>
```

### Step 2: Validate

```bash
# Preview SQL without executing
./mvnw liquibase:updateSQL

# Apply
./mvnw liquibase:update

# Rollback last changeset
./mvnw liquibase:rollbackCount -Dliquibase.rollbackCount=1
```

## Safe Migration Patterns

### Backward-Compatible Changes (deploy without downtime)

| Change | Safe? | Notes |
|--------|-------|-------|
| Add nullable column | YES | Old code ignores it |
| Add column with default | YES | Old code ignores it |
| Add index | YES | Use `CREATE INDEX CONCURRENTLY` on PostgreSQL |
| Add table | YES | Old code doesn't query it |
| Rename column | NO | Old code breaks — use expand/contract pattern |
| Drop column | NO | Old code breaks — remove code first, drop column next deploy |
| Change column type | NO | May lose data — add new column, migrate, drop old |

### Expand/Contract Pattern (for breaking changes)

```
Deploy 1: ADD new_column (expand)
Deploy 2: App writes to BOTH old + new columns (dual-write)
Deploy 3: Backfill new_column from old_column
Deploy 4: App reads from new_column only
Deploy 5: DROP old_column (contract)
```

### Large Table Migrations

For tables with millions of rows:

```sql
-- PostgreSQL: non-blocking index
CREATE INDEX CONCURRENTLY idx_device_status ON device(status);

-- Batched data migration (don't lock the whole table)
UPDATE device SET status = 'ACTIVE' WHERE id BETWEEN 1 AND 10000 AND status IS NULL;
UPDATE device SET status = 'ACTIVE' WHERE id BETWEEN 10001 AND 20000 AND status IS NULL;
-- ... repeat in batches
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| "Migration checksum mismatch" | Someone edited an already-applied migration | `flyway repair` or fix the checksum in `flyway_schema_history` |
| "Migration out of order" | Developer branching caused version gap | Set `flyway.outOfOrder=true` or renumber |
| Migration hangs | Lock on table (concurrent DDL) | Check `pg_locks` / `SHOW PROCESSLIST`, kill blocking query |
| "Relation already exists" | Migration partially applied | Mark as applied: `INSERT INTO flyway_schema_history ...` or fix manually |
| Rollback not available | No undo script written | Write one now, or manually reverse + mark as rolled back |

## Inter-Skill References

- New entity → also needs `adding-rest-endpoints` for the API layer
- Schema review → `reviewer` agent checks naming conventions + backward compatibility
- After migration → `java-test-coverage` to verify repository tests still pass
- CI/CD pipeline → `devops` agent for deployment ordering (migrate before deploy)
