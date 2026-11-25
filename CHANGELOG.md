# Changelog

All notable changes to BLOB OPTIMIZER are documented here. Versions follow [Semantic Versioning](https://semver.org/).

## [2.2.1] - 2026-11-25

### Removed
- **Every privacy entry that could not be changed (23).**
  - The information-only items: Defender/SpyNet (5), automatic update behaviour, activation checks and Bluetooth pairing.
  - Settings without a reliable switch: location history, geofencing, location-based ads, location override, Edge Secure Network, Microsoft 365 promotional features, OneDrive notifications, Copilot key and mobile-device notifications.
  - The Edge Legacy entries (6).
  - The *Microsoft Edge Legacy* and *Microsoft Defender and SpyNet* sections are gone; the Privacy page now has 156 settings in 20 sections, all switchable.

### Changed
- The self-test now fails if a privacy setting without a switch is ever added.

## [2.2.0] - 2026-11-25

### Added
- **Privacy page:** 179 privacy settings in 22 sections, from Privacy and Telemetry through App Privacy, Location, Search, Sync, Windows Update, Edge, Office / Microsoft 365, Explorer, the lock screen, the taskbar, activity and clipboard, Copilot and Windows AI, mobile devices and gaming.
  - Each setting explains what it does, what can be collected, the benefit of turning it off, what you lose and possible problems. It also has a recommendation (DISABLE / OPTIONAL / KEEP ENABLED) and a privacy impact rating (Low / Medium / High).
  - O&O ShutUp10++ IDs are shown where they were provided.
  - Filters: section, advice and search. *Choose all recommended* marks every DISABLE item. The page uses the same choose-then-apply, backup and undo flow as Tweaks.
  - 23 items are information only: Defender/SpyNet, automatic security updates, activation, Bluetooth pairing and items without a reliable switch. Edge Legacy items are marked *not applicable*.
- `docs/PRIVACY-SETTINGS.md`, generated from the catalogue by `tests/Export-PrivacyReference.ps1`.
- Terminal UI: *Privacy center* (`V`) on the dashboard.
- Self-test: checks that every section has items, that every switch uses a valid registry path, and that every explanation is complete.

### Changed
- The pending bar now reads "N to switch on, M to switch off", so it means the same thing on both the Tweaks and Privacy pages.

## [2.1.0] - 2026-11-25

### Added
- **Apps page: complete app removal.** It lists all installed programs (from the three Uninstall registry locations) and Microsoft Store apps, with size, install date, type, search and sorting (name, largest, newest).
  - **Uninstall** runs the app's own uninstaller (MSI products via `msiexec /X`), or removes Store apps with their data through Windows.
  - Once Windows no longer lists the program, a **leftover scan** looks for exact-name folders, registry keys, shortcuts and startup entries. You pick what to remove: folders and shortcuts go to the Recycle Bin, registry keys are exported to .reg first (a new restorable `RegKeyDelete` journal entry), and startup entries use the undo journal.
  - Shared folders are never touched, Windows-critical apps are protected, and shared runtimes are flagged.
  - If the uninstaller is cancelled, nothing is scanned or removed.
- Store apps are listed on the background data thread, so the Apps page preloads like the others.
- Overview: *Remove an app completely* in Start here.

## [2.0.0] - 2026-11-25

### Changed - complete visual redesign
- **New design language:** an engineering spec sheet. Warm paper and near-black ink with one signal colour (international orange) for pending changes, higher risk and the active page. Bahnschrift for structure and numbers, Segoe UI for reading, monospace only for technical values. Hairline rules instead of boxes, with no gradients, shadows or glow.
- **Navigation:** a numbered table of contents (01-11) with an orange marker, large page titles with page numbers, and plainer page names (Overview, Tweaks, External tools, System).
- **Overview:** large readouts (tweaks on, memory, disk, restorable changes), a *This PC* spec table and a *Start here* action list.
- **Presets:** three columns divided by rules, each with a risk meter, a count of what is already on, and the full list of included tweaks (filled = already on, outline = will change, orange = higher risk).
- **Tweaks:** dense ruled rows grouped by area, with a rectangular switch, a three-bar risk meter, a state column (*→ ON* / *→ OFF* in orange while waiting) and **?** help. Area and risk filters are text tabs; search is an underline field.
- **Pending bar:** a global black bar with *Discard* and *Review and apply N* that appears whenever choices are waiting.
- **Log drawer:** the activity log is now a one-line strip that opens on demand.
- **Dialogs:** paper surface with a stripe that turns orange for risky actions, and proper pluralisation.
- **Terminal UI:** white and grey text with yellow accents and inverted selection.

## [1.5.0] - 2026-11-25

### Changed
- **Choose first, then apply.** The switches on the Optimizations cards only record what you want (*WILL ACTIVATE* / *WILL DEACTIVATE*). **Apply changes (N)** applies everything in one go after a single preview dialog with the restore-point option. Activations are backed up first, and deactivations restore the saved originals. **Discard changes** clears your choices, and closing the window with unapplied choices asks first.
- **Black and blue** instead of black and green (window and terminal UI).

### Added
- **Risk level filter** (Low, Medium, High, Preference) next to the category filter and search.
- *Activate all shown* marks every shown setting to be activated (still applied only with Apply changes).

## [1.4.0] - 2026-11-25

### Changed
- **Black and green, very basic look.** Pure black background, green text and 1-pixel green lines, the Consolas monospace font everywhere, square corners, no shadows, no icon font (plain `[+]`, `[?]`, `!`, `ADMIN` markers) and text-only tabs. Severity is shown with words and inverted HIGH RISK badges. The terminal interface is black and green too.
- **Always runs as administrator.** When started without admin rights (from PowerShell, Windows Terminal or cmd), it relaunches itself through the standard Windows UAC prompt, keeping `-DryRun` / `-Tui`. If permission is declined, it continues in read-only mode. `-NoElevate` / `BLOB_NOELEVATE=1` skips the prompt.

### Added
- A cmd.exe launch command in the README and `BLOB.cmd` for local copies.

## [1.3.1] - 2026-11-23

### Changed
- **All tabs preload in the background**, so switching tabs takes milliseconds instead of 1–5 seconds. The Optimizations cards are prebuilt a few at a time so the window stays responsive.
- **Slow system data is collected on three parallel background threads** (network; security and disks; system, services and cleanup sizes) while the window is already usable. All tabs are ready in about 7 seconds instead of more than 20.
- After a change, only the current tab rebuilds immediately. Other affected tabs refresh in the background, and data is read live again.
- Registry reads use .NET directly (about 20× faster). Cards are cached and reused, so a switch flip refreshes in about 0.3 s instead of 2.5 s.
- The network snapshot uses `Get-NetIPAddress` / `Get-NetRoute` instead of the slow `Get-NetIPConfiguration`.
- Tooltips are built on first hover. Each tab remembers its scroll position.

## [1.3.0] - 2026-11-23

### Added
- 15 new settings (55 in total):
  - **FPS & latency:** disable power throttling, foreground priority boost, Multiplane Overlay fix, disable Xbox services.
  - **Network:** disable network throttling, stop sharing updates with other PCs.
  - **Performance:** file I/O (no last-access writes, no 8.3 names), Edge background/startup boost, faster Explorer folder loading.
  - **Quality of life:** the Xbox button no longer opens Game Bar.
  - **Privacy:** Recall snapshots, and Firefox, Chrome and Edge telemetry policies.
  - Each has a detailed explanation.
- Categories on every setting (FPS & Latency, Performance, Network, Quality of Life, Privacy & Security).
- **Optimizations** tab: all settings as cards with category filter chips, search, a risk label, an Activate / Deactivate switch, **+** for batch selection, **?** help, and warning and admin icons.
- *Optimize drives now* action (Windows Optimize-Volume: TRIM for SSDs, defrag for HDDs).
- New settings added to the STANDARD (33) and ADVANCED (42) presets. Xbox services, MPO and 8.3 names are opt-in only.

### Changed
- Navigation moved from the sidebar to tabs across the top. The four section pages were merged into the Optimizations tab (the terminal UI keeps its sections).
- Refreshing a page after a change keeps the scroll position.

## [1.2.0] - 2026-11-23

### Added
- Clear risk labels on every setting (LOW RISK, MEDIUM RISK, HIGH RISK, PREFERENCE), a risk legend on each section, and explanations of each risk level on hover.
- A **?** help icon on every setting, cleanup location and preset. Hovering it shows a detailed explanation, the risk, the exact registry or service changes (current → new), admin requirements, the current status and how to undo.
- Hand-written detailed explanations for all 40 settings. They also appear in the terminal details view.
- A *Create a System Restore point first* checkbox in every apply dialog, including presets and external tools.
- External Tools page and terminal menu (`T`): launchers for Chris Titus Tech's WinUtil and O&O ShutUp10++. The source URL is shown before launch, the ShutUp10++ signature is verified, and the launch is recorded in the journal.

### Changed
- Restore point creation detects when Windows silently skips it (24-hour limit) and reports that honestly.
- The window sizes itself to the screen.

## [1.1.0] - 2026-11-23

### Added
- Window interface (WPF, built into Windows) is now the default: dark theme, sidebar navigation, a dashboard with system cards, presets, checkbox tweak lists with risk and state badges, tables for services, startup programs and change history, a cleanup size preview, DNS and power controls, and a live activity log.
- A confirmation dialog for every change that lists exact registry paths and current → new values. ADVANCED items get a red danger style.
- `-Tui` switch (or `$env:BLOB_TUI = '1'`) to use the terminal interface. If WPF is unavailable, the tool falls back to the terminal interface automatically.
- The self-test now parses all window markup and builds every page. `tests/Render-Gui.ps1` renders every page to PNG.

### Changed
- Apply, undo, restore, Explorer restart and network diagnostics logic moved into UI-agnostic functions shared by both interfaces.

## [1.0.0] - 2026-11-23

### Added
- Single-file in-memory release (`BLOB.ps1`) that launches with `irm … | iex`. Nothing is installed or left running.
- Terminal UI built only on `[System.Console]`: dashboard, scrollable menus, multi-select, previews, confirmations, input fields, live work log, resize handling, alternate screen buffer in Windows Terminal.
- Sections: Performance, Gaming, Tweaks, Privacy, Services, Startup, Cleanup, Network, Power, Restore, System Info.
- 40 catalogued tweaks with risk levels (Minimal, Standard, Advanced, Optional) and live state detection.
- MINIMAL, STANDARD and ADVANCED presets with a full per-setting preview and an optional System Restore point.
- Change journal (JSON) with read → save → record → apply → verify for registry, services, startup entries, power plans, timeouts, hibernation and DNS.
- Restore of individual changes or whole sessions, `.reg` snapshots before each batch, and JSON config export/import.
- Dry-run mode (`-DryRun` or `$env:BLOB_DRYRUN = '1'`) and a read-only self-test (`$env:BLOB_SELFTEST = '1'`).
- Build script with ASCII and syntax validation, embedded presets and a SHA-256 checksum.
