---
name: elasticsearch-debug
description: Use when Elasticsearch queries return wrong results, no results, slow response, or when the index has mapping conflicts or health issues. Structured diagnostic workflow.
---

# Elasticsearch Debug

## Activation Rule

**Triggers:**
- ES query returns 0 hits when results are expected (or vice versa)
- Query is taking > 500ms
- Index health is RED or YELLOW
- Mapping conflict exception in logs
- Aggregation counts are wrong
- "search [X] doesn't work", "ES query broken", "index not found"

> **Override Directive:** Don't patch the Java query code before running diagnostics on ES directly. Always reproduce in ES first, then trace back to the Java client.

## Step 0: Check Memory First

Before any diagnostics, grep the shared memory for known ES patterns in this repo:

```bash
grep -i "elasticsearch\|<repo-name>\|<symptom keyword>" .github/../../../.copilot-shared/shared/memory/tech-discoveries.md
grep -i "<symptom keyword>" .github/../../../.copilot-shared/shared/memory/known-bugs.md
```

If a matching pattern exists: **go directly to the documented fix.** Skip Steps 1-6.

If no match: run the diagnostic steps below, then use `save-learning` skill to append the finding.

## Diagnostic Checklist

```
[ ] 1. Reproduce the query directly in ES (curl or Kibana)
[ ] 2. Check index exists and has documents
[ ] 3. Inspect the mapping for the queried fields
[ ] 4. Analyze how the search term is tokenized
[ ] 5. Run _explain to see why a document did/didn't match
[ ] 6. Profile the query for timing breakdown
[ ] 7. Trace to Java client code — verify the query built matches the ES query
```

## Step-by-Step Diagnostics

### Step 1: Verify the index and document count

```bash
# Index exists?
curl "localhost:9200/_cat/indices?v&h=index,health,docs.count,store.size" | grep <index-name>

# Count documents
curl "localhost:9200/<index>/_count"

# Sample documents
curl "localhost:9200/<index>/_search?size=3&pretty"
```

### Step 2: Check the mapping

```bash
curl "localhost:9200/<index>/_mapping?pretty"
```

**What to look for:**
- Field type: `text` (analyzed, full-text) vs `keyword` (exact match)
- Field has `index: false` → cannot be searched
- Nested object vs flat field
- Date format mismatch

### Step 3: Analyze how your search term is tokenized

```bash
# How does ES tokenize your search term against the field's analyzer?
curl -X POST "localhost:9200/<index>/_analyze?pretty" \
  -H 'Content-Type: application/json' \
  -d '{"field": "<field-name>", "text": "<your-search-term>"}'

# Compare with how the stored value is tokenized
curl -X POST "localhost:9200/_analyze?pretty" \
  -H 'Content-Type: application/json' \
  -d '{"analyzer": "standard", "text": "<stored-value>"}'
```

**Common mismatch:** Searching `PolicyName` with `match` on a `keyword` field → no hits (keyword is case-sensitive, exact). Fix: use `term` query or add a `text` field with `fields` mapping.

### Step 4: Run _explain on a specific document

```bash
curl -X GET "localhost:9200/<index>/_explain/<doc-id>?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": {"name": "my search term"}
    }
  }'
```

Output tells you exactly why the document matched or didn't match.

### Step 5: Profile the slow query

```bash
curl -X POST "localhost:9200/<index>/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "profile": true,
    "query": { ... your query ... }
  }'
```

Check `profile.shards[].searches[].query[].time_in_nanos` — the slow phase is the one to optimize.

### Step 6: Trace to Java client

Find where the query is built in the codebase:

```bash
# Find ES query builders
grep -rn "QueryBuilders\|NativeSearchQuery\|SearchRequest" src/ --include="*.java" -l

# Find the repository / search method
grep -rn "<domain-keyword>.*search\|search.*<domain-keyword>" src/ --include="*.java"
```

Print the actual JSON query being sent (add temporarily):
```java
log.debug("ES query: {}", searchRequest.source().toString());
```

Compare with the query that worked in Step 4.

---

## Common Problems & Fixes

| Symptom | Root Cause | Fix |
|---|---|---|
| `match` query returns 0 hits on a name field | Field is `keyword` (not analyzed) | Use `term` query or add `text` with `fields.keyword` |
| Case-sensitive mismatch | `keyword` field, different case | Normalize at index time or use `normalizer: lowercase` |
| Partial match not working | Using `term` instead of `match` | Switch to `match` or `wildcard` (careful of performance) |
| Aggregation on a `text` field fails | `text` fields don't support aggregations by default | Add `fielddata: true` (memory-heavy) or add a `keyword` sub-field |
| Wrong hit count | Query in `must` context (scored) instead of `filter` (exact) | Wrap stable conditions in `bool.filter` |
| Stale data in index | Refresh interval hasn't elapsed | `POST /<index>/_refresh` (don't do this in prod regularly) |
| Mapping conflict on index | Alias spans indices with different mappings | Reindex with unified mapping, update alias |

---

## Mapping Conflict Recovery

```bash
# 1. Get current mapping
curl "localhost:9200/<old-index>/_mapping?pretty" > old-mapping.json

# 2. Create new index with fixed mapping
curl -X PUT "localhost:9200/<new-index>" -H 'Content-Type: application/json' -d @new-mapping.json

# 3. Reindex data
curl -X POST "localhost:9200/_reindex" -H 'Content-Type: application/json' -d '{
  "source": {"index": "<old-index>"},
  "dest": {"index": "<new-index>"}
}'

# 4. Switch alias (atomic)
curl -X POST "localhost:9200/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [
    {"remove": {"index": "<old-index>", "alias": "<alias>"}},
    {"add": {"index": "<new-index>", "alias": "<alias>"}}
  ]
}'
```

---

## Index Health Recovery

```bash
# Diagnose unassigned shards
curl "localhost:9200/_cluster/allocation/explain?pretty"

# Force retry of unassigned shards
curl -X POST "localhost:9200/_cluster/reroute?retry_failed=true"

# Check disk watermark (common cause of red)
curl "localhost:9200/_cluster/settings?pretty" | grep watermark
```
