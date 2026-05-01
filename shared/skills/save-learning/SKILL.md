---
name: save-learning
description: "Run at the end of any investigation, bug fix, customer case, or tech discovery. Extracts the pattern and appends it to the right shared memory file so the next session doesn't start from zero."
---

# Save Learning

## Activation Rule

**Triggers:**
- End of any customer case investigation (SC-*, RSEG-*, INC-*)
- A bug is root-caused and fixed
- A new tech pattern is discovered in a repo (ES index structure, Akka config, RabbitMQ topology)
- User says "save this", "remember this pattern", "add to memory"

> **Override Directive:** This skill runs AFTER a task completes, not before. It extracts and stores — it doesn't investigate.

---

## Step 1: Classify What You Learned

Pick the target file based on what was found:

| Type of learning | Target file |
|---|---|
| Customer case: symptom → root cause → fix | `shared/memory/customer-cases.md` |
| Known bug: ID, symptom, version, workaround | `shared/memory/known-bugs.md` |
| Repo tech structure: ES index, RabbitMQ queue, Akka hierarchy, DB schema | `shared/memory/tech-discoveries.md` |
| Build/test commands discovered for a repo | `shared/memory/tech-discoveries.md` (Build & Test Commands table) |

If the learning spans multiple types, append to each relevant file.

---

## Step 2: Extract the Pattern

Ask these questions about what was just investigated:

**For customer cases:**
```
- What were the symptom keywords? (the words that would trigger a grep match)
- What was the root cause in one sentence?
- What was the immediate fix (what the customer ran)?
- What is the long-term code fix?
- Which DF/Vision versions were affected?
- What case IDs were involved?
```

**For bugs:**
```
- What is the Bug ID (DE-XXXX, VISION-XXXX, or "untracked")?
- What is the symptom in one sentence?
- What exact log pattern proves this bug is present?
- Which versions are affected and which version fixed it?
- What is the workaround?
```

**For tech discoveries:**
```
- Which repo? (verify exact name against Repo Registry in shared/memory/tech-discoveries.md)
- Which technology (ES, RabbitMQ, Akka, PG, Build)?
- What is the key structural fact (index name, queue config, actor root, table)?
- When was this verified?
```

If the repo is not yet in the Repo Registry, add it to the appropriate category table in `tech-discoveries.md` before appending the tech detail row.

---

## Step 3: Append to Memory

**Always append — never overwrite.** Add a new row to the relevant table section.

**Update the staleness marker** — after appending, update the file header timestamp:
```markdown
# <File Title>
<!-- Last updated: YYYY-MM-DD -->
```
If no `Last updated` line exists, add one after the `#` title line. This lets agents warn when memory is stale (>90 days).

### Appending to customer-cases.md

Add a row to the `## Case Patterns` table:
```markdown
| CP-NNN | <symptom keywords> | <root cause one sentence> | <immediate fix> | <long-term fix> | <versions> | <case IDs> |
```

Increment `CP-NNN` from the last entry. If the symptom already has a row (same root cause), add the new case ID to the existing row's `Case IDs` column instead of creating a duplicate.

### Appending to known-bugs.md

Add a row to the `## Bug Table`:
```markdown
| <Bug ID> | <symptom> | <log evidence pattern> | <affected versions> | <fixed in> | <workaround> |
```

If the bug already exists, update its `Fixed In` or `Workaround` columns if new information is available.

### Appending to tech-discoveries.md

Add a row to the relevant technology table. Add a new table/section if the technology doesn't have one yet.

---

## Step 4: Update repo-cache.md (if applicable)

If the task was performed on a specific repo, append one line to `.github/repo-cache.md` in that repo under `## Recent Context`:

```markdown
## Recent Context
YYYY-MM-DD: <one-line task summary and outcome>
```

Keep only the last 10 entries under Recent Context (delete oldest if over 10).

---

## Hard Rules

- **No customer names, IPs, or credentials** in any memory file — patterns only
- **One row per distinct root cause** — don't duplicate; update instead
- **Evidence pattern must be greppable** — the log pattern should be something another developer can grep for immediately
- **Immediate fix must be runnable** — CLI commands or config changes the customer can execute today
- **Long-term fix must reference a code location** — file path + method name if known
