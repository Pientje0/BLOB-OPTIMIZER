# BLOB OPTIMIZER

A portable Windows optimization utility with a full terminal interface.
There is no installer, no EXE, no GUI and nothing to uninstall. It runs inside one PowerShell session and stops completely when you close it.

```
 #####   ##        #####   #####
 ##  ##  ##       ##   ##  ##  ##
 #####   ##       ##   ##  #####
 ##  ##  ##       ##   ##  ##  ##
 #####   #######   #####   #####
        O P T I M I Z E R
```

## Launch

1. Right-click **Windows Terminal** (or PowerShell) and choose **Run as administrator**.
2. Paste the command and press Enter:

```powershell
irm https://raw.githubusercontent.com/Pientje0/BLOB-OPTIMIZER/v1.0.0/BLOB.ps1 | iex
```

**Dry run** shows every change it would make without modifying anything:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Pientje0/BLOB-OPTIMIZER/v1.0.0/BLOB.ps1))) -DryRun
```

> Pinning a version tag (`v1.0.0`) means the code you run is exactly the code you can read in that tag. Each new release gets a new tag and URL.

Without administrator rights, BLOB OPTIMIZER still starts in read-only mode: you can browse system info, settings, services, startup entries and cleanup sizes, and apply per-user settings. Anything machine-wide explains why it needs elevation. The tool never elevates itself.

### Run a local copy

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\BLOB.ps1          # normal
powershell -NoProfile -ExecutionPolicy Bypass -File .\BLOB.ps1 -DryRun  # dry run
```

## What it does

| Section | Contents |
|---|---|
| **Performance** | Menu delay, startup delay, Store background apps, visual effects, transparency, multimedia scheduling, live memory/CPU view, performance settings overview |
| **Gaming** | Game Mode, Game DVR, mouse acceleration, Sticky Keys prompt, GPU scheduling, fullscreen optimizations, MMCSS priority, power plan shortcut. **No FPS gains are promised.** |
| **Tweaks** | File Explorer (extensions, This PC, hidden files, recent files), taskbar (search, Task View, Widgets, End task, alignment), Start (recommendations, web search), classic context menu, long paths |
| **Privacy** | Advertising ID, tailored experiences, suggestions and auto-installed apps, lock screen ads, diagnostic data level, feedback, inking, activity history, DiagTrack service |
| **Services** | Curated review with explanations and recommended startup types, plus a browser of every service. Only startup types are changed, and critical services are protected |
| **Startup** | Run keys and Startup folders. Entries are disabled with the same mechanism Task Manager uses, so nothing is deleted |
| **Cleanup** | Temp files, thumbnail cache, crash dumps, WER reports, DirectX shader cache, Windows Update download cache, Recycle Bin, with a size preview first. Storage and disk health |
| **Network** | Adapter information, diagnostics (only when you start them), DNS presets or custom servers, DNS flush, IP renew, Winsock/TCP-IP reset |
| **Power** | Switch plans, add High/Ultimate Performance, display/sleep timeouts, hibernation |
| **Restore** | Change history, restore individual changes or a whole session, `.reg` snapshots, System Restore points, JSON config export/import |
| **Presets** | **MINIMAL**, **STANDARD**, **ADVANCED**. Each one lists every setting it will change (current value → new value) and waits for you to press `Y` |

### Keys

`↑ ↓ ← →` navigate · `Enter` select · `Space` toggle · `Tab` next group · `Esc` back · letter keys shown in the footer (`A` apply, `U` undo, and so on). `Ctrl+C` behaves like `Esc`, so the console is always restored. The layout adapts when you resize the window (minimum 64 × 20).

## Safety model

Every change goes through one code path in `src/Core.ps1`:

1. **Read** the current value.
2. **Save** the original (value, type, whether the value or key existed) in the change journal.
3. **Record** the modification.
4. **Apply** the change.
5. **Verify** by reading it back. A mismatch is recorded as `FAILED`.

Before each batch of tweaks, the affected registry keys are also exported to `.reg` files.

