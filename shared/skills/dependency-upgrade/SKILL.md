---
name: dependency-upgrade
description: Use when upgrading Maven or npm dependencies. Safe, incremental upgrade workflow — one dependency at a time, with CVE checks, build verification, and breaking change review.
---

# Dependency Upgrade

## Activation Rule

**Triggers:**
- "Upgrade [library] to [version]"
- "Update dependencies"
- "Fix CVE in [dependency]"
- "Dependabot / security alert for [package]"
- CI reports a vulnerable dependency

> **Override Directive:** Never upgrade all dependencies at once. One dependency at a time. Run tests after each. Commit after each successful upgrade.

## Maven Upgrade Workflow

### Step 1: Audit current state

```bash
# Check for vulnerable dependencies (OSS Index)
./mvnw org.sonatype.ossindex.maven:ossindex-maven-plugin:audit

# List outdated dependencies
./mvnw versions:display-dependency-updates

# List outdated plugin versions
./mvnw versions:display-plugin-updates
```

### Step 2: Check the CVE or release notes

Before upgrading:

1. Find the CVE: `https://nvd.nist.gov/vuln/search/results?query=CVE-XXXX-XXXX`
2. Find the library's changelog / migration guide
3. Check if any internal code uses the changed API (search for imports)

```bash
# Find usages of the library's classes
grep -rn "import org.springframework.security" src/main/java --include="*.java" | grep "OldClassName"

# Find usages in tests
grep -rn "import org.springframework.security" src/test/java --include="*.java" | grep "OldClassName"
```

### Step 3: Upgrade one dependency

```bash
# In pom.xml: update the version property or direct version
# Then verify Maven resolves correctly
./mvnw dependency:resolve -pl <module>

# Or use the versions plugin to update
./mvnw versions:set-property -Dproperty=spring-boot.version -DnewVersion=3.3.0

# Apply the change
./mvnw versions:commit
```

### Step 4: Run tests

```bash
# Run tests for the affected module
./mvnw test -pl <module>

# Run integration tests if they exist
./mvnw verify -pl <module>

# If Spring Boot upgrade, also run the full build
./mvnw clean install -DskipTests=false
```

### Step 5: Fix breaking changes

Common Spring Boot breaking changes:

```java
// Spring Boot 3.x: SecurityFilterChain (not WebSecurityConfigurerAdapter)
// BEFORE
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter { ... }

// AFTER
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception { ... }
}
```

Search for breaking patterns:
```bash
# Spring Boot 3.x migration
grep -rn "WebSecurityConfigurerAdapter\|HttpMethod.GET.matches\|AntPathMatcher" src/ --include="*.java"
```

### Step 6: Commit after each successful upgrade

```bash
git add pom.xml */pom.xml
git commit -m "chore: upgrade spring-boot-starter-security to 3.3.0 (CVE-2024-XXXX)"
```

---

## npm Upgrade Workflow

### Step 1: Audit current state

```bash
# Check for vulnerabilities
npm audit

# List outdated packages
npm outdated

# Check specific package vulnerabilities
npx audit-ci --moderate
```

### Step 2: Check breaking changes

```bash
# View changelog between versions
npx npm-check-updates --target <package-name>

# Or visit the package's GitHub releases page
```

### Step 3: Upgrade one dependency at a time

```bash
# Upgrade one package to latest compatible
npm install <package>@<version>

# Upgrade to next major (check breaking changes first!)
npx npm-check-updates -u --filter <package-name>
npm install
```

### Step 4: Run tests and type-check

```bash
npx tsc --noEmit       # type errors introduced by upgrade?
npx jest               # unit tests pass?
npm run build          # production build works?
```

### Step 5: Commit

```bash
git add package.json package-lock.json
git commit -m "chore: upgrade react to 18.3.0"
```

---

## CVE Priority Guide

| CVSS Score | Severity | Action |
|---|---|---|
| 9.0–10.0 | Critical | Fix immediately (same sprint, unplanned) |
| 7.0–8.9 | High | Fix in current or next sprint |
| 4.0–6.9 | Medium | Fix within 30 days |
| < 4.0 | Low | Fix in next planned upgrade cycle |

---

## Hard Rules

- **One upgrade per commit.** Never batch — makes rollback impossible.
- **Read the changelog** before upgrading any major version.
- **Run tests after each upgrade.** Don't upgrade N packages then run tests.
- **Check transitive dependencies.** `npm audit` or `mvn dependency:tree` may reveal the vulnerable package is a transitive dep — you may need to override it.
- **Don't suppress audit warnings** without a documented exception and a Jira ticket.
- **Lock file always committed.** `package-lock.json` and `pom.xml` both go in the commit.

---

## Override Transitive Dependency (Maven)

If the vulnerable package is pulled in transitively:

```xml
<!-- pom.xml: force the patched version -->
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.16.1</version>  <!-- override to patched version -->
    </dependency>
  </dependencies>
</dependencyManagement>
```

```bash
# Verify the override took effect
./mvnw dependency:tree | grep jackson-databind
```

## Override Transitive Dependency (npm)

```json
// package.json: npm overrides (npm 8.3+)
{
  "overrides": {
    "semver": "^7.5.4"
  }
}
```
