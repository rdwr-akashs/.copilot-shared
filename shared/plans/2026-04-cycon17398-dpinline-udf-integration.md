# CYCON-17398: dpInline UDF Integration Plan

**Status**: In Progress (Phases 2–6 complete, Phase 7 blocked, Phase 8 pending)  
**Created**: 2026-04-28  
**Updated**: 2026-04-29  
**Source**: PE plan v4.2 (`common_policy_editor/memory-bank/udf-shared-template-plan-v4.md`)  
**Repo**: `kvision_dp_inline_config`  
**Depends on**: PE side complete — UDF CRUD, FTL generation, `/for-dp` response with `feedFileName` + `fileHash`, backup export/import all done.

---

## TL;DR

dpInline needs to: (1) receive UDF feed data from PE's `/for-dp` response, (2) upload the feed file to DefensePro via Config Service, (3) track which feeds are uploaded to which devices, (4) clean up feeds when the last policy referencing them is deleted.

## Context: What PE Already Provides

PE's `/for-dp` endpoint returns a DTO that now includes:
```json
{
  "policyText": "...",
  "additionalPolicyData": {
    "userDefinedFeed": {
      "feedFileName": "my-feed",
      "fileHash": "sha256hex..."
    }
  }
}
```

The `policyText` (CLI text) already contains inline UDF profile commands:
```
dp user-defined-feed profiles table create "my-feed" -ra drop
dp user-defined-feed profiles ip-allowlist create "my-feed" "10.0.0.1" "32"
```

And the policy create command includes `-udf "my-feed"`.

The feed file lives on a **shared volume** at: `accesslists/userdefinedfeeds/{name}` (same pattern as DNS allow list at `accesslists/dnsallowlists/{name}`).

---

## Architecture

```
PE /for-dp response
  → dpInline calls getForDpResponse() which returns ForDpResponseDto
  → dpInline parses feedFileName + fileHash from additionalPolicyData.userDefinedFeed
  → policyText already contains inline UDF CLI (table create + ip-allowlist + -udf ref)
  → populateUdfFeedData() sets UdfFeedDto on ManagedPolicyDto

On policy ADD/UPDATE:
  → dpInline imports policyText to DP (existing flow — CLI includes UDF profile)
  → dpInline calls uploadUdfFeed() which delegates to UdfFeedUploadService
  → UdfFeedUploadService checks: is feed already uploaded to this device with same hash?
    → YES (hash match): skip upload
    → NO (new or changed): read feed file from shared volume, upload to DP via Config Service
  → UdfFeedUploadService saves feedName + hash in uploaded_feed table

On policy UPDATE (feed changed):
  → dpInline stores previousUdfFeedName before applying update
  → After upload, if old feed differs from new: cleanupUdfFeed(oldFeedName)

On policy DELETE:
  → dpInline stores udfFeedNameToCleanup before delete
  → After policy delete, calls cleanupUdfFeed() for the feed that was referenced
  → UdfFeedUploadService checks: any other policies on this device still reference this feed?
    → YES: skip cleanup
    → NO (last reference): send CLI delete to DP, remove uploaded_feed row
```

### Key Design Decisions (discovered during implementation)
1. **Feed file source:** Shared volume (`accesslists/userdefinedfeeds/{name}`), NOT HTTP download from PE — same pattern as DNS allow list
2. **UDF metadata source:** Extracted from PE's `/for-dp` response via `ForDpResponseDto`, NOT provided by the client on the REST request
3. **`getPolicyText()` refactored:** Now calls `getForDpResponse()` instead of `getPolicyTemplateText()` — extracts both `policyText` and UDF metadata in one call
4. **No migration needed:** `ddl-auto=update` in Spring Boot handles schema changes
5. **`UdfFeedDto` has no `content` field:** Feed content is read from shared volume by `UdfFeedUploadService`, not passed through DTOs

---

## Task List

### Phase 2: DTOs

