# CYCON-17398: dpInline UDF Integration Plan

**Status**: Ready to implement  
**Created**: 2026-04-28  
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

PE also serves the feed file at: `GET /api/policy-editor/user-defined-feed/{name}/file`

---

## Architecture

```
PE /for-dp response
  → dpInline parses feedFileName + fileHash from additionalPolicyData
  → policyText already contains inline UDF CLI (table create + ip-allowlist + -udf ref)

On policy ADD/UPDATE:
  → dpInline imports policyText to DP (existing flow — CLI includes UDF profile)
  → dpInline checks: is feed already uploaded to this device with same hash?
    → YES (hash match): skip upload
    → NO (new or changed): download feed file from PE, upload to DP via Config Service
  → dpInline saves feedName + hash in uploaded_feed table

On policy DELETE:
  → dpInline checks: any other policies on this device still reference this feed?
    → YES: skip cleanup
    → NO (last reference): send CLI delete to DP, remove uploaded_feed row
```

---

## Task List

### Phase 2: DTOs

- [ ] **2.1** Add `userDefinedFeed` to PE response DTO
  - **File**: `src/main/java/.../dto/template/PolicyEditorPoTemplateDto.java`  
    *(or whichever DTO deserializes the `/for-dp` response — check `additionalPolicyData` field)*
  - **Change**: Add inner class or field to capture `feedFileName` and `fileHash` from PE's `AdditionalPolicyDataDTO.UserDefinedFeedData`
  
- [ ] **2.2** Add `UdfFeedDto` to managed policy DTO
  - **File**: `src/main/java/.../dto/policy/ManagedPolicyDto.java`
  - **Change**: Add `UdfFeedDto udfFeedDto` (mirrors existing `DnsAllowListDto dnsAllowListDto` pattern)
  - **Fields**: `feedName`, `fileHash`, `content` (byte[] or InputStream for file data)

### Phase 3: Database

- [ ] **3.1** Create `UploadedFeed` entity
  - **New file**: `src/main/java/.../model/UploadedFeed.java`
  - **Fields**: composite key (deviceIp + feedName), `fileHash` (String), `uploadedAt` (Timestamp)
  - **Pattern**: follows `ManagedPolicy` entity style with `@EmbeddedId`

- [ ] **3.2** Create `UploadedFeedId` embeddable
  - **New file**: `src/main/java/.../model/UploadedFeedId.java`
  - **Fields**: `deviceIp` (String), `feedName` (String)
  - **Pattern**: similar to `PolicyID` embedded key

- [ ] **3.3** Create `UploadedFeedRepository`
  - **New file**: `src/main/java/.../repository/UploadedFeedRepository.java`
  - **Methods**: 
    - `findById(UploadedFeedId id)` — check if feed is already uploaded
    - `deleteById(UploadedFeedId id)` — remove tracking row on cleanup

- [ ] **3.4** Add `udfFeedName` column to `ManagedPolicy`
  - **File**: `src/main/java/.../model/ManagedPolicy.java`
  - **Change**: Add `private String udfFeedName;` — tracks which feed this policy references (needed for cleanup decisions)

- [ ] **3.5** Add count query to `ManagedPolicyRepository`
  - **File**: `src/main/java/.../repository/ManagedPolicyRepository.java`
  - **Change**: Add `long countByUdfFeedNameAndId_DeviceIp(String feedName, String deviceIp)` — count policies on a device referencing a feed (for cleanup gate)

- [ ] **3.6** Flyway/Liquibase migration
  - **New file**: migration script for `uploaded_feed` table + `udf_feed_name` column on `managed_policy`
  - **Check**: what migration tool dpInline uses (`src/main/resources/db/migration/` or similar)

### Phase 4: PE Client

- [ ] **4.1** Add feed file download method to PE client
  - **File**: `src/main/java/.../webClients/PolicyEditorRestWebClient.java`
  - **Change**: Add method to download feed file content:
    ```java
    public byte[] downloadUdfFeedFile(String feedName) {
        // GET /api/policy-editor/user-defined-feed/{feedName}/file
        // Returns file content as byte[]
    }
    ```
  - **Pattern**: follows existing `requestApi()` / `requestApiWithInputStream()` patterns in the class

### Phase 5: Feed Upload Service

- [ ] **5.1** Create `UdfFeedUploadService`
  - **New file**: `src/main/java/.../service/accesslists/UdfFeedUploadService.java`
  - **Methods**:
    ```java
    /**
     * Upload feed file to DP if hash differs from last upload.
     * Steps: check uploaded_feed table → compare hash → download from PE → upload to DP → update tracking row
     */
    void uploadFeedIfChanged(String deviceIp, String feedName, String fileHash);
    
    /**
     * Remove feed from DP if no other policies reference it on this device.
     * Steps: count policies with this feedName on device → if 0: CLI delete + remove tracking row
     */
    void cleanupFeedIfUnused(String deviceIp, String feedName);
    ```
  - **Dependencies**: `PolicyEditorRestWebClient`, `ConfigServiceWebClient`, `UploadedFeedRepository`, `ManagedPolicyRepository`, `DefenseProCommandsService`

