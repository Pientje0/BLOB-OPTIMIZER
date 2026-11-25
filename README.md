# BLOB OPTIMIZER

A portable Windows optimization utility with a modern window interface, plus a full terminal interface.
There is no installer, no EXE and nothing to uninstall. It runs inside one PowerShell session and stops completely when you close it.

```
 #####   ##        #####   #####
 ##  ##  ##       ##   ##  ##  ##
 #####   ##       ##   ##  #####
 ##  ##  ##       ##   ##  ##  ##
 #####   #######   #####   #####
        O P T I M I Z E R
```

## Launch

Open **PowerShell**, **Windows Terminal** or plain **cmd**. It does not need to be an administrator window. Paste the command and press Enter. BLOB OPTIMIZER always runs as administrator: if needed, it asks Windows for permission (the normal UAC prompt) and reopens itself in an administrator window.

PowerShell / Windows Terminal:

```powershell
irm https://raw.githubusercontent.com/Pientje0/BLOB-OPTIMIZER/v2.4.0/BLOB.ps1 | iex
```

cmd.exe:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Pientje0/BLOB-OPTIMIZER/v2.4.0/BLOB.ps1 | iex"
```

**Terminal-only interface** (keyboard UI inside PowerShell):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Pientje0/BLOB-OPTIMIZER/v2.4.0/BLOB.ps1))) -Tui
```

**Dry run** shows every change it would make without modifying anything:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Pientje0/BLOB-OPTIMIZER/v2.4.0/BLOB.ps1))) -DryRun
```

> Pinning a version tag (`v2.4.0`) means the code you run is exactly the code you can read in that tag. Each new release gets a new tag and URL.

**Administrator rights.** BLOB OPTIMIZER requests administrator rights at start-up through the standard Windows UAC prompt. It never bypasses or suppresses that prompt. If you choose *No*, it continues in read-only mode: you can browse everything and apply per-user settings. Add `-NoElevate` (or set `$env:BLOB_NOELEVATE = '1'`) to skip the prompt.

### Run a local copy

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\BLOB.ps1          # normal
powershell -NoProfile -ExecutionPolicy Bypass -File .\BLOB.ps1 -DryRun  # dry run
powershell -NoProfile -ExecutionPolicy Bypass -File .\BLOB.ps1 -Tui     # terminal interface
```

## Interfaces

**Design.** BLOB looks like an engineering spec sheet rather than a "gamer app": warm paper background, near-black ink, and one signal colour (international orange) used only for what needs your attention, such as pending changes, higher-risk tweaks and the active page. Bahnschrift, the DIN-style typeface built into Windows, sets the structure and numbers; Segoe UI is for reading; a monospace face is used only for technical values. Hairline rules instead of boxes, no gradients, no shadows, almost no rounding.

**Window (default).** A numbered table of contents on the left (01 Overview, 02 Presets, 03 Tweaks, Privacy, Appearance, Services, Startup, Apps, Install, Cleanup, Network, Power, Measure, Restore, External tools, System), large page titles, ruled tables and a log drawer at the bottom that shows the last action and opens on demand.

**Overview.** Four large readouts (tweaks on, memory, free disk, restorable changes), a *This PC* spec table, and a *Start here* list of the next useful actions.

**Search everything (`Ctrl+K`).** One box that finds pages, tweaks, privacy settings (also by O&O ID, such as `U008`), installed apps and apps to install. Enter opens the right page with the filter already set.

**Did Windows undo my settings?** Feature updates, or a change in Settings, can quietly put values back. On every start BLOB compares each change it still owns with the PC. When something was changed back, an orange bar on the Overview and Restore pages says how many, with **Details**, **Re-apply** (writes the value again and checks it sticks) and **Keep Windows' values** (BLOB stops counting that change as its own). Re-applying keeps the original backup, so undo still returns the PC to how it was before BLOB.

**What changed.** After every apply, undo, install or re-apply, a summary lists exactly what changed, what was already set and what failed. **Save as text file** keeps it for later or for someone helping you.

**Tweaks.** All 53 tweaks as dense ruled rows, grouped by area (FPS & Latency, Performance, Network, Quality of Life, Privacy & Security) and filterable by area, **risk level** (Low, Medium, High, Preference) and search. Each row has an on/off switch, the name and a one-line description, a three-bar **risk meter** (HIGH in orange), the current state and a **?** with the full explanation.
- **Choose first, apply after.** A switch only records what you want. The row turns orange with *→ ON* or *→ OFF*, and a black bar appears at the bottom: "2 to switch on, 1 to switch off. Nothing has been changed yet." **Review and apply** opens one dialog listing every exact change, with the restore-point option. **Discard** forgets your choices, and closing the window with choices waiting asks first.

