# Dependency Audit

Use this when you need to audit and upgrade dependencies in a Maven or npm project. Invokes the `dependency-upgrade` skill and `devops` agent.

---

## Fill in the blanks, then send to Copilot

```
@devops

## Dependency Audit: <Module/Repo Name>

### Scope
<!-- Mark what to audit -->
- [ ] Maven (Java) dependencies
- [ ] npm (frontend) dependencies
- [ ] Both

### Module path
<relative path to pom.xml or package.json, e.g., my-service/ or frontend/>

### Known CVE (if triggered by a security alert)
CVE: <CVE-XXXX-XXXXX>
Package: <e.g., spring-security-core 5.7.4>
Fixed in: <e.g., 6.0.1>

### Target
<!-- Mark one -->
- [ ] Fix a specific CVE only
- [ ] Upgrade all outdated dependencies (minor/patch only)
- [ ] Upgrade to latest major versions

### Constraints
<e.g., "Cannot upgrade Spring Boot past 3.2.x due to Java 11 requirement">
<e.g., "Must stay compatible with Vision 4.85.x API">
```

---

## What the agent will do

1. Run `mvn versions:display-dependency-updates` or `npm outdated`
2. Run `mvn ossindex:audit` or `npm audit` for CVEs
3. Prioritise upgrades by severity (Critical first)
4. Upgrade ONE dependency at a time, run tests after each
5. Fix any breaking changes before moving to the next
6. Commit after each successful upgrade with message `chore: upgrade <package> to <version>`
7. Produce a summary of what was upgraded and any remaining vulnerabilities

---

## Upgrade Rules (Applied Automatically)

- One dependency per commit
- Tests must pass before the next upgrade
- No suppression of audit warnings without a Jira ticket
- Major version upgrades require changelog review first
- Transitive vulnerabilities resolved via `dependencyManagement` (Maven) or `overrides` (npm)

---

## After the Audit

Review the output and raise a Jira ticket for any vulnerabilities that couldn't be fixed (incompatible fix version, blocked by other constraints). Use:

```
Type: Bug
Priority: based on CVSS score (Critical → Blocker, High → Major)
Title: [Security] CVE-XXXX-XXXXX in <package> - <summary>
Labels: security, dependency
```
