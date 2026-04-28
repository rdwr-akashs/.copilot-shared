# Example: Handling PR Review Comments

This example demonstrates the complete workflow for the `handling-pr-review-comments` skill using a real-world scenario.

## User Request

```
Check PR #{NUMBER} comments and generate review responses. 
Make code changes for actual issues. 
Create a .md file for replies - don't reply in Bitbucket.
```

---

## Step-by-Step Execution

### Step 1: Fetch PR Data

```javascript
// Get PR metadata
mcp_bitbucket-mcp_get_pull_request({
    pr_id: {NUMBER},
    repo_slug: "{REPO_NAME}"
})

// Get all comments
mcp_bitbucket-mcp_list_pr_comments({
    pr_id: {NUMBER},
    repo_slug: "{REPO_NAME}"
})

// Get diffstat for context
mcp_bitbucket-mcp_get_pull_request_diffstat({
    pr_id: {NUMBER},
    repo_slug: "{REPO_NAME}"
})
```

**Output:** {N} comments found across {M} files

---

### Step 2: Analyze Comments

Comments categorized:

**Critical Issues ({N}):**
1. Memory leak - resource not cleaned up
2. Race condition - lock acquired too late
3. NPE risk - null check missing
4. Data corruption - wrong operation order

**Quality Issues ({N}):**
5. Missing RBAC on endpoints
6. Hardcoded string literals
7. Missing logging
8. Unnecessary comments
9. Wrong error message wording
10. Code smell - long method
11. Validation inconsistency
12. Anti-pattern usage
13. Code formatting needed

**Design Decisions ({N}):**
14. Validation location (already exists elsewhere)
15. Service layer returns framework type (architectural)
16. Field visibility (must be public for external use)
17. Method naming (current is more descriptive)
18. Lock implementation choice (better for use case)

**No Action Required ({N}):**
19. "Do we need this API?" - Yes, per spec
20. Already handled in different layer
21. False positive from reviewer misunderstanding
22. Intentional design per architecture

---

### Step 3: Read Affected Code

```bash
read_file("service/src/main/java/.../ServiceImpl.java")
read_file("service/src/main/java/.../RestController.java")
read_file("service/src/main/java/.../Validator.java")
read_file("service/src/main/java/.../Entity.java")
read_file("service/src/main/java/.../DTO.java")
read_file("util/src/main/java/.../Utility.java")
```

---

### Step 4: Generate Response Document

```markdown
# PR #{NUMBER} Review Responses

## Summary
- {N} total comments
- {N} code changes required
- {N} design decisions explained
- {N} no action needed

## Detailed Responses

### 1. Memory Leak (#{COMMENT_ID})
**Comment:** "Resource not cleaned up, potential memory leak"

**Response:**
Valid - resource map grows unbounded. Fixed by removing entries in finally 
blocks of create() (success/failure) and delete(). 
Map now bounded to active resource count (max {LIMIT}).

**Code Change:** Added cleanup in finally blocks.

### 2. Race Condition (#{COMMENT_ID})
**Comment:** "Lock acquired too late, race condition possible..."

**Response:**
Excellent catch. Lock must be before existence check.

**Code Change:** Moved lock acquisition to before existence check.

{...continues for all comments...}
```

Created: `PR-{NUMBER}-Review-Responses.md`

---

### Step 5: Implement Code Fixes

#### Critical Fixes

**Fix 1: Race Condition**
```java
// ServiceImpl.java
// BEFORE:
if (repository.existsByName(name)) {
    throw new ConflictException(...);
}
Lock lock = getLock(name);
lock.lock();

// AFTER:
Lock lock = getLock(name);
lock.lock();
try {
    if (repository.existsByName(name)) {
        throw new ConflictException(...);
    }
    // ... create logic ...
} finally {
    lock.unlock();
    locks.remove(name);  // Clean up to prevent memory leak
}
```

**Fix 2: NPE Protection**
```java
// RestController.java
// BEFORE:
DTO created = service.create(
    name, stream, fileName, creator, 
    parseData(formPart.getValue()));

// AFTER:
DataNode data = formPart != null 
    ? parseData(formPart.getValue()) 
    : null;
DTO created = service.create(
    name, stream, fileName, creator, data);
```

