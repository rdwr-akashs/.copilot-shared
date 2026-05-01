# Bug Report

Use this prompt when investigating a bug. It triggers the `debugger` agent and the `systematic-debugging` skill with a pre-filled context template.

---

## Fill in the blanks, then send to Copilot

```
@debugger

## Bug: <Short Description>

### Symptom
<Exact error message, UI state, or CLI output the user/customer reported.>

### Reproduction Steps
1. <Step 1>
2. <Step 2>
3. <Observed result>
4. <Expected result>

### Environment
- Product version: <e.g., DefenseFlow 4.7.2 build 12, Vision 4.85.60>
- Node roles: Active=<IP>, Standby=<IP>
- HA mode: <Active/Standby | Standalone>
- Topology: <brief description>

### Component (best guess)
<!-- Mark one or more -->
- [ ] REST API / Controller
- [ ] Service / Business logic
- [ ] Akka Actor
- [ ] RabbitMQ Consumer/Producer
- [ ] Elasticsearch query
- [ ] PostgreSQL / Repository
- [ ] HA / Replication
- [ ] React UI
- [ ] External integration

### Log Evidence (if available)
```
<Paste relevant log lines here>
```

### Support Bundle Path (for customer cases)
<path-to-your-support-bundle>\<case-id>\

### Jira Ticket
<INC-XXXX | SC-XXXX | DE-XXXX | RSEG-XXXX>
```

---

## What the agent will do

1. Reproduce the symptom with a failing test (write test before fix)
2. Narrow the component using logs and code search
3. Find the root cause — trace through call stack, actor hierarchy, or query path
4. Propose the minimal fix
5. Run tests and confirm the fix doesn't break other functionality

---

## For Customer Cases

If this is a customer escalation (SC-*, RSEG-*, INC-*):

```
@case-investigator

Case: <SC-XXXX>
Support bundle: <path>
Symptom: <one-line description>
```

The `case-investigator` agent follows the full `customer-case-rca` workflow and produces an RCA document.
