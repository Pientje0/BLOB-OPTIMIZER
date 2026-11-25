# ============================================================================
#  BLOB OPTIMIZER - GuiPages.ps1
#  Window pages: page list, Dashboard, Presets, tweak sections, System Info.
#  Every action previews exact changes in a dialog before anything happens.
# ============================================================================

function Get-BlobGuiPages {
    @(
        @{ Key = 'dashboard'; Label = 'Home'; Icon = 0xE80F; Subtitle = 'System overview and quick actions'; Build = { New-BlobGuiDashboard } }
        @{ Key = 'presets'; Label = 'Presets'; Icon = 0xE734; Subtitle = 'MINIMAL, STANDARD or ADVANCED - every change is listed before it is applied'; Build = { New-BlobGuiPresets } }
        @{ Key = 'optimize'; Label = 'Optimizations'; Icon = 0xEC4A; Subtitle = 'Every setting as a card. Flip the switch to activate (with a full preview) or deactivate (restores the original).'; Build = { New-BlobGuiOptimizations } }
        @{ Key = 'services'; Label = 'Services'; Icon = 0xE912; Gap = $true; Subtitle = 'Startup types only - services are never deleted, critical ones are protected'; Build = { New-BlobGuiServices } }
        @{ Key = 'startup'; Label = 'Startup'; Icon = 0xE7B5; Subtitle = 'Programs that launch at sign-in. Disabled the same way Task Manager does it.'; Build = { New-BlobGuiStartup } }
        @{ Key = 'cleanup'; Label = 'Cleanup'; Icon = 0xE74D; Subtitle = 'Temporary files and caches with a size preview. Deleted files cannot be restored.'; Build = { New-BlobGuiCleanup } }
        @{ Key = 'network'; Label = 'Network'; Icon = 0xE968; Subtitle = 'Information, diagnostics, DNS and optional resets'; Build = { New-BlobGuiNetwork } }
        @{ Key = 'power'; Label = 'Power'; Icon = 0xE945; Subtitle = 'Power plans, display and sleep timeouts, hibernation'; Build = { New-BlobGuiPower } }
        @{ Key = 'restore'; Label = 'Restore'; Icon = 0xE81C; Gap = $true; Subtitle = 'Undo changes, registry snapshots, restore points and configuration files'; Build = { New-BlobGuiRestore } }
        @{ Key = 'tools'; Label = 'Tools'; Icon = 0xE8A7; Subtitle = 'Launch well-known third-party tools: Chris Titus Tech WinUtil and O&O ShutUp10++'; Build = { New-BlobGuiTools } }
        @{ Key = 'sysinfo'; Label = 'Info'; Icon = 0xE946; Subtitle = 'Hardware and Windows details (read-only)'; Build = { New-BlobGuiSysInfo } }
    )
}

