# ============================================================================
#  BLOB OPTIMIZER - Performance.ps1
#  Responsiveness tweaks, background apps, visual effects, memory info.
# ============================================================================

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

Register-BlobTweak @{
    Id = 'perf.menudelay'; Section = 'Performance'; Group = 'Responsiveness'; Risk = 'Minimal'
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
    Id = 'perf.transparency'; Section = 'Performance'; Group = 'Visual effects'; Risk = 'Optional'
    Name = 'Disable transparency effects'
    Description = 'Turns off the acrylic/blur transparency in Start, taskbar and Settings. Mostly a visual preference.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'perf.sysresp'; Section = 'Performance'; Group = 'Scheduling'; Risk = 'Advanced'
    Name = 'Prioritise foreground multimedia'
    Description = 'Lowers SystemResponsiveness from 20 to 10 so the multimedia scheduler reserves less CPU for background tasks.'
    Registry = @(@{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Value = 10 })
    Warning = 'Effect varies by system and workload; benefits are not guaranteed.'
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

function Show-BlobPerformance {
    Show-BlobTweakSection -Section 'Performance' -Crumb 'Performance' -Intro @(
        '{White}Performance', '{Gray}Space selects, A applies with a full preview, U restores the saved original values.') -Extras @(
        @{ Label = 'Memory and resource information'; Detail = 'Live RAM, commit, CPU load and the top processes by memory.'
           Action = { $null = Show-BlobText -Crumb 'Performance > Resources' -Lines (Get-BlobMemoryInfo) } },
        @{ Label = 'Current performance settings'; Detail = 'Visual effects, transparency, Game Mode, page file and power plan.'
           Action = { $null = Show-BlobText -Crumb 'Performance > Settings' -Lines (Get-BlobPerfSettingsInfo) } },
        @{ Label = 'Manage startup programs'; Detail = 'Opens the Startup section.'; Action = { Show-BlobStartup } },
        @{ Label = 'Open Windows Performance Options'; Detail = 'Launches the built-in SystemPropertiesPerformance dialog for manual fine tuning.'
           Action = { Start-Process 'SystemPropertiesPerformance.exe' -ErrorAction SilentlyContinue } }
    )
}