**Fix 3: Resource Cleanup Order**
```java
// ServiceImpl.java
// BEFORE:
try {
    fileProcessor.deleteFile(fileName);  // File first
    repository.delete(entity);  // DB second
}

// AFTER:
try {
    repository.delete(entity);  // DB first (transactional)
    logger.info("Deleted resource from DB: name='{}'", name);
    
    try {
        fileProcessor.deleteFile(fileName);  // File second (best effort)
        logger.info("Deleted file: {}", fileName);
    } catch (IOException e) {
        logger.error("Failed to delete file '{}' - orphaned file: {}", 
                fileName, e.getMessage());
    }
}
```

#### Quality Improvements

**Add RBAC:**
```java
@GET
@Produces(MediaType.APPLICATION_JSON)
@RolesAllowed({
    Role.SYSTEM_USER, Role.SYS_ADMIN, Role.SEC_ADMIN,
    Role.USR_ADMIN, Role.DEV_ADMIN, Role.DEVICE_OPERATOR
})
public Response getAllResources() {
```

**Extract Constants:**
```java
private static final String DEFAULT_FILE_NAME = "unknown.txt";
private static final String DEFAULT_NAME = "UntitledResource";
private static final String MODE_REPLACE = "replace";
private static final String MODE_APPEND = "append";
```

**Add Logging:**
```java
private static final Logger logger = LoggerFactory.getLogger(RestController.class);

public Response createResource(...) {
    logger.info("POST /resources - Creating new resource");
    // ...
}
```

**Use Builder Pattern:**
```java
// Add to entity:
@Builder
@NoArgsConstructor
@AllArgsConstructor

// Use in service:
Entity entity = Entity.builder()
    .name(name)
    .creator(creator)
    .count(count.get())
    .hash(fileHash)
    .createdTime(now)
    .updateTime(now)
    .metadata(JsonUtils.toJsonString(metadata))
    .build();
```

---

### Step 6: Create Summary Documents

**Created Files:**
1. `PR-{NUMBER}-Review-Responses.md` - Full analysis (~300 lines)
2. `PR-{NUMBER}-Changes-Summary.md` - Technical details (~200 lines)
3. `PR-{NUMBER}-Quick-Reference.md` - Copy-paste responses (~80 lines)

---

### Step 7: Validate

```bash
# Check for errors
get_errors(filePaths: [
    "service/src/main/java/.../RestController.java",
    "service/src/main/java/.../ServiceImpl.java",
    "service/src/main/java/.../Validator.java",
    "service/src/main/java/.../Entity.java"
])

# Result: Minor warnings only (unused imports, false positives)
```

---

## Final Output

### Statistics
- **Files Modified:** {N}
- **Critical Fixes:** {N}
- **Quality Improvements:** {N}
- **Lines Changed:** ~{N}
- **Time Saved:** ~{N} hours of manual analysis and implementation

### Deliverables
✅ PR-{NUMBER}-Review-Responses.md (complete analysis)
✅ PR-{NUMBER}-Changes-Summary.md (technical documentation)
✅ PR-{NUMBER}-Quick-Reference.md (copy-paste responses)
✅ All code changes implemented and verified
✅ No compilation errors
✅ Ready for user to post responses to Bitbucket

---

## User Next Steps

1. Review the generated response documents
2. Copy responses from `PR-{NUMBER}-Quick-Reference.md`
3. Post to Bitbucket PR comments manually
4. Run tests: `./mvnw test`
5. Run formatter: `./mvnw spotless:apply`
6. Push changes and request re-review

---

## Key Takeaways

**What Made This Effective:**

1. ✅ **Comprehensive Analysis** - Read actual code, not just comments
2. ✅ **Categorization** - Separated critical from quality from design decisions
3. ✅ **Technical Responses** - No fluff, just facts and reasoning
4. ✅ **Prioritized Fixes** - Critical safety issues first
5. ✅ **Verified Changes** - Checked for compilation errors
6. ✅ **Documentation** - Multiple formats for different needs

**Common Mistakes Avoided:**

1. ❌ Didn't implement without understanding
2. ❌ Didn't agree without technical analysis
3. ❌ Didn't add performative language
4. ❌ Didn't post directly to Bitbucket (user controls communication)
5. ❌ Didn't skip design decision justifications

---

## Time Breakdown

- **Fetch & Analyze:** ~15 min
- **Read Code:** ~20 min  
- **Generate Responses:** ~10 min
- **Implement Fixes:** ~30 min
- **Create Summaries:** ~10 min
- **Validate:** ~5 min

**Total:** ~90 minutes (vs. 3+ hours manual)











