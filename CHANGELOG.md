# Changelog

All notable changes to BLOB OPTIMIZER are documented here. Versions follow [Semantic Versioning](https://semver.org/).

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