**Privacy: 156 settings in 20 sections, every one switchable.** Privacy, telemetry, app permissions, Cortana and input, location, search, settings sync, security, Windows Update, Edge, Office and Microsoft 365, Explorer, the lock screen, the taskbar, activity and clipboard, Copilot and Windows AI, mobile devices, miscellaneous and gaming. Every setting comes with:
- a plain explanation of what it does and what Windows or Microsoft can collect;
- the benefit of turning it off, what you lose, and any problems it can cause;
- a recommendation (**DISABLE**, **OPTIONAL**, **KEEP ENABLED**) and a **privacy impact** rating (Low / Medium / High);
- the O&O ShutUp10++ ID where known (U008, L005, L008, M029-M031, M103, W010, E157, F020, F021, P099, C208-C211).

Filter by section, by advice and by search (including O&O IDs). **Choose all recommended** marks every DISABLE item. It uses the same choose-then-apply flow, backups and undo as Tweaks. Only settings BLOB can actually change are listed. Microsoft Defender, automatic security updates and Windows activation are never changed and are not shown. The full text of all entries is in [docs/PRIVACY-SETTINGS.md](docs/PRIVACY-SETTINGS.md).

**Appearance: how Windows looks.** Three theme tiles at the top (**Light**, **Dark**, **Mixed**: light apps with a dark taskbar) drawn as a small preview, then 16 switches in five groups:
- *Colours and theme:* dark mode for apps, dark mode for Windows, transparency, accent colour from the wallpaper, accent colour on title bars, accent colour on Start and taskbar;
- *Taskbar:* align left, seconds in the clock, never combine buttons;
- *Start menu:* more pins;
- *File Explorer:* compact view, full path in the title bar, check boxes to select files;
- *Desktop and scrolling:* This PC on the desktop, full-quality wallpaper, always show scroll bars.

Everything is per user (no administrator rights), uses the same choose-then-apply flow and undo as Tweaks, and is never part of a preset. After applying, Windows is told to refresh its colours, so dark mode switches without signing out. Switching off something that was already on before BLOB (dark mode, for example) sets the Windows default value and is recorded too, so undo returns exactly what you had. Links open Windows' own pages for a fixed accent colour, the background and themes.

**Apps: complete removal.** Every installed program (86 on a typical PC) and Microsoft Store app, with size, install date, search and sorting. **Uninstall** removes an app completely, in three steps:
1. **Its own uninstaller runs first.** The program undoes its own drivers, services and file associations the way its maker intended. Store apps are removed by Windows together with their app data.
2. **Leftover scan.** Only once Windows no longer lists the program, BLOB looks for folders (Program Files, AppData, ProgramData), registry keys, Start menu and desktop shortcuts and startup entries that carry its exact name. If the uninstaller was cancelled, nothing is scanned or removed.
3. **You choose.** Everything found is listed with a checkbox. Folders and shortcuts go to the **Recycle Bin**. Registry keys are **exported to .reg** before removal and can be restored from Restore. Startup entries go through the normal undo journal.

Shared folders (`Microsoft`, `Common Files`, `WindowsApps`, `Packages` …) are never removed. Components Windows needs (Edge, WebView2, Microsoft Store, App Installer, Windows Security) are protected, and shared runtimes (Visual C++, .NET, drivers) are flagged *Shared component* with a warning.

**Install: popular apps with winget.** 49 well-known apps in 10 groups (browsers, gaming, communication, media, utilities, hardware info, passwords, documents, development, runtimes). Tick what you want and choose **Install selected**. Apps already on the PC are marked *Installed*. **Update all apps** runs `winget upgrade --all`. Packages come from the official winget repository through winget, which is built into Windows 10/11 (App Installer); BLOB itself downloads nothing. Without winget the page links to App Installer in the Microsoft Store. Remove installed apps on the Apps page.

**Measure: honest before/after numbers.** Boot times come from Windows' own boot performance log (last boot and the average of the last 5; reading it needs administrator rights). **Take a snapshot** records memory in use, processes, running services, startup programs, tweaks on and free space. Take one before a preset and one after a restart, and BLOB compares the first and the latest in plain words; differences under 5% are called *about the same*. No numbers are invented and no gains are promised.

**Undo everything.** One button on the Restore page that returns every restorable change BLOB ever made, with a restore-point option first.

**Instant pages.** Every page preloads in the background a few seconds after the window opens, so switching is instant. Slow system information (network, disks, security status, services, cleanup sizes) is collected on three parallel background threads inside the same PowerShell process, and these threads are closed when the window closes. After you change something, the current page refreshes immediately and other affected pages refresh quietly in the background.

