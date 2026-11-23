# ============================================================================
#  BLOB OPTIMIZER - TweakDetails.ps1
#  Plain-language explanations shown in the "?" help of every setting:
#  what it does, why you might want it, and the trade-off.
# ============================================================================

$Blob.RiskInfo = @{
    Minimal  = @{ Label = 'LOW RISK'; Color = 'Green'; Text = 'Low risk. A small, well-understood setting that does not affect stability, security or compatibility.' }
    Standard = @{ Label = 'MEDIUM RISK'; Color = 'Cyan'; Text = 'Medium risk. Changes a Windows feature or default behaviour. Safe for most PCs, but you may notice a feature behaving differently.' }
    Advanced = @{ Label = 'HIGH RISK'; Color = 'Yellow'; Text = 'Higher risk. Affects scheduling, drivers or system services. Results vary per PC. Create a restore point and test afterwards.' }
    Optional = @{ Label = 'PREFERENCE'; Color = 'Gray'; Text = 'Personal preference. Not an optimization: it only changes how Windows looks or behaves. Never part of a preset.' }
}

$Blob.TweakDetails = @{
    'perf.menudelay'     = 'Windows waits 400 ms before opening a submenu when you hover it. This lowers the wait to 100 ms so menus such as the right-click "Send to" open almost instantly. Purely a feel change; nothing else is affected.'
    'perf.startupdelay'  = 'After sign-in, Explorer deliberately waits several seconds before starting your startup programs, to keep the desktop responsive. Removing the delay starts them right away. On slow hard drives the desktop can feel busier for the first minute.'
    'perf.bgapps'        = 'Microsoft Store (UWP) apps can keep running in the background to refresh live tiles, receive notifications and sync. This blocks that globally. Classic desktop programs (Steam, Discord, Chrome) are not affected. Store apps like Mail or Phone Link will only update while open.'
    'perf.visualfx'      = 'Switches visual effects to a custom set: no minimize/maximize animation, no taskbar animations and no Aero Peek preview. Font smoothing and thumbnails stay on, so Windows still looks normal. Helps most on older or integrated graphics.'
    'perf.transparency'  = 'Turns off the blurred, see-through (acrylic) background in Start, the taskbar, Action Center and Settings. Saves a small amount of GPU work; mostly a visual preference.'
    'perf.sysresp'       = 'The Multimedia Class Scheduler reserves 20% of CPU time for background work while multimedia apps run. Setting SystemResponsiveness to 10 reserves only 10%, giving foreground audio/video/games slightly more. Effect is usually small and depends on the workload.'
    'game.gamemode'      = 'Game Mode tells Windows to give the running game priority, and to hold off Windows Update driver installs and restart notifications while you play. It is on by default in recent Windows; this makes sure it is enabled.'
    'game.dvr'           = 'Xbox Game Bar can continuously record the last minutes of gameplay in the background so you can "record what happened". That recording costs GPU encoder time and disk writes. This turns background recording off; you can still take screenshots and start recordings manually with Win+G.'
    'game.mouseaccel'    = 'With "Enhance pointer precision" on, the pointer moves further when you move the mouse faster. Many players prefer it off so the same hand movement always moves the same distance (1:1 aim). Purely a preference.'
    'game.stickykeys'    = 'Pressing Shift five times opens a Sticky Keys prompt, which often interrupts games. This disables only that keyboard shortcut. Sticky Keys itself stays available in Settings > Accessibility if you need it.'
    'game.hags'          = 'Hardware-accelerated GPU scheduling lets the graphics card manage its own memory queue instead of Windows. On recent GPUs and drivers it can reduce latency a little; on some systems it causes stutter or issues with capture software. Requires a restart and a supported GPU (NVIDIA 10-series / AMD RX 5000 or newer).'
    'game.fso'           = 'Windows normally runs "exclusive fullscreen" games in an optimized borderless mode so overlays and Alt+Tab work smoothly. Disabling it globally forces true exclusive fullscreen. Some older games run better; newer games and overlays may behave worse. Test per game.'
    'game.mmcss'         = 'Raises the priority of the "Games" task in the Multimedia Class Scheduler (GPU priority 8, CPU priority 6, High scheduling category). Only games that register with MMCSS benefit. There is no guaranteed FPS change.'
    'tw.fileext'         = 'File Explorer hides known extensions by default, so "invoice.pdf.exe" shows as "invoice.pdf". Showing extensions makes it obvious what type every file really is - a useful safety improvement.'
    'tw.thispc'          = 'File Explorer opens on Home (recent files and Quick access). This makes it open on This PC, which shows your drives and main folders directly.'
    'tw.hidden'          = 'Shows files and folders marked as hidden, such as AppData. Protected operating system files remain hidden. Useful for troubleshooting; some people find the extra items cluttered.'
    'tw.recent'          = 'Explorer Home lists recently opened files and frequently used folders. Turning this off keeps that list empty - useful on shared screens or for privacy. Your files are not touched.'
    'tw.searchicon'      = 'Replaces the wide search box on the taskbar with a small search icon, freeing taskbar space. Search works exactly the same (also via the Windows key).'
    'tw.taskview'        = 'Removes the Task View (virtual desktops) button from the taskbar. Task View is still available with Win+Tab.'
    'tw.widgets'         = 'Disables the Widgets board (news, weather, stocks) and its taskbar button using the official Windows policy. Stops the news feed from loading in the background.'
    'tw.endtask'         = 'Adds an "End task" option when you right-click an app on the taskbar (Windows 11 23H2 and newer), so you can close a frozen program without opening Task Manager. Unsaved work in that app is lost, as with Task Manager.'
    'tw.leftalign'       = 'Moves the Start button and taskbar icons from the center to the left, like Windows 10. Purely visual.'
    'tw.startrecs'       = 'Stops the Start menu from tracking and showing recently opened files and promoted app recommendations in the "Recommended" section.'
    'tw.websearch'       = 'Start menu search normally also sends your typing to Bing and shows web results. This applies the official policy so search only shows local apps, files and settings - faster and more private.'
    'tw.classicmenu'     = 'Windows 11 shows a shortened right-click menu with "Show more options". This makes the full classic menu appear immediately. Undo removes the registry keys again. A future Windows update could stop honouring this.'
    'tw.verbose'         = 'Instead of a generic "Please wait" during sign-in, sign-out and shutdown, Windows shows what it is doing (for example "Stopping services"). Useful to see what is slow. No performance effect.'
    'tw.longpaths'       = 'Lets programs that support it use file paths longer than the classic 260-character limit (common with deep project folders and Node.js). Programs that do not support long paths are not changed.'
    'tw.snapsuggest'     = 'When you snap a window to one side, Windows suggests other windows to fill the remaining space. This turns off those suggestions; snapping itself still works.'
    'tw.settingsads'     = 'Stops the recurring full-screen "Let us finish setting up your device" screen that promotes Microsoft account, OneDrive and Microsoft 365 after updates.'
    'pv.adid'            = 'Windows gives each user an advertising ID that apps can read to show personalised ads and track you across apps. Disabling it gives apps a blank ID instead. Ads are not removed, only less personalised.'
    'pv.tailored'        = 'Allows Microsoft to use your diagnostic data to personalise tips, ads and recommendations. Turning it off stops that use. It does not change how much diagnostic data is collected.'
    'pv.suggestions'     = 'Turns off several "suggested content" switches: app suggestions in Start, tips in Settings, Windows tips and the silent automatic installation of promoted apps (such as games appearing in Start). Apps that are already installed are not removed.'
    'pv.lockscreen'      = 'Removes "fun facts, tips, tricks and more" and promotional overlays from the lock screen. Your lock screen picture stays.'
    'pv.diag'            = 'Applies the official diagnostic data policy at "Required" - the minimum level Home and Pro support. Windows keeps sending only the data needed to stay secure and up to date. Settings will show "managed by your organization" for this option; that is normal for policies.'
    'pv.feedback'        = 'Sets "Feedback frequency" to Never, so Windows stops popping up surveys asking how you like features. You can still send feedback manually with the Feedback Hub.'
    'pv.inking'          = 'Windows can learn from your typing and handwriting to build a personal dictionary for better suggestions. This stops collecting that data. Text suggestions become less personalised.'
    'pv.diagtrack'       = 'Sets the "Connected User Experiences and Telemetry" (DiagTrack) service to Disabled, so it no longer starts and uploads diagnostic data. It is not a security component. Windows Insider builds and Feedback Hub rely on it. Undo restores the original startup type.'
    'pv.activity'        = 'Activity history records which apps, files and websites you use so Timeline and "pick up where you left off" can work, and can upload it. This official policy stops collecting and uploading it.'
    'pv.apptracking'     = 'Windows tracks which apps you launch to improve Start and search results (the "Most used" list). Turning it off stops that tracking; the Most used list no longer updates.'
    'perf.lastaccess'    = 'Every time a file is read, NTFS can write a "last accessed" timestamp back to disk - extra small writes on every file open. Turning it off (the same as "fsutil behavior set disablelastaccess 1") removes those writes. Backup or sync tools that rely on last-access dates are rare. Takes effect after a restart.'
    'perf.8dot3'         = 'For compatibility with DOS, NTFS can give every new file a second short name like PROGRA~1. Creating them slows folders that hold many thousands of files. Disabling it only affects files created afterwards; existing short names stay. Very old installers and 16-bit programs are the only things that may care.'
    'perf.edgeboost'     = 'Startup Boost preloads Microsoft Edge processes at sign-in so it opens faster, and background mode keeps Edge running after you close the window (for extensions and notifications). Both use memory and CPU even when you never open Edge. These official policies turn both off.'
    'perf.folderdiscovery' = 'Explorer inspects the files in every folder to guess whether it is a Pictures, Music, Videos or Documents folder, and picks columns and views from that. In folders with many files this "folder type discovery" makes opening noticeably slow. This sets all folders to the general type so they open immediately.'
    'game.powerthrottle' = 'Power throttling (EcoQoS) lets Windows run background and minimized apps on efficient cores or at lower clock speeds to save energy. If a game, launcher or streaming tool is treated as background work it can get throttled. Turning it off means no process is ever slowed to save power - better consistency, higher power use.'
    'game.priority'      = 'Win32PrioritySeparation controls how the CPU scheduler shares time between programs. The value 38 (hex 26) uses short, variable time slices and gives the foreground window a 3x boost, which some players find smoother. Background work gets less CPU while you play. The default value is 2.'
    'game.mpo'           = 'Multiplane Overlay lets the GPU compose some layers (like video or a game) directly instead of through the desktop compositor. With some NVIDIA/AMD drivers it causes flickering, black screens or stutter, and Microsoft documents OverlayTestMode = 5 as the workaround. Only use it if you have those symptoms.'
    'game.xbox'          = 'Xbox Live Auth Manager, Xbox Live Game Save and Xbox Live Networking Service run on demand for the Xbox app, PC Game Pass and games that use Xbox sign-in or cloud saves. Disabling them stops them from ever starting. If you play Game Pass or Microsoft Store games, keep them on. The Xbox controller service is not touched.'
    'game.nexus'         = 'By default the Guide (Xbox) button on a controller opens Xbox Game Bar, which can interrupt fullscreen games. This makes the button do nothing in Windows, while Game Bar stays available with Win+G.'
    'game.netthrottle'   = 'The Multimedia Class Scheduler limits how many non-multimedia network packets Windows processes per millisecond while audio or video plays (NetworkThrottlingIndex, default 10). Setting it to 0xFFFFFFFF removes the limit. It mainly helps transfer speeds on very fast connections while media plays; it is not a ping fix.'
    'game.dopeer'        = 'Delivery Optimization can download Windows and Store updates from, and upload them to, other PCs on your network or the internet. Upload can use bandwidth while you game. This official policy (DODownloadMode = 0) downloads only straight from Microsoft and never uploads to other PCs.'
    'pv.recall'          = 'Recall on Copilot+ PCs takes regular snapshots of your screen so you can search your activity later. This official policy turns off saving those snapshots for your account. PCs without Recall are unaffected.'
    'pv.firefox'         = 'Uses Firefox enterprise policies to turn off Firefox telemetry (usage and performance data sent to Mozilla) and the "default browser agent" scheduled task that reports which browser is your default. Firefox will say it is managed by your organization; that only means a policy is set.'
    'pv.chrome'          = 'Uses the official Chrome policy MetricsReportingEnabled = 0, which stops Chrome sending usage statistics and crash reports to Google and locks that option off. Chrome will say it is managed by your organization; that only means a policy is set.'
    'pv.edgediag'        = 'Uses official Edge policies to send only required diagnostic data (DiagnosticData = 0) and to stop sending browsing history for ads, search and news personalization (PersonalizationReportingEnabled = 0).'
    'pv.copilot'         = 'Applies the official TurnOffWindowsCopilot policy for your account, which hides the Windows Copilot sidebar on builds that respect it. Newer Copilot app versions may ignore this policy.'
}

function Get-BlobTweakExplanation {
    param($Tweak)
    if ($Blob.TweakDetails.ContainsKey($Tweak.Id)) { return $Blob.TweakDetails[$Tweak.Id] }
    return $Tweak.Description
}
