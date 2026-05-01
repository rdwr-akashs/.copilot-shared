# Terminal Commands Reference — Cross-Repo Exploration

Since `run_in_terminal` is the only tool that works for sibling repos, use these shell commands for all operations. Substitute `<REPO>` with the actual repo name (e.g., `<sibling-repo>`).

## List Directory Structure

```bash
# List repo root
ls "%COPILOT_WORKSPACE_ROOT%\<REPO>"

# List Java package tree (directories only)
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java" -type d

# List files in a specific package dir
ls "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\service\policy"

# Limit output for large trees
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java" -type d | head -30
```

## Read a Single File

```bash
# Read entire file
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\MyClass.java"

# Read with line numbers
cat -n "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\MyClass.java"

# Read a specific line range (lines 50–100)
sed -n '50,100p' "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\MyClass.java"

# Read only first / last N lines
head -80 "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\MyClass.java"
tail -50 "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\java\com\<org>\...\MyClass.java"
```

## Read Multiple Files in Parallel (Batched)

**Always batch file reads into a single terminal call** to avoid multiple round trips. Separate files with a clear delimiter so the output is easy to parse.

```bash
# Read 2–3 related files in one call
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\ServiceA.java" && \
echo "===== ServiceB.java =====" && \
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\ServiceB.java" && \
echo "===== ServiceC.java =====" && \
cat "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\ServiceC.java"

# Read all files in a directory at once
for f in "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\...\dto"/*.java; do
  echo "===== $f ====="; cat "$f"
done

# Read files matched by a pattern (e.g., all *Transaction*.java files)
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" -name "*Transaction*.java" | \
  xargs -I{} sh -c 'echo "===== {} ====="; cat "{}"'
```

> **Why batch?** `run_in_terminal` is the only cross-repo tool. Each tool call is a round trip. Reading 5 files in one call is 5× faster than 5 separate calls.

## Search for Code

```bash
# Find text in Java files (recursive, with line numbers)
grep -rn "someMethod" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java"

# Find class/interface definitions
grep -rn "class MyClass\|interface MyInterface" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java"

# Find files by name pattern
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" -name "*Transaction*.java"

# Find annotations (e.g., all @Service classes — list files only)
grep -rn "@Service" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" -l

# Find method signatures
grep -rn "public.*upload\|void.*upload" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java"

# Context search (5 lines before/after match)
grep -rn -B5 -A5 "runDpCommands" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java"

# Search + immediately read matching files (search-then-read in one call)
grep -rln "AdditionalPolicyData" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" | \
  xargs -I{} sh -c 'echo "===== {} ====="; cat "{}"'
```

## Check Config Files

```bash
# Find all config files
find "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\resources" -type f

# Read all config files at once
for f in "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\resources"/*.properties \
         "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\resources"/*.yml; do
  [ -f "$f" ] && echo "===== $f =====" && cat "$f"
done
```

## Build and Test

```bash
# Build (skip tests)
cd "%COPILOT_WORKSPACE_ROOT%\<REPO>" && ./mvnw clean install -DskipTests

# Run tests
cd "%COPILOT_WORKSPACE_ROOT%\<REPO>" && ./mvnw test

# Check current branch
cd "%COPILOT_WORKSPACE_ROOT%\<REPO>" && git branch --show-current
```

## One-Shot Entry Point Detection

```bash
# Find all entry points in priority order (1 terminal call)
echo "=== Controllers ===" && \
grep -rln "@RestController\|@Path" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" && \
echo "=== DTOs ===" && \
grep -rln "class.*Dto\|class.*Request\|class.*Response" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" | head -15 && \
echo "=== this project Clients ===" && \
grep -rln "<domain-keyword>\|WebClient\|RestTemplate" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src" --include="*.java" && \
echo "=== Config ===" && \
grep -rn "<api-keyword-1>\|<api-keyword-2>" "%COPILOT_WORKSPACE_ROOT%\<REPO>\src\main\resources" -r 2>/dev/null
```

## Question → Command Mapping

| Question | Command |
|----------|---------|
| What endpoint does X call on this project? | `grep -rn "<api-keyword>\|<api-base-path>" <REPO>/src --include="*.java"` |
| What DTO shape does X send to this project? | Find the client class first, then read its request builder |
| How does X authenticate with this project? | `grep -rn "Authorization\|Bearer\|token\|auth" <REPO>/src --include="*.java" -l` |
| What config connects X to this project? | `grep -rn "<api-keyword-1>\|<api-keyword-2>" <REPO>/src/main/resources -r` |
| Find controllers + DTOs (L1 scan) | `grep -rln "@RestController\|@Path\|class.*Dto" <REPO>/src --include="*.java" \| head -20` |
| Find service classes calling this project (L2) | `grep -rln "<domain-keyword-1>\|<domain-keyword-2>" <REPO>/src --include="*.java"` |

