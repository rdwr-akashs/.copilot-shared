# Incident Postmortem

Structured post-incident analysis template. Produces a blameless postmortem document backed by log evidence and a concrete action plan.

---

## Send this to Copilot Chat

```
@developer

## Incident Postmortem

### Incident Details
- **ID**: <JIRA-ID or INC number>
- **Date/Time**: <YYYY-MM-DD HH:mm UTC>
- **Duration**: <time to resolve>
- **Severity**: <P1 / P2 / P3>
- **Impact**: <what was affected, how many users/customers>

### Timeline
<!-- Fill in key events -->
| Time (UTC) | Event |
|------------|-------|
|            | First alert / customer report |
|            | Investigation started |
|            | Root cause identified |
|            | Fix deployed |
|            | Service confirmed healthy |

### What to produce

1. **Root Cause Analysis**
   - What failed (with exact log lines if support files are attached)
   - Why the failure wasn't prevented or caught earlier
   - Contributing factors (recent deployments, config changes, load)

2. **5 Whys**
   - Drill from symptom to root cause

3. **What went well**
   - Things that helped during the incident

4. **What went poorly**
   - Things that slowed diagnosis or recovery

5. **Action Items**
   | # | Action | Owner | Priority | DE/Story | Status |
   |---|--------|-------|----------|----------|--------|

6. **Lessons Learned**
   - Save key findings to `shared/memory/known-bugs.md` or `tech-discoveries.md`
   - Update runbooks if applicable

### Output

A complete postmortem document at `.agent_work/<incident-id>/postmortem.md`
```

---

## When to use

- After any P1 or P2 incident
- After a customer escalation that reveals a product gap
- Pairs well with the `customer-case-rca` instruction for DefenseFlow/Vision cases
