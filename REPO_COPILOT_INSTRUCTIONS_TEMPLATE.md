# Template: `.github/.copilot-instructions.md` for Each Repo

**Copy this file into each repo at: `.github/.copilot-instructions.md`**

Then customize the `[REPO-SPECIFIC]` sections below.

---

```markdown
---
description: "[REPO-NAME] — [Brief description of what this repo does]"
applyTo: "[repo-name]/**"
---

# [REPO-NAME] Instructions

> **Shared baseline:** c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md
>
> This file extends the shared rules with repo-specific conventions. For agent routing, hard rules, and universal patterns, see the shared baseline above.

## Repo-Specific Context

### Language & Framework

**Language:** [Java 21 / TypeScript / Python]  
**Primary Framework:** [Spring Boot 3.2 / React 19 / FastAPI]  
**Key Libraries:** [List 3-5 critical dependencies]

**Example:**
```
Language: Java 21
Framework: Spring Boot 3.2
Key Libraries: PostgreSQL 15, ExaBGP gRPC, RxJava 3
```

### Repository Purpose

[2-3 sentences about what this repo does and why it matters]

**Example:**
```
This repository implements the DefenseFlow security engine, 
responsible for BGP/OSPF route filtering and line-rate traffic 
analysis. It serves as the core decision-making component for 
the Radware DDoS mitigation platform.
```

### Critical Modules

| Module | Location | Purpose | Owner |
|--------|----------|---------|-------|
| Security Engine | `security-engine/` | Route filtering, line-rate analysis | @squad-security |
| HA Orchestrator | `ha-orchestrator/` | Active/Standby coordination | @squad-ha |
| Policy Engine | `policy-engine/` | Real-time policy evaluation | @squad-policy |

### Build & Test Commands

```bash
# Full build (all modules)
./mvnw clean install

# Build specific module + dependencies
./mvnw -pl security-engine -am clean install

# Run tests for module
./mvnw -pl security-engine test

# Run integration tests
./mvnw -pl security-engine failsafe:integration-test

# Check code quality
./mvnw checkstyle:check spotbugs:check
```

### Known Patterns

#### Pattern 1: Request-Response Flow

**Location:** `security-engine/src/main/java/com/radware/security/api/`

**What it does:** All REST endpoints validate input → delegate to service layer → repository handles persistence

**Example:**
```java
@PostMapping("/routes")
public ResponseEntity<RouteResponse> addRoute(@RequestBody @Valid RouteRequest req) {
    RouteResponse resp = routeService.addRoute(req);  // Service owns logic
    return ResponseEntity.ok(resp);
}
```

**When to use:** Every new REST endpoint

---

#### Pattern 2: HA Failover Detection

**Location:** `ha-orchestrator/src/main/java/com/radware/ha/witness/`

**What it does:** Monitors Vision connectivity + standby heartbeat. Triggers failover if both unreachable.

**Key file:** `VisionWitnessApiImpl.java` (lines 167-177)

**Important:** BGP peers are NOT synced during HA (known limitation, not a bug)

**When to use:** Understanding standby behavior during failover

---

### Verified Code Patterns (Anti-Patterns)

❌ **Don't do this:**
```java
@Autowired private RouteService service;  // Field injection — forbidden
if (obj == null) return null;             // Never return null
public class CustomException extends Exception { }  // Use ProjectException instead
```

✅ **Do this instead:**
```java
public class RouteController {
    private final RouteService service;
    public RouteController(RouteService service) {  // Constructor DI
        this.service = service;
    }
}

return Optional.of(obj);  // Use Optional
throw new ProjectException(HttpStatus.INTERNAL_SERVER_ERROR, "Details...");
```

### Testing Strategy

**Unit Tests:** `src/test/java/`
- Test service logic in isolation
- Mock repository layer
- Target: 80%+ coverage

**Integration Tests:** `src/test/java/it/`
- Test with real PostgreSQL (TestContainers)
- Test REST endpoints end-to-end
- Target: Critical paths only

**Example:** `RouteServiceTest.java`
```java
@Test
void shouldFilterBgpRoutes() {
    // Given: 100 routes, 20 match policy
    // When: Apply policy filter
    // Then: Return 20 filtered routes
}
```

### Debugging Guide

**Problem:** BGP peers stuck in IDLE state  
**Root cause:** Usually `PeersUpdateWorker` not running on standby  
**Debug steps:**
1. Check `ha_list.txt` — confirm you're on active or standby
2. Check logs: `grep "PeersUpdateWorker" logs/one.line.problems.log`
3. If on standby: Check if replication is current (see Memory section below)

**Problem:** HA failover not triggering  
**Root cause:** Vision unreachability detection failure  
**Debug steps:**
1. Check Vision connectivity: `curl https://<vision-ip>:8443/api/system`
2. Check HA logs: `grep "Vision\|failover" logs/ha.log | head -50`
3. Verify witness timers: `grep "witness.*interval" config/ha.properties`

