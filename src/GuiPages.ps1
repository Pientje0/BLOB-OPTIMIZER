# ============================================================================
#  BLOB OPTIMIZER - GuiPages.ps1
#  Window pages: page list, Dashboard, Presets, tweak sections, System Info.
#  Every action previews exact changes in a dialog before anything happens.
# ============================================================================

function Get-BlobGuiPages {
    @(
        @{ Key = 'dashboard'; Label = 'Dashboard'; Icon = 0xE80F; Subtitle = 'System overview and quick actions'; Build = { New-BlobGuiDashboard } }
        @{ Key = 'presets'; Label = 'Presets'; Icon = 0xE734; Subtitle = 'MINIMAL, STANDARD or ADVANCED - every change is listed before it is applied'; Build = { New-BlobGuiPresets } }
        @{ Key = 'performance'; Label = 'Performance'; Icon = 0xEC4A; Gap = $true; Subtitle = 'Responsiveness, background apps and visual effects'
           Build = { New-BlobGuiTweakPage 'Performance' @(
                   @{ Label = 'Memory and resources'; Action = { Show-BlobGuiMessage -Title 'Memory and resources' -Lines (Get-BlobMemoryInfo) } },
                   @{ Label = 'Current performance settings'; Action = { Show-BlobGuiMessage -Title 'Performance settings' -Lines (Get-BlobPerfSettingsInfo) } },
                   @{ Label = 'Windows Performance Options'; Action = { Start-Process 'SystemPropertiesPerformance.exe' -ErrorAction SilentlyContinue } }) } }
        @{ Key = 'gaming'; Label = 'Gaming'; Icon = 0xE7FC; Subtitle = 'Less background interference while gaming. No FPS gains are promised.'
           Build = { New-BlobGuiTweakPage 'Gaming' @(
                   @{ Label = 'Gaming status'; Action = { Show-BlobGuiMessage -Title 'Gaming status' -Lines (Get-BlobGamingStatus) } },
                   @{ Label = 'Power plans'; Action = { Show-BlobGuiPage 'power' } }) } }
        @{ Key = 'tweaks'; Label = 'Tweaks'; Icon = 0xE713; Subtitle = 'File Explorer, taskbar, Start menu and Windows behaviour'
           Build = { New-BlobGuiTweakPage 'Tweaks' @(
                   @{ Label = 'Restart Windows Explorer'; Action = {
                           if (Confirm-BlobGui -Title 'Restart Windows Explorer?' -OkText 'Restart Explorer' -Lines @('{Gray}The taskbar and open Explorer windows close and reopen. Nothing else is affected.')) {
                               Restart-BlobExplorer; Add-BlobGuiLog '{Green}Explorer restarted.' } } }) } }
        @{ Key = 'privacy'; Label = 'Privacy'; Icon = 0xE72E; Subtitle = 'Advertising, suggestions and optional data collection. Security protections stay on.'
           Build = { New-BlobGuiTweakPage 'Privacy' @(
                   @{ Label = 'Privacy overview'; Action = { Show-BlobGuiMessage -Title 'Privacy overview' -Lines (Get-BlobPrivacyOverview) } },
                   @{ Label = 'Windows privacy settings'; Action = { Start-Process 'ms-settings:privacy' -ErrorAction SilentlyContinue } }) } }
        @{ Key = 'services'; Label = 'Services'; Icon = 0xE912; Gap = $true; Subtitle = 'Startup types only - services are never deleted, critical ones are protected'; Build = { New-BlobGuiServices } }
        @{ Key = 'startup'; Label = 'Startup'; Icon = 0xE7B5; Subtitle = 'Programs that launch at sign-in. Disabled the same way Task Manager does it.'; Build = { New-BlobGuiStartup } }
        @{ Key = 'cleanup'; Label = 'Cleanup'; Icon = 0xE74D; Subtitle = 'Temporary files and caches with a size preview. Deleted files cannot be restored.'; Build = { New-BlobGuiCleanup } }
        @{ Key = 'network'; Label = 'Network'; Icon = 0xE968; Subtitle = 'Information, diagnostics, DNS and optional resets'; Build = { New-BlobGuiNetwork } }
        @{ Key = 'power'; Label = 'Power'; Icon = 0xE945; Subtitle = 'Power plans, display and sleep timeouts, hibernation'; Build = { New-BlobGuiPower } }
        @{ Key = 'restore'; Label = 'Restore'; Icon = 0xE81C; Gap = $true; Subtitle = 'Undo changes, registry snapshots, restore points and configuration files'; Build = { New-BlobGuiRestore } }
        @{ Key = 'tools'; Label = 'External Tools'; Icon = 0xE8A7; Subtitle = 'Launch well-known third-party tools: Chris Titus Tech WinUtil and O&O ShutUp10++'; Build = { New-BlobGuiTools } }
        @{ Key = 'sysinfo'; Label = 'System Info'; Icon = 0xE946; Subtitle = 'Hardware and Windows details (read-only)'; Build = { New-BlobGuiSysInfo } }
    )
}

