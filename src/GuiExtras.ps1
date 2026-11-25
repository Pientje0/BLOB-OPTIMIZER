# ============================================================================
#  BLOB OPTIMIZER - GuiExtras.ps1
#  Drift bar and flows, Undo everything, Install page (winget), Measure page,
#  global search (Ctrl+K) and the "What changed" summary after applying.
# ============================================================================

# ---------------------------------------------------------------------------
#  Drift: settings Windows (or you) changed back
# ---------------------------------------------------------------------------
function New-BlobDriftBar {
    param([array]$Drift)
    $b = [Windows.Controls.Border]::new()
    $b.Background = Get-BlobBrush 'SignalSoft'; $b.BorderBrush = Get-BlobBrush 'Signal'; $b.BorderThickness = '3,0,0,0'
    $b.Padding = '18,14'; $b.Margin = '0,0,0,26'
    $d = [Windows.Controls.DockPanel]::new()
    $btns = New-BlobStack 'Horizontal'
    [Windows.Controls.DockPanel]::SetDock($btns, 'Right')
    [void]$btns.Children.Add((New-BlobButton 'Details' { Show-BlobGuiDriftDetails }))
    [void]$btns.Children.Add((New-BlobButton "Keep Windows' values" { Invoke-BlobGuiDriftAccept }))
    [void]$btns.Children.Add((New-BlobButton "Re-apply $($Drift.Count)" { Invoke-BlobGuiDriftRepair } 'Accent' -Margin '0'))
    $btns.VerticalAlignment = 'Center'
    [void]$d.Children.Add($btns)
    $t = New-BlobStack
    [void]$t.Children.Add((New-BlobText $(if ($Drift.Count -eq 1) { "1 of your settings was changed back" } else { "$($Drift.Count) of your settings were changed back" }) 16 'Ink' 'SemiBold' -Display))
    [void]$t.Children.Add((New-BlobText 'Windows updates (or a change in Settings) put them back. Re-apply them, or keep the current values.' 12.5 'Ink2' 'Normal' '0,3,16,0'))
    [void]$d.Children.Add($t)
    $b.Child = $d
    return $b
}

function Get-BlobDriftLines {
    param([array]$Drift)
    return @($Drift | ForEach-Object { "{White}$($_.Label)"; "{Gray}    $($_.Target)"; "{DarkGray}        now $($_.Now) {White}-> {White}BLOB set $($_.Want)" })
}

function Show-BlobGuiDriftDetails {
    $drift = @(Get-BlobDrift)
    Show-BlobGuiMessage -Title "$($drift.Count) setting(s) changed back" -Lines (@('{Gray}These were changed by BLOB and later put back by Windows or in Settings.', '') + (Get-BlobDriftLines $drift))
}