- [x] **2.1** ~~Add `userDefinedFeed` to PE response DTO~~ → **Replaced with `ForDpResponseDto`**
  - **New file**: `src/main/java/.../dto/template/ForDpResponseDto.java`
  - **What was done**: Created `ForDpResponseDto` with `policyText` + `AdditionalPolicyData.UserDefinedFeedData` inner classes. The `/for-dp` response is now deserialized into this DTO instead of a raw string.
  - **Note**: Original plan assumed modifying `PolicyEditorPoTemplateDto.java` — this was incorrect. The `/for-dp` endpoint returns a different shape entirely.

- [x] **2.2** Add `UdfFeedDto` to managed policy DTO
  - **File**: `src/main/java/.../dto/accesslists/UdfFeedDto.java` (new)
  - **File**: `src/main/java/.../dto/policy/ManagedPolicyDto.java` (modified)
  - **What was done**: Created `UdfFeedDto` with `feedName` and `fileHash` fields (no `content` field — feed file is read from shared volume). Added `UdfFeedDto udfFeedDto` field to `ManagedPolicyDto`.

### Phase 3: Database

- [x] **3.1** Create `UploadedFeed` entity
  - **New file**: `src/main/java/.../model/UploadedFeed.java`
  - **Fields**: `@EmbeddedId UploadedFeedId id`, `String fileHash`, `Date uploadedAt`

- [x] **3.2** Create `UploadedFeedId` embeddable
  - **New file**: `src/main/java/.../model/UploadedFeedId.java`
  - **Fields**: `String deviceIp`, `String feedName`

- [x] **3.3** Create `UploadedFeedRepository`
  - **New file**: `src/main/java/.../repository/UploadedFeedRepository.java`
  - **Methods**: inherits `findById()` and `deleteById()` from `JpaRepository`

- [x] **3.4** Add `udfFeedName` column to `ManagedPolicy`
  - **File**: `src/main/java/.../model/ManagedPolicy.java`
  - **What was done**: Added `private String udfFeedName;`

- [x] **3.5** Add count query to `ManagedPolicyRepository`
  - **File**: `src/main/java/.../repository/ManagedPolicyRepository.java`
  - **What was done**: Added `long countByUdfFeedNameAndId_DeviceIp(String feedName, String deviceIp)`

- [x] **3.6** ~~Flyway/Liquibase migration~~ → **Not needed**
  - **Reason**: dpInline uses `ddl-auto=update` — Hibernate auto-creates the `uploaded_feed` table and adds the `udf_feed_name` column

### Phase 4: PE Client — ~~HTTP Download~~ → Shared Volume + ForDpResponse

- [x] **4.1** ~~Add feed file download method to PE client~~ → **Replaced**
  - **Original plan**: Add `downloadUdfFeedFile()` to `PolicyEditorRestWebClient`
  - **What was actually done**:
    1. Added `getForDpResponse(String templateName)` to `SecurityPolicyTemplatesService` — calls PE's `/for-dp` endpoint and deserializes into `ForDpResponseDto`
    2. Updated `PolicyTransaction.getPolicyText()` to use `getForDpResponse()` instead of `getPolicyTemplateText()` — extracts both policyText and UDF metadata
    3. Feed file content is read from **shared volume** at `accesslists/userdefinedfeeds/{name}` by `UdfFeedUploadService.readFeedFileContent()` — same pattern as DNS allow list
  - **No change to `PolicyEditorRestWebClient`** — `downloadUdfFeedFile()` was NOT added

### Phase 5: Feed Upload Service

- [x] **5.1** Create `UdfFeedUploadService`
  - **New file**: `src/main/java/.../service/accesslists/UdfFeedUploadService.java`
  - **Methods**:
    - `uploadFeedIfChanged(deviceIp, feedName, fileHash)` — checks hash, reads from shared volume, uploads to DP, saves tracking row
    - `cleanupFeedIfUnused(deviceIp, feedName)` — counts references, deletes from DP + tracking row if zero
  - **Dependencies**: `UploadedFeedRepository`, `ManagedPolicyRepository`, `DefenseProCommandsService`
  - **Note**: No `PolicyEditorRestWebClient` dependency (feed file read from shared volume, not HTTP)
  - **⚠️ `uploadFeedToDp()` is a TODO placeholder** — blocked on Config Service API endpoint

