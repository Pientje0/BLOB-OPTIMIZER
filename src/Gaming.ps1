# ============================================================================
#  BLOB OPTIMIZER - Gaming.ps1
#  Game Mode, Game DVR, input and scheduling options.
#  No tweak here promises higher FPS: results depend on hardware and games.
# ============================================================================

Register-BlobTweak @{
    Id = 'game.gamemode'; Section = 'Gaming'; Group = 'Game Mode'; Risk = 'Minimal'
    Name = 'Enable Windows Game Mode'
    Description = 'Lets Windows prioritise the active game and pause Windows Update installs and notifications while playing.'
    Registry = @(
        @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AutoGameModeEnabled'; Value = 1 },
        @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AllowAutoGameMode'; Value = 1 })
}
Register-BlobTweak @{
    Id = 'game.dvr'; Section = 'Gaming'; Group = 'Game Mode'; Risk = 'Standard'
    Name = 'Disable background recording (Game DVR)'
    Description = 'Stops Xbox Game Bar from continuously recording gameplay in the background. Manual capture still works.'
    Registry = @(
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = 0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'game.mouseaccel'; Section = 'Gaming'; Group = 'Input'; Risk = 'Optional'
    Name = 'Disable mouse acceleration'
    Description = 'Turns off "Enhance pointer precision" for 1:1 mouse movement, preferred by many players.'
    Registry = @(
        @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed'; Value = '0'; Type = 'String' },
        @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Value = '0'; Type = 'String' },
        @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Value = '0'; Type = 'String' })
    Note = 'Applies after sign-out.'
}
Register-BlobTweak @{
    Id = 'game.stickykeys'; Section = 'Gaming'; Group = 'Input'; Risk = 'Standard'
    Name = 'Disable Sticky Keys shortcut prompt'
    Description = 'Stops the Sticky Keys dialog from appearing when Shift is pressed five times. Sticky Keys itself remains available in Settings.'
    Registry = @(@{ Path = 'HKCU:\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Value = '506'; Type = 'String' })
}
Register-BlobTweak @{
    Id = 'game.hags'; Section = 'Gaming'; Group = 'Graphics'; Risk = 'Advanced'
    Name = 'Hardware-accelerated GPU scheduling'
    Description = 'Lets a supported GPU manage its own memory scheduling. Requires a compatible GPU and driver.'
    Registry = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'HwSchMode'; Value = 2 })
    Warning = 'Requires a restart. Can help or hurt depending on GPU, driver and game - test and undo if needed.'
}
Register-BlobTweak @{
    Id = 'game.fso'; Section = 'Gaming'; Group = 'Graphics'; Risk = 'Advanced'
    Name = 'Disable fullscreen optimizations (global)'
    Description = 'Makes exclusive-fullscreen games use true exclusive mode instead of the optimised borderless path.'
    Registry = @(
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Value = 2 },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_HonorUserFSEBehaviorMode'; Value = 1 },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehavior'; Value = 2 },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_DXGIHonorFSEWindowsCompatible'; Value = 1 })
    Warning = 'May slow Alt+Tab and disable some overlays. Results vary per game.'
}
Register-BlobTweak @{
    Id = 'game.mmcss'; Section = 'Gaming'; Group = 'Scheduling'; Risk = 'Advanced'
    Name = 'Higher multimedia priority for games'
    Description = 'Raises the "Games" task priority in the Multimedia Class Scheduler (GPU Priority 8, Priority 6, High category).'
    Registry = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority'; Value = 8 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Value = 6 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Scheduling Category'; Value = 'High'; Type = 'String' })
    Warning = 'Only affects games that register with MMCSS. No guaranteed FPS change.'
}

function Get-BlobGamingStatus {
    $lines = @('{Cyan}Gaming status', '')
    foreach ($id in @('game.gamemode', 'game.dvr', 'game.hags', 'game.fso', 'game.mouseaccel', 'perf.bgapps')) {
        $t = Get-BlobTweak $id
        if ($t) { $lines += ('{{Gray}}{0,-44} {1}' -f $t.Name, (Format-BlobState (Get-BlobTweakState $t))) }
    }
    $lines += ''
    $lines += "{Gray}Active power plan                            {White}$((Get-BlobActivePowerPlan).Name)"
    try {
        foreach ($g in (Get-CimInstance Win32_VideoController -ErrorAction Stop)) {
            $lines += "{Gray}GPU                                          {White}$($g.Name)  {DarkGray}driver $($g.DriverVersion)"
        }
    } catch { }
    $lines += ''
    $lines += '{DarkGray}Honest note: these settings reduce background interference. They cannot guarantee'
    $lines += '{DarkGray}more FPS - GPU drivers, game settings and hardware matter far more.'
    return $lines
}

function Show-BlobGaming {
    Show-BlobTweakSection -Section 'Gaming' -Crumb 'Gaming' -Intro @(
        '{White}Gaming', '{Gray}Options that reduce background interference while gaming. No FPS gains are promised.') -Extras @(
        @{ Label = 'Gaming status overview'; Detail = 'Shows Game Mode, Game DVR, GPU scheduling, power plan and GPU drivers.'
           Action = { $null = Show-BlobText -Crumb 'Gaming > Status' -Lines (Get-BlobGamingStatus) } },
        @{ Label = 'Choose power plan'; Detail = 'Opens the Power section (High / Ultimate Performance plans).'; Action = { Show-BlobPower } },
        @{ Label = 'Background apps setting'; Detail = 'Store apps running in the background - shared with the Performance section.'
           Action = { Invoke-BlobTweakSet -Tweaks @(Get-BlobTweak 'perf.bgapps') -Crumb 'Gaming' -Tag 'gaming' } }
    )
}
