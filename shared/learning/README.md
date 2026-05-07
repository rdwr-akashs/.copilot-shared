# Central Learning Documentation

**Organized learning materials and best practices shared across all repositories.**

---

## Organization

### Best Practices by Technology
- **Path:** `best-practices/`
- **Contents:**
  - `java-patterns.md` - Java design patterns and conventions
  - `react-patterns.md` - React & frontend patterns
  - `devops-patterns.md` - Deployment, CI/CD, infrastructure
  - `database-patterns.md` - Data persistence patterns

### Troubleshooting & Debugging
- **Path:** `troubleshooting/`
- **Contents:**
  - `common-errors.md` - Frequently encountered errors and solutions
  - `debug-strategies.md` - Debugging approaches for different scenarios
  - `performance-tuning.md` - Performance optimization techniques

### Design & Architecture
- **Path:** `design-patterns/`
- **Contents:**
  - Microservices architecture
  - Event-driven design
  - API design patterns

---

## File Structure

```
learning/
├── README.md                        # This file
│
├── best-practices/
│   ├── java-patterns.md
│   ├── react-patterns.md
│   ├── devops-patterns.md
│   └── database-patterns.md
│
├── troubleshooting/
│   ├── common-errors.md
│   ├── debug-strategies.md
│   └── performance-tuning.md
│
└── design-patterns/
    ├── microservices-architecture.md
    ├── event-driven-design.md
    └── api-design.md
```

---

## How to Use

### From Copilot in Any Repo

**Reference learning materials:**
```markdown
Refer to /.copilot-shared/shared/learning/best-practices/java-patterns.md
for common patterns in this codebase.
```

**Access via symlinks (from individual repos):**
```bash
# In df_core/.github/
cat learning/best-practices/java-patterns.md
cat learning/troubleshooting/common-errors.md
```

### Link from .copilot-instructions.md

```markdown
## Learning Resources

- [Best Practices](../../.copilot-shared/shared/learning/best-practices/)
- [Troubleshooting Guide](../../.copilot-shared/shared/learning/troubleshooting/)
- [Design Patterns](../../.copilot-shared/shared/learning/design-patterns/)
```

---

## Contributing

When you discover a pattern, best practice, or debugging strategy:

1. **Write it down** in the appropriate `.md` file
2. **Include examples** with code snippets
3. **Link back** to relevant repos, tickets, or PRs
4. **Update timestamp** in file header

**Template for new learning:**

```markdown
## [Pattern Name]

**Description:** What this pattern is and when to use it

**Why it matters:** Impact and benefits

**Example:**
\`\`\`java
// Code example
\`\`\`

**Related:**
- Similar patterns
- Opposite approaches
- Relevant issues: [TICKET-123]

**Discovered in:** df_core, kvision_configuration_service
**Last updated:** [Date]
```

---

## Quick Reference

### Java Development
- [Java Patterns](best-practices/java-patterns.md)
- [Common Errors](troubleshooting/common-errors.md)

### React / Frontend
- [React Patterns](best-practices/react-patterns.md)
- [Performance Tuning](troubleshooting/performance-tuning.md)

### DevOps / Deployment
- [DevOps Patterns](best-practices/devops-patterns.md)
- [Troubleshooting Deployment](troubleshooting/common-errors.md)

---

## Statistics

- **Last Updated:** [Auto-updated on push]
- **Total Learning Files:** [Count]
- **Repositories Covered:** 5+
- **Most Referenced:** [Top pattern/guide]
