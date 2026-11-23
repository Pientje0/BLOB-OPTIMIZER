# ============================================================================
#  BLOB OPTIMIZER - Performance.ps1
#  Responsiveness tweaks, background apps, visual effects, memory info.
# ============================================================================

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

Register-BlobTweak @{
    Id = 'perf.menudelay'; Category = 'Quality of Life'; Section = 'Performance'; Group = 'Responsiveness'; Risk = 'Minimal'
    Name = 'Faster menu display'
    Description = 'Reduces the delay before cascading menus open from 400 ms to 100 ms.'
    Registry = @(@{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay'; Value = '100'; Type = 'String' })
    Note = 'Applies after sign-out.'
}
Register-BlobTweak @{
    Id = 'perf.startupdelay'; Section = 'Performance'; Group = 'Responsiveness'; Risk = 'Standard'
    Name = 'Remove startup app delay'
    Description = 'Windows waits a few seconds before launching startup apps. This removes that artificial delay.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name = 'StartupDelayInMSec'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'perf.bgapps'; Section = 'Performance'; Group = 'Background apps'; Risk = 'Standard'
    Name = 'Stop Store apps running in the background'
    Description = 'Prevents Microsoft Store apps from running when not open. Desktop programs are not affected.'
    Registry = @(
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Value = 1 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'BackgroundAppGlobalToggle'; Value = 0 })
    Note = 'Some Store apps (e.g. Mail, Phone Link) will not notify you while closed.'
}
Register-BlobTweak @{
    Id = 'perf.visualfx'; Section = 'Performance'; Group = 'Visual effects'; Risk = 'Standard'
    Name = 'Lighter visual effects'
    Description = 'Turns off window minimize/maximize animation, taskbar animations and Aero Peek. Fonts stay smooth.'
    Registry = @(
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Value = 3 },
        @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Value = '0'; Type = 'String' },
        @{ Path = $adv; Name = 'TaskbarAnimations'; Value = 0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Value = 0 })
    Note = 'Applies after sign-out.'; RestartExplorer = $true
}
Register-BlobTweak @{
    Id = 'perf.transparency'; Category = 'Quality of Life'; Section = 'Performance'; Group = 'Visual effects'; Risk = 'Optional'
    Name = 'Disable transparency effects'
    Description = 'Turns off the acrylic/blur transparency in Start, taskbar and Settings. Mostly a visual preference.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'perf.sysresp'; Category = 'FPS & Latency'; Section = 'Performance'; Group = 'Scheduling'; Risk = 'Advanced'
    Name = 'Prioritise foreground multimedia'
    Description = 'Lowers SystemResponsiveness from 20 to 10 so the multimedia scheduler reserves less CPU for background tasks.'
    Registry = @(@{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Value = 10 })
    Warning = 'Effect varies by system and workload; benefits are not guaranteed.'
}

