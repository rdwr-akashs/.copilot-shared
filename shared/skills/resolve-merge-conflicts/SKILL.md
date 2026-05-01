---
name: resolve-merge-conflicts
description: "Use when a branch has merge conflicts after a rebase or merge. Resolves each conflict by understanding the intent of both sides before choosing a resolution."
---

# Resolve Merge Conflicts

## Activation Rule

**Triggers:**
- User says "resolve conflicts", "fix merge conflicts", "I have conflicts after rebase"
- `git status` shows `both modified:` files
- Files contain `<<<<<<`, `=======`, `>>>>>>>` markers
- A rebase or merge was interrupted with conflict errors

> **Override Directive:** Never blindly pick one side. Always read both sides and understand the intent before resolving. When in doubt, ask.

---

## Step 1: Get the Full Picture

```bash
# See all conflicting files
git status --short | grep '^UU\|^AA\|^DD\|^AU\|^UA\|^DU\|^UD'

# Or simply:
git diff --name-only --diff-filter=U

# How many conflicts total?
git diff --name-only --diff-filter=U | wc -l
```

Read the merge/rebase context before touching a single file:
```bash
# What branch is being merged/rebased?
git log --oneline HEAD...MERGE_HEAD 2>/dev/null || git log --oneline HEAD~5

# What commit introduced the conflict on the incoming side?
git log --oneline MERGE_HEAD 2>/dev/null | head -5
```

---

## Step 2: Categorise Each Conflict

For EACH conflicted file, identify which category it falls into before resolving:

| Category | Signs | Resolution strategy |
|---|---|---|
| **Parallel independent changes** | Both sides touch different lines near each other | Keep both — merge manually |
| **Same line, different intent** | Both sides change the same logic differently | Understand which change is correct for the feature goal |
| **One side deleted, other modified** | `deleted by us/them` in git status | Decide if deletion or modification is the right outcome |
| **Conflict is just formatting/import order** | Only whitespace/import diffs | Take the incoming side's ordering, keep your logic |
| **Generated file conflict** | `pom.xml` dependency versions, lock files | Usually take the higher version; never guess |
| **Structural rename + modification** | File moved on one side, changed on the other | `git log --follow <file>` to trace history |

---

## Step 3: Resolve Each File

For each file:

### 3a. Read Both Sides in Context

```bash
# Show the conflict with surrounding context
grep -n -A 5 -B 5 '<<<<<<<' <file>
```

The conflict markers mean:
```
<<<<<<< HEAD (or ours)       <- your current branch's version
... your changes ...
=======
... incoming changes ...
>>>>>>> feature-branch (or theirs)   <- the branch being merged in
```

### 3b. Apply the Resolution

Choose the correct approach:

**Keep ours only:**
```bash
git checkout --ours <file>
git add <file>
```

**Keep theirs only:**
```bash
git checkout --theirs <file>
git add <file>
```

**Keep both (manual merge):**
Edit the file directly — remove ALL three marker lines (`<<<<<<<`, `=======`, `>>>>>>>`), leaving the correct combined content. Then:
```bash
git add <file>
```

**Verify no markers remain:**
```bash
grep -rn '<<<<<<<\|=======\|>>>>>>>' <file>
# Must return nothing before staging
```

---

## Step 4: Conflict-Type Playbook

### Java source files
1. Check if both sides add to the same method or add different methods.
2. If both sides modify the same method body — understand each change's purpose. Combine if compatible; pick the more complete version if they overlap.
3. Imports: keep all unique imports from both sides, sorted.
4. Never resolve a Java conflict without compiling: `./mvnw -pl <module> -am clean install -DskipTests`

### `pom.xml` (Maven)
1. Dependency version conflicts: always take the **higher** version unless a specific version is pinned for a reason — check the commit message.
2. New `<dependency>` blocks added on both sides: keep both.
3. `<parent>` version conflict: take the newer version.
4. Plugin configuration conflicts: read both sides carefully — don't discard configuration.
5. After resolving: `./mvnw validate` to check well-formedness.

### `package.json` / `package-lock.json`
1. `package.json` conflicts: keep all `dependencies`/`devDependencies` from both sides; take the higher version when the same package differs.
2. `package-lock.json`: **delete and regenerate** — never manually resolve a lock file.
   ```bash
   rm package-lock.json
   npm install
   git add package-lock.json
   ```

### `*.yaml` / `*.yml` (config, CI)
1. YAML is indentation-sensitive — verify indentation is correct after merging.
2. For CI pipeline files: keep all steps from both sides unless they're genuinely duplicates.
3. Validate after resolving: `python -c "import yaml; yaml.safe_load(open('<file>'))"` or equivalent.

### SQL migration files (`*.sql`, Flyway, Liquibase)
1. **Never modify an existing migration that has already run** — instead, keep both migrations and ensure version numbers don't collide.
2. If both sides added a migration with the same version number, one must be renumbered.
3. Check with the author before renumbering.

### FreeMarker templates (`.ftl`) / other templates
1. Resolve as plain text, keep intent of both sides.
2. Validate by running the build: templates are compiled at build time.

---

## Step 5: Build and Test After All Conflicts Resolved

```bash
# No unresolved conflicts remain
git diff --name-only --diff-filter=U
# (must be empty)

# Full build
./mvnw clean install -DskipTests

# Run tests
./mvnw -pl <affected-module> test

# For frontend conflicts
cd <ui-dir> && npm install && npm test
```

---

## Step 6: Complete the Merge or Rebase

```bash
# If mid-merge:
git merge --continue

# If mid-rebase:
git rebase --continue

# If mid-cherry-pick:
git cherry-pick --continue
```

If the build fails after continuing, do NOT `--skip` or `--abort` without understanding why. Re-run the systematic-debugging skill.

---

## Common Mistakes to Avoid

| Mistake | Why it's wrong | What to do instead |
|---|---|---|
| Picking one side without reading the other | Silently discards valid work | Always read both sides |
| Leaving conflict markers in the file | Will cause compile or runtime errors | Always grep for markers after resolving |
| Resolving `package-lock.json` manually | Lock files are generated — manual edits corrupt them | Delete and `npm install` |
| Resolving without building | Conflicts can be syntactically valid but semantically broken | Always build after resolving |
| Using `git checkout --ours` on every file | Discards all incoming changes | Only use when you've confirmed their changes are genuinely not needed |
| Skipping tests because "it's just a merge" | Merges introduce integration bugs | Always run tests |

---

## Output Format

After resolving, report:

```
## Merge Conflict Resolution

**Files resolved:** N
**Strategy used per file:**
- `<file>`: kept both sides — [one-line explanation]
- `<file>`: kept ours — [one-line explanation]
- `<file>`: kept theirs — [one-line explanation]

**Build result:** [PASS / FAIL + error summary]
**Tests run:** [module(s) tested, pass/fail count]
**Remaining issues:** [none | list]
```