# ---------------------------------------------------------------------------
#  Shared apply / undo flows
# ---------------------------------------------------------------------------
function Invoke-BlobGuiApply {
    param([array]$Tweaks, [string]$Tag = 'gui', [string[]]$ExtraLines = @(), [string]$Title, [switch]$ForceDanger)
    $Tweaks = @($Tweaks | Where-Object { $_ })
    if ($Tweaks.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Tick one or more items first.'); return $false }
    if (-not $Title) { $Title = "Apply {0} optimization(s)?" -f $Tweaks.Count }
    $danger = $ForceDanger -or (@($Tweaks | Where-Object { $_.Risk -eq 'Advanced' }).Count -gt 0)
    $canRp = $Blob.IsAdmin -and -not $Blob.DryRun
    $rpText = if ($canRp) { 'Create a System Restore point first (recommended)' }
              elseif ($Blob.DryRun) { 'Create a System Restore point first (not available in dry run)' }
              else { 'Create a System Restore point first (requires administrator)' }
    $ok = Show-BlobGuiDialog -Title $Title -Subtitle 'These exact settings will change. Original values are saved first.' `
        -Lines ($ExtraLines + (Get-BlobTweakPreview $Tweaks)) -Danger:$danger -OkText 'Apply' `
        -CheckText $rpText -CheckDefault $canRp -CheckEnabled $canRp
    if (-not $ok) { return $false }
    if ($Blob.Gui.DialogCheck) { Invoke-BlobGuiRestorePointStep "BLOB OPTIMIZER - before $Tag" }
    Start-BlobGuiTask ("Applying {0} optimization(s)" -f $Tweaks.Count)
    $out = Invoke-BlobTweakCore -Tweaks $Tweaks -Tag $Tag -Log { param($m) Add-BlobGuiLog $m }
    Add-BlobGuiLog "{Cyan}$($out.Summary)"
    if ($out.NeedsExplorer) {
        if (Show-BlobGuiDialog -Title 'Restart Windows Explorer now?' -OkText 'Restart Explorer' -CancelText 'Later' -Lines @(
                '{Gray}Some changes appear only after Explorer restarts.',
                '{Gray}The taskbar and open Explorer windows close and reopen. Choose Later to restart or sign out yourself.')) {
            Restart-BlobExplorer; Add-BlobGuiLog '{Green}Explorer restarted.'
        }
    }
    Update-BlobGuiPage
    return $true
}

# Rich hover help for one tweak: explanation, risk, exact changes, undo.
function New-BlobTweakTooltip {
    param($Tweak)
    $r = $Blob.RiskInfo[$Tweak.Risk]
    $state = Get-BlobTweakState $Tweak
    $paras = @(
        (Get-BlobTweakExplanation $Tweak),
        "{$($r.Color)}$($r.Label){Gray} - $($r.Text)")
    if ($Tweak.Warning) { $paras += "{Yellow}Warning: $($Tweak.Warning)" }
    if ($Tweak.Note) { $paras += "{Gray}When it applies: $($Tweak.Note)" }
    $paras += $(if ($Tweak.Admin) { '{Yellow}Requires administrator rights (machine-wide setting).' } else { '{Green}Works without administrator rights (your account only).' })
    $paras += "{Gray}Current status: {White}$(switch ($state) { 'Applied' { 'applied' } 'Partial' { 'partly applied' } 'Default' { 'not applied (Windows default or your own setting)' } default { 'not applicable' } })"
    $paras += '{Gray}Undo: the original value is saved before the change; restore it with "Undo selected" or from the Restore page.'
    $mono = @(Get-BlobTweakPreview @($Tweak) | Select-Object -Skip 1 | Where-Object { $_ -match '^\{(Gray|DarkGray)\} {4}' -and $_ -notmatch 'Note:' })
    return New-BlobTooltipPanel -Title $Tweak.Name -Paragraphs $paras -Mono $mono -MonoTitle 'Exact changes (current -> new)'
}

function Invoke-BlobGuiUndo {
    param([array]$Tweaks)
    $Tweaks = @($Tweaks | Where-Object { $_ })
    if ($Tweaks.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Tick the items you want to restore first.'); return }
    $undo = Get-BlobUndoPlan $Tweaks
    if ($undo.Records.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing to restore' -Kind Warning -Lines $undo.Lines; return }
    if (-not (Confirm-BlobGui -Title 'Restore original values?' -Lines $undo.Lines -OkText 'Restore')) { return }
    Start-BlobGuiTask 'Restoring original values'
    $ok, $bad = Invoke-BlobRestoreCore -Records $undo.Records -Log { param($m) Add-BlobGuiLog $m }
    Add-BlobGuiLog ("{Cyan}Restore finished: {0} restored, {1} not restored." -f $ok, $bad)
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  Dashboard
# ---------------------------------------------------------------------------
function New-BlobStatCard {
    param([string]$Title, [string]$Value, [string]$Sub = '', [double]$Fraction = -1, [string]$ValueColor = 'White')
    $s = New-BlobStack
    [void]$s.Children.Add((New-BlobText $Title.ToUpper() 10.5 'DarkGray' 'Bold'))
    [void]$s.Children.Add((New-BlobText $Value 16 $ValueColor 'SemiBold' '0,6,0,0'))
    if ($Fraction -ge 0) { $bar = New-BlobBar $Fraction 230; $bar.Margin = '0,10,0,0'; [void]$s.Children.Add($bar) }
    if ($Sub) { [void]$s.Children.Add((New-BlobText $Sub 12 'Gray' 'Normal' '0,6,0,0')) }
    return (New-BlobCard $s '0,0,12,12' '18,14' 268)
}

function New-BlobGuiDashboard {
    $root = New-BlobStack
    $si = $Blob.SysInfo
    $wrap = New-Object Windows.Controls.WrapPanel
    [void]$wrap.Children.Add((New-BlobStatCard 'Windows' $si.OS))
    [void]$wrap.Children.Add((New-BlobStatCard 'Processor' $si.CPU))
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $total = [double]$os.TotalVisibleMemorySize * 1KB; $used = $total - [double]$os.FreePhysicalMemory * 1KB
        [void]$wrap.Children.Add((New-BlobStatCard 'Memory' $si.RAM ("{0} in use ({1:N0}%)" -f (Format-BlobSize $used), (100 * $used / $total)) ($used / $total)))
    } catch { [void]$wrap.Children.Add((New-BlobStatCard 'Memory' $si.RAM)) }
    [void]$wrap.Children.Add((New-BlobStatCard 'Graphics' $si.GPU))
    try {
        $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop
        [void]$wrap.Children.Add((New-BlobStatCard "System drive $($env:SystemDrive)" ("{0} free" -f (Format-BlobSize $c.FreeSpace)) ("of {0}" -f (Format-BlobSize $c.Size)) (1 - $c.FreeSpace / $c.Size)))
    } catch { }
    [void]$wrap.Children.Add((New-BlobStatCard 'Power plan' (Get-BlobActivePowerPlan).Name))
    [void]$wrap.Children.Add((New-BlobStatCard 'Computer' $si.Host "Uptime $($si.Uptime)"))
    $adminText = if ($Blob.IsAdmin) { 'Administrator' } else { 'Standard user' }
    [void]$wrap.Children.Add((New-BlobStatCard 'Permissions' $adminText $(if ($Blob.IsAdmin) { 'All features available' } else { 'System-wide changes need admin' }) -1 $(if ($Blob.IsAdmin) { 'Green' } else { 'Yellow' })))
    [void]$root.Children.Add((New-BlobHeading 'System'))
    [void]$root.Children.Add($wrap)

    $applied = @($Blob.Tweaks | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
    $restorable = @(Get-BlobAppliedChanges).Count
    $startup = @(Get-BlobStartupEntries)
    $wrap2 = New-Object Windows.Controls.WrapPanel
    [void]$wrap2.Children.Add((New-BlobStatCard 'Optimizations applied' "$applied of $($Blob.Tweaks.Count)" 'Detected from current settings' ($applied / [Math]::Max(1, $Blob.Tweaks.Count))))
    [void]$wrap2.Children.Add((New-BlobStatCard 'Restorable changes' "$restorable" 'Saved in the change journal'))
    [void]$wrap2.Children.Add((New-BlobStatCard 'Startup programs' ("{0} enabled" -f @($startup | Where-Object { $_.Enabled }).Count) ("{0} entries in total" -f $startup.Count)))
    [void]$root.Children.Add((New-BlobHeading 'Status' '0,10,0,10'))
    [void]$root.Children.Add($wrap2)

    [void]$root.Children.Add((New-BlobHeading 'Quick actions' '0,10,0,10'))
    $qa = New-BlobStack 'Horizontal'
    [void]$qa.Children.Add((New-BlobButton 'Choose a preset' { Show-BlobGuiPage 'presets' } 'Accent'))
    [void]$qa.Children.Add((New-BlobButton 'Scan for cleanup' { Show-BlobGuiPage 'cleanup' }))
    [void]$qa.Children.Add((New-BlobButton 'Create restore point' { Invoke-BlobGuiRestorePoint }))
    [void]$qa.Children.Add((New-BlobButton 'Review changes' { Show-BlobGuiPage 'restore' }))
    [void]$qa.Children.Add((New-BlobButton 'External tools' { Show-BlobGuiPage 'tools' }))
    [void]$root.Children.Add((New-BlobCard $qa))
    [void]$root.Children.Add((New-BlobText 'BLOB OPTIMIZER never disables Microsoft Defender, Windows Firewall, SmartScreen, UAC or Windows Update.' 12 'DarkGray' 'Normal' '2,6,0,0'))
    return $root
}

# ---------------------------------------------------------------------------
#  Presets
# ---------------------------------------------------------------------------
function New-BlobGuiPresets {
    $root = New-BlobStack
    $wrap = New-Object Windows.Controls.WrapPanel
    $accent = @{ MINIMAL = 'Green'; STANDARD = 'Cyan'; ADVANCED = 'Yellow' }
    foreach ($p in @(Get-BlobPresets)) {
        $tw = @($p.Ids | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
        $appliedCount = @($tw | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
        $color = if ($accent.ContainsKey($p.Name)) { $accent[$p.Name] } else { 'Cyan' }
        $s = New-BlobStack
        $title = New-BlobStack 'Horizontal'
        [void]$title.Children.Add((New-BlobText $p.Name 22 $color 'Bold'))
        $riskLines = @($tw | ForEach-Object { "{$($Blob.RiskInfo[$_.Risk].Color)}$($Blob.RiskInfo[$_.Risk].Label.PadRight(12)){White}$($_.Name)" })
        [void]$title.Children.Add((New-BlobHelpIcon (New-BlobTooltipPanel -Title "$($p.Name) preset" -Paragraphs @($p.Description, $p.Warning, '{Gray}Every setting in this preset and its risk level:') -Mono $riskLines)))
        [void]$s.Children.Add($title)
        [void]$s.Children.Add((New-BlobText "$($tw.Count) settings  -  $appliedCount already applied" 12 'DarkGray' 'Normal' '0,4,0,10'))
        [void]$s.Children.Add((New-BlobText $p.Description 13 'Gray'))
        if ($p.Warning) { [void]$s.Children.Add((New-BlobText $p.Warning 12 'Yellow' 'Normal' '0,10,0,0')) }
        $list = New-BlobStack 'Vertical' '0,12,0,14'
        foreach ($t in ($tw | Select-Object -First 8)) { [void]$list.Children.Add((New-BlobText ("- " + $t.Name) 12 'Gray')) }
        if ($tw.Count -gt 8) { [void]$list.Children.Add((New-BlobText ("+ {0} more (all listed before applying)" -f ($tw.Count - 8)) 12 'DarkGray')) }
        [void]$s.Children.Add($list)
        $btn = New-BlobButton 'Review and apply' ([scriptblock]::Create("Invoke-BlobGuiPreset '$($p.Name -replace "'", "''")'")) 'Accent'
        $btn.HorizontalAlignment = 'Left'
        [void]$s.Children.Add($btn)
        [void]$wrap.Children.Add((New-BlobCard $s '0,0,14,14' '20,18' 290))
    }
    [void]$root.Children.Add($wrap)
    [void]$root.Children.Add((New-BlobText 'Personal-preference tweaks (OPTIONAL) are never part of a preset. Every preset change can be undone from Restore.' 12 'DarkGray' 'Normal' '2,4,0,0'))
    return $root
}

function Invoke-BlobGuiRestorePoint {
    if (-not $Blob.IsAdmin) { Show-BlobGuiAdminRequired 'Creating a System Restore point is a machine-wide operation.'; return }
    if (-not (Confirm-BlobGui -Title 'Create a System Restore point?' -OkText 'Create' -Lines @('{Gray}This can take a minute. System Protection must be on for the system drive.', '{DarkGray}Windows creates at most one restore point per 24 hours by default.'))) { return }
    Start-BlobGuiTask 'Creating System Restore point'
    Add-BlobGuiLog (New-BlobRestorePoint 'BLOB OPTIMIZER manual restore point')
}

function Invoke-BlobGuiPreset {
    param([string]$Name)
    $p = @(Get-BlobPresets) | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if (-not $p) { return }
    $tw = @($p.Ids | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
    $extra = @()
    if ($p.Warning) { $extra = @("{Yellow}$($p.Warning)", '') }
    $null = Invoke-BlobGuiApply -Tweaks $tw -Tag "preset-$($p.Name)" -ExtraLines $extra -Title "Apply the $($p.Name) preset ($($tw.Count) optimizations)?" -ForceDanger:($p.Name -match 'ADVANCED')
}

# ---------------------------------------------------------------------------
#  Tweak sections
# ---------------------------------------------------------------------------
function New-BlobGuiTweakRow {
    param($Tweak)
    $grid = New-Object Windows.Controls.Grid
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = '*'
    $c1 = New-Object Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
    $grid.ColumnDefinitions.Add($c0); $grid.ColumnDefinitions.Add($c1)
    $grid.Margin = '0,6,0,6'

    $cb = New-Object Windows.Controls.CheckBox
    $content = New-BlobStack
    [void]$content.Children.Add((New-BlobText $Tweak.Name 14 'White' 'SemiBold'))
    [void]$content.Children.Add((New-BlobText $Tweak.Description 12.5 'Gray' 'Normal' '0,2,0,0'))
    if ($Tweak.Warning) { [void]$content.Children.Add((New-BlobText ("! " + $Tweak.Warning) 12 'Yellow' 'Normal' '0,3,0,0')) }
    elseif ($Tweak.Note) { [void]$content.Children.Add((New-BlobText $Tweak.Note 12 'DarkGray' 'Normal' '0,3,0,0')) }
    $cb.Content = $content
    $cb.Tag = $Tweak
    [Windows.Controls.Grid]::SetColumn($cb, 0)
    [void]$grid.Children.Add($cb)

    $badges = New-BlobStack 'Horizontal'
    $badges.VerticalAlignment = 'Top'; $badges.Margin = '12,2,0,0'
    if ($Tweak.Admin) { [void]$badges.Children.Add((New-BlobBadge 'ADMIN' 'DarkGray')) }
    [void]$badges.Children.Add((New-BlobRiskBadge $Tweak.Risk))
    $state = Get-BlobTweakState $Tweak
    $stateBadge = switch ($state) { 'Applied' { New-BlobBadge 'APPLIED' 'Green' } 'Partial' { New-BlobBadge 'PARTIAL' 'Yellow' } default { New-BlobBadge 'NOT SET' 'DarkGray' } }
    [void]$badges.Children.Add($stateBadge)
    [void]$badges.Children.Add((New-BlobHelpIcon (New-BlobTweakTooltip $Tweak)))
    [Windows.Controls.Grid]::SetColumn($badges, 1)
    [void]$grid.Children.Add($badges)
    $Blob.Gui.P.Checks += $cb
    return $grid
}

function New-BlobGuiTweakPage {
    param([string]$Section, [array]$Tools = @())
    $Blob.Gui.P = @{ Checks = @(); Section = $Section }
    $root = New-BlobStack
    [void]$root.Children.Add((New-BlobRiskLegend))
    $tweaks = @($Blob.Tweaks | Where-Object { $_.Section -eq $Section })
    $groups = @($tweaks | ForEach-Object { $_.Group } | Select-Object -Unique)
    foreach ($g in $groups) {
        [void]$root.Children.Add((New-BlobHeading $g))
        $stack = New-BlobStack
        $items = @($tweaks | Where-Object { $_.Group -eq $g })
        for ($i = 0; $i -lt $items.Count; $i++) {
            [void]$stack.Children.Add((New-BlobGuiTweakRow $items[$i]))
            if ($i -lt $items.Count - 1) {
                $sep = New-Object Windows.Controls.Border
                $sep.Height = 1; $sep.Background = Get-BlobBrush '#1E2A38'; $sep.Margin = '0,4,0,4'
                [void]$stack.Children.Add($sep)
            }
        }
        [void]$root.Children.Add((New-BlobCard $stack))
    }
    if ($Tools.Count -gt 0) {
        [void]$root.Children.Add((New-BlobHeading 'Tools'))
        $tb = New-BlobStack 'Horizontal'
        foreach ($t in $Tools) { [void]$tb.Children.Add((New-BlobButton $t.Label $t.Action)) }
        [void]$root.Children.Add((New-BlobCard $tb))
    }
    Set-BlobGuiPageActions @(
        (New-BlobButton 'Select all' { foreach ($c in $Blob.Gui.P.Checks) { $c.IsChecked = $true } }),
        (New-BlobButton 'Clear' { foreach ($c in $Blob.Gui.P.Checks) { $c.IsChecked = $false } }),
        (New-BlobButton 'Undo selected' { Invoke-BlobGuiUndo @($Blob.Gui.P.Checks | Where-Object { $_.IsChecked } | ForEach-Object { $_.Tag }) } -ToolTip 'Restore the original values saved by BLOB OPTIMIZER'),
        (New-BlobButton 'Review and apply' { $null = Invoke-BlobGuiApply -Tweaks @($Blob.Gui.P.Checks | Where-Object { $_.IsChecked } | ForEach-Object { $_.Tag }) -Tag $Blob.Gui.P.Section } 'Accent' -Margin '0'))
    return $root
}

# ---------------------------------------------------------------------------
#  System Info
# ---------------------------------------------------------------------------
function New-BlobGuiSysInfo {
    $lines = Get-BlobSystemInfoLines
    $Blob.Gui.P = @{ Text = (($lines | ForEach-Object { Get-BlobPlainText $_ }) -join [Environment]::NewLine) }
    Set-BlobGuiPageActions @((New-BlobButton 'Copy to clipboard' {
                Set-Clipboard -Value $Blob.Gui.P.Text; Add-BlobGuiLog '{Green}System information copied to the clipboard.' } -Margin '0'))
    $root = New-BlobStack
    $current = $null
    foreach ($l in $lines) {
        if ($l -match '^\{Cyan\}') {
            if ($current) { [void]$root.Children.Add((New-BlobCard $current)) }
            [void]$root.Children.Add((New-BlobHeading (Get-BlobPlainText $l)))
            $current = New-BlobStack
            continue
        }
        if (-not $current) { $current = New-BlobStack }
        if ($l) { [void]$current.Children.Add((ConvertTo-BlobTextBlock $l -Mono -Size 12.5)) }
    }
    if ($current) { [void]$root.Children.Add((New-BlobCard $current)) }
    return $root
}

# ---------------------------------------------------------------------------
#  External tools
# ---------------------------------------------------------------------------
function New-BlobGuiTools {
    $root = New-BlobStack
    $warn = New-BlobStack
    [void]$warn.Children.Add((New-BlobText 'Third-party software' 14 'Yellow' 'SemiBold'))
    [void]$warn.Children.Add((New-BlobText 'These tools are made by other developers. BLOB OPTIMIZER only starts them for you: it shows the official download address first, verifies digital signatures where possible, and records that you launched them. Changes made inside these tools are NOT tracked and cannot be undone from the Restore page - use their own undo options and a System Restore point.' 12.5 'Gray' 'Normal' '0,4,0,0'))
    [void]$root.Children.Add((New-BlobCard $warn))
    $wrap = New-Object Windows.Controls.WrapPanel
    foreach ($t in $Blob.ExternalTools) {
        $s = New-BlobStack
        $head = New-BlobStack 'Horizontal'
        [void]$head.Children.Add((New-BlobText $t.Name 17 'White' 'SemiBold'))
        [void]$head.Children.Add((New-BlobHelpIcon (New-BlobTooltipPanel -Title $t.Name -Paragraphs (Get-BlobExternalToolLines $t))))
        [void]$s.Children.Add($head)
        [void]$s.Children.Add((New-BlobText $t.Publisher 12 'DarkGray' 'Normal' '0,2,0,10'))
        [void]$s.Children.Add((New-BlobText $t.Summary 13 'Gray'))
        [void]$s.Children.Add((New-BlobText "Source: $($t.Url)" 11.5 'DarkGray' 'Normal' '0,10,0,0'))
        if ($t.Kind -eq 'Exe') { [void]$s.Children.Add((New-BlobText "Signature must be valid and from $($t.Signer) before it runs." 11.5 'DarkGray' 'Normal' '0,2,0,0')) }
        $btns = New-BlobStack 'Horizontal' '0,14,0,0'
        [void]$btns.Children.Add((New-BlobButton 'Launch' ([scriptblock]::Create("Invoke-BlobGuiExternalTool '$($t.Id)'")) 'Accent'))
        [void]$btns.Children.Add((New-BlobButton 'Website' ([scriptblock]::Create("Start-Process '$($t.Home)'"))))
        [void]$s.Children.Add($btns)
        [void]$wrap.Children.Add((New-BlobCard $s '0,0,14,14' '20,18' 440))
    }
    [void]$root.Children.Add($wrap)
    return $root
}

function Invoke-BlobGuiExternalTool {
    param([string]$Id)
    $t = Get-BlobExternalTool $Id
    if (-not $t) { return }
    $canRp = $Blob.IsAdmin -and -not $Blob.DryRun
    $rpText = if ($canRp) { 'Create a System Restore point first (strongly recommended)' } else { 'Create a System Restore point first (requires administrator)' }
    $ok = Show-BlobGuiDialog -Title "Launch $($t.Name)?" -Subtitle 'Third-party software - read before continuing' -Lines (Get-BlobExternalToolLines $t) `
        -OkText 'Launch' -Kind 'Warning' -CheckText $rpText -CheckDefault $canRp -CheckEnabled $canRp
    if (-not $ok) { return }
    if ($Blob.Gui.DialogCheck) { Invoke-BlobGuiRestorePointStep "BLOB OPTIMIZER - before $($t.Name)" }
    Start-BlobGuiTask "Launching $($t.Name)"
    $null = Start-BlobExternalTool -Tool $t -Log { param($m) Add-BlobGuiLog $m }
}
