# ============================================================================
#  BLOB OPTIMIZER - GuiPages.ps1
#  Window pages: page list, Overview, Presets, Tweaks, System, External tools.
#  Every action previews exact changes in a dialog before anything happens.
# ============================================================================

function Get-BlobGuiPages {
    @(
        @{ Key = 'dashboard'; Label = 'Overview'; Subtitle = 'Where this PC stands, and where to start.'; Build = { New-BlobGuiDashboard } }
        @{ Key = 'presets'; Label = 'Presets'; Subtitle = 'Three tested bundles. Each one lists every value it changes before anything happens.'; Build = { New-BlobGuiPresets } }
        @{ Key = 'optimize'; Label = 'Tweaks'; Subtitle = 'Switch what you want on or off. Nothing is changed until you review and apply.'; Build = { New-BlobGuiOptimizations } }
        @{ Key = 'privacy'; Label = 'Privacy'; Subtitle = "$(@(Get-BlobPrivacyItems).Count) privacy settings in $($Blob.PrivacyGroups.Count) sections. Every one explained, rated and recommended. Nothing changes until you review and apply."; Build = { New-BlobGuiPrivacy } }
        @{ Key = 'services'; Label = 'Services'; Subtitle = 'Startup types only. Nothing is deleted, and services Windows depends on are locked.'; Build = { New-BlobGuiServices } }
        @{ Key = 'startup'; Label = 'Startup'; Subtitle = 'Programs that start when you sign in. Disabled the same way Task Manager does it.'; Build = { New-BlobGuiStartup } }
        @{ Key = 'apps'; Label = 'Apps'; Subtitle = 'Remove programs completely: their own uninstaller first, then the leftovers you choose.'; Build = { New-BlobGuiApps } }
        @{ Key = 'install'; Label = 'Install'; Subtitle = 'Popular apps, installed with winget from the official winget repository.'; Build = { New-BlobGuiInstall } }
        @{ Key = 'cleanup'; Label = 'Cleanup'; Subtitle = 'Temporary files and caches. Sizes are measured first; deleted files are gone for good.'; Build = { New-BlobGuiCleanup } }
        @{ Key = 'network'; Label = 'Network'; Subtitle = 'Adapters, DNS, diagnostics and the last-resort resets.'; Build = { New-BlobGuiNetwork } }
        @{ Key = 'power'; Label = 'Power'; Subtitle = 'Power plans, screen and sleep timers, hibernation.'; Build = { New-BlobGuiPower } }
        @{ Key = 'measure'; Label = 'Measure'; Subtitle = 'Real numbers: boot times from Windows and snapshots you can compare.'; Build = { New-BlobGuiMeasure } }
        @{ Key = 'restore'; Label = 'Restore'; Subtitle = 'Everything BLOB has changed, and the way back.'; Build = { New-BlobGuiRestore } }
        @{ Key = 'tools'; Label = 'External tools'; Subtitle = 'Two well-known third-party utilities, started on request.'; Build = { New-BlobGuiTools } }
        @{ Key = 'sysinfo'; Label = 'System'; Subtitle = 'Hardware and Windows details. Read-only.'; Build = { New-BlobGuiSysInfo } }
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
    $Blob.Gui.Collected = New-Object System.Collections.ArrayList
    $out = Invoke-BlobTweakCore -Tweaks $Tweaks -Tag $Tag -Log $Blob.GuiShared.LogCollect
    Add-BlobGuiLog "{Cyan}$($out.Summary)"
    Show-BlobGuiChangeSummary 'What changed'
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
# A large readout: label, big number, small note. Used in a row divided by rules.
function New-BlobReadout {
    param([string]$Label, [string]$Value, [string]$Note = '', [bool]$First = $false, [string]$ValueColor = 'Ink')
    $b = [Windows.Controls.Border]::new()
    $b.BorderBrush = Get-BlobBrush 'Rule'; $b.BorderThickness = $(if ($First) { '0' } else { '1,0,0,0' })
    $b.Padding = $(if ($First) { '0,2,24,2' } else { '24,2,24,2' })
    $sp = New-BlobStack
    [void]$sp.Children.Add((New-BlobText $Label.ToUpper() 12 'Ink3' 'Normal' -Display))
    [void]$sp.Children.Add((New-BlobText $Value 44 $ValueColor 'Light' '0,2,0,0' -Display))
    if ($Note) { [void]$sp.Children.Add((New-BlobText $Note 12.5 'Ink2')) }
    $b.Child = $sp
    return $b
}

function New-BlobSpecRow {
    param([string]$Label, [string]$Value, [string]$ValueColor = 'Ink')
    $b = [Windows.Controls.Border]::new()
    $b.BorderBrush = Get-BlobBrush 'Rule'; $b.BorderThickness = '0,0,0,1'; $b.Padding = '0,9'
    $d = [Windows.Controls.DockPanel]::new()
    $l = New-BlobText $Label 12.5 'Ink3'
    $l.Width = 120
    [void]$d.Children.Add($l)
    [void]$d.Children.Add((New-BlobText $Value 13 $ValueColor))
    $b.Child = $d
    return $b
}

# A full-width action row: title, one line of explanation, an arrow.
function New-BlobActionRow {
    param([string]$Title, [string]$Note, [scriptblock]$Action)
    $btn = [Windows.Controls.Button]::new()
    $btn.Style = $Blob.Gui.Window.FindResource('RowButton')
    $d = [Windows.Controls.DockPanel]::new()
    $arrow = New-BlobText ([string][char]0x2192) 19 'Ink' 'Normal' '12,0,6,0' -Display
    $arrow.VerticalAlignment = 'Center'
    [Windows.Controls.DockPanel]::SetDock($arrow, 'Right')
    [void]$d.Children.Add($arrow)
    $sp = New-BlobStack
    [void]$sp.Children.Add((New-BlobText $Title 15.5 'Ink' 'SemiBold' -Display))
    [void]$sp.Children.Add((New-BlobText $Note 12.5 'Ink2' 'Normal' '0,2,0,0'))
    [void]$d.Children.Add($sp)
    $btn.Content = $d
    Register-BlobClick $btn $Action
    return $btn
}

function New-BlobGuiDashboard {
    $root = New-BlobStack
    $si = $Blob.SysInfo
    $core = @(Get-BlobCoreTweaks)
    $applied = @($core | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
    $restorable = @(Get-BlobAppliedChanges).Count

    $drift = @(Get-BlobDrift)
    if ($drift.Count) { [void]$root.Children.Add((New-BlobDriftBar $drift)) }

    # Readouts
    $row = [Windows.Controls.Grid]::new()
    $row.Margin = '0,4,0,34'
    for ($i = 0; $i -lt 4; $i++) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = '*'; $row.ColumnDefinitions.Add($cd) }
    $cells = @()
    $cells += New-BlobReadout 'Tweaks on' "$applied/$($core.Count)" 'detected from current settings' $true
    $memNote = ''; $memVal = '-'
    try {
        $os = Get-BlobPrefetch 'OS'
        if (-not $os) { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop }
        $total = [double]$os.TotalVisibleMemorySize * 1KB; $used = $total - [double]$os.FreePhysicalMemory * 1KB
        $memVal = '{0:N0}%' -f (100 * $used / $total); $memNote = '{0} of {1} in use' -f (Format-BlobSize $used), (Format-BlobSize $total)
    } catch { }
    $cells += New-BlobReadout 'Memory' $memVal $memNote
    $diskVal = '-'; $diskNote = ''
    try {
        $c = @(Get-BlobPrefetch 'LogicalDisks') | Where-Object { $_.DeviceID -eq $env:SystemDrive } | Select-Object -First 1
        if (-not $c) { $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop }
        $diskVal = Format-BlobSize $c.FreeSpace; $diskNote = "free on $($env:SystemDrive) of $(Format-BlobSize $c.Size)"
    } catch { }
    $cells += New-BlobReadout 'Disk' $diskVal $diskNote
    $cells += New-BlobReadout 'Undo' "$restorable" 'changes can be restored'
    for ($i = 0; $i -lt 4; $i++) { [Windows.Controls.Grid]::SetColumn($cells[$i], $i); [void]$row.Children.Add($cells[$i]) }
    [void]$root.Children.Add($row)

    # Two columns: this PC / start here
    $cols = [Windows.Controls.Grid]::new()
    $c0 = [Windows.Controls.ColumnDefinition]::new(); $c0.Width = '5*'
    $cg = [Windows.Controls.ColumnDefinition]::new(); $cg.Width = '44'
    $c1 = [Windows.Controls.ColumnDefinition]::new(); $c1.Width = '6*'
    $cols.ColumnDefinitions.Add($c0); $cols.ColumnDefinitions.Add($cg); $cols.ColumnDefinitions.Add($c1)

    $spec = New-BlobStack
    [void]$spec.Children.Add((New-BlobHeading 'This PC' '0,0,0,2'))
    [void]$spec.Children.Add((New-BlobSpecRow 'Windows' $si.OS))
    [void]$spec.Children.Add((New-BlobSpecRow 'Processor' $si.CPU))
    [void]$spec.Children.Add((New-BlobSpecRow 'Graphics' $si.GPU))
    [void]$spec.Children.Add((New-BlobSpecRow 'Memory' $si.RAM))
    [void]$spec.Children.Add((New-BlobSpecRow 'Power plan' (Get-BlobActivePowerPlan).Name))
    [void]$spec.Children.Add((New-BlobSpecRow 'Computer' "$($si.Host), up $($si.Uptime)"))
    [void]$spec.Children.Add((New-BlobSpecRow 'Rights' $(if ($Blob.IsAdmin) { 'Administrator' } else { 'Limited - system settings are read-only' }) $(if ($Blob.IsAdmin) { 'Ink' } else { 'SignalText' })))
    [Windows.Controls.Grid]::SetColumn($spec, 0); [void]$cols.Children.Add($spec)

    $start = New-BlobStack
    [void]$start.Children.Add((New-BlobHeading 'Start here' '0,0,0,2'))
    [void]$start.Children.Add((New-BlobActionRow 'Apply a preset' 'Minimal, Standard or Advanced. Every value is shown before it changes.' { Show-BlobGuiPage 'presets' }))
    [void]$start.Children.Add((New-BlobActionRow 'Pick individual tweaks' "$($core.Count) settings, sorted by what they affect and how risky they are." { Show-BlobGuiPage 'optimize' }))
    [void]$start.Children.Add((New-BlobActionRow 'Review your privacy' "$(@(Get-BlobPrivacyItems).Count) privacy settings in $($Blob.PrivacyGroups.Count) sections, each explained with a clear recommendation." { Show-BlobGuiPage 'privacy' }))
    [void]$start.Children.Add((New-BlobActionRow 'Remove an app completely' 'Its own uninstaller, then the folders and keys it leaves behind.' { Show-BlobGuiPage 'apps' }))
    [void]$start.Children.Add((New-BlobActionRow 'Install apps' 'Popular apps in one go with winget, which is built into Windows.' { Show-BlobGuiPage 'install' }))
    [void]$start.Children.Add((New-BlobActionRow 'Measure before and after' 'Boot times from Windows itself, plus snapshots to compare.' { Show-BlobGuiPage 'measure' }))
    [void]$start.Children.Add((New-BlobActionRow 'Clear temporary files' 'Measures caches and temp folders first, then asks.' { Show-BlobGuiPage 'cleanup' }))
    [void]$start.Children.Add((New-BlobActionRow 'Make a restore point' 'A Windows-level safety net before you change anything big.' { Invoke-BlobGuiRestorePoint }))
    [void]$start.Children.Add((New-BlobActionRow 'Review or undo changes' 'Every change BLOB made, with its original value.' { Show-BlobGuiPage 'restore' }))
    [Windows.Controls.Grid]::SetColumn($start, 2); [void]$cols.Children.Add($start)
    [void]$root.Children.Add($cols)

    [void]$root.Children.Add((New-BlobText 'BLOB never touches Microsoft Defender, Windows Firewall, SmartScreen, UAC or Windows Update.' 12 'Ink3' 'Normal' '0,30,0,0'))
    return $root
}

# ---------------------------------------------------------------------------
#  Presets
# ---------------------------------------------------------------------------
function New-BlobGuiPresets {
    $root = New-BlobStack
    $grid = [Windows.Controls.Primitives.UniformGrid]::new()
    $grid.Columns = 3; $grid.Margin = '0,6,0,0'
    $presets = @(Get-BlobPresets)
    $maxRisk = @{ MINIMAL = 'Minimal'; STANDARD = 'Standard'; ADVANCED = 'Advanced' }
    for ($i = 0; $i -lt $presets.Count; $i++) {
        $p = $presets[$i]
        $tw = @($p.Ids | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
        $on = @($tw | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
        $col = [Windows.Controls.Border]::new()
        $col.BorderBrush = Get-BlobBrush 'Rule'
        $col.BorderThickness = $(if ($i -eq 0) { '0' } else { '1,0,0,0' })
        $col.Padding = $(if ($i -eq 0) { '0,0,28,0' } else { '28,0,28,0' })
        $d = [Windows.Controls.DockPanel]::new()

        $btn = New-BlobButton 'Review and apply' ([scriptblock]::Create("Invoke-BlobGuiPreset '$($p.Name -replace "'", "''")'")) $(if ($i -eq 1) { 'Accent' } else { 'Normal' })
        $btn.HorizontalAlignment = 'Stretch'; $btn.Margin = '0,18,0,0'; $btn.Padding = '14,9'
        [Windows.Controls.DockPanel]::SetDock($btn, 'Bottom')
        [void]$d.Children.Add($btn)

        $sp = New-BlobStack
        $name = $p.Name.Substring(0, 1) + $p.Name.Substring(1).ToLower()
        [void]$sp.Children.Add((New-BlobText $name 30 'Ink' 'SemiBold' -Display))
        $meta = New-BlobStack 'Horizontal' '0,6,0,14'
        if ($maxRisk.ContainsKey($p.Name)) { [void]$meta.Children.Add((New-BlobRiskBadge $maxRisk[$p.Name])) }
        [void]$meta.Children.Add((New-BlobText "  $($tw.Count) tweaks, $on already on" 12 'Ink3' 'Normal' '10,0,0,0' -Mono))
        [void]$sp.Children.Add($meta)
        $desc = New-BlobText $p.Description 13.5 'Ink2'
        $desc.MinHeight = 60
        [void]$sp.Children.Add($desc)
        if ($p.Warning) { [void]$sp.Children.Add((New-BlobText $p.Warning 12.5 'SignalText' 'Normal' '0,10,0,0')) }
        [void]$sp.Children.Add((New-BlobText 'INCLUDES' 11.5 'Ink3' 'Normal' '0,18,0,6' -Display))
        foreach ($t in $tw) {
            $line = [Windows.Controls.DockPanel]::new()
            $line.Margin = '0,0,0,5'
            $st = Get-BlobTweakState $t
            $mark = [Windows.Shapes.Rectangle]::new()
            $mark.Width = 8; $mark.Height = 8; $mark.Margin = '0,5,10,0'; $mark.VerticalAlignment = 'Top'
            $mark.Stroke = $(if ($t.Risk -eq 'Advanced') { Get-BlobBrush 'Signal' } else { Get-BlobBrush 'Ink' }); $mark.StrokeThickness = 1.2
            $mark.Fill = $(if ($st -eq 'Applied') { $mark.Stroke } else { [Windows.Media.Brushes]::Transparent })
            [void]$line.Children.Add($mark)
            [void]$line.Children.Add((New-BlobText $t.Name 12.5 'Ink'))
            [void]$sp.Children.Add($line)
        }
        [void]$sp.Children.Add((New-BlobText 'Filled = already on.  Outline = will change.  Orange = higher risk.' 11.5 'Ink3' 'Normal' '0,10,0,0'))
        [void]$d.Children.Add($sp)
        $col.Child = $d
        [void]$grid.Children.Add($col)
    }
    [void]$root.Children.Add($grid)
    [void]$root.Children.Add((New-BlobText 'Personal-preference tweaks are never part of a preset. Everything a preset changes can be undone from Restore.' 12 'Ink3' 'Normal' '0,28,0,0'))
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

$Blob.GuiRiskFilters = [ordered]@{ All = 'All'; Minimal = 'Low risk'; Standard = 'Medium risk'; Advanced = 'High risk'; Optional = 'Preference' }

function Get-BlobGuiFilteredTweaks {
    $list = @(Get-BlobCoreTweaks)
    if ($Blob.Gui.OptFilter -and $Blob.Gui.OptFilter -ne 'All') { $list = @($list | Where-Object { $_.Category -eq $Blob.Gui.OptFilter }) }
    if ($Blob.Gui.OptRisk -and $Blob.Gui.OptRisk -ne 'All') { $list = @($list | Where-Object { $_.Risk -eq $Blob.Gui.OptRisk }) }
    $q = [string]$Blob.Gui.OptSearch
    if ($q.Trim()) {
        $q = $q.Trim()
        $list = @($list | Where-Object { $_.Name -like "*$q*" -or $_.Description -like "*$q*" -or $_.Category -like "*$q*" })
    }
    return $list
}

function New-BlobChip {
    param([string]$Text)
    return (New-BlobText $Text.ToUpper() 11 'Ink3' 'Normal' -Display)
}

# Plain-text markers: ! warning, ADMIN lock, > search.
function New-BlobGlyph {
    param([int]$Code, [string]$Color = 'Gray', [double]$Size = 13)
    $map = @{ 0xE7BA = '!'; 0xE72E = 'ADMIN'; 0xE721 = [string][char]0x2315; 0xE710 = '+'; 0xE73E = 'x' }
    $t = New-BlobText $(if ($map.ContainsKey($Code)) { $map[$Code] } else { '*' }) $Size $Color 'SemiBold' -Display
    $t.VerticalAlignment = 'Center'
    return $t
}

# One tweak as a ruled row: [marker][switch][name + description][risk][state][?]
function New-BlobTweakCard {
    param($Tweak, [string]$State, [string]$Pending)
    $state = $State
    $wantOn = if ($Pending) { $Pending -eq 'On' } else { $state -eq 'Applied' }
    $row = [Windows.Controls.Border]::new()
    $row.BorderBrush = Get-BlobBrush 'Rule'; $row.BorderThickness = '0,0,0,1'
    $row.Background = if ($Pending) { Get-BlobBrush 'SignalSoft' } else { [Windows.Media.Brushes]::Transparent }
    $row.Uid = $(if ($Pending) { 'P' } else { '' })
    $row.Add_MouseEnter({ param($s, $e) if ($s.Uid -ne 'P') { $s.Background = Get-BlobBrush 'Hover' } })
    $row.Add_MouseLeave({ param($s, $e) if ($s.Uid -ne 'P') { $s.Background = [Windows.Media.Brushes]::Transparent } })
    $g = [Windows.Controls.Grid]::new()
    foreach ($w in @('4', '58', '*', '96', '112', '34')) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = $w; $g.ColumnDefinitions.Add($cd) }

    $marker = [Windows.Controls.Border]::new()
    $marker.Background = if ($Pending) { Get-BlobBrush 'Signal' } else { [Windows.Media.Brushes]::Transparent }
    [void]$g.Children.Add($marker)

    $sw = [Windows.Controls.CheckBox]::new()
    $sw.Style = $Blob.Gui.Window.FindResource('Switch')
    $sw.IsChecked = $wantOn
    $sw.VerticalAlignment = 'Center'; $sw.HorizontalAlignment = 'Center'
    $row.Tag = $sw
    if ($Tweak.Admin -and -not $Blob.IsAdmin) {
        $sw.IsEnabled = $false
        $holder = [Windows.Controls.Border]::new()
        $holder.Background = [Windows.Media.Brushes]::Transparent; $holder.VerticalAlignment = 'Center'
        $holder.Child = $sw
        Set-BlobTooltip $holder (New-BlobTooltipPanel -Title 'Needs administrator rights' -Paragraphs @('This is a machine-wide setting. Start BLOB again and choose Yes in the Windows permission prompt to change it.'))
        [Windows.Controls.Grid]::SetColumn($holder, 1); [void]$g.Children.Add($holder)
    } else {
        $sw.DataContext = $Tweak.Id
        Register-BlobClick $sw $Blob.GuiShared.SwitchClick
        [Windows.Controls.Grid]::SetColumn($sw, 1); [void]$g.Children.Add($sw)
    }

    $text = New-BlobStack
    $text.Margin = '6,0,16,0'; $text.VerticalAlignment = 'Center'
    $title = New-BlobStack 'Horizontal'
    [void]$title.Children.Add((New-BlobText $Tweak.Name 14 'Ink' 'SemiBold'))
    if ($Tweak.Admin) { $ad = New-BlobBadge 'ADMIN' 'Ink3'; $ad.Margin = '10,1,0,0'; [void]$title.Children.Add($ad) }
    [void]$text.Children.Add($title)
    $desc = New-BlobText $Tweak.Description 12.5 'Ink2' 'Normal' '0,2,0,0'
    $desc.TextWrapping = 'NoWrap'; $desc.TextTrimming = 'CharacterEllipsis'
    [void]$text.Children.Add($desc)
    [Windows.Controls.Grid]::SetColumn($text, 2); [void]$g.Children.Add($text)

    $risk = New-BlobRiskBadge $Tweak.Risk
    [Windows.Controls.Grid]::SetColumn($risk, 3); [void]$g.Children.Add($risk)

    $arrow = [string][char]0x2192
    $stText = if ($Pending -eq 'On') { "$arrow ON" } elseif ($Pending -eq 'Off') { "$arrow OFF" } else { switch ($state) { 'Applied' { 'On' } 'Partial' { 'Partly on' } default { 'Off' } } }
    $stColor = if ($Pending) { 'SignalText' } elseif ($state -eq 'Applied') { 'Ink' } elseif ($state -eq 'Partial') { 'Ink2' } else { 'Ink3' }
    $st = New-BlobText $stText 13 $stColor $(if ($Pending -or $state -eq 'Applied') { 'SemiBold' } else { 'Normal' }) -Display
    $st.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($st, 4); [void]$g.Children.Add($st)

    $help = New-BlobHelpIcon -Builder $Blob.GuiShared.TweakTip
    $help.DataContext = $Tweak.Id
    $help.Margin = '0'; $help.HorizontalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($help, 5); [void]$g.Children.Add($help)

    $g.Margin = '0,10,0,10'
    $row.Child = $g
    return $row
}

# Returns the row for a tweak, reusing the cached element when its state and
# pending choice are unchanged (so switching, searching and filtering stay instant).
function Get-BlobGuiCard {
    param($Tweak, [string]$State)
    if (-not $Blob.Gui.CardCache) { $Blob.Gui.CardCache = @{} }
    $pend = [string]$Blob.Gui.Pending[$Tweak.Id]
    $c = $Blob.Gui.CardCache[$Tweak.Id]
    if (-not ($c -and $c.State -eq $State -and $c.Pending -eq $pend)) {
        $el0 = if ($Tweak.Section -eq 'PrivacyCenter') { New-BlobPrivacyRow $Tweak $State $pend } else { New-BlobTweakCard $Tweak $State $pend }
        $c = @{ Element = $el0; State = $State; Pending = $pend }
        $Blob.Gui.CardCache[$Tweak.Id] = $c
    }
    $el = $c.Element
    if ($el.Parent -is [Windows.Controls.Panel]) { $el.Parent.Children.Remove($el) }
    if ($el.Tag -is [Windows.Controls.CheckBox]) { $el.Tag.IsChecked = $(if ($pend) { $pend -eq 'On' } else { $State -eq 'Applied' }) }
    return $el
}

function New-BlobGroupHeader {
    param([string]$Title, [string]$Note)
    $b = [Windows.Controls.Border]::new()
    $b.BorderBrush = Get-BlobBrush 'Ink'; $b.BorderThickness = '0,0,0,1.5'; $b.Padding = '0,0,0,6'; $b.Margin = '0,26,0,0'
    $d = [Windows.Controls.DockPanel]::new()
    $n = New-BlobText $Note 12 'Ink3' 'Normal' -Mono
    $n.VerticalAlignment = 'Bottom'
    [Windows.Controls.DockPanel]::SetDock($n, 'Right')
    [void]$d.Children.Add($n)
    [void]$d.Children.Add((New-BlobText $Title 18 'Ink' 'SemiBold' -Display))
    $b.Child = $d
    return $b
}

function Update-BlobGuiCardGrid {
    $g = $Blob.Gui.CardGrid
    if (-not $g) { return }
    if ($Blob.Gui.Current -eq 'privacy') { Update-BlobGuiPrivacyList; return }
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    $g.Children.Clear()
    $states = @{}
    foreach ($t in (Get-BlobCoreTweaks)) { $states[$t.Id] = Get-BlobTweakState $t }
    $list = @(Get-BlobGuiFilteredTweaks)
    foreach ($cat in @($Blob.GuiCategories | Where-Object { $_ -ne 'All' })) {
        $inCat = @($list | Where-Object { $_.Category -eq $cat })
        if ($inCat.Count -eq 0) { continue }
        $onCount = @($inCat | Where-Object { $states[$_.Id] -eq 'Applied' }).Count
        [void]$g.Children.Add((New-BlobGroupHeader $cat "$onCount of $($inCat.Count) on"))
        foreach ($t in $inCat) { [void]$g.Children.Add((Get-BlobGuiCard $t $states[$t.Id])) }
    }
    if ($list.Count -eq 0) { [void]$g.Children.Add((New-BlobText 'Nothing matches these filters.' 14 'Ink3' 'Normal' '0,30,0,0')) }
    $active = @($states.Values | Where-Object { $_ -eq 'Applied' }).Count
    $n = $Blob.Gui.Pending.Count
    $dot = [string][char]0x00B7
    $Blob.Gui.CardCount.Text = "$($list.Count) shown  $dot  $active of $($states.Count) on  $dot  $n waiting"
    Update-BlobGuiPendingBar
    $Blob.Gui.PageScroll.UpdateLayout(); $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
}

# A switch only records what you want; nothing changes until Review and apply.
function Switch-BlobGuiTweak {
    param([string]$Id)
    $t = Get-BlobTweak $Id
    if (-not $t) { return }
    $state = Get-BlobTweakState $t
    $cur = $Blob.Gui.Pending[$Id]
    $isOn = if ($cur) { $cur -eq 'On' } else { $state -eq 'Applied' }
    if (-not $isOn) {
        if ($state -eq 'Applied') { $Blob.Gui.Pending.Remove($Id) } else { $Blob.Gui.Pending[$Id] = 'On' }
    } else {
        if ($state -eq 'Applied') { $Blob.Gui.Pending[$Id] = 'Off' } else { $Blob.Gui.Pending.Remove($Id) }
    }
    Update-BlobGuiCardGrid
}

function Invoke-BlobGuiApplyPending {
    $on = @($Blob.Gui.Pending.Keys | Where-Object { $Blob.Gui.Pending[$_] -eq 'On' } | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
    $off = @($Blob.Gui.Pending.Keys | Where-Object { $Blob.Gui.Pending[$_] -eq 'Off' } | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
    if ($on.Count + $off.Count -eq 0) {
        Show-BlobGuiMessage -Title 'Nothing to apply' -Lines @('{Gray}Switch the tweaks you want on or off first.', '{Gray}Nothing changes until you review and apply.')
        return
    }
    $lines = @()
    if ($on.Count) {
        $lines += "{Cyan}ACTIVATE ($($on.Count))"
        $lines += @(Get-BlobTweakPreview $on | Select-Object -SkipLast 2)
    }
    $undo = $null
    if ($off.Count) {
        $undo = Get-BlobUndoPlan $off
        $lines += "{Cyan}DEACTIVATE ($($off.Count)) - restore the values saved before they were changed"
        $lines += $undo.Lines
        $lines += ''
    }
    $lines += '{Gray}Original values are saved to the change journal before anything is modified.'
    $total = $on.Count + $off.Count
    $danger = @($on | Where-Object { $_.Risk -eq 'Advanced' }).Count -gt 0
    $canRp = $Blob.IsAdmin -and -not $Blob.DryRun
    $rpText = if ($canRp) { 'Create a System Restore point first (recommended)' } elseif ($Blob.DryRun) { 'Create a System Restore point first (not available in dry run)' } else { 'Create a System Restore point first (requires administrator)' }
    $noun = if ($total -eq 1) { 'change' } else { 'changes' }
    $ok = Show-BlobGuiDialog -Title "Apply $total ${noun}?" -Subtitle 'These exact settings will change.' -Lines $lines -Danger:$danger `
        -OkText "Apply $total $noun" -CheckText $rpText -CheckDefault $canRp -CheckEnabled $canRp
    if (-not $ok) { return }
    if ($Blob.Gui.DialogCheck) { Invoke-BlobGuiRestorePointStep 'BLOB OPTIMIZER - before applying changes' }
    $needsExplorer = $false
    $Blob.Gui.Collected = New-Object System.Collections.ArrayList
    if ($on.Count) {
        Start-BlobGuiTask "Activating $($on.Count) setting(s)"
        $out = Invoke-BlobTweakCore -Tweaks $on -Tag 'changes' -Log $Blob.GuiShared.LogCollect
        Add-BlobGuiLog "{Cyan}$($out.Summary)"
        $needsExplorer = $out.NeedsExplorer
    }
    if ($undo -and $undo.Records.Count) {
        Start-BlobGuiTask "Deactivating $($off.Count) setting(s)"
        $a, $b = Invoke-BlobRestoreCore -Records $undo.Records -Log $Blob.GuiShared.LogCollect
        Add-BlobGuiLog ("{Cyan}Deactivated: {0} value(s) restored, {1} not restored." -f $a, $b)
        if (@($off | Where-Object { $_.RestartExplorer }).Count) { $needsExplorer = $true }
    }
    $Blob.Gui.Pending.Clear()
    Show-BlobGuiChangeSummary 'What changed'
    if ($needsExplorer -and -not $Blob.DryRun) {
        if (Show-BlobGuiDialog -Title 'Restart Windows Explorer now?' -OkText 'Restart Explorer' -CancelText 'Later' -Lines @(
                '{Gray}Some changes appear only after Explorer restarts.',
                '{Gray}The taskbar and open Explorer windows close and reopen. Choose Later to restart or sign out yourself.')) {
            Restart-BlobExplorer; Add-BlobGuiLog '{Green}Explorer restarted.'
        }
    }
    Update-BlobGuiPage
}

# Text filter: active one in ink with a signal underline.
function New-BlobGuiFilterChip {
    param([string]$Text, [bool]$Active, [scriptblock]$Action)
    $b = [Windows.Controls.Button]::new()
    $b.Style = $Blob.Gui.Window.FindResource('ChipButton')
    $b.Content = $Text
    if ($Active) { $b.Foreground = Get-BlobBrush 'Ink'; $b.BorderBrush = Get-BlobBrush 'Signal'; $b.FontWeight = 'SemiBold' }
    Register-BlobClick $b $Action
    return $b
}

function New-BlobFilterRow {
    param([string]$Label, $Chips)
    $d = [Windows.Controls.DockPanel]::new()
    $d.Margin = '0,0,0,2'
    $l = New-BlobText $Label.ToUpper() 11.5 'Ink3' 'Normal' '0,5,0,0' -Display
    $l.Width = 86
    [void]$d.Children.Add($l)
    [void]$d.Children.Add($Chips)
    return $d
}

function New-BlobGuiOptimizations {
    $root = New-BlobStack
    $top = [Windows.Controls.DockPanel]::new()

    # Search (underline field with a hint)
    $sbox = [Windows.Controls.Grid]::new()
    $sbox.Width = 240; $sbox.VerticalAlignment = 'Top'; $sbox.Margin = '24,0,0,0'
    $search = [Windows.Controls.TextBox]::new()
    $search.Text = [string]$Blob.Gui.OptSearch; $search.Padding = '22,5,2,5'
    $hint = New-BlobText 'Search' 13.5 'Ink3' 'Normal' '23,6,0,0'
    $hint.IsHitTestVisible = $false
    if ($search.Text) { $hint.Visibility = 'Collapsed' }
    $glass = New-BlobGlyph 0xE721 'Ink2' 15
    $glass.Margin = '1,0,0,2'; $glass.HorizontalAlignment = 'Left'; $glass.IsHitTestVisible = $false
    [void]$sbox.Children.Add($search); [void]$sbox.Children.Add($hint); [void]$sbox.Children.Add($glass)
    $Blob.Gui.SearchHint = $hint
    $search.Add_TextChanged({
            param($s, $e)
            $Blob.Gui.OptSearch = $s.Text
            $Blob.Gui.SearchHint.Visibility = if ($s.Text) { 'Collapsed' } else { 'Visible' }
            Update-BlobGuiCardGrid
        })
    [Windows.Controls.DockPanel]::SetDock($sbox, 'Right')
    [void]$top.Children.Add($sbox)

    $filters = New-BlobStack
    $cats = [Windows.Controls.WrapPanel]::new()
    foreach ($c in $Blob.GuiCategories) {
        $count = if ($c -eq 'All') { @(Get-BlobCoreTweaks).Count } else { @(Get-BlobCoreTweaks | Where-Object { $_.Category -eq $c }).Count }
        [void]$cats.Children.Add((New-BlobGuiFilterChip "$c $count" ($Blob.Gui.OptFilter -eq $c) ([scriptblock]::Create("`$Blob.Gui.OptFilter = '$c'; Show-BlobGuiPage 'optimize' -Rebuild"))))
    }
    [void]$filters.Children.Add((New-BlobFilterRow 'Area' $cats))
    if (-not $Blob.Gui.OptRisk) { $Blob.Gui.OptRisk = 'All' }
    $risks = [Windows.Controls.WrapPanel]::new()
    foreach ($k in $Blob.GuiRiskFilters.Keys) {
        $count = if ($k -eq 'All') { @(Get-BlobCoreTweaks).Count } else { @(Get-BlobCoreTweaks | Where-Object { $_.Risk -eq $k }).Count }
        [void]$risks.Children.Add((New-BlobGuiFilterChip "$($Blob.GuiRiskFilters[$k]) $count" ($Blob.Gui.OptRisk -eq $k) ([scriptblock]::Create("`$Blob.Gui.OptRisk = '$k'; Show-BlobGuiPage 'optimize' -Rebuild"))))
    }
    [void]$filters.Children.Add((New-BlobFilterRow 'Risk' $risks))
    [void]$top.Children.Add($filters)
    [void]$root.Children.Add($top)

    $info = [Windows.Controls.DockPanel]::new()
    $info.Margin = '0,10,0,0'
    $legend = New-BlobRiskLegend
    [Windows.Controls.DockPanel]::SetDock($legend, 'Right')
    [void]$info.Children.Add($legend)
    $Blob.Gui.CardCount = New-BlobText '' 12 'Ink3' 'Normal' -Mono
    $Blob.Gui.CardCount.VerticalAlignment = 'Center'
    [void]$info.Children.Add($Blob.Gui.CardCount)
    [void]$root.Children.Add($info)

    $list = New-BlobStack
    $Blob.Gui.CardGrid = $list
    [void]$root.Children.Add($list)

    [void]$root.Children.Add((New-BlobHeading 'Related tools' '0,36,0,4'))
    $toolDefs = @(
        @('Memory and resources', 'What is using RAM and CPU right now.', { Show-BlobGuiMessage -Title 'Memory and resources' -Lines (Get-BlobMemoryInfo) }),
        @('Gaming status', 'Game Mode, recording, GPU scheduling and drivers at a glance.', { Show-BlobGuiMessage -Title 'Gaming status' -Lines (Get-BlobGamingStatus) }),
        @('Privacy overview', 'Your diagnostic-data level and every privacy setting.', { Show-BlobGuiMessage -Title 'Privacy overview' -Lines (Get-BlobPrivacyOverview) }),
        @('Optimize drives', 'TRIM for SSDs, defragmentation for hard drives (Windows Optimize-Volume).', {
                if (-not $Blob.IsAdmin) { Show-BlobGuiAdminRequired 'Drive optimization needs administrator rights.'; return }
                if (Confirm-BlobGui -Title 'Optimize all fixed drives now?' -OkText 'Optimize' -Lines @('{Gray}Uses the built-in Windows optimizer (Optimize-Volume): SSDs get TRIM, hard drives are defragmented.', '{Gray}Safe to run. Hard drive defragmentation can take a long time; the window waits until it finishes.')) {
                    Start-BlobGuiTask 'Optimizing drives'; Invoke-BlobOptimizeDrives -Log { param($m) Add-BlobGuiLog $m } } }),
        @('Restart Explorer', 'Makes taskbar and Explorer changes show up without signing out.', { if (Confirm-BlobGui -Title 'Restart Windows Explorer?' -OkText 'Restart Explorer' -Lines @('{Gray}The taskbar and open Explorer windows close and reopen.')) { Restart-BlobExplorer; Add-BlobGuiLog '{White}Explorer restarted.' } }))
    foreach ($d in $toolDefs) { [void]$root.Children.Add((New-BlobActionRow $d[0] $d[1] $d[2])) }

    Set-BlobGuiPageActions @(
        (New-BlobButton 'Choose all shown' {
                foreach ($t in (Get-BlobGuiFilteredTweaks)) {
                    if ($t.Admin -and -not $Blob.IsAdmin) { continue }
                    if ((Get-BlobTweakState $t) -ne 'Applied') { $Blob.Gui.Pending[$t.Id] = 'On' } elseif ($Blob.Gui.Pending[$t.Id] -eq 'Off') { $Blob.Gui.Pending.Remove($t.Id) }
                }
                Update-BlobGuiCardGrid } -ToolTip 'Mark every tweak currently shown to be switched on. Nothing changes until you review and apply.' -Margin '0'))
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
