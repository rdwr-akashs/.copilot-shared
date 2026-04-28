# Handling PR Review Comments Skill

Automates the entire workflow of analyzing Bitbucket PR comments, generating structured responses, and implementing code fixes.

## Quick Start

```
User: "Check PR #{NUMBER} comments and make fixes. Create .md for replies, don't post to Bitbucket."

AI: [Follows the skill workflow automatically]
    1. Fetches PR data and comments
    2. Analyzes each comment (critical/quality/design/no-action)
    3. Reads affected code files
    4. Generates PR-{N}-Review-Responses.md
    5. Implements all code fixes
    6. Creates summary documents
    7. Validates changes
```

## What This Skill Does

✅ **Fetches** PR metadata, comments, and diffstat from Bitbucket  
✅ **Categorizes** comments by severity (critical/quality/design/no-action)  
✅ **Analyzes** each issue technically (reads code, understands context)  
✅ **Generates** structured response document with technical justifications  
✅ **Implements** code fixes (critical first, then quality, then refactoring)  
✅ **Documents** all changes with before/after examples  
✅ **Validates** changes (checks for compilation errors)  
✅ **Creates** multiple output formats (full analysis, technical summary, quick reference)

## What It Doesn't Do

❌ Does NOT post responses to Bitbucket (user maintains control)  
❌ Does NOT blindly implement suggestions (evaluates technical merit)  
❌ Does NOT add performative language ("Great point!", "You're right!")  
❌ Does NOT skip design decision justifications

## When To Use

- You have a Bitbucket PR with review comments to address
- You want structured, technical responses without manual analysis
- You need code fixes implemented with proper categorization
- You want documentation of what was changed and why

## Workflow Overview

```
1. FETCH (15 min)
   └─> Get PR, comments, diffstat from Bitbucket

2. ANALYZE (20 min)
   └─> Read code, categorize by severity, identify real issues

3. RESPOND (10 min)
   └─> Generate structured markdown with technical justifications

4. IMPLEMENT (30 min)
   └─> Fix critical issues first, then quality, then refactoring

5. DOCUMENT (10 min)
   └─> Create summaries and quick-reference guides

6. VALIDATE (5 min)
   └─> Check compilation, verify no regressions

Total: ~90 minutes (saves 2+ hours of manual work)
```

## Output Files

1. **`PR-{N}-Review-Responses.md`**
   - Complete analysis of all comments
   - Technical responses with code locations
   - Design decision justifications
   - Summary statistics

2. **`PR-{N}-Changes-Summary.md`**
   - Detailed technical changes per file
   - Before/after code examples
   - Testing requirements
   - Pre-commit checklist

3. **`PR-{N}-Quick-Reference.md`**
   - Copy-paste responses for Bitbucket
   - Critical fixes summary
   - Quick decision rationales

## Example Usage

See [EXAMPLE.md](./EXAMPLE.md) for a complete walkthrough of handling a PR with multiple comments.

## Key Features

### Smart Categorization
- **Critical:** Race conditions, memory leaks, NPE, security
- **Quality:** RBAC, validation, logging, constants
- **Design:** Architectural decisions requiring justification
- **No Action:** Already handled, false positives, by-design

### Technical Responses
```markdown
❌ BAD: "Great point! I'll fix that."
✅ GOOD: "Valid - lock map grows unbounded. Fixed by removing locks in 
         finally blocks. Map now bounded to max 200 feeds."
```

### Prioritized Implementation
1. Critical fixes (safety, correctness)
2. Quality improvements (RBAC, logging, validation)
3. Refactoring (builder pattern, comments, formatting)

### Design Decision Justification
```markdown
**Comment:** "Use synchronized instead of ReentrantLock"

**Response:**
ReentrantLock provides explicit lock/unlock (better for complex 
try-finally), fair queuing (can add later), and interruptible 
acquisition. Overhead negligible. Keeping current implementation.

**No Change Required.**
```

## Common Fix Patterns

The skill recognizes and implements these patterns automatically:

- Extract hardcoded strings to constants
- Add RBAC annotations to endpoints
- Add logging to controllers
- Null safety checks
- Fix race conditions with proper lock ordering
- Memory leak prevention (cleanup in finally blocks)
- Transaction ordering (DB first, then files)
- Builder pattern for entities
- Remove unnecessary comments

See [SKILL.md](./SKILL.md) for complete pattern library.

## Integration with Other Skills

Works well with:
- **systematic-debugging** - For investigating complex issues
- **test-driven-development** - For adding tests after fixes
- **verification-before-completion** - For final validation
- **commit-push** - For committing changes after review

## Success Criteria

After running this skill, you should have:

✅ All PR comments analyzed and categorized  
✅ Critical safety issues fixed  
✅ Quality improvements implemented  
✅ Design decisions documented with technical reasoning  
✅ No compilation errors  
✅ Response documents ready for user to post to Bitbucket

## Tips for Best Results

1. **Provide PR URL or number** - More context = better analysis
2. **Let AI read the code** - Don't summarize issues manually
3. **Review generated responses** - Before posting to Bitbucket
4. **Run tests after** - Verify fixes work as expected
5. **Trust the categorization** - Critical issues are prioritized correctly

## Limitations

- Requires Bitbucket MCP server to be configured
- Cannot post comments directly (by design - user maintains control)
- Some complex refactoring may need human review
- Design decisions require user to validate justifications

## Contributing

To improve this skill:
1. Add new fix patterns to SKILL.md
2. Document edge cases in EXAMPLE.md
3. Update categorization rules as needed
4. Share examples of successful PR handling

---

**Version:** 1.0  
**Last Updated:** 2026-04-15  
**Author:** AI Assistant  
**Status:** Production Ready