- **Restorable:** registry values (keys the tool created are removed again), service startup types, startup entries, power plan, timeouts, hibernation, DNS servers.
- **Not restorable, and labeled that way:** file cleanup, DNS flush, IP renew and network resets. The tool never claims these can be undone.
- `OPTIONAL` tweaks are personal preferences and are never part of a preset.
- It never touches Microsoft Defender, Windows Firewall, SmartScreen, UAC, Windows Update policies or antivirus exclusions.

### Files it creates

Files are created only after you make your first real change. Dry runs and browsing write nothing.

```
%LOCALAPPDATA%\BLOB-OPTIMIZER\
  changes.json          change journal (originals for restore)
  logs\session-*.log    operation logs
  registry-backups\     .reg snapshots taken before each batch
```

Delete that folder at any time to remove all traces. Configuration exports go wherever you choose (Documents by default).

## Transparency and antivirus

- The source is plain, readable PowerShell with no obfuscation, no encoded commands, no hidden windows and no `-EncodedCommand`.
- It downloads nothing at runtime, and it creates no services, scheduled tasks, Run keys or background processes.
- It makes network connections only when you start a diagnostic. The screen lists the hosts first.
- `BLOB.ps1.sha256` is published with each release. Check a download with `Get-FileHash .\BLOB.ps1`.
- Releases should be Authenticode-signed when a code-signing certificate is available: `Set-AuthenticodeSignature .\BLOB.ps1 -Certificate $cert -TimestampServer http://timestamp.digicert.com`.

Antivirus products sometimes flag `irm | iex` tools heuristically, and no tool can promise it will never be flagged. **Do not disable your antivirus or add exclusions.** If BLOB.ps1 is detected:

1. Compare the file hash with the published `BLOB.ps1.sha256`.
2. Read the source. Everything is in `src/` and the release is a plain concatenation of it.
3. Report a suspected false positive to the vendor, for example Microsoft at https://www.microsoft.com/wdsi/filesubmission, with the file and the release URL.

## Development

```
BLOB-OPTIMIZER/
├── BLOB.ps1                 generated single-file release (do not edit)
├── BLOB.ps1.sha256
├── README.md  CHANGELOG.md
├── src/                     readable source modules (edit these)
│   ├── Core.ps1             state, journal, registry/service engine, restore
│   ├── UI.ps1               terminal UI toolkit ([Console] only)
│   ├── Engine.ps1           tweak catalogue, preview/apply/undo, presets
│   ├── Dashboard.ps1        logo, system summary, main menu, system info
│   ├── Performance.ps1  Gaming.ps1  Tweaks.ps1  Privacy.ps1
│   ├── Services.ps1  Startup.ps1  Cleanup.ps1  Network.ps1  Power.ps1
│   ├── Restore.ps1          history, snapshots, restore points, export/import
│   └── Main.ps1             entry point, self-test
├── config/presets.json      preset definitions (embedded at build time)
├── build/Build-Release.ps1  concatenates src/ into BLOB.ps1
├── tests/Test-Engine.ps1    apply → journal → restore round-trip test
└── docs/TESTING.md          release testing checklist
```

Build a release:

```powershell
powershell -NoProfile -File .\build\Build-Release.ps1 -Repository Pientje0/BLOB-OPTIMIZER
```

The build wraps every module in one script block, so no functions or variables leak into the user's session. It embeds `presets.json`, fails if the output contains non-ASCII characters or syntax errors, and writes the SHA-256 file.

Add a tweak by calling `Register-BlobTweak` in the section file with an `Id`, a `Risk` level and its `Registry` or `Services` operations. State detection, preview, backup, undo and presets work for it automatically.

Requirements: Windows 10/11 and Windows PowerShell 5.1 or PowerShell 7+. No modules, packages or external tools are needed. It only uses built-in commands such as `reg.exe`, `sc.exe`, `powercfg.exe`, `netsh.exe` and `ipconfig.exe`.

## Disclaimer

BLOB OPTIMIZER changes Windows settings. Results depend on your hardware and configuration, and no performance improvement is guaranteed. Review every preview and use dry run if you are unsure. Inspired by the distribution model of Chris Titus Tech's Windows Utility. It is an independent project and not affiliated with it.