# ---------------------------------------------------------------------------
#  Shared apply / undo flows
# ---------------------------------------------------------------------------
function Invoke-BlobGuiApply {
    param([array]$Tweaks, [string]$Tag = 'gui', [string[]]$ExtraLines = @(), [string]$Title, [switch]$ForceDanger)
    $Tweaks = @($Tweaks | Where-Object { $_ })
    if ($Tweaks.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select one or more settings first (+ on a card).'); return $false }
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
    if ($Tweaks.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select the items you want to restore first (+ on a card).'); return $false }
    $undo = Get-BlobUndoPlan $Tweaks
    if ($undo.Records.Count -eq 0) {
        Show-BlobGuiMessage -Title 'Nothing to restore' -Kind Warning -Lines ($undo.Lines + @('', '{Gray}This setting already matched before BLOB OPTIMIZER changed anything (Windows default or your own choice), so there is no saved original to go back to.'))
        return $false
    }
    if (-not (Confirm-BlobGui -Title 'Restore original values?' -Lines $undo.Lines -OkText 'Restore')) { return $false }
    Start-BlobGuiTask 'Restoring original values'
    $ok, $bad = Invoke-BlobRestoreCore -Records $undo.Records -Log { param($m) Add-BlobGuiLog $m }
    Add-BlobGuiLog ("{Cyan}Restore finished: {0} restored, {1} not restored." -f $ok, $bad)
    Update-BlobGuiPage
    return $true
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
    $wrap = [Windows.Controls.WrapPanel]::new()
    [void]$wrap.Children.Add((New-BlobStatCard 'Windows' $si.OS))
    [void]$wrap.Children.Add((New-BlobStatCard 'Processor' $si.CPU))
    try {
        $os = Get-BlobPrefetch 'OS'
        if (-not $os) { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop }
        $total = [double]$os.TotalVisibleMemorySize * 1KB; $used = $total - [double]$os.FreePhysicalMemory * 1KB
        [void]$wrap.Children.Add((New-BlobStatCard 'Memory' $si.RAM ("{0} in use ({1:N0}%)" -f (Format-BlobSize $used), (100 * $used / $total)) ($used / $total)))
    } catch { [void]$wrap.Children.Add((New-BlobStatCard 'Memory' $si.RAM)) }
    [void]$wrap.Children.Add((New-BlobStatCard 'Graphics' $si.GPU))
    try {
        $c = @(Get-BlobPrefetch 'LogicalDisks') | Where-Object { $_.DeviceID -eq $env:SystemDrive } | Select-Object -First 1
        if (-not $c) { $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop }
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
    $wrap2 = [Windows.Controls.WrapPanel]::new()
    [void]$wrap2.Children.Add((New-BlobStatCard 'Optimizations applied' "$applied of $($Blob.Tweaks.Count)" 'Detected from current settings' ($applied / [Math]::Max(1, $Blob.Tweaks.Count))))
    [void]$wrap2.Children.Add((New-BlobStatCard 'Restorable changes' "$restorable" 'Saved in the change journal'))
    [void]$wrap2.Children.Add((New-BlobStatCard 'Startup programs' ("{0} enabled" -f @($startup | Where-Object { $_.Enabled }).Count) ("{0} entries in total" -f $startup.Count)))
    [void]$root.Children.Add((New-BlobHeading 'Status' '0,10,0,10'))
    [void]$root.Children.Add($wrap2)

    [void]$root.Children.Add((New-BlobHeading 'Quick actions' '0,10,0,10'))
    $qa = New-BlobStack 'Horizontal'
    [void]$qa.Children.Add((New-BlobButton 'Choose a preset' { Show-BlobGuiPage 'presets' } 'Accent'))
    [void]$qa.Children.Add((New-BlobButton 'All optimizations' { Show-BlobGuiPage 'optimize' }))
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
    $wrap = [Windows.Controls.WrapPanel]::new()
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
#  Optimizations: all settings as cards with switches
# ---------------------------------------------------------------------------
$Blob.GuiCategories = @('All', 'FPS & Latency', 'Performance', 'Network', 'Quality of Life', 'Privacy & Security')

function Get-BlobGuiFilteredTweaks {
    $list = @($Blob.Tweaks)
    if ($Blob.Gui.OptFilter -and $Blob.Gui.OptFilter -ne 'All') { $list = @($list | Where-Object { $_.Category -eq $Blob.Gui.OptFilter }) }
    $q = [string]$Blob.Gui.OptSearch
    if ($q.Trim()) {
        $q = $q.Trim()
        $list = @($list | Where-Object { $_.Name -like "*$q*" -or $_.Description -like "*$q*" -or $_.Category -like "*$q*" })
    }
    return $list
}

function New-BlobChip {
    param([string]$Text)
    $b = [Windows.Controls.Border]::new()
    $b.Background = Get-BlobBrush '#062A10'; $b.CornerRadius = 0; $b.Padding = '8,2'
    $b.HorizontalAlignment = 'Left'; $b.VerticalAlignment = 'Center'
    $b.Child = New-BlobText $Text 11 '#2EDB55' 'SemiBold'
    return $b
}

# Plain-text markers (no icon font): ! warning, ADMIN lock, > search, + / x select.
function New-BlobGlyph {
    param([int]$Code, [string]$Color = 'Gray', [double]$Size = 13)
    $map = @{ 0xE7BA = '!'; 0xE72E = 'ADMIN'; 0xE721 = '>'; 0xE710 = '[+]'; 0xE73E = '[x]' }
    $t = [Windows.Controls.TextBlock]::new()
    $t.Text = if ($map.ContainsKey($Code)) { $map[$Code] } else { '*' }
    $t.FontFamily = [Windows.Media.FontFamily]::new('Consolas')
    $t.FontWeight = 'Bold'
    $t.FontSize = $Size; $t.Foreground = Get-BlobBrush $Color; $t.VerticalAlignment = 'Center'
    return $t
}

function New-BlobTweakCard {
    param($Tweak, [string]$State, [bool]$Selected)
    $state = $State
    $selected = $Selected
    $card = [Windows.Controls.Border]::new()
    $card.Background = Get-BlobBrush '#000000'; $card.CornerRadius = 0; $card.Padding = '16,14,16,12'; $card.Margin = '0,0,12,12'
    $card.BorderThickness = 1
    $card.BorderBrush = if ($selected) { Get-BlobBrush 'Cyan' } elseif ($state -eq 'Applied') { Get-BlobBrush '#0F6A24' } else { Get-BlobBrush '#0F6A24' }
    $card.MinHeight = 190
    $dock = [Windows.Controls.DockPanel]::new()
    $dock.LastChildFill = $true

    # Bottom row: + ? ! ...... label switch
    $bottom = [Windows.Controls.DockPanel]::new()
    $bottom.Margin = '0,12,0,0'
    [Windows.Controls.DockPanel]::SetDock($bottom, 'Bottom')
    $right = New-BlobStack 'Horizontal'
    [Windows.Controls.DockPanel]::SetDock($right, 'Right')
    $labelText = switch ($state) { 'Applied' { 'Deactivate' } 'Partial' { 'Partly on' } default { 'Activate' } }
    $labelColor = switch ($state) { 'Applied' { 'White' } 'Partial' { 'Yellow' } default { 'Gray' } }
    [void]$right.Children.Add((New-BlobText $labelText 12.5 $labelColor 'Normal' '0,0,10,0'))
    $right.Children[0].VerticalAlignment = 'Center'
    $sw = [Windows.Controls.CheckBox]::new()
    $sw.Style = $Blob.Gui.Window.FindResource('Switch')
    $sw.IsChecked = ($state -eq 'Applied')
    $sw.VerticalAlignment = 'Center'
    $card.Tag = $sw          # lets a reused card reset its switch after a cancelled click
    if ($Tweak.Admin -and -not $Blob.IsAdmin) {
        $sw.IsEnabled = $false
        $holder = [Windows.Controls.Border]::new()
        $holder.Background = [Windows.Media.Brushes]::Transparent
        $holder.Child = $sw
        Set-BlobTooltip $holder (New-BlobTooltipPanel -Title 'Administrator required' -Paragraphs @('This is a machine-wide setting. Restart BLOB OPTIMIZER from an administrator terminal to change it.'))
        [void]$right.Children.Add($holder)
    } else {
        $sw.DataContext = $Tweak.Id
        Register-BlobClick $sw $Blob.GuiShared.SwitchClick
        [void]$right.Children.Add($sw)
    }
    [void]$bottom.Children.Add($right)
    $left = New-BlobStack 'Horizontal'
    $plus = [Windows.Controls.Button]::new()
    $plus.Style = $Blob.Gui.Window.FindResource('IconButton')
    $plus.Content = $(if ($selected) { '[x]' } else { '[+]' })
    $plus.Width = 34
    if ($selected) { $plus.Foreground = Get-BlobBrush 'Cyan' }
    $plus.ToolTip = if ($selected) { 'Selected - click to unselect' } else { 'Select for batch apply / undo' }
    $plus.DataContext = $Tweak.Id
    Register-BlobClick $plus $Blob.GuiShared.SelectClick
    [void]$left.Children.Add($plus)
    $help = New-BlobHelpIcon -Builder $Blob.GuiShared.TweakTip
    $help.DataContext = $Tweak.Id
    $help.Margin = '4,0,0,0'
    [void]$left.Children.Add($help)
    if ($Tweak.Risk -eq 'Advanced') {
        $warn = New-BlobGlyph 0xE7BA 'Yellow' 15
        $warn.Margin = '10,0,0,0'; $warn.Cursor = [Windows.Input.Cursors]::Help
        $wt = @($Blob.RiskInfo.Advanced.Text)
        if ($Tweak.Warning) { $wt += "{Yellow}$($Tweak.Warning)" }
        Set-BlobTooltip $warn (New-BlobTooltipPanel -Title 'Higher risk setting' -Paragraphs $wt)
        [void]$left.Children.Add($warn)
    }
    if ($Tweak.Admin) {
        $lock = New-BlobGlyph 0xE72E $(if ($Blob.IsAdmin) { 'DarkGray' } else { 'Yellow' }) 13
        $lock.Margin = '10,0,0,0'
        Set-BlobTooltip $lock (New-BlobTooltipPanel -Title 'Administrator setting' -Paragraphs @('Machine-wide setting: needs administrator rights.'))
        [void]$left.Children.Add($lock)
    }
    [void]$bottom.Children.Add($left)
    [void]$dock.Children.Add($bottom)

    # Top row: category chip ...... risk badge
    $top = [Windows.Controls.DockPanel]::new()
    [Windows.Controls.DockPanel]::SetDock($top, 'Top')
    $risk = New-BlobRiskBadge $Tweak.Risk
    [Windows.Controls.DockPanel]::SetDock($risk, 'Right')
    [void]$top.Children.Add($risk)
    [void]$top.Children.Add((New-BlobChip $Tweak.Category))
    [void]$dock.Children.Add($top)

    $body = New-BlobStack
    [void]$body.Children.Add((New-BlobText $Tweak.Name 15 'White' 'SemiBold' '0,12,0,6'))
    $desc = New-BlobText $Tweak.Description 12.5 '#2EDB55'
    $desc.MaxHeight = 70; $desc.TextTrimming = 'CharacterEllipsis'
    [void]$body.Children.Add($desc)
    [void]$dock.Children.Add($body)
    $card.Child = $dock
    return $card
}

# Returns the card for a tweak, reusing the cached element when its state and
# selection are unchanged (so switching, searching and filtering stay instant).
function Get-BlobGuiCard {
    param($Tweak, [string]$State)
    if (-not $Blob.Gui.CardCache) { $Blob.Gui.CardCache = @{} }
    $sel = [bool]$Blob.Gui.Selected[$Tweak.Id]
    $c = $Blob.Gui.CardCache[$Tweak.Id]
    if (-not ($c -and $c.State -eq $State -and $c.Selected -eq $sel)) {
        $c = @{ Element = (New-BlobTweakCard $Tweak $State $sel); State = $State; Selected = $sel }
        $Blob.Gui.CardCache[$Tweak.Id] = $c
    }
    $el = $c.Element
    if ($el.Parent -is [Windows.Controls.Panel]) { $el.Parent.Children.Remove($el) }
    if ($el.Tag -is [Windows.Controls.CheckBox]) { $el.Tag.IsChecked = ($State -eq 'Applied') }
    return $el
}

function Update-BlobGuiCardGrid {
    $g = $Blob.Gui.CardGrid
    if (-not $g) { return }
    $g.Children.Clear()
    $states = @{}
    foreach ($t in $Blob.Tweaks) { $states[$t.Id] = Get-BlobTweakState $t }
    $list = @(Get-BlobGuiFilteredTweaks)
    foreach ($t in $list) { [void]$g.Children.Add((Get-BlobGuiCard $t $states[$t.Id])) }
    $active = @($states.Values | Where-Object { $_ -eq 'Applied' }).Count
    $Blob.Gui.CardCount.Text = "$($list.Count) shown  -  $active of $($Blob.Tweaks.Count) active  -  $(@($Blob.Gui.Selected.Keys).Count) selected"
    $n = @($Blob.Gui.Selected.Keys).Count
    if ($Blob.Gui.ApplySelBtn) { $Blob.Gui.ApplySelBtn.Content = $(if ($n) { "Apply selected ($n)" } else { 'Apply selected' }) }
    Update-BlobGuiCardColumns
}

function Get-BlobGuiSelectedTweaks { return @($Blob.Gui.Selected.Keys | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ }) }

function Switch-BlobGuiSelect {
    param([string]$Id)
    if ($Blob.Gui.Selected.ContainsKey($Id)) { $Blob.Gui.Selected.Remove($Id) } else { $Blob.Gui.Selected[$Id] = $true }
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    Update-BlobGuiCardGrid
    $Blob.Gui.PageScroll.UpdateLayout(); $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
}

# Switch on a card: activate (apply with preview) or deactivate (restore original).
function Switch-BlobGuiTweak {
    param([string]$Id)
    $t = Get-BlobTweak $Id
    if (-not $t) { return }
    $done = if ((Get-BlobTweakState $t) -eq 'Applied') { Invoke-BlobGuiUndo @($t) } else { Invoke-BlobGuiApply -Tweaks @($t) -Tag $t.Id }
    if (-not $done) { Update-BlobGuiPage }   # cancelled: put the switch back
}

function New-BlobGuiOptimizations {
    $root = New-BlobStack
    # Filter chips + search
    $bar = [Windows.Controls.DockPanel]::new()
    $bar.Margin = '0,0,0,6'
    $sbox = [Windows.Controls.Grid]::new()
    $sbox.Width = 250; $sbox.VerticalAlignment = 'Top'
    $search = [Windows.Controls.TextBox]::new()
    $search.Text = [string]$Blob.Gui.OptSearch; $search.Padding = '30,6,8,6'
    $hint = New-BlobText 'Search settings...' 13 'DarkGray' 'Normal' '31,7,0,0'
    $hint.IsHitTestVisible = $false
    if ($search.Text) { $hint.Visibility = 'Collapsed' }
    $glass = New-BlobGlyph 0xE721 'DarkGray' 12
    $glass.Margin = '10,0,0,0'; $glass.HorizontalAlignment = 'Left'; $glass.IsHitTestVisible = $false
    [void]$sbox.Children.Add($search); [void]$sbox.Children.Add($hint); [void]$sbox.Children.Add($glass)
    $Blob.Gui.SearchHint = $hint
    [Windows.Controls.DockPanel]::SetDock($sbox, 'Right')
    $search.Add_TextChanged({
            param($s, $e)
            $Blob.Gui.OptSearch = $s.Text
            $Blob.Gui.SearchHint.Visibility = if ($s.Text) { 'Collapsed' } else { 'Visible' }
            Update-BlobGuiCardGrid
        })
    [void]$bar.Children.Add($sbox)
    $chips = [Windows.Controls.WrapPanel]::new()
    foreach ($c in $Blob.GuiCategories) {
        $count = if ($c -eq 'All') { $Blob.Tweaks.Count } else { @($Blob.Tweaks | Where-Object { $_.Category -eq $c }).Count }
        $b = [Windows.Controls.Button]::new()
        $b.Style = $Blob.Gui.Window.FindResource('ChipButton')
        $b.Content = "$c  $count"
        if ($Blob.Gui.OptFilter -eq $c) { $b.Background = Get-BlobBrush '#062A10'; $b.BorderBrush = Get-BlobBrush 'Cyan'; $b.Foreground = Get-BlobBrush 'Cyan' }
        Register-BlobClick $b ([scriptblock]::Create("`$Blob.Gui.OptFilter = '$c'; Show-BlobGuiPage 'optimize' -Rebuild"))
        [void]$chips.Children.Add($b)
    }
    [void]$bar.Children.Add($chips)
    [void]$root.Children.Add($bar)

    $info = [Windows.Controls.DockPanel]::new()
    $info.Margin = '0,0,0,12'
    $Blob.Gui.CardCount = New-BlobText '' 12 'DarkGray'
    $legend = New-BlobStack 'Horizontal'
    [Windows.Controls.DockPanel]::SetDock($legend, 'Right')
    foreach ($k in @('Minimal', 'Standard', 'Advanced', 'Optional')) { $rb = New-BlobRiskBadge $k; [void]$legend.Children.Add($rb) }
    [void]$info.Children.Add($legend)
    [void]$info.Children.Add($Blob.Gui.CardCount)
    [void]$root.Children.Add($info)

    $grid = [Windows.Controls.Primitives.UniformGrid]::new()
    $grid.Columns = 3
    $Blob.Gui.CardGrid = $grid
    [void]$root.Children.Add($grid)

    [void]$root.Children.Add((New-BlobHeading 'More tools' '0,12,0,10'))
    $tools = [Windows.Controls.WrapPanel]::new()
    $toolDefs = @(
        @('Memory and resources', { Show-BlobGuiMessage -Title 'Memory and resources' -Lines (Get-BlobMemoryInfo) }),
        @('Gaming status', { Show-BlobGuiMessage -Title 'Gaming status' -Lines (Get-BlobGamingStatus) }),
        @('Privacy overview', { Show-BlobGuiMessage -Title 'Privacy overview' -Lines (Get-BlobPrivacyOverview) }),
        @('Optimize drives now', {
                if (-not $Blob.IsAdmin) { Show-BlobGuiAdminRequired 'Drive optimization needs administrator rights.'; return }
                if (Confirm-BlobGui -Title 'Optimize all fixed drives now?' -OkText 'Optimize' -Lines @('{Gray}Uses the built-in Windows optimizer (Optimize-Volume): SSDs get TRIM, hard drives are defragmented.', '{Gray}Safe to run. Hard drive defragmentation can take a long time; the window waits until it finishes.')) {
                    Start-BlobGuiTask 'Optimizing drives'; Invoke-BlobOptimizeDrives -Log { param($m) Add-BlobGuiLog $m } } }),
        @('Restart Explorer', { if (Confirm-BlobGui -Title 'Restart Windows Explorer?' -OkText 'Restart Explorer' -Lines @('{Gray}The taskbar and open Explorer windows close and reopen.')) { Restart-BlobExplorer; Add-BlobGuiLog '{Green}Explorer restarted.' } }),
        @('Windows Performance Options', { Start-Process 'SystemPropertiesPerformance.exe' -ErrorAction SilentlyContinue }),
        @('Windows privacy settings', { Start-Process 'ms-settings:privacy' -ErrorAction SilentlyContinue }))
    foreach ($d in $toolDefs) { $tb = New-BlobButton $d[0] $d[1]; $tb.Margin = '0,0,8,8'; [void]$tools.Children.Add($tb) }
    [void]$root.Children.Add((New-BlobCard $tools))

    $Blob.Gui.ApplySelBtn = New-BlobButton 'Apply selected' {
        $sel = Get-BlobGuiSelectedTweaks
        if (Invoke-BlobGuiApply -Tweaks $sel -Tag 'selection') { $Blob.Gui.Selected.Clear(); Update-BlobGuiPage } } 'Accent' -Margin '0'
    Set-BlobGuiPageActions @(
        (New-BlobButton 'Select shown' { foreach ($t in (Get-BlobGuiFilteredTweaks)) { $Blob.Gui.Selected[$t.Id] = $true }; Update-BlobGuiCardGrid }),
        (New-BlobButton 'Clear selection' { $Blob.Gui.Selected.Clear(); Update-BlobGuiCardGrid }),
        (New-BlobButton 'Undo selected' { $null = Invoke-BlobGuiUndo (Get-BlobGuiSelectedTweaks) } -ToolTip 'Restore the original values saved by BLOB OPTIMIZER'),
        $Blob.Gui.ApplySelBtn)
    Update-BlobGuiCardGrid
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
    $wrap = [Windows.Controls.WrapPanel]::new()
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
