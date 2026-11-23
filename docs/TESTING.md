# Release testing checklist

Run this on a test VM or a spare PC before tagging a release. Test **Windows PowerShell 5.1** and **PowerShell 7**, and test both as **Administrator** and as a **standard user**.

## 1. Automated checks

- [ ] `powershell -NoProfile -File .\build\Build-Release.ps1` succeeds (ASCII check, syntax check, SHA-256 written)
- [ ] `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Engine.ps1` prints **All engine tests passed**
- [ ] Self-test passes in PS 5.1: `$env:BLOB_SELFTEST='1'; Get-Content -Raw .\BLOB.ps1 | iex`
- [ ] Self-test passes in PS 7: `$env:BLOB_SELFTEST='1'; pwsh -NoProfile -Command "Get-Content -Raw .\BLOB.ps1 | iex"`
- [ ] After the run, `Get-Command *-Blob*` returns nothing and `$Blob` is undefined, so nothing leaked into the session
- [ ] `%LOCALAPPDATA%\BLOB-OPTIMIZER` was **not** created by the self-test or a dry run

## 2. Launch

- [ ] `irm <raw URL> | iex` launches from an elevated Windows Terminal
- [ ] The same command from a standard-user terminal starts in read-only mode with a yellow **STANDARD USER** badge
- [ ] `-DryRun` through the scriptblock form shows the magenta **DRY RUN** badge
- [ ] Windows PowerShell ISE shows a clear "use a console" message instead of breaking
- [ ] Classic conhost (`powershell.exe` window) renders the borders correctly

## 3. Terminal UI

- [ ] Arrow keys, Enter, Esc, Space, Tab, PgUp/PgDn, Home/End work in menus
- [ ] Number keys 1–9, 10, 11, P and 0 work on the dashboard
- [ ] Resizing the window redraws without garbage. Below 64×20 a "window too small" message appears and Esc leaves it
- [ ] Long lists scroll and the "more below" indicator appears in text views
- [ ] `Ctrl+C` acts as Esc. Exiting restores colours, cursor, title and scrollback
- [ ] Nothing remains in Task Manager after exit

## 4. Apply → verify → restore (per section)

For each section, apply one tweak with **A**. Confirm the preview shows current → new values, then confirm the state changes to **APPLIED**:

- [ ] Performance  - [ ] Gaming  - [ ] Tweaks (Explorer restart prompt appears)  - [ ] Privacy
- [ ] **U** (undo) brings the state back. In regedit, the original value or the absence of the value and key is restored
- [ ] Restore → Change history shows each change. Restoring one record works, and restoring it again is refused
- [ ] Restore → Undo a whole session restores everything from that run
- [ ] A `.reg` snapshot exists under `registry-backups` for each batch

## 5. Presets

- [ ] Each preset shows the full list of settings before anything happens. **N** cancels without changes
- [ ] ADVANCED shows the red warning banner
- [ ] As admin, the restore-point prompt appears, and **Y** creates a point (or Windows reports one exists within 24 h)
- [ ] Re-applying a preset reports **SAME** for settings that are already applied
- [ ] As a standard user, machine-wide items are **SKIP**ped with a reason

## 6. Services / Startup / Power / Network / Cleanup

- [ ] Protected services (WinDefend, mpssvc, wuauserv, etc.) cannot be changed
- [ ] Changing a curated service's startup type records the original, and restoring brings it back
- [ ] Disabling a startup entry also shows it as disabled in Task Manager → Startup. **E** and **U** re-enable it
- [ ] Switching the power plan and restoring it works. Ultimate Performance creates a plan, and restore deletes it once another plan is active
- [ ] Changing the display timeout and restoring it works. The hibernation toggle and its restore work (admin)
- [ ] DNS change shows current → new values. Restoring returns to the original (DHCP or static)
- [ ] Diagnostics lists the hosts and only runs after **Y**
- [ ] Cleanup shows sizes before deleting, warns that the action is permanent, skips locked files, and records a non-reversible action

## 7. Config export / import

- [ ] Export writes JSON with no hostname or user name
- [ ] Import on a second PC previews every setting before applying. Unknown IDs are listed and ignored
- [ ] An invalid or foreign JSON file gives a clear error

## 8. Transparency

- [ ] The release contains no `-EncodedCommand`, Base64 payloads, `Add-MpPreference` or Defender/Firewall changes
- [ ] There are no network requests except user-started diagnostics (check with Resource Monitor)
- [ ] `Get-FileHash .\BLOB.ps1` matches `BLOB.ps1.sha256`
- [ ] The release is signed if a certificate is available (`Get-AuthenticodeSignature .\BLOB.ps1`)