Register-BlobTweak @{
    Id = 'perf.lastaccess'; Section = 'Performance'; Group = 'Storage and I/O'; Risk = 'Standard'
    Name = 'Optimize file I/O (no last-access writes)'
    Description = 'Stops NTFS from writing a "last opened" timestamp every time a file is read, saving disk writes.'
    Registry = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'NtfsDisableLastAccessUpdate'; Value = 2147483649 })
    Note = 'Applies after restart. Many recent Windows installs already have this behaviour.'
}
Register-BlobTweak @{
    Id = 'perf.8dot3'; Section = 'Performance'; Group = 'Storage and I/O'; Risk = 'Advanced'
    Name = 'Disable 8.3 short file names'
    Description = 'Stops NTFS creating legacy DOS-style short names (PROGRA~1) for new files, which speeds up folders with many files.'
    Registry = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'NtfsDisable8dot3NameCreation'; Value = 1 })
    Warning = 'Very old installers or 16-bit software may expect short names. Only affects files created afterwards.'
}
Register-BlobTweak @{
    Id = 'perf.edgeboost'; Section = 'Performance'; Group = 'Background apps'; Risk = 'Standard'
    Name = 'Stop Microsoft Edge running in the background'
    Description = 'Turns off Edge Startup Boost and background mode, so Edge does not preload at sign-in or keep running after you close it.'
    Registry = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'StartupBoostEnabled'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'BackgroundModeEnabled'; Value = 0 })
    Note = 'Edge may open a moment slower. Edge shows "managed by your organization" for policies.'
}
Register-BlobTweak @{
    Id = 'perf.folderdiscovery'; Section = 'Performance'; Group = 'Responsiveness'; Risk = 'Standard'; RestartExplorer = $true
    Name = 'Optimize Windows Explorer folder loading'
    Description = 'Stops Explorer scanning folder contents to guess a folder type (Pictures, Music...), which makes large folders open faster.'
    Registry = @(@{ Path = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'; Name = 'FolderType'; Value = 'NotSpecified'; Type = 'String' })
    Note = 'Folders use the general layout; you can still change view per folder.'
}

function Get-BlobMemoryInfo {
    $lines = @('{Cyan}Memory and resources', '')
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $total = [double]$os.TotalVisibleMemorySize * 1KB
        $free = [double]$os.FreePhysicalMemory * 1KB
        $used = $total - $free
        $lines += ("{{Gray}}RAM in use    {0}  {{White}}{1} / {2}  {{DarkGray}}({3:N0}%)" -f (Format-BlobBar ($used / $total) 30), (Format-BlobSize $used), (Format-BlobSize $total), (100 * $used / $total))
        $cTotal = [double]$os.TotalVirtualMemorySize * 1KB; $cFree = [double]$os.FreeVirtualMemory * 1KB
        $lines += ("{{Gray}}Commit        {0}  {{White}}{1} / {2}" -f (Format-BlobBar (($cTotal - $cFree) / $cTotal) 30), (Format-BlobSize ($cTotal - $cFree)), (Format-BlobSize $cTotal))
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average).Average
        if ($null -ne $cpu) { $lines += ("{{Gray}}CPU load      {0}  {{White}}{1:N0}%" -f (Format-BlobBar ($cpu / 100) 30), $cpu) }
        $lines += ("{{Gray}}Processes     {{White}}{0}" -f (Get-Process).Count)
        $up = (Get-Date) - $os.LastBootUpTime
        $lines += ("{{Gray}}Uptime        {{White}}{0}d {1}h {2}m" -f $up.Days, $up.Hours, $up.Minutes)
    } catch { $lines += "{Red}Could not read memory information: $($_.Exception.Message)" }
    $lines += ''; $lines += '{Cyan}Top processes by memory (working set)'; $lines += ''
    $lines += '{DarkGray}  NAME                              MEMORY       CPU TIME'
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 | ForEach-Object {
        $cpuT = if ($_.CPU) { '{0:N0}s' -f $_.CPU } else { '-' }
        $lines += ('{{White}}  {0,-32}  {{Gray}}{1,10}   {{DarkGray}}{2,9}' -f ($_.ProcessName -replace '[{}]', ''), (Format-BlobSize $_.WorkingSet64), $cpuT)
    }
    $lines += ''; $lines += '{DarkGray}Information only. BLOB OPTIMIZER never "cleans" RAM - Windows manages memory well on its own.'
    return $lines
}

