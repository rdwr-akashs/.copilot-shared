# Memory Centralization Checklist

**Use this checklist to centralize memory, learning, and case docs from individual repos into `.copilot-shared`.**

---

## Pre-Centralization

- [ ] **Backup**: Create backup of each repo's `.github/memory/`, `docs/memory/`, and `.agent_work/` directories
  ```bash
  for repo in df_core kvision_*; do
    zip -r "${repo}-memory-backup.zip" "$repo/.github/memory" "$repo/docs/*" 2>/dev/null
  done
  ```

- [ ] **Identify Repos**: List all repos to migrate from
  - [ ] common_policy_editor
  - [ ] df_core
  - [ ] kvision_configuration_service
  - [ ] kvision_incident_response
  - [ ] webui_components
  - [ ] vision_core
  - [ ] [Other: ________________]

- [ ] **Verify Central Structure**: Check that `/.copilot-shared/shared/` exists
  ```bash
  ls -la /.copilot-shared/shared/
  ```

---

## Automated Centralization (Recommended)

### Using PowerShell Script

- [ ] **Run centralization script**:
  ```powershell
  .\bin\centralize-memory.ps1 -RepoPath "C:\repos" `
    -CentralPath "C:\rdwr-intelij\.copilot-shared" `
    -Repos @("common_policy_editor") `
    -CreateSymlinks $true `
    -DeleteLocal $false `
    -Verify $true
  ```

- [ ] **Review log output**:
  ```bash
  tail centralize-memory-*.log
  ```

- [ ] **Verify results**:
  - [ ] Central memory folders populated with repo-specific docs
  - [ ] Symlinks created in each repo's `.github/`
  - [ ] All verification checks passed

---

## Manual Centralization (If Needed)

### Step 1: Copy Repo Memory

- [ ] **For each repo**, copy memory to central location:
  ```bash
  # df_core example
  cp -r /c/repos/df_core/.github/memory/* \
    /c/rdwr-intelij/.copilot-shared/shared/memory/df_core/
  
  cp -r /c/repos/df_core/docs/memory/* \
    /c/rdwr-intelij/.copilot-shared/shared/memory/df_core/ 2>/dev/null
  ```

- [ ] **Copy learning docs**:
  ```bash
  cp -r /c/repos/df_core/docs/learning/* \
    /c/rdwr-intelij/.copilot-shared/shared/learning/ 2>/dev/null
  ```

- [ ] **Copy case files**:
  ```bash
  cp -r /c/repos/df_core/.agent_work/RSEG-* \
    /c/rdwr-intelij/.copilot-shared/shared/cases/customer-cases/ 2>/dev/null
  ```

### Step 2: Create Symlinks

- [ ] **For each repo**, create symlinks in `.github/`:
  ```bash
  cd /c/repos/df_core/.github
  
  # Windows PowerShell
  cmd /c mklink /d copilot-memory ..\..\..\..\.copilot-shared\shared\memory\df_core
  cmd /c mklink /d learning ..\..\..\..\.copilot-shared\shared\learning
  cmd /c mklink /d cases ..\..\..\..\.copilot-shared\shared\cases
  
  # Git Bash / Linux
  ln -s ../../../.copilot-shared/shared/memory/df_core copilot-memory
  ln -s ../../../.copilot-shared/shared/learning learning
  ln -s ../../../.copilot-shared/shared/cases cases
  ```

- [ ] **Verify symlinks**:
  ```bash
  ls -la /c/repos/df_core/.github/copilot-memory
  ls -la /c/repos/df_core/.github/learning
  ```

### Step 3: Configure Git

- [ ] **Enable symlink support** in each repo:
  ```bash
  cd /c/repos/df_core
  git config core.symlinks true
  git add .github/copilot-memory .github/learning .github/cases
  git commit -m "chore: centralize memory, learning, and case docs"
  ```

---

## Documentation Updates

- [ ] **Update `.copilot-instructions.md`** in each repo:
  ```markdown
  ## Memory & Learning Resources
  
  ### Central Resources
  - **Memory**: [See .github/copilot-memory](../../.copilot-shared/shared/memory/df_core/)
  - **Learning**: [See .github/learning](../../.copilot-shared/shared/learning/)
  - **Cases**: [See .github/cases](../../.copilot-shared/shared/cases/)
  - **Cross-Repo**: [See central memory](../../.copilot-shared/shared/memory/cross-repo/)
  
  These are symlinks to centralized location in `.copilot-shared`.
  ```

- [ ] **Check symlinks can be accessed from IDE**:
  - [ ] Navigate to `.github/copilot-memory/` in VS Code
  - [ ] Verify files are readable
  - [ ] Try opening a memory file

---

## Cleanup (Optional)

### Only After Verifying Centralization Works!

- [ ] **Remove local memory copies** from individual repos:
  ```bash
  for repo in df_core kvision_*; do
    cd /c/repos/$repo
    rm -rf .github/memory           # Now a symlink
    rm -rf docs/memory
    rm -rf docs/learning
    # Keep .agent_work/ intact (symlink to central cases)
  done
  ```

- [ ] **Verify symlinks still work**:
  ```bash
  cat /c/repos/df_core/.github/copilot-memory/memory.md  # Should work
  ```

- [ ] **Commit cleanup** (optional):
  ```bash
  git add -A
  git commit -m "chore: remove local memory copies (now centralized)"
  git push
  ```

---

## Verification Checklist

- [ ] **Central directories created**:
  ```
  ✓ shared/memory/cross-repo/
  ✓ shared/memory/df_core/
  ✓ shared/memory/kvision_*/
  ✓ shared/learning/
  ✓ shared/cases/
  ```

- [ ] **Memory files consolidated**:
  - [ ] `shared/memory/<repo>/memory.md` exists and has content
  - [ ] `shared/memory/<repo>/performance-notes.md` exists
  - [ ] `shared/learning/` has best-practices docs

- [ ] **Symlinks functional**:
  ```bash
  cd /c/repos/df_core/.github
  cat copilot-memory/memory.md        # Should display content
  cat learning/best-practices/*.md    # Should display content
  ```

- [ ] **Copilot can access**:
  - [ ] Open repo in VS Code
  - [ ] In Copilot chat, ask it to reference "the central memory in .github/copilot-memory"
  - [ ] Verify it can read the file

- [ ] **Git tracking**:
  ```bash
  cd /c/repos/df_core
  git ls-files -s | grep copilot-memory  # Should show "120000" (symlink)
  ```

---

## Troubleshooting

### Symlinks Not Created (Admin Rights)

**Problem**: `mklink` fails with "Access Denied"

**Solution**:
- Run PowerShell as Administrator, OR
- Use Git Bash (may have better symlink support), OR
- Use `--follow-symlinks` in git config

### Symlinks Not Tracked by Git

**Problem**: Symlinks show as modified files or don't commit

**Solution**:
```bash
git config core.symlinks true
git rm --cached <symlink>
git add <symlink>
git commit -m "fix: enable symlink tracking"
```

### Memory Files Not Visible in Copilot

**Problem**: Copilot doesn't see the centralized memory

**Solution**:
1. Verify symlinks exist: `ls -la .github/copilot-memory/`
2. Check `.copilot-instructions.md` includes memory reference
3. Reload Copilot context: `Ctrl+Shift+P` → "Copilot: Reset context"
4. Verify file paths are relative to repo root

### Merge Conflicts in Symlinks

**Problem**: Git shows symlink conflicts during merge

**Solution**:
```bash
# Take theirs (symlink from main branch)
git checkout --theirs .github/copilot-memory
git add .github/copilot-memory
git commit -m "resolve: use central symlink"
```

---

## Success Criteria

✅ **Centralization is complete when:**

1. All repo-specific memory is in `/.copilot-shared/shared/memory/<repo>/`
2. All learning docs are in `/.copilot-shared/shared/learning/`
3. All case files are in `/.copilot-shared/shared/cases/`
4. Each repo has symlinks in `.github/copilot-memory/`, `.github/learning/`, `.github/cases/`
5. Symlinks are tracked by git (`core.symlinks = true`)
6. Copilot can access memory from each repo without local copies
7. `.copilot-instructions.md` in each repo references central memory
8. Local copies have been deleted (optional but recommended)

---

## Support & Questions

For issues or questions:
- See [CENTRALIZED_MEMORY_SETUP.md](../CENTRALIZED_MEMORY_SETUP.md) for detailed architecture
- Review [shared/memory/README.md](../shared/memory/README.md) for memory organization
- Check [shared/learning/README.md](../shared/learning/README.md) for learning docs
- Review [cases/README.md](../cases/README.md) for case documentation structure

**Last Updated**: [Auto-updated on push]