### Memory & Context

**Repo-Specific Memory:** See `copilot-memory.md` in this directory

**Cross-Repo Patterns:** `../../.copilot-shared/shared/memory/cross-repo-learnings.md`

**Architecture Map:** `../../.copilot-shared/shared/memory/architecture-map.md`

### When You're Done

Before marking work as complete:

```bash
# 1. Build passes
./mvnw clean install -DskipIntegrationTests

# 2. Tests pass
./mvnw test

# 3. No style violations
./mvnw checkstyle:check

# 4. Code is documented (Javadoc on public methods)
./mvnw javadoc:javadoc

# 5. Follow verification checklist
# See ../../.copilot-shared/shared/instructions/00-core-instructions.md
```

---

## For Specific Task Types

### Implementing a Feature

1. **Start:** Read `../../.copilot-shared/shared/instructions/00-core-instructions.md` → Agent Routing
2. **Plan:** Ask @architect for design doc if missing
3. **Follow:** `../../.copilot-shared/shared/skills/executing-plans/SKILL.md` (if a plan exists)
4. **Code:** Use patterns above, follow Java conventions
5. **Verify:** Run commands in "When You're Done" section

### Investigating a Bug

1. **Start:** Read the Debugging Guide above
2. **Follow:** `../../.copilot-shared/shared/skills/systematic-debugging/SKILL.md`
3. **Produce:** Root Cause Analysis (see shared instructions)
4. **Propose:** Minimal fix + regression test cases

### Code Review

1. **Context:** Read `../../.copilot-shared/shared/instructions/00-core-instructions.md` → Universal Hard Rules
2. **Tools:** Use `../../.copilot-shared/shared/skills/pattern-detection/SKILL.md`
3. **Standard:** Compare against verified patterns above

---

## Linked Resources

| Resource | Purpose | Location |
|----------|---------|----------|
| Universal Rules | DI, error handling, naming | [00-core-instructions.md](../../.copilot-shared/shared/instructions/00-core-instructions.md) |
| Agent Base | All agents follow this | [agent-base.template.md](../../.copilot-shared/shared/instructions/agent-base.template.md) |
| Java Conventions | Java/Spring specific | [java-conventions.instructions.md](../../.copilot-shared/shared/instructions/java-conventions.instructions.md) |
| Skills | Workflows & patterns | [skills/](../../.copilot-shared/shared/skills/) |
| Cross-Repo Learning | Multi-repo patterns | [cross-repo-learnings.md](../../.copilot-shared/shared/memory/cross-repo-learnings.md) |
| Known Bugs | Bugs affecting multiple repos | [known-bugs.md](../../.copilot-shared/shared/memory/known-bugs.md) |

---
```

---

## Customization Examples

### Example 1: Java Service (like df_core)

Replace `[REPO-SPECIFIC]` placeholders:

```markdown
---
description: "df_core — DefenseFlow Security Engine (Java/Spring Boot)"
applyTo: "df_core/**"
---

# DF Core Instructions

> **Shared baseline:** c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md

## Repo-Specific Context

### Language & Framework

**Language:** Java 21  
**Primary Framework:** Spring Boot 3.2  
**Key Libraries:** PostgreSQL 15, ExaBGP gRPC, RxJava 3, Log4j2

### Repository Purpose

DefenseFlow Security Engine is the core decision-making component for line-rate 
BGP/OSPF route filtering and DDoS mitigation. Runs on active/standby architecture 
with automatic failover.

### Critical Modules

| Module | Location | Purpose |
|--------|----------|---------|
| BGP Engine | `bgp/src/main/java/` | BGP peer management |
| Policy Evaluator | `policy-engine/src/main/java/` | Real-time policy checks |
| HA Coordinator | `ha-orchestrator/src/main/java/` | Failover logic |

[... rest of template with df_core specifics ...]
```

### Example 2: React Frontend (like webui_components)

```markdown
---
description: "webui_components — Radware Web UI Component Library (React)"
applyTo: "webui_components/**"
---

# WebUI Components Instructions

> **Shared baseline:** c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md
> **React Conventions:** c:\rdwr-intelij\.copilot-shared\shared\instructions\react-conventions.instructions.md

## Repo-Specific Context

### Language & Framework

**Language:** TypeScript 5.2 (strict mode)  
**Framework:** React 19 with Hooks  
**State Management:** Redux Toolkit  
**Styling:** Tailwind CSS v4  
**Testing:** Vitest + React Testing Library

### Repository Purpose

Shared React component library for all Radware web applications. Includes:
- Policy editor components
- Dashboard widgets
- Configuration forms
- Real-time monitoring displays

