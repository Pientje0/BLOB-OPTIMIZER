# Changelog

All notable changes to BLOB OPTIMIZER are documented here. Versions follow [Semantic Versioning](https://semver.org/).

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