**Help on every tweak.** Hover the **?** for what it does, why you might want it, the trade-off, the exact registry or service change (current → new), whether it needs admin rights and how to undo it. Hover the risk meter for what the level means.

**Restore point on apply.** Every apply confirmation, including presets, has a *Create a System Restore point first* checkbox. It is ticked by default when running as administrator. BLOB OPTIMIZER tells you honestly if Windows skipped the restore point because one was already made in the last 24 hours.

**External tools.** One-click launchers for [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil) and [O&O ShutUp10++](https://www.oo-software.com/en/shutup10). See *Third-party tools* below.

**Terminal (`-Tui`).** The full keyboard-driven terminal UI. It has the same features and uses the same engine and the same backup journal.

## What it does

| Section | Contents |
|---|---|
| **Performance** | Menu delay, startup delay, Store background apps, Edge background/startup boost, visual effects, transparency, multimedia scheduling, file I/O (last-access writes, 8.3 names), Explorer folder loading, drive optimization (TRIM/defrag), live memory/CPU view |
| **Gaming** | Game Mode, Game DVR, mouse acceleration, Sticky Keys prompt, GPU scheduling, fullscreen optimizations, MMCSS priority, power throttling, foreground priority, Multiplane Overlay fix, Xbox services, Xbox button, network throttling, update sharing (Delivery Optimization). **No FPS gains are promised.** |
| **Tweaks** | File Explorer (extensions, This PC, hidden files, recent files), taskbar (search, Task View, Widgets, End task, alignment), Start (recommendations, web search), classic context menu, long paths |
| **Appearance** | Dark/light/mixed theme, accent colour, transparency, taskbar (alignment, clock seconds, button combining), Start pins, File Explorer view, desktop icon, wallpaper quality, scroll bars |
| **Privacy** | Advertising ID, tailored experiences, suggestions and auto-installed apps, lock screen ads, diagnostic data level, feedback, inking, activity history, Recall snapshots, DiagTrack service, Firefox / Chrome / Edge telemetry policies |
| **Services** | Curated review with explanations and recommended startup types, plus a browser of every service. Only startup types are changed, and critical services are protected |
| **Startup** | Run keys and Startup folders. Entries are disabled with the same mechanism Task Manager uses, so nothing is deleted |
| **Cleanup** | Temp files, thumbnail cache, crash dumps, WER reports, DirectX shader cache, Windows Update download cache, Recycle Bin, with a size preview first. Storage and disk health |
| **Network** | Adapter information, diagnostics (only when you start them), DNS presets or custom servers, DNS flush, IP renew, Winsock/TCP-IP reset |
| **Power** | Switch plans, add High/Ultimate Performance, display/sleep timeouts, hibernation |
| **Restore** | Change history, restore individual changes or a whole session, `.reg` snapshots, System Restore points, JSON config export/import |
| **Presets** | **MINIMAL**, **STANDARD**, **ADVANCED**. Each one lists every setting it will change (current value → new value) and waits for you to press `Y` |

### Terminal keys

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
- It never touches Microsoft Defender, Windows Firewall, SmartScreen, UAC or antivirus exclusions, and it never switches off automatic security updates. (The Privacy page offers only optional update preferences: driver updates, preview builds, feature-upgrade delay, update sharing and Store auto-updates.)

### Files it creates

Files are created only after you make your first real change. Dry runs and browsing write nothing.

```
%LOCALAPPDATA%\BLOB-OPTIMIZER\
  changes.json          change journal (originals for restore)
  logs\session-*.log    operation logs
  registry-backups\     .reg snapshots taken before each batch
  measurements.json     snapshots from the Measure page
```

Delete that folder at any time to remove all traces. Configuration exports go wherever you choose (Documents by default).

## Third-party tools

The **External Tools** page (or `T` in the terminal UI) can launch two well-known tools made by other developers. Nothing is downloaded until you click **Launch** and confirm a dialog that shows the exact source address.

| Tool | Source | How it runs |
|---|---|---|
| Chris Titus Tech's WinUtil | `https://christitus.com/win` | Opens a separate administrator PowerShell window (Windows asks for permission) and runs `irm https://christitus.com/win \| iex` |
| O&O ShutUp10++ | `https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe` | Downloads to `%TEMP%\BLOB-OPTIMIZER-tools`, **checks that the Authenticode signature is valid and from O&O Software**, and only then starts it. If the check fails, the file is deleted |

Changes made inside these tools are **not** recorded by BLOB OPTIMIZER and cannot be undone from Restore. Use their own undo options and a System Restore point (offered in the launch dialog).

## Transparency and antivirus

- The source is plain, readable PowerShell with no obfuscation, no encoded commands, no hidden windows and no `-EncodedCommand`.
- It downloads nothing at runtime unless you explicitly launch a third-party tool from External Tools. It creates no services, scheduled tasks, Run keys or background processes.
- It makes network connections only when you start a diagnostic or launch an external tool. The address is always shown first.
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
├── BLOB.cmd                 double-click / cmd launcher for a local copy of BLOB.ps1
├── README.md  CHANGELOG.md
├── src/                     readable source modules (edit these)
│   ├── Core.ps1             state, journal, registry/service engine, restore
│   ├── UI.ps1               terminal UI toolkit ([Console] only)
│   ├── Engine.ps1           tweak catalogue, preview/apply/undo, presets
│   ├── Dashboard.ps1        logo, system summary, main menu, system info
│   ├── Performance.ps1  Gaming.ps1  Tweaks.ps1  Privacy.ps1
│   ├── Services.ps1  Startup.ps1  Cleanup.ps1  Network.ps1  Power.ps1
│   ├── Restore.ps1          history, snapshots, restore points, export/import
│   ├── TweakDetails.ps1     risk levels and detailed per-setting explanations
│   ├── ExternalTools.ps1    WinUtil / ShutUp10++ launchers with signature check
│   ├── PrivacyCenter.ps1  PrivacyData1-3.ps1   privacy page engine and catalogue
│   ├── Apps.ps1             complete app removal and leftover scan
│   ├── Appearance.ps1       dark mode, colours, taskbar, Start and Explorer look
│   ├── Drift.ps1            detects settings Windows changed back, re-applies them
│   ├── Measure.ps1          boot times and before/after snapshots
│   ├── Winget.ps1           app catalogue and winget install/upgrade
│   ├── Prefetch.ps1         parallel background data collection
│   ├── GuiXaml.ps1          window markup and dark theme (WPF XAML)
│   ├── Gui.ps1              window shell, navigation, dialogs, activity log
│   ├── GuiPages.ps1         dashboard, presets, tweak sections, system info
│   ├── GuiSystem.ps1        services, startup, cleanup, network, power, restore
│   ├── GuiApps.ps1  GuiPrivacy.ps1   apps and privacy pages
│   ├── GuiExtras.ps1        install, measure, drift bar, Ctrl+K search, change summary
│   └── Main.ps1             entry point, interface choice, self-test
├── config/presets.json      preset definitions (embedded at build time)
├── build/Build-Release.ps1  concatenates src/ into BLOB.ps1
├── tests/Test-Engine.ps1    apply → journal → restore round-trip test
├── tests/Render-Gui.ps1     renders every window page to PNG (dry run)
└── docs/TESTING.md          release testing checklist
```

Build a release:

```powershell
powershell -NoProfile -File .\build\Build-Release.ps1 -Repository Pientje0/BLOB-OPTIMIZER
```

The build wraps every module in one script block, so no functions or variables leak into the user's session. It embeds `presets.json`, fails if the output contains non-ASCII characters or syntax errors, and writes the SHA-256 file.

**Optional code signing.** Pass the thumbprint of a code-signing certificate (in `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My`) and the build signs `BLOB.ps1` with Authenticode (SHA-256, timestamped), checks that the signature is valid and only then writes the checksum. Without `-CertThumbprint` the build is unchanged.

```powershell
powershell -NoProfile -File .\build\Build-Release.ps1 -CertThumbprint <thumbprint>
```

`-TimestampServer` picks another RFC 3161 server (default `http://timestamp.digicert.com`). A signed script lets people check who built it with `Get-AuthenticodeSignature .\BLOB.ps1`; note that `irm | iex` runs the text and does not check signatures.

Add a tweak by calling `Register-BlobTweak` in the section file with an `Id`, a `Risk` level and its `Registry` or `Services` operations. State detection, preview, backup, undo and presets work for it automatically.

Requirements: Windows 10/11 and Windows PowerShell 5.1 or PowerShell 7+. The window interface uses WPF, which is built into Windows. No modules, packages or external tools are needed (the Install page uses winget when Windows has it). It only uses built-in commands such as `reg.exe`, `sc.exe`, `powercfg.exe`, `netsh.exe` and `ipconfig.exe`.

## Disclaimer

BLOB OPTIMIZER changes Windows settings. Results depend on your hardware and configuration, and no performance improvement is guaranteed. Review every preview and use dry run if you are unsure. Inspired by the distribution model of Chris Titus Tech's Windows Utility. It is an independent project and not affiliated with it.