### Critical Modules

| Module | Location | Purpose |
|--------|----------|---------|
| Policy Editor | `src/components/PolicyEditor/` | Drag-drop policy builder |
| Dashboard | `src/components/Dashboard/` | Real-time metrics |
| Form Components | `src/components/Forms/` | Reusable form fields |

### Known Patterns

#### Pattern 1: Component with Redux State

**Location:** `src/components/PolicyEditor/PolicyEditor.tsx`

```typescript
interface PolicyEditorProps {
  policyId: string;
}

export function PolicyEditor({ policyId }: PolicyEditorProps) {
  const dispatch = useDispatch();
  const policy = useSelector(selectPolicy(policyId));
  
  const handleSave = (updated: Policy) => {
    dispatch(updatePolicy(updated));  // Dispatches Redux action
  };
  
  return <div>{/* render */}</div>;
}
```

#### Pattern 2: Custom Hook for Async Data

```typescript
export function usePolicy(id: string) {
  const [policy, setPolicy] = useState<Policy | null>(null);
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    setLoading(true);
    fetchPolicy(id)
      .then(setPolicy)
      .finally(() => setLoading(false));
  }, [id]);
  
  return { policy, loading };
}
```

### Testing Strategy

**Unit Tests:** `src/**/*.test.tsx`
- Test component props, state changes
- Mock Redux store
- Target: 70%+ coverage

**Integration Tests:** `src/**/*.spec.tsx`
- Test component with real Redux
- Test user interactions
- Target: Critical paths only

### Build & Test Commands

```bash
# Install dependencies
npm install

# Development server
npm run dev

# Build production
npm run build

# Run tests
npm run test

# Check coverage
npm run test:coverage

# Lint & format
npm run lint
npm run format
```

[... rest of template ...]
```

### Example 3: Python Service

```markdown
---
description: "analytics_engine — Real-time Traffic Analysis (Python/FastAPI)"
applyTo: "analytics_engine/**"
---

# Analytics Engine Instructions

> **Shared baseline:** c:\rdwr-intelij\.copilot-shared\shared\instructions\00-core-instructions.md

## Repo-Specific Context

### Language & Framework

**Language:** Python 3.11+  
**Framework:** FastAPI 0.100+  
**ORM:** SQLAlchemy 2.0  
**Async:** AsyncIO + Uvicorn  
**Testing:** Pytest + Pytest-asyncio

### Repository Purpose

Real-time packet analysis and threat detection engine. Consumes traffic from 
DefenseFlow and produces security alerts and analytics.

### Build & Test Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Development server
uvicorn main:app --reload

# Run tests
pytest tests/

# Run with coverage
pytest --cov=src tests/

# Type checking
mypy src/

# Code quality
ruff check src/
```

[... rest of template ...]
```

---

## Deployment & Rollout

### Phase 1: Create Shared Space ✅ (Already done)

See `TOKEN_OPTIMIZATION_IMPLEMENTATION.md`

### Phase 2: Add Instructions to Each Repo (1-2 hours)

For each repo:

```bash
# 1. Create .github directory
mkdir -p <repo>/.github

# 2. Copy this template
cp /path/to/REPO_COPILOT_INSTRUCTIONS_TEMPLATE.md <repo>/.github/.copilot-instructions.md

# 3. Customize with repo-specific info
# Edit: Language, Framework, Modules, Patterns, Commands

# 4. Create symlink to shared instructions
cd <repo>/.github
ln -s ../../.copilot-shared/shared/instructions instructions-shared

# 5. Create memory file
cat > copilot-memory.md << 'EOF'
# [Repo Name] Copilot Memory

## Known Issues
[Add any discovered issues]

## Verified Commands
[Commands that reliably work]

## Code Patterns
[Patterns to follow]
EOF

# 6. Commit
git add .github/
git commit -m "add: Copilot instructions (linked to shared space)"
```

### Phase 3: Verify All Repos Work (30 min)

```bash
# For each repo:
# 1. Open in VS Code
# 2. Invoke an agent (@developer, @debugger, etc.)
# 3. Verify it can see shared instructions
# 4. Verify repo-specific instructions load
```

### Phase 4: Monitor & Maintain (ongoing)

See `MULTI_REPO_STRATEGY.md` → Maintenance Schedule

---

## Summary

**For each repo, just:**
1. Copy this template to `.github/.copilot-instructions.md`
2. Fill in repo-specific sections (Language, Framework, Modules, etc.)
3. Create `copilot-memory.md` for findings
4. Create symlink to shared instructions
5. Commit

**Result:**
- All 15+ repos share one set of instructions/skills/memory
- Each repo can customize without duplication
- 95% token savings across system
- Easy to update rules globally

See: `MULTI_REPO_STRATEGY.md` for full multi-repo architecture