- [ ] **5.2** Add DP CLI delete method to `DefenseProCommandsService`
  - **File**: `src/main/java/.../service/defensepro/DefenseProCommandsService.java`
  - **Change**: Add method to delete UDF profile from DP:
    ```java
    public void deleteUdfProfile(String feedName, String deviceIp) {
        // dp user-defined-feed profiles table delete "{feedName}"
    }
    ```
  - **Pattern**: follows existing `policyDelete()` / `importDnsAllowList()` patterns

### Phase 6: Transaction Flow

- [ ] **6.1** Wire UDF upload into `PolicyTransactionAdd.runTransaction()`
  - **File**: `src/main/java/.../service/policy/PolicyTransactionAdd.java`
  - **Change**: After `importDnsAllowList(policyDto)`, add:
    ```java
    uploadUdfFeed(policyDto);   // new method in PolicyTransaction base
    ```
  - **Pattern**: mirrors `importDnsAllowList()` flow

- [ ] **6.2** Wire UDF upload into `PolicyTransactionUpdate.runTransaction()`
  - **File**: `src/main/java/.../service/policy/PolicyTransactionUpdate.java`
  - **Change**: Same as 6.1 — upload if hash changed. Additionally, if old feed differs from new feed, cleanup old.

- [ ] **6.3** Wire UDF cleanup into `PolicyTransactionDelete.runTransaction()`
  - **File**: `src/main/java/.../service/policy/PolicyTransactionDelete.java`
  - **Change**: After policy delete, call `cleanupFeedIfUnused()` for the feed that was referenced

- [ ] **6.4** Add base `uploadUdfFeed()` to `PolicyTransaction`
  - **File**: `src/main/java/.../service/policy/PolicyTransaction.java`
  - **Change**: Add protected method (mirrors existing `importDnsAllowList()`):
    ```java
    protected void uploadUdfFeed(ManagedPolicyDto policyDto) throws Exception {
        UdfFeedDto udfDto = policyDto.getUdfFeedDto();
        if (udfDto != null && StringUtils.isNotBlank(udfDto.getFeedName())) {
            udfFeedUploadService.uploadFeedIfChanged(
                policyDto.getDeviceIp(), udfDto.getFeedName(), udfDto.getFileHash());
        }
    }
    ```

- [ ] **6.5** Pass `UdfFeedUploadService` through constructors
  - **Files**: `PolicyTransactionAdd`, `PolicyTransactionUpdate`, `PolicyTransactionDelete`, `ManagedPolicyService`
  - **Change**: Add `UdfFeedUploadService` parameter to constructors (follows existing `ConfigServiceWebClient` injection pattern)

- [ ] **6.6** Populate `udfFeedName` when saving `ManagedPolicy`
  - **File**: `src/main/java/.../service/policy/PolicyModelDtoMapper.java` (or wherever `dtoToPolicyModel()` lives)
  - **Change**: Map `udfFeedDto.feedName` → `managedPolicy.udfFeedName`

### Phase 7: Configuration

- [ ] **7.1** Config Service feed upload endpoint
  - **Status**: ⚠️ **BLOCKED** — awaiting Config team response on the exact API endpoint for uploading feed files to DP
  - **Placeholder**: Use `ConfigServiceWebClient` with a TBD endpoint path
  - **Notes**: The feed file lives on PE at `accesslists/userdefinedfeeds/{name}.txt`. dpInline downloads it from PE, then uploads to DP device.

- [ ] **7.2** Application properties
  - **File**: `src/main/resources/application.yml` (or `.properties`)
  - **Change**: Add config for feed file paths/endpoints if needed (may not be needed if using PE download + Config Service upload directly)

### Phase 8: Testing

- [ ] **8.1** `UdfFeedUploadService` unit tests
  - **Scenarios**:
    - Hash match → skip upload (verify no PE download, no DP upload)
    - Hash mismatch → download from PE + upload to DP + update tracking row
    - New feed (no tracking row) → download + upload + insert tracking row
    - PE download fails → propagate exception
    - DP upload fails → propagate exception (no tracking row saved)

- [ ] **8.2** `PolicyTransactionAdd` test — UDF path
  - **Scenarios**:
    - Policy with UDF → verify `uploadUdfFeed()` called
    - Policy without UDF → verify no UDF upload attempted
    - UDF upload fails → verify rollback behavior

- [ ] **8.3** `PolicyTransactionDelete` test — cleanup path
  - **Scenarios**:
    - Last policy referencing feed → verify `cleanupFeedIfUnused()` triggers CLI delete + row removal
    - Other policies still reference feed → verify no cleanup

- [ ] **8.4** `PolicyTransactionUpdate` test — feed change
  - **Scenarios**:
    - Feed changed (old feed → new feed) → upload new + cleanup old if unused
    - Feed unchanged → skip
    - Feed removed → cleanup old if unused