- [x] **5.2** Add DP CLI delete method to `DefenseProCommandsService`
  - **File**: `src/main/java/.../service/defensepro/DefenseProCommandsService.java`
  - **What was done**: Added `deleteUdfProfile(feedName, deviceIp)` using `runArbitraryCommand()` with CLI: `dp udf profiles table delete "{feedName}"`

### Phase 6: Transaction Flow

- [x] **6.1** Wire UDF upload into `PolicyTransactionAdd.runTransaction()`
  - **File**: `src/main/java/.../service/policy/PolicyTransactionAdd.java`
  - **What was done**: Added `uploadUdfFeed(policyDto)` call after `importDnsAllowList()`

- [x] **6.2** Wire UDF upload into `PolicyTransactionUpdate.runTransaction()`
  - **File**: `src/main/java/.../service/policy/PolicyTransactionUpdate.java`
  - **What was done**: Stores `previousUdfFeedName` before update. After `uploadUdfFeed()`, compares old vs new and calls `cleanupUdfFeed()` on old feed if changed.

- [x] **6.3** Wire UDF cleanup into `PolicyTransactionDelete.runTransaction()`
  - **File**: `src/main/java/.../service/policy/PolicyTransactionDelete.java`
  - **What was done**: Stores `udfFeedNameToCleanup` before delete, calls `cleanupUdfFeed()` after delete completes

- [x] **6.4** Add base `uploadUdfFeed()` and `cleanupUdfFeed()` to `PolicyTransaction`
  - **File**: `src/main/java/.../service/policy/PolicyTransaction.java`
  - **What was done**:
    - `uploadUdfFeed(policyDto)` — null-checks `UdfFeedDto`, delegates to `UdfFeedUploadService`, logs audit
    - `cleanupUdfFeed(deviceIp, feedName)` — null-checks feedName, delegates to `UdfFeedUploadService`, catches+logs errors
    - `populateUdfFeedData(policyDto, forDpResponse)` — extracts UDF data from ForDpResponseDto into policyDto
    - `getPolicyText()` refactored to call `getForDpResponse()` and populate UDF data

- [x] **6.5** Pass `UdfFeedUploadService` through constructors
  - **Files**: `PolicyTransactionAdd`, `PolicyTransactionUpdate`, `PolicyTransactionDelete`, `PolicyTransaction` base, `ManagedPolicyService`
  - **What was done**: Added `UdfFeedUploadService` parameter to all transaction constructors and `ManagedPolicyService`

- [x] **6.6** Populate `udfFeedName` when saving `ManagedPolicy`
  - **File**: `src/main/java/.../service/policy/PolicyModelDtoMapper.java`
  - **What was done**: 
    - `dtoToPolicyModel()`: maps `udfFeedDto.feedName` → `policy.udfFeedName`
    - `policyModelToDto()`: maps `policy.udfFeedName` → new `UdfFeedDto` on dto

### Phase 7: Configuration

- [ ] **7.1** Config Service feed upload endpoint
  - **Status**: ⚠️ **BLOCKED** — awaiting Config team response on the exact API endpoint for uploading feed files to DP
  - **Current state**: `UdfFeedUploadService.uploadFeedToDp()` is a TODO placeholder that logs a warning
  - **When unblocked**: Implement actual upload via `ConfigServiceWebClient` or similar

- [x] **7.2** ~~Application properties~~ → **Not needed**
  - **Reason**: Feed path is hardcoded as `accesslists/userdefinedfeeds` constant in `UdfFeedUploadService` (matches DNS allow list pattern). No additional config needed.

### Phase 8: Testing

- [ ] **8.1** `UdfFeedUploadService` unit tests
  - **Status**: Not started
  - **Scenarios**:
    - Hash match → skip upload (verify no file read, no DP upload)
    - Hash mismatch → read from volume + upload to DP + update tracking row
    - New feed (no tracking row) → read + upload + insert tracking row
    - Feed file not found on shared volume → propagate DicException
    - DP upload fails → propagate exception (no tracking row saved)