function Get-BlobPerfSettingsInfo {
    $lines = @('{Cyan}Windows performance settings', '')
    $vfx = Get-BlobRegState 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting'
    $vfxName = switch ($vfx.Value) { 0 { 'Let Windows choose' } 1 { 'Best appearance' } 2 { 'Best performance' } 3 { 'Custom' } default { 'Let Windows choose (default)' } }
    $lines += "{Gray}Visual effects mode     {White}$vfxName"
    $tr = Get-BlobRegState 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency'
    $lines += "{Gray}Transparency            {White}" + $(if ($tr.Exists -and $tr.Value -eq 0) { 'Off' } else { 'On' })
    $gm = Get-BlobRegState 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'
    $lines += "{Gray}Game Mode               {White}" + $(if ($gm.Exists -and $gm.Value -eq 0) { 'Off' } else { 'On (default)' })
    $bg = Get-BlobRegState 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled'
    $lines += "{Gray}Store background apps   {White}" + $(if ($bg.Exists -and $bg.Value -eq 1) { 'Blocked' } else { 'Allowed' })
    $lines += "{Gray}Active power plan       {White}$((Get-BlobActivePowerPlan).Name)"
    try {
        $pf = Get-CimInstance Win32_PageFileUsage -ErrorAction Stop
        foreach ($p in $pf) { $lines += ("{{Gray}}Page file               {{White}}{0}  {{DarkGray}}({1} MB allocated, {2} MB peak)" -f $p.Name, $p.AllocatedBaseSize, $p.PeakUsage) }
        $auto = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).AutomaticManagedPagefile
        $lines += "{Gray}Page file management    {White}" + $(if ($auto) { 'Automatic (recommended)' } else { 'Manual' })
    } catch { }
    $lines += ''
    $lines += '{DarkGray}Startup programs are managed in the Startup section; services in Services.'
    return $lines
}

# Runs Windows' own drive optimizer: TRIM for SSDs, defragmentation for hard drives.
function Invoke-BlobOptimizeDrives {
    param([scriptblock]$Log = { param($m) })
    if (-not $Blob.IsAdmin) { & $Log '{Yellow} SKIP {White}Optimize drives {Gray}(administrator rights required)'; return }
    $vols = @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -and $_.FileSystem -in @('NTFS', 'ReFS') })
    foreach ($v in $vols) {
        $label = "Drive $($v.DriveLetter):"
        if ($Blob.DryRun) { & $Log "{Magenta} DRY  {White}$label would be optimized"; continue }
        & $Log "{Gray}Optimizing $label (SSD: TRIM, HDD: defragment) - this can take a while..."
        try {
            Optimize-Volume -DriveLetter $v.DriveLetter -ErrorAction Stop
            & $Log "{Green} OK   {White}$label optimized"
            Add-BlobActionRecord -Source 'performance' -Label "Optimized drive $($v.DriveLetter):" -Target $label
        } catch { & $Log "{Yellow} SKIP {White}$label {Gray}($($_.Exception.Message -replace '[{}]', ''))" }
    }
}

function Show-BlobPerformance {
    Show-BlobTweakSection -Section 'Performance' -Crumb 'Performance' -Intro @(
        '{White}Performance', '{Gray}Space selects, A applies with a full preview, U restores the saved original values.') -Extras @(
        @{ Label = 'Memory and resource information'; Detail = 'Live RAM, commit, CPU load and the top processes by memory.'
           Action = { $null = Show-BlobText -Crumb 'Performance > Resources' -Lines (Get-BlobMemoryInfo) } },
        @{ Label = 'Current performance settings'; Detail = 'Visual effects, transparency, Game Mode, page file and power plan.'
           Action = { $null = Show-BlobText -Crumb 'Performance > Settings' -Lines (Get-BlobPerfSettingsInfo) } },
        @{ Label = 'Manage startup programs'; Detail = 'Opens the Startup section.'; Action = { Show-BlobStartup } },
        @{ Label = 'Optimize drives now'; Detail = 'Runs the Windows drive optimizer: TRIM for SSDs, defragmentation for hard drives. Admin.'
           Action = { if (Confirm-BlobAction -Crumb 'Performance' -Question 'Optimize all fixed drives now?' -Lines @('{Gray}Uses the built-in Windows optimizer (Optimize-Volume). SSDs get TRIM, hard drives are defragmented.', '{Gray}Safe to run; hard drive defragmentation can take a long time.')) {
                   Start-BlobWork 'Performance'; Invoke-BlobOptimizeDrives -Log { param($m) Write-BlobWork $m }; Complete-BlobWork 'Drive optimization finished.' } } },
        @{ Label = 'Open Windows Performance Options'; Detail = 'Launches the built-in SystemPropertiesPerformance dialog for manual fine tuning.'
           Action = { Start-Process 'SystemPropertiesPerformance.exe' -ErrorAction SilentlyContinue } }
    )
}
