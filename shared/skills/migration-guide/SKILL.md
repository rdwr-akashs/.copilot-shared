---
name: migration-guide
description: Use when migrating Java/Spring projects to a new major version (Java 11→17→21, Spring Boot 2→3, Jakarta EE). Provides an incremental, test-at-every-step workflow.
---

# Migration Guide

## Activation Rule

**Triggers:**
- "Migrate to Java 17/21"
- "Upgrade Spring Boot to 3.x"
- "Move from javax to jakarta"
- "JDK upgrade plan"
- "Spring 6 migration"

> **Override Directive:** Never upgrade Java version and framework version in the same step. Upgrade the JDK first, stabilize, then upgrade the framework.

## Pre-Migration Checklist

```
[ ] Current Java version and target version identified
[ ] Current Spring Boot / framework version identified
[ ] Full test suite passes on current version (baseline)
[ ] CI pipeline tested locally (./mvnw clean verify)
[ ] Dependency tree exported: ./mvnw dependency:tree > deps-before.txt
[ ] Known incompatible libraries identified (check release notes)
```

## Phase 1: JDK Upgrade (e.g., 11 → 17 → 21)

### Step 1: Update toolchain

```xml
<!-- pom.xml — root -->
<properties>
    <java.version>17</java.version>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
</properties>
```

### Step 2: Fix compilation errors

Common issues by version:

| From → To | Breaking Change | Fix |
|-----------|----------------|-----|
| 8 → 11 | `javax.xml.bind` removed | Add `jakarta.xml.bind-api` + `jaxb-runtime` |
| 8 → 11 | `sun.misc.Unsafe` usage | Replace with `VarHandle` |
| 11 → 17 | Strong encapsulation | Add `--add-opens` to JVM args or fix reflection |
| 11 → 17 | Sealed classes keyword | Rename classes named `sealed`, `permits` |
| 17 → 21 | `SecurityManager` deprecated | Remove usage |
| 17 → 21 | Thread API changes | Review virtual thread compatibility |

### Step 3: Run tests

```bash
./mvnw clean verify -DskipITs=false
```

Fix all failures before proceeding. Commit: `chore: upgrade to Java 17`

## Phase 2: Framework Upgrade (e.g., Spring Boot 2 → 3)

### Step 1: Read the official migration guide

- Spring Boot 2→3: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide
- Use `spring-boot-properties-migrator` temporarily:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-properties-migrator</artifactId>
    <scope>runtime</scope>
</dependency>
```

### Step 2: javax → jakarta namespace

```bash
# Find all javax imports that need migration
grep -rn "import javax\." src/ --include="*.java" | grep -v "javax.crypto\|javax.net\|javax.security"
```

Automated rename:
```bash
find src/ -name "*.java" -exec sed -i 's/import javax\.persistence/import jakarta.persistence/g' {} +
find src/ -name "*.java" -exec sed -i 's/import javax\.servlet/import jakarta.servlet/g' {} +
find src/ -name "*.java" -exec sed -i 's/import javax\.validation/import jakarta.validation/g' {} +
find src/ -name "*.java" -exec sed -i 's/import javax\.annotation/import jakarta.annotation/g' {} +
find src/ -name "*.java" -exec sed -i 's/import javax\.inject/import jakarta.inject/g' {} +
```

### Step 3: Update companion libraries

| Library | Spring Boot 2 | Spring Boot 3 |
|---------|--------------|---------------|
| Hibernate | 5.x | 6.x (auto with Boot 3) |
| Spring Security | 5.x | 6.x |
| Flyway | 8.x | 9.x+ |
| Liquibase | 4.x | 4.17+ |
| Swagger/OpenAPI | springfox | springdoc-openapi 2.x |

### Step 4: Property changes

```properties
# Renamed in Boot 3
spring.redis.* → spring.data.redis.*
spring.elasticsearch.* → spring.elasticsearch.uris
server.max-http-header-size → server.max-http-request-header-size
```

### Step 5: Test, fix, commit

```bash
./mvnw clean verify
```

Commit: `chore: upgrade to Spring Boot 3.x`

## Phase 3: Post-Migration Cleanup

```
[ ] Remove spring-boot-properties-migrator dependency
[ ] Remove any --add-opens flags that are no longer needed
[ ] Update Dockerfile base image to match new JDK
[ ] Update CI pipeline JDK version
[ ] Run full integration test suite
[ ] Export new dependency tree: ./mvnw dependency:tree > deps-after.txt
[ ] Diff: diff deps-before.txt deps-after.txt
[ ] Update docs/codebase/STACK.md with new versions
[ ] Save migration notes to shared/memory/tech-discoveries.md
```

## Inter-Skill References

- After migration: `dependency-upgrade` to catch outdated transitive deps
- Before migration: `systematic-debugging` if current build is broken
- After migration: `java-test-coverage` to verify no coverage regression
