# Terminal Commands Reference — Cross-Repo Exploration

Since `run_in_terminal` is the only tool that works for sibling repos, use these shell commands for all operations. Substitute `<REPO>` with the actual repo name (e.g., `kvision_dp_inline_config`).

## List Directory Structure

```bash
# List repo root
ls "C:\rdwr-intelij\<REPO>"

# List Java package tree (directories only)
find "C:\rdwr-intelij\<REPO>\src\main\java" -type d

# List files in a specific package dir
ls "C:\rdwr-intelij\<REPO>\src\main\java\com\radware\...\service\policy"

# Limit output for large trees
find "C:\rdwr-intelij\<REPO>\src\main\java" -type d | head -30
```

## Read a Single File

```bash
# Read entire file
cat "C:\rdwr-intelij\<REPO>\src\main\java\com\radware\...\MyClass.java"

# Read with line numbers
cat -n "C:\rdwr-intelij\<REPO>\src\main\java\com\radware\...\MyClass.java"

# Read a specific line range (lines 50–100)
sed -n '50,100p' "C:\rdwr-intelij\<REPO>\src\main\java\com\radware\...\MyClass.java"

# Read only first / last N lines
head -80 "C:\rdwr-intelij\<REPO>\src\main\java\com\radware\...\MyClass.java"
tail -50 "C:\rdwr-intelij\<REPO>\src\main\java\com\radware\...\MyClass.java"
```

## Read Multiple Files in Parallel (Batched)

**Always batch file reads into a single terminal call** to avoid multiple round trips. Separate files with a clear delimiter so the output is easy to parse.

```bash
# Read 2–3 related files in one call
cat "C:\rdwr-intelij\<REPO>\src\...\ServiceA.java" && \
echo "===== ServiceB.java =====" && \
cat "C:\rdwr-intelij\<REPO>\src\...\ServiceB.java" && \
echo "===== ServiceC.java =====" && \
cat "C:\rdwr-intelij\<REPO>\src\...\ServiceC.java"

# Read all files in a directory at once
for f in "C:\rdwr-intelij\<REPO>\src\...\dto"/*.java; do
  echo "===== $f ====="; cat "$f"
done

# Read files matched by a pattern (e.g., all *Transaction*.java files)
find "C:\rdwr-intelij\<REPO>\src" -name "*Transaction*.java" | \
  xargs -I{} sh -c 'echo "===== {} ====="; cat "{}"'
```

> **Why batch?** `run_in_terminal` is the only cross-repo tool. Each tool call is a round trip. Reading 5 files in one call is 5× faster than 5 separate calls.

## Search for Code

```bash
# Find text in Java files (recursive, with line numbers)
grep -rn "someMethod" "C:\rdwr-intelij\<REPO>\src" --include="*.java"

# Find class/interface definitions
grep -rn "class MyClass\|interface MyInterface" "C:\rdwr-intelij\<REPO>\src" --include="*.java"

# Find files by name pattern
find "C:\rdwr-intelij\<REPO>\src" -name "*Transaction*.java"

# Find annotations (e.g., all @Service classes — list files only)
grep -rn "@Service" "C:\rdwr-intelij\<REPO>\src" --include="*.java" -l

# Find method signatures
grep -rn "public.*upload\|void.*upload" "C:\rdwr-intelij\<REPO>\src" --include="*.java"

# Context search (5 lines before/after match)
grep -rn -B5 -A5 "runDpCommands" "C:\rdwr-intelij\<REPO>\src" --include="*.java"

# Search + immediately read matching files (search-then-read in one call)
grep -rln "AdditionalPolicyData" "C:\rdwr-intelij\<REPO>\src" --include="*.java" | \
  xargs -I{} sh -c 'echo "===== {} ====="; cat "{}"'
```

## Check Config Files

```bash
# Find all config files
find "C:\rdwr-intelij\<REPO>\src\main\resources" -type f

# Read all config files at once
for f in "C:\rdwr-intelij\<REPO>\src\main\resources"/*.properties \
         "C:\rdwr-intelij\<REPO>\src\main\resources"/*.yml; do
  [ -f "$f" ] && echo "===== $f =====" && cat "$f"
done
```

## Build and Test

```bash
# Build (skip tests)
cd "C:\rdwr-intelij\<REPO>" && ./mvnw clean install -DskipTests

# Run tests
cd "C:\rdwr-intelij\<REPO>" && ./mvnw test

# Check current branch
cd "C:\rdwr-intelij\<REPO>" && git branch --show-current
```

## One-Shot Entry Point Detection

```bash
# Find all entry points in priority order (1 terminal call)
echo "=== Controllers ===" && \
grep -rln "@RestController\|@Path" "C:\rdwr-intelij\<REPO>\src" --include="*.java" && \
echo "=== DTOs ===" && \
grep -rln "class.*Dto\|class.*Request\|class.*Response" "C:\rdwr-intelij\<REPO>\src" --include="*.java" | head -15 && \
echo "=== PE Clients ===" && \
grep -rln "policy-editor\|PolicyEditor\|WebClient\|RestTemplate" "C:\rdwr-intelij\<REPO>\src" --include="*.java" && \
echo "=== Config ===" && \
grep -rn "policy.editor\|policy-editor" "C:\rdwr-intelij\<REPO>\src\main\resources" -r 2>/dev/null
```

## Question → Command Mapping

| Question | Command |
|----------|---------|
| What endpoint does X call on PE? | `grep -rn "policy-editor\|/rest/v2/policy" <REPO>/src --include="*.java"` |
| What DTO shape does X send to PE? | Find the client class first, then read its request builder |
| How does X authenticate with PE? | `grep -rn "Authorization\|Bearer\|token\|auth" <REPO>/src --include="*.java" -l` |
| What config connects X to PE? | `grep -rn "policy.editor\|policy-editor" <REPO>/src/main/resources -r` |
| Find controllers + DTOs (L1 scan) | `grep -rln "@RestController\|@Path\|class.*Dto" <REPO>/src --include="*.java" \| head -20` |
| Find service classes using PE (L2) | `grep -rln "policy-editor\|PolicyEditor\|po-template" <REPO>/src --include="*.java"` |

