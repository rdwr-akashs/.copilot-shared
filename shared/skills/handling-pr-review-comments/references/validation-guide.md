# Validation, Testing & Common Pitfalls — PR Review Comments

## Validation Checklist

Before finalizing:

```
✓ Every comment has a response (even if "No change")
✓ Critical issues have code fixes
✓ Responses cite code locations
✓ Design decisions have technical justification
✓ No performative language
✓ All code changes are documented
✓ Summary statistics are accurate
```

## Testing Strategy

After implementing fixes:

```bash
# 1. Check for compile errors
get_errors(filePaths: [modified_files])

# 2. Run affected module tests
./mvnw -pl {module} test

# 3. Run full build (skip tests for speed)
./mvnw clean install -DskipTests

# 4. Run formatter (if required)
./mvnw spotless:apply
```

## Common Pitfalls

### Pitfall 1: Implementing Without Understanding
```
❌ Comment says "add validation"
   You add validation without checking if it exists elsewhere

✓ grep_search for existing validation first
  Check if validation is in service layer vs. controller
  Only add if truly missing
```

### Pitfall 2: Missing Context
```
❌ Comment says "use private"
   You make field private
   Build breaks because service layer uses it

✓ Check usage with semantic_search or grep_search
  Verify visibility requirements
  Push back if comment is wrong
```

### Pitfall 3: Over-Responding
```
❌ Write 3 paragraphs explaining why you agree

✓ "Fixed." or "Good catch - {issue}. Fixed in {location}."
  Let code speak for itself
```

### Pitfall 4: Blind Implementation
```
❌ Reviewer says "use synchronized instead of ReentrantLock"
   You change it without evaluating

✓ Evaluate technical trade-offs
  Check project patterns
  Push back with reasoning if current is better
```