- [ ] **8.2** `PolicyTransactionAdd` test — UDF path
  - **Status**: Not started
  - **Scenarios**:
    - Policy with UDF → verify `uploadUdfFeed()` called
    - Policy without UDF → verify no UDF upload attempted
    - UDF upload fails → verify exception propagation

- [ ] **8.3** `PolicyTransactionDelete` test — cleanup path
  - **Status**: Not started
  - **Scenarios**:
    - Last policy referencing feed → verify `cleanupFeedIfUnused()` triggers CLI delete + row removal
    - Other policies still reference feed → verify no cleanup
    - Policy with no UDF feed → verify no cleanup attempted

- [ ] **8.4** `PolicyTransactionUpdate` test — feed change
  - **Status**: Not started
  - **Scenarios**:
    - Feed changed (old feed → new feed) → upload new + cleanup old if unused
    - Feed unchanged → upload (hash check), no cleanup
    - Feed removed (old feed → null) → cleanup old if unused
    - Feed added (null → new feed) → upload new, no cleanup

- [ ] **8.5** `PolicyTransaction.getPolicyText()` test — ForDpResponse parsing
  - **Status**: Not started
  - **Scenarios**:
    - Response with UDF data → verify `populateUdfFeedData()` sets UdfFeedDto on policyDto
    - Response without UDF data → verify UdfFeedDto remains null
    - Response with null additionalPolicyData → verify no NPE

- [ ] **8.6** `PolicyModelDtoMapper` tests — UDF mapping
  - **Status**: Not started
  - **Scenarios**:
    - DTO with UdfFeedDto → model has udfFeedName
    - DTO without UdfFeedDto → model udfFeedName is null
    - Model with udfFeedName → DTO has UdfFeedDto with feedName
    - Model without udfFeedName → DTO UdfFeedDto is null

---

## Files Summary

### New Files (7)
| File | Description | Status |
|------|-------------|--------|
| `dto/template/ForDpResponseDto.java` | Deserializes PE's `/for-dp` response (policyText + additionalPolicyData.userDefinedFeed) | ✅ Done |
| `dto/accesslists/UdfFeedDto.java` | DTO for UDF feed data (feedName, fileHash) | ✅ Done |
| `model/UploadedFeed.java` | Entity tracking uploaded feeds per device | ✅ Done |
| `model/UploadedFeedId.java` | Composite key (deviceIp + feedName) | ✅ Done |
| `repository/UploadedFeedRepository.java` | JPA repo for uploaded feed tracking | ✅ Done |
| `service/accesslists/UdfFeedUploadService.java` | Upload + cleanup logic (uploadFeedToDp is TODO) | ✅ Done (partial) |
| ~~DB migration script~~ | ~~`uploaded_feed` table + `udf_feed_name` column~~ | N/A (ddl-auto=update) |

### Modified Files (11)
| File | Change | Status |
|------|--------|--------|
| `dto/policy/ManagedPolicyDto.java` | Add `UdfFeedDto udfFeedDto` field | ��� Done |
| `model/ManagedPolicy.java` | Add `udfFeedName` column | ✅ Done |
| `repository/ManagedPolicyRepository.java` | Add `countByUdfFeedNameAndId_DeviceIp()` query | ✅ Done |
| `service/template/SecurityPolicyTemplatesService.java` | Add `getForDpResponse()` method | ✅ Done |
| `service/defensepro/DefenseProCommandsService.java` | Add `deleteUdfProfile()` CLI method | ✅ Done |
| `service/policy/PolicyTransaction.java` | Add `uploadUdfFeed()`, `cleanupUdfFeed()`, `populateUdfFeedData()`, refactor `getPolicyText()` | ✅ Done |
| `service/policy/PolicyTransactionAdd.java` | Call `uploadUdfFeed()` in transaction | ✅ Done |
| `service/policy/PolicyTransactionUpdate.java` | Store previous feed, call upload + cleanup old | ✅ Done |
| `service/policy/PolicyTransactionDelete.java` | Store feed name, call `cleanupUdfFeed()` after delete | ✅ Done |
| `service/policy/ManagedPolicyService.java` | Pass `UdfFeedUploadService` to transactions | ✅ Done |
| `service/policy/PolicyModelDtoMapper.java` | Map `udfFeedName` ↔ `UdfFeedDto` | ✅ Done |