---

## Files Summary

### New Files (~6)
| File | Description |
|------|-------------|
| `model/UploadedFeed.java` | Entity tracking uploaded feeds per device |
| `model/UploadedFeedId.java` | Composite key (deviceIp + feedName) |
| `repository/UploadedFeedRepository.java` | JPA repo for uploaded feed tracking |
| `dto/accesslists/UdfFeedDto.java` | DTO for UDF feed data in managed policy flow |
| `service/accesslists/UdfFeedUploadService.java` | Upload + cleanup logic |
| DB migration script | `uploaded_feed` table + `udf_feed_name` column |

### Modified Files (~10)
| File | Change |
|------|--------|
| `dto/template/PolicyEditorPoTemplateDto.java` | Parse UDF data from PE response |
| `dto/policy/ManagedPolicyDto.java` | Add `UdfFeedDto` field |
| `model/ManagedPolicy.java` | Add `udfFeedName` column |
| `repository/ManagedPolicyRepository.java` | Add count query |
| `webClients/PolicyEditorRestWebClient.java` | Add feed file download method |
| `service/defensepro/DefenseProCommandsService.java` | Add UDF profile delete CLI |
| `service/policy/PolicyTransaction.java` | Add `uploadUdfFeed()` base method |
| `service/policy/PolicyTransactionAdd.java` | Call `uploadUdfFeed()` in transaction |
| `service/policy/PolicyTransactionUpdate.java` | Call upload + cleanup old |
| `service/policy/PolicyTransactionDelete.java` | Call `cleanupFeedIfUnused()` |
| `service/policy/ManagedPolicyService.java` | Pass `UdfFeedUploadService` to transactions |
| `PolicyModelDtoMapper` (or equivalent) | Map `udfFeedName` |

---

## Dependency Graph

```
Phase 2 (DTOs) ─── no dependencies
Phase 3 (DB)   ─── no dependencies
Phase 4 (PE Client) ─── no dependencies
Phase 5 (Upload Service) ─── depends on Phase 3 + Phase 4
Phase 6 (Transactions) ─── depends on Phase 2 + Phase 5
Phase 7 (Config) ─── BLOCKED on Config team
Phase 8 (Tests) ─── depends on all above
```

**Parallelizable**: Phases 2, 3, 4 can be done in parallel.

---

## Existing Patterns to Follow

| Pattern | Example in dpInline | UDF Equivalent |
|---------|-------------------|----------------|
| Access list DTO on managed policy | `DnsAllowListDto dnsAllowListDto` on `ManagedPolicyDto` | `UdfFeedDto udfFeedDto` |
| Access list import in transaction | `importDnsAllowList(policyDto)` in `PolicyTransaction` | `uploadUdfFeed(policyDto)` |
| File download from PE | `requestApiWithInputStream()` in `PolicyEditorRestWebClient` | `downloadUdfFeedFile(feedName)` |
| DP CLI via vDirect | `policyImport()`, `policyDelete()` in `DefenseProCommandsService` | `deleteUdfProfile()` |
| Per-device tracking | N/A (new concept) | `UploadedFeed` entity with composite key |

---

## Verification

### How to confirm end-to-end success
1. Create a UDF feed in PE with excluded addresses
2. Create a policy referencing that feed in PE
3. Assign policy to a managed policy in dpInline (policy ADD transaction)
4. Verify: feed file downloaded from PE and uploaded to DP device
5. Verify: `uploaded_feed` table row created with correct hash
6. Re-add same policy → verify feed upload is skipped (hash match)
7. Update feed file in PE → re-apply → verify feed is re-uploaded (hash change)
8. Delete the last policy referencing the feed → verify DP cleanup CLI sent + tracking row removed
9. Delete a non-last policy → verify no cleanup

### Rollback behavior
- If feed upload fails during policy ADD, the policy import should still be rolled back (existing rollback in `PolicyTransactionAdd`)
- Feed tracking row should NOT be saved if upload fails

---

## Open Questions

1. **Config Service file upload API endpoint** — awaiting Config team response. This blocks Phase 7 and the actual upload implementation in Phase 5 (the service can be structured/tested with mocks, but the real endpoint URL is TBD).
2. **Feed file format on DP** — is the file uploaded as-is from PE, or does DP expect a specific format/encoding?
3. **vDirect template for UDF delete** — does `dp user-defined-feed profiles table delete` require a vDirect template, or can it be sent as raw CLI? Check existing `policyImport` pattern.

---

## How to Use This Plan

From the dpInline repo's Copilot Chat:

```
Read the plan at C:\rdwr-intelij\.copilot-shared\plans\2026-04-cycon17398-dpinline-udf-integration.md
and execute Phase 2 (DTOs).
```

Or for the full implementation:
```
Read the plan at C:\rdwr-intelij\.copilot-shared\plans\2026-04-cycon17398-dpinline-udf-integration.md
and execute all phases that are not blocked.
```