function Invoke-BlobGuiDriftRepair {
    $drift = @(Get-BlobDrift)
    if ($drift.Count -eq 0) { Update-BlobGuiPage; return }
    $ok = Show-BlobGuiDialog -Title "Re-apply $($drift.Count) setting(s)?" -Subtitle 'Your original values stay saved, so undo still returns the PC to how it was before BLOB.' `
        -Lines (Get-BlobDriftLines $drift) -OkText 'Re-apply'
    if (-not $ok) { return }
    Start-BlobGuiTask 'Re-applying settings that were changed back'
    $Blob.Gui.Collected = New-Object System.Collections.ArrayList
    foreach ($i in $drift) { $line = Repair-BlobDrift $i; Add-BlobGuiLog $line; [void]$Blob.Gui.Collected.Add($line) }
    Show-BlobGuiChangeSummary 'Re-applied settings'
    Update-BlobGuiPage
}

function Invoke-BlobGuiDriftAccept {
    $drift = @(Get-BlobDrift)
    if ($drift.Count -eq 0) { Update-BlobGuiPage; return }
    $ok = Show-BlobGuiDialog -Title "Keep the current values?" -OkText "Keep Windows' values" -Lines (@(
            '{Gray}BLOB stops tracking these settings and leaves them as they are now.',
            '{Gray}They will no longer appear in Undo everything.', '') + (Get-BlobDriftLines $drift))
    if (-not $ok) { return }
    foreach ($i in $drift) { Set-BlobDriftAccepted $i }
    Add-BlobGuiLog "{White}Kept the current values of $($drift.Count) setting(s)."
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  Undo everything
# ---------------------------------------------------------------------------
function Invoke-BlobGuiUndoEverything {
    $recs = @(Get-BlobAppliedChanges)
    if ($recs.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing to undo' -Lines @('{Gray}BLOB has no changes that can be undone on this PC.'); return }
    $bySource = $recs | Group-Object { $_.Label } | Sort-Object Count -Descending
    $lines = @('{White}Every value below goes back to what it was before BLOB changed it:', '')
    $lines += @($bySource | ForEach-Object { "{Gray}  $($_.Name)  {DarkGray}($($_.Count) value(s))" })
    $lines += ''; $lines += '{Gray}Removed app leftovers in the Recycle Bin and cleaned files are not affected.'
    $canRp = $Blob.IsAdmin -and -not $Blob.DryRun
    $ok = Show-BlobGuiDialog -Title "Undo all $($recs.Count) change(s)?" -Subtitle 'Puts this PC back the way it was before BLOB.' -Lines $lines -OkText 'Undo everything' -Danger `
        -CheckText $(if ($canRp) { 'Create a System Restore point first' } else { 'Create a System Restore point first (needs administrator, not in dry run)' }) -CheckDefault $false -CheckEnabled $canRp
    if (-not $ok) { return }
    if ($Blob.Gui.DialogCheck) { Invoke-BlobGuiRestorePointStep 'BLOB OPTIMIZER - before undo everything' }
    Start-BlobGuiTask "Undoing $($recs.Count) change(s)"
    $Blob.Gui.Collected = New-Object System.Collections.ArrayList
    $a, $b = Invoke-BlobRestoreCore -Records $recs -Log $Blob.GuiShared.LogCollect
    Add-BlobGuiLog ("{White}Undo everything finished: {0} restored, {1} not restored." -f $a, $b)
    Show-BlobGuiChangeSummary 'Undo everything'
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  What changed
# ---------------------------------------------------------------------------
$Blob.GuiShared.LogCollect = { param($m) Add-BlobGuiLog $m; if ($null -ne $Blob.Gui.Collected) { [void]$Blob.Gui.Collected.Add($m) } }

function Show-BlobGuiChangeSummary {
    param([string]$Title = 'What changed')
    $lines = @($Blob.Gui.Collected | Where-Object { $_ -match '(OK|SAME|SKIP|FAIL|DRY) ' -or $_ -match "^\{Cyan\}" })
    if ($lines.Count -eq 0) { return }
    $plain = @($lines | ForEach-Object { (Get-BlobPlainText $_).TrimEnd() })
    $ok = @($plain | Where-Object { $_ -match '^\s*OK ' }).Count
    $fail = @($plain | Where-Object { $_ -match '^\s*FAIL ' }).Count
    $dry = @($plain | Where-Object { $_ -match '^\s*DRY ' }).Count
    $same = @($plain | Where-Object { $_ -match '^\s*SAME ' }).Count
    $Blob.Gui.SummaryText = $plain
    $sub = if ($dry) { "Dry run: $dry would change, $same already set, nothing was modified." } else { "$ok changed, $same already set, $fail failed." }
    $save = Show-BlobGuiDialog -Title $Title -Subtitle "$sub The same list is in the log at the bottom." -Lines $lines -OkText 'Save as text file' -CancelText 'Close' -Kind $(if ($fail) { 'Warning' } else { 'Info' })
    if (-not $save) { return }
    $dlg = [Microsoft.Win32.SaveFileDialog]::new()
    $dlg.Filter = 'Text file (*.txt)|*.txt'
    $dlg.FileName = "BLOB-changes-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmm')
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if ($dlg.ShowDialog($Blob.Gui.Window) -ne $true) { return }
    $head = @("BLOB OPTIMIZER $($Blob.Version) - $Title", (Get-Date).ToString('yyyy-MM-dd HH:mm'), "Computer: $($Blob.SysInfo.Host)", '')
    [IO.File]::WriteAllLines($dlg.FileName, [string[]]($head + $Blob.Gui.SummaryText), (New-Object Text.UTF8Encoding($false)))
    Add-BlobGuiLog "{White}Saved the summary to {Gray}$($dlg.FileName)"
}

# ---------------------------------------------------------------------------
#  Install page (winget)
# ---------------------------------------------------------------------------
function Get-BlobGuiWingetInstalled {
    if ($null -eq $Blob.Gui.WingetText) { $Blob.Gui.WingetText = Get-BlobWingetListText }
    $found = Get-BlobWingetInstalledIds $Blob.Gui.WingetText
    foreach ($k in @($Blob.Gui.WingetAdded.Keys)) { $found[$k] = $true }
    return $found
}

function Update-BlobGuiInstallList {
    $P = $Blob.Gui.P
    if (-not $P -or -not $P.List) { return }
    $P.List.Children.Clear()
    $installed = Get-BlobGuiWingetInstalled
    $q = ([string]$Blob.Gui.InstSearch).Trim()
    $apps = @($Blob.WingetCatalog | Where-Object { -not $q -or $_.Name -like "*$q*" -or $_.Id -like "*$q*" -or $_.Cat -like "*$q*" })
    foreach ($cat in @($apps | ForEach-Object { $_.Cat } | Select-Object -Unique)) {
        $inCat = @($apps | Where-Object { $_.Cat -eq $cat })
        $n = @($inCat | Where-Object { $installed[$_.Id] }).Count
        [void]$P.List.Children.Add((New-BlobGroupHeader $cat "$n of $($inCat.Count) installed"))
        $wrap = [Windows.Controls.Primitives.UniformGrid]::new()
        $wrap.Columns = 2; $wrap.Margin = '0,4,0,0'
        foreach ($a in $inCat) {
            $row = [Windows.Controls.Border]::new()
            $row.BorderBrush = Get-BlobBrush 'Rule'; $row.BorderThickness = '0,0,0,1'; $row.Padding = '2,9'; $row.Margin = '0,0,24,0'
            $dock = [Windows.Controls.DockPanel]::new()
            $state = New-BlobText $(if ($installed[$a.Id]) { 'Installed' } else { '' }) 12 'Ink3' 'Normal' -Display
            $state.VerticalAlignment = 'Center'
            [Windows.Controls.DockPanel]::SetDock($state, 'Right'); [void]$dock.Children.Add($state)
            $cb = [Windows.Controls.CheckBox]::new()
            $content = New-BlobStack
            [void]$content.Children.Add((New-BlobText $a.Name 14 'Ink' 'SemiBold'))
            [void]$content.Children.Add((New-BlobText $a.Id 11.5 'Ink3' 'Normal' '0,1,0,0' -Mono))
            $cb.Content = $content
            $cb.Tag = $a.Id
            if ($installed[$a.Id]) { $cb.IsEnabled = $false } else { $cb.IsChecked = [bool]$Blob.Gui.InstSel[$a.Id] }
            $cb.Add_Checked({ param($s, $e) $Blob.Gui.InstSel[$s.Tag] = $true; Update-BlobGuiInstallButton })
            $cb.Add_Unchecked({ param($s, $e) $Blob.Gui.InstSel.Remove($s.Tag); Update-BlobGuiInstallButton })
            [void]$dock.Children.Add($cb)
            $row.Child = $dock
            [void]$wrap.Children.Add($row)
        }
        [void]$P.List.Children.Add($wrap)
    }
    Update-BlobGuiInstallButton
}

function Update-BlobGuiInstallButton {
    $n = $Blob.Gui.InstSel.Count
    if ($Blob.Gui.P -and $Blob.Gui.P.InstallBtn) { $Blob.Gui.P.InstallBtn.Content = $(if ($n) { "Install $n" } else { 'Install selected' }) }
}

function New-BlobGuiInstall {
    $P = @{}
    $Blob.Gui.P = $P
    if (-not $Blob.Gui.InstSel) { $Blob.Gui.InstSel = @{} }
    if (-not $Blob.Gui.WingetAdded) { $Blob.Gui.WingetAdded = @{} }
    $root = New-BlobStack
    if (-not (Test-BlobWinget)) {
        $s = New-BlobStack
        [void]$s.Children.Add((New-BlobText 'winget is not available on this PC' 18 'Ink' 'SemiBold' -Display))
        [void]$s.Children.Add((New-BlobText 'winget comes with "App Installer" from the Microsoft Store. Install or update it, then open this page again.' 13 'Ink2' 'Normal' '0,6,0,12'))
        $b = New-BlobButton 'Open App Installer in the Store' { Start-Process 'ms-windows-store://pdp/?productid=9NBLGGH4NNS1' -ErrorAction SilentlyContinue } 'Accent'
        $b.HorizontalAlignment = 'Left'
        [void]$s.Children.Add($b)
        [void]$root.Children.Add((New-BlobCard $s))
        return $root
    }
    $top = [Windows.Controls.DockPanel]::new()
    $sbox = [Windows.Controls.Grid]::new()
    $sbox.Width = 240; $sbox.HorizontalAlignment = 'Right'
    $search = [Windows.Controls.TextBox]::new()
    $search.Text = [string]$Blob.Gui.InstSearch; $search.Padding = '22,5,2,5'
    $hint = New-BlobText 'Search apps' 13.5 'Ink3' 'Normal' '23,6,0,0'
    $hint.IsHitTestVisible = $false
    if ($search.Text) { $hint.Visibility = 'Collapsed' }
    $glass = New-BlobGlyph 0xE721 'Ink2' 15
    $glass.Margin = '1,0,0,2'; $glass.HorizontalAlignment = 'Left'; $glass.IsHitTestVisible = $false
    [void]$sbox.Children.Add($search); [void]$sbox.Children.Add($hint); [void]$sbox.Children.Add($glass)
    $P.Hint = $hint
    $search.Add_TextChanged({ param($s, $e) $Blob.Gui.InstSearch = $s.Text; $Blob.Gui.P.Hint.Visibility = if ($s.Text) { 'Collapsed' } else { 'Visible' }; Update-BlobGuiInstallList })
    [Windows.Controls.DockPanel]::SetDock($sbox, 'Right')
    [void]$top.Children.Add($sbox)
    [void]$top.Children.Add((New-BlobText 'Tick the apps you want. They are installed one after another with winget, from the official winget repository. Remove them later on the Apps page.' 13 'Ink2' 'Normal' '0,4,24,0'))
    [void]$root.Children.Add($top)
    $P.List = New-BlobStack
    [void]$root.Children.Add($P.List)
    $P.InstallBtn = New-BlobButton 'Install selected' { Invoke-BlobGuiInstall } 'Accent' -Margin '0'
    Set-BlobGuiPageActions @(
        (New-BlobButton 'Update all apps' { Invoke-BlobGuiWingetUpgrade } -ToolTip 'Runs winget upgrade --all for every app winget knows how to update'),
        (New-BlobButton 'Refresh' { $Blob.Gui.WingetText = $null; $Blob.PrefetchValid = $false; Show-BlobGuiPage 'install' -Rebuild }),
        $P.InstallBtn)
    Update-BlobGuiInstallList
    return $root
}

function Invoke-BlobGuiInstall {
    $ids = @($Blob.Gui.InstSel.Keys)
    $apps = @($Blob.WingetCatalog | Where-Object { $_.Id -in $ids })
    if ($apps.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Tick the apps you want to install first.'); return }
    $lines = @($apps | ForEach-Object { "{White}$($_.Name)  {DarkGray}$($_.Id)" })
    $lines += ''; $lines += '{Gray}Each app is downloaded by winget from its official source and installed with its own installer.'
    $lines += '{Gray}This can take a few minutes. The window stays usable; progress appears in the log.'
    if (-not (Show-BlobGuiDialog -Title "Install $($apps.Count) app(s)?" -Lines $lines -OkText 'Install')) { return }
    Start-BlobGuiTask "Installing $($apps.Count) app(s) with winget"
    $Blob.Gui.Collected = New-Object System.Collections.ArrayList
    $i = 0
    foreach ($a in $apps) {
        $i++
        Set-BlobGuiStatus "Installing $($a.Name) ($i of $($apps.Count))..."
        Install-BlobWingetApp -App $a -Log $Blob.GuiShared.LogCollect -Pump { Update-BlobGui; Start-Sleep -Milliseconds 150 }
        if (@($Blob.Gui.Collected | Where-Object { $_ -match "OK .*$([regex]::Escape($a.Name))" }).Count) { $Blob.Gui.WingetAdded[$a.Id] = $true; $Blob.Gui.InstSel.Remove($a.Id) }
    }
    Show-BlobGuiChangeSummary 'Installed apps'
    $Blob.PrefetchValid = $false
    if ($Blob.Gui.Cache.ContainsKey('apps')) { $Blob.Gui.Cache['apps'].Stale = $true }
    Update-BlobGuiPage
}

function Invoke-BlobGuiWingetUpgrade {
    if (-not (Show-BlobGuiDialog -Title 'Update all apps?' -OkText 'Update all' -Lines @(
                '{Gray}Runs winget upgrade --all: every app winget can update is updated with its own installer.',
                '{Gray}Apps that are open may need to be closed. This can take a while.'))) { return }
    Start-BlobGuiTask 'Updating apps with winget'
    $Blob.Gui.Collected = New-Object System.Collections.ArrayList
    Update-BlobWingetAll -Log $Blob.GuiShared.LogCollect -Pump { Update-BlobGui; Start-Sleep -Milliseconds 150 }
    Show-BlobGuiChangeSummary 'Updated apps'
}

# ---------------------------------------------------------------------------
#  Measure page
# ---------------------------------------------------------------------------
function New-BlobGuiMeasure {
    $P = @{}
    $Blob.Gui.P = $P
    $root = New-BlobStack
    $boots = @(Get-BlobBootTimes 12)
    $snaps = @(Get-BlobSnapshots)

    $row = [Windows.Controls.Grid]::new()
    $row.Margin = '0,4,0,30'
    for ($i = 0; $i -lt 4; $i++) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = '*'; $row.ColumnDefinitions.Add($cd) }
    $last = if ($boots.Count) { '{0:N1} s' -f ($boots[0].BootMs / 1000) } else { [string][char]0x2014 }
    $avg = if ($boots.Count -ge 2) { '{0:N1} s' -f (($boots | Select-Object -First 5 | Measure-Object BootMs -Average).Average / 1000) } else { [string][char]0x2014 }
    $os = $null; try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { }
    $ram = if ($os) { Format-BlobSize ((([double]$os.TotalVisibleMemorySize - [double]$os.FreePhysicalMemory)) * 1KB) } else { [string][char]0x2014 }
    $cells = @(
        (New-BlobReadout 'Last boot' $last $(if ($boots.Count) { $boots[0].Date.ToString('yyyy-MM-dd HH:mm') } else { 'no boot records available' }) $true),
        (New-BlobReadout 'Average boot' $avg 'last 5 boots'),
        (New-BlobReadout 'Memory in use' $ram 'right now'),
        (New-BlobReadout 'Processes' "$(@(Get-Process).Count)" 'running right now'))
    for ($i = 0; $i -lt 4; $i++) { [Windows.Controls.Grid]::SetColumn($cells[$i], $i); [void]$row.Children.Add($cells[$i]) }
    [void]$root.Children.Add($row)

    [void]$root.Children.Add((New-BlobHeading 'Boot history' '0,0,0,8'))
    if ($boots.Count) {
        $rows = @($boots | ForEach-Object { [pscustomobject]@{ Date = $_.Date.ToString('yyyy-MM-dd HH:mm'); Boot = '{0:N1} s' -f ($_.BootMs / 1000); MainPath = '{0:N1} s' -f ($_.MainPathMs / 1000); AfterSignIn = '{0:N1} s' -f ($_.PostBootMs / 1000) } })
        $g = New-BlobGrid @(@{ Header = 'Boot'; Path = 'Date'; Width = 180 }, @{ Header = 'Total boot time'; Path = 'Boot'; Width = 160 }, @{ Header = 'Until desktop'; Path = 'MainPath'; Width = 160 }, @{ Header = 'Settling after sign-in'; Path = 'AfterSignIn'; Width = 1 }) ([Math]::Min(380, 40 + 32 * $rows.Count))
        $g.ItemsSource = $rows
        [void]$root.Children.Add($g)
        [void]$root.Children.Add((New-BlobText 'From Windows'' own boot performance log. "Until desktop" is the time to a usable desktop; "settling" is the work that continues after sign-in.' 12 'Ink3' 'Normal' '0,8,0,0'))
    } else {
        $why = if (-not $Blob.IsAdmin) { 'Reading the Windows boot performance log needs administrator rights. Start BLOB again and choose Yes in the permission prompt.' } else { 'Windows has not recorded any boots in its performance log yet. Restart the PC once and come back.' }
        [void]$root.Children.Add((New-BlobText $why 13 'Ink2'))
    }

    [void]$root.Children.Add((New-BlobHeading 'Snapshots' '0,30,0,8'))
    [void]$root.Children.Add((New-BlobText 'Take one before you apply a preset and one after a restart. For a fair comparison, wait two minutes after signing in. Differences under 5% are normal noise.' 13 'Ink2' 'Normal' '0,0,0,10'))
    if ($snaps.Count) {
        $g2 = New-BlobGrid @(@{ Header = 'Taken'; Path = 'Time'; Width = 140 }, @{ Header = 'Label'; Path = 'Label'; Width = 1 }, @{ Header = 'Boot s'; Path = 'BootSec'; Width = 80 }, @{ Header = 'RAM MB'; Path = 'RamUsedMB'; Width = 90 }, @{ Header = 'Processes'; Path = 'Processes'; Width = 90 }, @{ Header = 'Services'; Path = 'Services'; Width = 80 }, @{ Header = 'Startup'; Path = 'StartupApps'; Width = 76 }, @{ Header = 'Tweaks on'; Path = 'TweaksOn'; Width = 90 }) ([Math]::Min(300, 40 + 32 * $snaps.Count))
        $rev = @($snaps); [Array]::Reverse($rev)
        $g2.ItemsSource = $rev
        [void]$root.Children.Add($g2)
        if ($snaps.Count -ge 2) {
            [void]$root.Children.Add((New-BlobHeading "Compare: first '$($snaps[0].Label)' with latest '$($snaps[-1].Label)'" '0,24,0,8'))
            foreach ($l in (Compare-BlobSnapshots $snaps[0] $snaps[-1])) { [void]$root.Children.Add((ConvertTo-BlobTextBlock $l -Mono -Size 12.5)) }
        }
    } else { [void]$root.Children.Add((New-BlobText 'No snapshots yet.' 13 'Ink3')) }
    Set-BlobGuiPageActions @((New-BlobButton 'Take a snapshot' {
                $label = Show-BlobGuiInput -Title 'Name this snapshot' -Prompt @('{Gray}For example: Before Standard preset, After restart.') -Default $(if (@(Get-BlobSnapshots).Count) { 'After changes' } else { 'Before changes' }) -Validate { param($v) if (-not $v) { 'Enter a short name.' } }
                if (-not $label) { return }
                $s = New-BlobSnapshot $label
                Add-BlobGuiLog "{White}Snapshot '$label' taken {Gray}(RAM $($s.RamUsedMB) MB, $($s.Processes) processes, $($s.StartupApps) startup programs)"
                Update-BlobGuiPage } 'Accent' -Margin '0'))
    return $root
}

# ---------------------------------------------------------------------------
#  Search everything (Ctrl+K)
# ---------------------------------------------------------------------------
function Get-BlobSearchIndex {
    $idx = New-Object System.Collections.ArrayList
    foreach ($p in $Blob.Gui.Pages) { [void]$idx.Add(@{ Title = $p.Label; Where = 'Page'; Go = [scriptblock]::Create("Show-BlobGuiPage '$($p.Key)'") }) }
    foreach ($t in (Get-BlobCoreTweaks)) { [void]$idx.Add(@{ Title = $t.Name; Where = "Tweaks - $($t.Category)"; Text = $t.Description; Key = 'optimize'; Value = $t.Name }) }
    foreach ($t in (Get-BlobPrivacyItems)) { [void]$idx.Add(@{ Title = $t.Name + $(if ($t.Privacy.Oo) { " ($($t.Privacy.Oo))" }); Where = "Privacy - $($t.Group)"; Text = $t.Privacy.Does; Key = 'privacy'; Value = $t.Name }) }
    foreach ($a in @($Blob.Gui.AppsData)) { if ($a) { [void]$idx.Add(@{ Title = $a.Name; Where = 'Apps - installed'; Text = $a.Publisher; Key = 'apps'; Value = $a.Name }) } }
    foreach ($t in (Get-BlobAppearanceItems)) { [void]$idx.Add(@{ Title = $t.Name; Where = "Appearance - $($t.Group)"; Text = $t.Description; Key = 'appearance'; Value = $t.Name }) }
    foreach ($a in $Blob.WingetCatalog) { [void]$idx.Add(@{ Title = $a.Name; Where = "Install - $($a.Cat)"; Text = $a.Id; Key = 'install'; Value = $a.Name }) }
    return $idx.ToArray()
}

function Invoke-BlobSearchResult {
    param($R)
    if ($R.Go) { & $R.Go; return }
    switch ($R.Key) {
        'optimize' { $Blob.Gui.OptFilter = 'All'; $Blob.Gui.OptRisk = 'All'; $Blob.Gui.OptSearch = $R.Value }
        'privacy' { $Blob.Gui.PcSection = 'All sections'; $Blob.Gui.PcRec = 'All'; $Blob.Gui.PcSearch = $R.Value }
        'apps' { $Blob.Gui.AppsFilter = 'All'; $Blob.Gui.AppsSearch = $R.Value }
        'install' { $Blob.Gui.InstSearch = $R.Value }
    }
    Show-BlobGuiPage $R.Key -Rebuild
}

function Show-BlobGuiSearch {
    if ($Blob.Gui.Window.OwnedWindows.Count -gt 0) { return }
    $d = New-BlobGuiWindow $Blob.GuiDialogXaml
    $d.Owner = $Blob.Gui.Window
    $d.Height = 560
    $d.FindName('DlgTitle').Text = 'Search everything'
    $d.FindName('DlgSub').Text = 'Pages, tweaks, privacy settings (and O&O IDs), installed apps and apps to install. Enter opens, Esc closes.'
    $body = $d.FindName('DlgBody')
    $box = [Windows.Controls.TextBox]::new()
    $box.FontSize = 16; $box.Margin = '0,0,0,12'
    $list = [Windows.Controls.ListBox]::new()
    $list.MinHeight = 300
    [void]$body.Children.Add($box); [void]$body.Children.Add($list)
    $d.FindName('DlgOk').Content = 'Open'
    $d.FindName('DlgCancel').Content = 'Close'
    $d.Tag = @{ Index = (Get-BlobSearchIndex); Box = $box; List = $list; Result = $null }
    $box.Tag = $d; $list.Tag = $d
    $box.Add_TextChanged({
            param($s, $e)
            $st = $s.Tag.Tag
            $q = $s.Text.Trim()
            $st.List.Items.Clear()
            if ($q.Length -lt 2) { return }
            $hits = @($st.Index | Where-Object { $_.Title -like "*$q*" } | Select-Object -First 30)
            if ($hits.Count -lt 30) { $hits += @($st.Index | Where-Object { $_.Title -notlike "*$q*" -and $_.Text -like "*$q*" } | Select-Object -First (30 - $hits.Count)) }
            foreach ($h in $hits) {
                $item = [Windows.Controls.ListBoxItem]::new()
                $sp = New-BlobStack
                [void]$sp.Children.Add((New-BlobText $h.Title 14 'Ink' 'SemiBold'))
                [void]$sp.Children.Add((New-BlobText $h.Where 12 'Ink3' 'Normal' -Display))
                $item.Content = $sp; $item.Tag = $h; $item.Padding = '8,6'
                [void]$st.List.Items.Add($item)
            }
            if ($st.List.Items.Count) { $st.List.SelectedIndex = 0 }
        })
    $go = {
        param($s, $e)
        $w = [Windows.Window]::GetWindow($s)
        $st = $w.Tag
        if ($st.List.SelectedItem) { $st.Result = $st.List.SelectedItem.Tag; $w.Close() }
    }
    $d.FindName('DlgOk').Add_Click($go)
    $list.Add_MouseDoubleClick($go)
    $d.FindName('DlgCancel').Add_Click({ param($s, $e) [Windows.Window]::GetWindow($s).Close() })
    $d.Add_PreviewKeyDown({
            param($s, $e)
            $st = $s.Tag
            switch ($e.Key) {
                'Escape' { $s.Close(); $e.Handled = $true }
                'Down' { if ($st.List.Items.Count) { $st.List.SelectedIndex = [Math]::Min($st.List.Items.Count - 1, $st.List.SelectedIndex + 1); $st.List.ScrollIntoView($st.List.SelectedItem) }; $e.Handled = $true }
                'Up' { if ($st.List.Items.Count) { $st.List.SelectedIndex = [Math]::Max(0, $st.List.SelectedIndex - 1); $st.List.ScrollIntoView($st.List.SelectedItem) }; $e.Handled = $true }
                'Return' { if ($st.List.SelectedItem) { $st.Result = $st.List.SelectedItem.Tag; $s.Close() }; $e.Handled = $true }
            }
        })
    $d.Add_ContentRendered({ param($s, $e) $s.Tag.Box.Focus() })
    $null = $d.ShowDialog()
    if ($d.Tag.Result) { Invoke-BlobSearchResult $d.Tag.Result }
}

# ---------------------------------------------------------------------------
#  Appearance page
# ---------------------------------------------------------------------------
$Blob.ThemeModes = [ordered]@{
    Light = @{ Apps = $false; System = $false; Note = 'Light apps, light taskbar' }
    Dark  = @{ Apps = $true; System = $true; Note = 'Dark apps, dark taskbar' }
    Mixed = @{ Apps = $false; System = $true; Note = 'Light apps, dark taskbar' }
}

# Effective dark/light for one switch, counting a pending choice.
function Test-BlobGuiWantsOn {
    param([string]$Id)
    $p = [string]$Blob.Gui.Pending[$Id]
    if ($p) { return ($p -eq 'On') }
    return ((Get-BlobTweakState (Get-BlobTweak $Id)) -eq 'Applied')
}

function Set-BlobGuiPendingTo {
    param([string]$Id, [bool]$On)
    $isOn = (Get-BlobTweakState (Get-BlobTweak $Id)) -eq 'Applied'
    if ($On -eq $isOn) { $Blob.Gui.Pending.Remove($Id) } else { $Blob.Gui.Pending[$Id] = $(if ($On) { 'On' } else { 'Off' }) }
}

function Set-BlobGuiThemeMode {
    param([string]$Mode)
    $m = $Blob.ThemeModes[$Mode]
    if (-not $m) { return }
    Set-BlobGuiPendingTo 'app.darkapps' $m.Apps
    Set-BlobGuiPendingTo 'app.darksystem' $m.System
    Update-BlobGuiCardGrid
}

# A small drawing of the desktop in that mode: window (apps) above a taskbar (system).
function New-BlobThemeTile {
    param([string]$Mode, [bool]$Selected)
    $m = $Blob.ThemeModes[$Mode]
    $conv = [Windows.Media.BrushConverter]::new()
    $winBg = if ($m.Apps) { '#202020' } else { '#FFFFFF' }
    $winBar = if ($m.Apps) { '#2B2B2B' } else { '#F0F0F0' }
    $winLine = if ($m.Apps) { '#3D3D3D' } else { '#E2E2E2' }
    $taskBg = if ($m.System) { '#1C1C1C' } else { '#EEEEEE' }
    $taskIcon = if ($m.System) { '#5A5A5A' } else { '#BDBDBD' }

    $tile = [Windows.Controls.Border]::new()
    $tile.Width = 200; $tile.Margin = '0,0,16,0'; $tile.Padding = '10'; $tile.Cursor = 'Hand'
    $tile.BorderThickness = $(if ($Selected) { '2' } else { '1' })
    $tile.BorderBrush = Get-BlobBrush $(if ($Selected) { 'Signal' } else { 'Rule' })
    $tile.Background = Get-BlobBrush $(if ($Selected) { 'SignalSoft' } else { 'Surface' })
    $tile.DataContext = $Mode
    $sp = New-BlobStack

    $screen = [Windows.Controls.Grid]::new()
    $screen.Height = 104
    $screen.Background = $conv.ConvertFrom('#9FB4C7')
    $win = [Windows.Controls.Border]::new()
    $win.Width = 120; $win.Height = 62; $win.Margin = '0,10,0,0'; $win.VerticalAlignment = 'Top'; $win.HorizontalAlignment = 'Center'
    $win.Background = $conv.ConvertFrom($winBg); $win.BorderBrush = $conv.ConvertFrom($winLine); $win.BorderThickness = '1'
    $ws = New-BlobStack
    $bar = [Windows.Controls.Border]::new(); $bar.Height = 12; $bar.Background = $conv.ConvertFrom($winBar)
    [void]$ws.Children.Add($bar)
    foreach ($w in @(84, 64, 74)) {
        $ln = [Windows.Controls.Border]::new(); $ln.Height = 5; $ln.Width = $w; $ln.Margin = '8,7,0,0'; $ln.HorizontalAlignment = 'Left'
        $ln.Background = $conv.ConvertFrom($winLine); [void]$ws.Children.Add($ln)
    }
    $win.Child = $ws
    [void]$screen.Children.Add($win)
    $task = [Windows.Controls.Border]::new()
    $task.Height = 16; $task.VerticalAlignment = 'Bottom'; $task.Background = $conv.ConvertFrom($taskBg)
    $icons = New-BlobStack 'Horizontal'
    $icons.HorizontalAlignment = 'Center'; $icons.VerticalAlignment = 'Center'
    for ($i = 0; $i -lt 5; $i++) { $ic = [Windows.Controls.Border]::new(); $ic.Width = 8; $ic.Height = 8; $ic.Margin = '3,0'; $ic.Background = $conv.ConvertFrom($taskIcon); [void]$icons.Children.Add($ic) }
    $task.Child = $icons
    [void]$screen.Children.Add($task)
    [void]$sp.Children.Add($screen)

    $label = New-BlobStack 'Horizontal'
    $label.Margin = '0,10,0,0'
    [void]$label.Children.Add((New-BlobText $Mode 15.5 'Ink' 'SemiBold' -Display))
    if ($Selected) { $chk = New-BlobText ("  " + [char]0x2713) 15 'SignalText' 'SemiBold'; [void]$label.Children.Add($chk) }
    [void]$sp.Children.Add($label)
    [void]$sp.Children.Add((New-BlobText $m.Note 12 'Ink2' 'Normal' '0,2,0,0'))
    $tile.Child = $sp
    $tile.Add_MouseLeftButtonUp({ param($s, $e) if (-not $Blob.Gui.Busy) { Set-BlobGuiThemeMode ([string]$s.DataContext) } })
    return $tile
}

function Update-BlobGuiAppearanceList {
    $g = $Blob.Gui.CardGrid
    if (-not $g) { return }
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    # Theme tiles follow the switches, including choices not applied yet.
    if (-not $Blob.Gui.P -or -not $Blob.Gui.P.Tiles) { return }
    $tiles = $Blob.Gui.P.Tiles
    $tiles.Children.Clear()
    $apps = Test-BlobGuiWantsOn 'app.darkapps'; $sys = Test-BlobGuiWantsOn 'app.darksystem'
    foreach ($k in $Blob.ThemeModes.Keys) {
        $m = $Blob.ThemeModes[$k]
        [void]$tiles.Children.Add((New-BlobThemeTile $k ($m.Apps -eq $apps -and $m.System -eq $sys)))
    }
    $Blob.Gui.P.ThemeNote.Text = if ($apps -and -not $sys) { 'Now: dark apps with a light taskbar (a custom mix). Pick a tile or use the two switches below.' } else { '' }
    $g.Children.Clear()
    $items = @(Get-BlobAppearanceItems)
    $states = @{}
    foreach ($t in $items) { $states[$t.Id] = Get-BlobTweakState $t }
    foreach ($grp in $Blob.AppearanceGroups) {
        $inGrp = @($items | Where-Object { $_.Group -eq $grp })
        if ($inGrp.Count -eq 0) { continue }
        $on = @($inGrp | Where-Object { $states[$_.Id] -eq 'Applied' }).Count
        [void]$g.Children.Add((New-BlobGroupHeader $grp "$on of $($inGrp.Count) on"))
        foreach ($t in $inGrp) { [void]$g.Children.Add((Get-BlobGuiCard $t $states[$t.Id])) }
    }
    $dot = [string][char]0x00B7
    $onAll = @($states.Values | Where-Object { $_ -eq 'Applied' }).Count
    $Blob.Gui.CardCount.Text = "$($items.Count) settings  $dot  $onAll on  $dot  $($Blob.Gui.Pending.Count) waiting"
    Update-BlobGuiPendingBar
    $Blob.Gui.PageScroll.UpdateLayout(); $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
}

function New-BlobGuiAppearance {
    $root = New-BlobStack
    [void]$root.Children.Add((New-BlobHeading 'Theme' '0,0,0,10'))
    $tiles = New-BlobStack 'Horizontal'
    [void]$root.Children.Add($tiles)
    $note = New-BlobText '' 12.5 'SignalText' 'Normal' '0,10,0,0'
    [void]$root.Children.Add($note)
    $Blob.Gui.P = @{ Tiles = $tiles; ThemeNote = $note }
    [void]$root.Children.Add((New-BlobText 'Choosing a tile only marks the change. Review and apply in the bar below; apps that follow Windows switch at once, and undo returns your current colours.' 12.5 'Ink2' 'Normal' '0,10,0,0'))

    $Blob.Gui.CardCount = New-BlobText '' 12 'Ink3' 'Normal' '0,22,0,0' -Mono
    [void]$root.Children.Add($Blob.Gui.CardCount)
    $list = New-BlobStack
    $Blob.Gui.CardGrid = $list; $Blob.Gui.GridKind = 'appearance'
    [void]$root.Children.Add($list)

    [void]$root.Children.Add((New-BlobHeading 'More in Windows Settings' '0,36,0,4'))
    foreach ($d in @(
            @('Accent colour', 'Choose a fixed accent colour (turn off the wallpaper option above first).', { Start-Process 'ms-settings:colors' }),
            @('Background', 'Wallpaper, slideshow or Windows Spotlight.', { Start-Process 'ms-settings:personalization-background' }),
            @('Themes and desktop icons', 'Complete themes, mouse pointers, sounds and desktop icon settings.', { Start-Process 'ms-settings:themes' }),
            @('Restart Explorer', 'Makes taskbar, Start and desktop changes show up without signing out.', { if (Confirm-BlobGui -Title 'Restart Windows Explorer?' -OkText 'Restart Explorer' -Lines @('{Gray}The taskbar and open Explorer windows close and reopen.')) { Restart-BlobExplorer; Add-BlobGuiLog '{White}Explorer restarted.' } }))) {
        [void]$root.Children.Add((New-BlobActionRow $d[0] $d[1] $d[2]))
    }
    Set-BlobGuiPageActions @(
        (New-BlobButton 'Windows colour settings' { Start-Process 'ms-settings:colors' } -Margin '0'))
    Update-BlobGuiAppearanceList
    return $root
}