### NOT Modified (corrected from original plan)
| File | Original Plan | Why Not Modified |
|------|---------------|------------------|
| `dto/template/PolicyEditorPoTemplateDto.java` | Parse UDF data from PE response | `/for-dp` returns a different shape — `ForDpResponseDto` created instead |
| `webClients/PolicyEditorRestWebClient.java` | Add feed file download method | Feed file read from shared volume, not via HTTP |

---

## Dependency Graph

```
Phase 2 (DTOs) ─── ✅ DONE
Phase 3 (DB)   ─── ✅ DONE
Phase 4 (PE Client → Shared Volume + ForDpResponse) ─── ✅ DONE
Phase 5 (Upload Service) ─── ✅ DONE (uploadFeedToDp is TODO)
Phase 6 (Transactions) ─── ✅ DONE
Phase 7 (Config Service upload) ─── ⛔ BLOCKED on Config team
Phase 8 (Tests) ─── ⏳ PENDING (ready to start)
```

---

## Existing Patterns Followed

| Pattern | Example in dpInline | UDF Implementation |
|---------|-------------------|----------------|
| Access list DTO on managed policy | `DnsAllowListDto dnsAllowListDto` on `ManagedPolicyDto` | `UdfFeedDto udfFeedDto` on `ManagedPolicyDto` |
| Access list import in transaction | `importDnsAllowList(policyDto)` in `PolicyTransaction` | `uploadUdfFeed(policyDto)` in `PolicyTransaction` |
| File read from shared volume | `getDnsAllowListContent()` reads from `accesslists/dnsallowlists/` | `readFeedFileContent()` reads from `accesslists/userdefinedfeeds/` |
| DP CLI via runArbitraryCommand | `policyDelete()` in `DefenseProCommandsService` | `deleteUdfProfile()` in `DefenseProCommandsService` |
| Per-device tracking | N/A (new concept) | `UploadedFeed` entity with composite key |
| `/for-dp` response parsing | Previously raw string via `getPolicyTemplateText()` | Now `ForDpResponseDto` via `getForDpResponse()` |

---

## Verification

### How to confirm end-to-end success
1. Create a UDF feed in PE with excluded addresses
2. Create a policy referencing that feed in PE
3. Assign policy to a managed policy in dpInline (policy ADD transaction)
4. Verify: feed file read from shared volume and uploaded to DP device
5. Verify: `uploaded_feed` table row created with correct hash
6. Re-add same policy → verify feed upload is skipped (hash match)
7. Update feed file in PE → re-apply → verify feed is re-uploaded (hash change)
8. Delete the last policy referencing the feed → verify DP cleanup CLI sent + tracking row removed
9. Delete a non-last policy → verify no cleanup

### Rollback behavior
- If feed upload fails during policy ADD, the exception propagates and policy import is rolled back (existing rollback in `PolicyTransactionAdd`)
- Feed tracking row is NOT saved if upload fails (upload happens before save)
- Cleanup errors are caught and logged but do NOT fail the delete transaction

---

## Open Questions

1. **Config Service file upload API endpoint** — awaiting Config team response. This blocks Phase 7 and the actual `uploadFeedToDp()` implementation in `UdfFeedUploadService`.
2. **Feed file format on DP** — is the file uploaded as-is from the shared volume, or does DP expect a specific format/encoding?
3. **vDirect template for UDF delete** — current implementation uses `runArbitraryCommand()` with raw CLI `dp udf profiles table delete "{feedName}"`. Should this use a Velocity (.vm) template instead?

---

## How to Use This Plan

From the dpInline repo's Copilot Chat:

```
Read the plan at .github/plans/2026-04-cycon17398-dpinline-udf-integration.md
and execute Phase 8 (Tests).
```

Or to finish all remaining work:
```
Read the plan at .github/plans/2026-04-cycon17398-dpinline-udf-integration.md
and execute all phases that are not blocked.
```
