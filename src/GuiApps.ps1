# ============================================================================
#  BLOB OPTIMIZER - GuiApps.ps1
#  The Apps page: every installed program and Store app, removed completely
#  (own uninstaller first, then the leftovers you choose).
# ============================================================================

$Blob.GuiShared.AppUninstall = { Invoke-BlobGuiUninstall $Blob.Gui.Sender.DataContext }

function Get-BlobGuiFilteredApps {
    $list = @($Blob.Gui.AppsData)
    switch ($Blob.Gui.AppsFilter) {
        'Desktop' { $list = @($list | Where-Object { $_.Kind -eq 'Desktop' }) }
        'Store' { $list = @($list | Where-Object { $_.Kind -eq 'Store' }) }
    }
    $q = ([string]$Blob.Gui.AppsSearch).Trim()
    if ($q) { $list = @($list | Where-Object { $_.Name -like "*$q*" -or $_.Publisher -like "*$q*" }) }
    switch ($Blob.Gui.AppsSort) {
        'Size' { $list = @($list | Sort-Object @{ Expression = { $_.SizeBytes }; Descending = $true }, Name) }
        'Newest' { $list = @($list | Sort-Object @{ Expression = { if ($_.InstallDate) { $_.InstallDate } else { [datetime]::MinValue } }; Descending = $true }, Name) }
        default { $list = @($list | Sort-Object Name) }
    }
    return $list
}

function New-BlobAppRow {
    param($App)
    $row = [Windows.Controls.Border]::new()
    $row.BorderBrush = Get-BlobBrush 'Rule'; $row.BorderThickness = '0,0,0,1'; $row.Padding = '0,10'
    $row.Background = [Windows.Media.Brushes]::Transparent
    $row.Add_MouseEnter({ param($s, $e) $s.Background = Get-BlobBrush 'Hover' })
    $row.Add_MouseLeave({ param($s, $e) $s.Background = [Windows.Media.Brushes]::Transparent })
    $g = [Windows.Controls.Grid]::new()
    foreach ($w in @('*', '96', '104', '84', '126')) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = $w; $g.ColumnDefinitions.Add($cd) }

    $text = New-BlobStack
    $text.Margin = '4,0,16,0'; $text.VerticalAlignment = 'Center'
    $title = New-BlobStack 'Horizontal'
    [void]$title.Children.Add((New-BlobText $App.Name 14 'Ink' 'SemiBold'))
    if ($App.Protected) { $b = New-BlobBadge 'WINDOWS NEEDS THIS' 'Ink3'; $b.Margin = '10,1,0,0'; [void]$title.Children.Add($b) }
    elseif ($App.Shared) { $b = New-BlobBadge 'SHARED COMPONENT' 'SignalText'; $b.Margin = '10,1,0,0'; [void]$title.Children.Add($b) }
    [void]$text.Children.Add($title)
    $meta = @($App.Publisher, $(if ($App.Version) { "version $($App.Version)" }), $App.Scope) | Where-Object { $_ }
    $m = New-BlobText ($meta -join ('  ' + [string][char]0x00B7 + '  ')) 12.5 'Ink2' 'Normal' '0,2,0,0'
    $m.TextWrapping = 'NoWrap'; $m.TextTrimming = 'CharacterEllipsis'
    [void]$text.Children.Add($m)
    [void]$g.Children.Add($text)

    $size = New-BlobText $(if ($App.SizeBytes -gt 0) { Format-BlobSize $App.SizeBytes } else { [string][char]0x2014 }) 12.5 'Ink2' 'Normal' -Mono
    $size.VerticalAlignment = 'Center'; $size.HorizontalAlignment = 'Right'; $size.Margin = '0,0,16,0'
    [Windows.Controls.Grid]::SetColumn($size, 1); [void]$g.Children.Add($size)
    $date = New-BlobText $(if ($App.InstallDate) { $App.InstallDate.ToString('yyyy-MM-dd') } else { [string][char]0x2014 }) 12.5 'Ink3' 'Normal' -Mono
    $date.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($date, 2); [void]$g.Children.Add($date)
    $kind = New-BlobText $(if ($App.Kind -eq 'Store') { 'STORE' } else { 'PROGRAM' }) 11.5 'Ink3' 'Normal' -Display
    $kind.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($kind, 3); [void]$g.Children.Add($kind)

    if ($App.Protected) {
        $lock = New-BlobText 'Protected' 13 'Ink3' 'Normal' -Display
        $lock.VerticalAlignment = 'Center'; $lock.HorizontalAlignment = 'Right'; $lock.Margin = '0,0,4,0'
        Set-BlobTooltip $lock (New-BlobTooltipPanel -Title 'Windows depends on this' -Paragraphs @('Removing it can break Windows features or other apps, so BLOB does not offer it.'))
        [Windows.Controls.Grid]::SetColumn($lock, 4); [void]$g.Children.Add($lock)
    } else {
        $btn = [Windows.Controls.Button]::new()
        $btn.Content = 'Uninstall'; $btn.Padding = '14,4'; $btn.Margin = '0,0,4,0'; $btn.HorizontalAlignment = 'Right'; $btn.VerticalAlignment = 'Center'
        $btn.DataContext = $App.Id
        Register-BlobClick $btn $Blob.GuiShared.AppUninstall
        [Windows.Controls.Grid]::SetColumn($btn, 4); [void]$g.Children.Add($btn)
    }
    $row.Child = $g
    return $row
}

function Update-BlobGuiAppsList {
    $P = $Blob.Gui.P
    if (-not $P -or -not $P.List) { return }
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    $P.List.Children.Clear()
    if (-not $Blob.Gui.AppRowCache) { $Blob.Gui.AppRowCache = @{} }
    $list = @(Get-BlobGuiFilteredApps)
    foreach ($a in $list) {
        $el = $Blob.Gui.AppRowCache[$a.Id]
        if (-not $el) { $el = New-BlobAppRow $a; $Blob.Gui.AppRowCache[$a.Id] = $el }
        if ($el.Parent -is [Windows.Controls.Panel]) { $el.Parent.Children.Remove($el) }
        [void]$P.List.Children.Add($el)
    }
    if ($list.Count -eq 0) { [void]$P.List.Children.Add((New-BlobText 'Nothing matches.' 14 'Ink3' 'Normal' '0,24,0,0')) }
    $total = ($list | Measure-Object -Property SizeBytes -Sum).Sum
    $dot = [string][char]0x00B7
    $P.Count.Text = "$($list.Count) shown  $dot  $(Format-BlobSize $total) reported by the programs  $dot  Store apps do not report a size"
    $Blob.Gui.PageScroll.UpdateLayout(); $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
}

function New-BlobGuiApps {
    $P = @{}
    $Blob.Gui.P = $P
    if (-not $Blob.Gui.AppsFilter) { $Blob.Gui.AppsFilter = 'All' }
    if (-not $Blob.Gui.AppsSort) { $Blob.Gui.AppsSort = 'Name' }
    $Blob.Gui.AppsData = @(Get-BlobDesktopApps) + @(Get-BlobStoreApps)
    $Blob.Gui.AppRowCache = @{}
    $root = New-BlobStack

    $top = [Windows.Controls.DockPanel]::new()
    $sbox = [Windows.Controls.Grid]::new()
    $sbox.Width = 240; $sbox.VerticalAlignment = 'Top'; $sbox.Margin = '24,0,0,0'
    $search = [Windows.Controls.TextBox]::new()
    $search.Text = [string]$Blob.Gui.AppsSearch; $search.Padding = '22,5,2,5'
    $hint = New-BlobText 'Search apps' 13.5 'Ink3' 'Normal' '23,6,0,0'
    $hint.IsHitTestVisible = $false
    if ($search.Text) { $hint.Visibility = 'Collapsed' }
    $glass = New-BlobGlyph 0xE721 'Ink2' 15
    $glass.Margin = '1,0,0,2'; $glass.HorizontalAlignment = 'Left'; $glass.IsHitTestVisible = $false
    [void]$sbox.Children.Add($search); [void]$sbox.Children.Add($hint); [void]$sbox.Children.Add($glass)
    $P.Hint = $hint
    $search.Add_TextChanged({ param($s, $e) $Blob.Gui.AppsSearch = $s.Text; $Blob.Gui.P.Hint.Visibility = if ($s.Text) { 'Collapsed' } else { 'Visible' }; Update-BlobGuiAppsList })
    [Windows.Controls.DockPanel]::SetDock($sbox, 'Right')
    [void]$top.Children.Add($sbox)

    $filters = New-BlobStack
    $all = $Blob.Gui.AppsData
    $types = [Windows.Controls.WrapPanel]::new()
    foreach ($f in @(@('All', "All $($all.Count)"), @('Desktop', "Programs $(@($all | Where-Object { $_.Kind -eq 'Desktop' }).Count)"), @('Store', "Store apps $(@($all | Where-Object { $_.Kind -eq 'Store' }).Count)"))) {
        [void]$types.Children.Add((New-BlobGuiFilterChip $f[1] ($Blob.Gui.AppsFilter -eq $f[0]) ([scriptblock]::Create("`$Blob.Gui.AppsFilter = '$($f[0])'; Show-BlobGuiPage 'apps' -Rebuild"))))
    }
    [void]$filters.Children.Add((New-BlobFilterRow 'Type' $types))
    $sorts = [Windows.Controls.WrapPanel]::new()
    foreach ($o in @(@('Name', 'Name'), @('Size', 'Largest first'), @('Newest', 'Newest first'))) {
        [void]$sorts.Children.Add((New-BlobGuiFilterChip $o[1] ($Blob.Gui.AppsSort -eq $o[0]) ([scriptblock]::Create("`$Blob.Gui.AppsSort = '$($o[0])'; Show-BlobGuiPage 'apps' -Rebuild"))))
    }
    [void]$filters.Children.Add((New-BlobFilterRow 'Sort' $sorts))
    [void]$top.Children.Add($filters)
    [void]$root.Children.Add($top)

    # How it works, in three lines
    $how = [Windows.Controls.Grid]::new()
    $how.Margin = '0,14,0,6'
    for ($i = 0; $i -lt 3; $i++) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = '*'; $how.ColumnDefinitions.Add($cd) }
    $steps = @(
        @('1', 'Own uninstaller', 'The program removes itself the way its maker intended. Store apps are removed by Windows, data included.'),
        @('2', 'Leftover scan', 'Only once Windows no longer lists it: folders, registry keys, shortcuts and startup entries with its exact name.'),
        @('3', 'You choose', 'Folders and shortcuts go to the Recycle Bin. Registry keys are backed up to .reg first.'))
    for ($i = 0; $i -lt 3; $i++) {
        $b = [Windows.Controls.Border]::new()
        $b.BorderBrush = Get-BlobBrush 'Rule'; $b.BorderThickness = $(if ($i -eq 0) { '0' } else { '1,0,0,0' }); $b.Padding = $(if ($i -eq 0) { '0,0,20,0' } else { '20,0,20,0' })
        $d = [Windows.Controls.DockPanel]::new()
        $n = New-BlobText $steps[$i][0] 30 'Ghost' 'Light' '0,-4,12,0' -Display
        [void]$d.Children.Add($n)
        $sp = New-BlobStack
        [void]$sp.Children.Add((New-BlobText $steps[$i][1] 14.5 'Ink' 'SemiBold' -Display))
        [void]$sp.Children.Add((New-BlobText $steps[$i][2] 12.5 'Ink2' 'Normal' '0,2,0,0'))
        [void]$d.Children.Add($sp)
        $b.Child = $d
        [Windows.Controls.Grid]::SetColumn($b, $i); [void]$how.Children.Add($b)
    }
    [void]$root.Children.Add($how)

    # Column heads
    $head = [Windows.Controls.Grid]::new()
    $head.Margin = '0,18,0,0'
    foreach ($w in @('*', '96', '104', '84', '126')) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = $w; $head.ColumnDefinitions.Add($cd) }
    $heads = @(@('NAME', 0, 'Left', '4,0,0,6'), @('SIZE', 1, 'Right', '0,0,16,6'), @('INSTALLED', 2, 'Left', '0,0,0,6'), @('TYPE', 3, 'Left', '0,0,0,6'))
    foreach ($h in $heads) {
        $t = New-BlobText $h[0] 11.5 'Ink3' 'Normal' $h[3] -Display
        $t.HorizontalAlignment = $h[2]
        [Windows.Controls.Grid]::SetColumn($t, $h[1]); [void]$head.Children.Add($t)
    }
    $hb = [Windows.Controls.Border]::new()
    $hb.BorderBrush = Get-BlobBrush 'Ink'; $hb.BorderThickness = '0,0,0,1.5'; $hb.Child = $head
    [void]$root.Children.Add($hb)

    $P.List = New-BlobStack
    [void]$root.Children.Add($P.List)
    $P.Count = New-BlobText '' 12 'Ink3' 'Normal' '0,14,0,0' -Mono
    [void]$root.Children.Add($P.Count)

    Set-BlobGuiPageActions @(
        (New-BlobButton 'Apps & features' { Start-Process 'ms-settings:appsfeatures' -ErrorAction SilentlyContinue } -ToolTip 'Open the Windows list of installed apps'),
        (New-BlobButton 'Refresh' { $Blob.PrefetchValid = $false; Show-BlobGuiPage 'apps' -Rebuild } -Margin '0'))
    Update-BlobGuiAppsList
    return $root
}

# Leftover picker: one checkbox per item, all ticked by default.
function Show-BlobGuiLeftovers {
    param($App, [array]$Items)
    $d = New-BlobGuiWindow $Blob.GuiDialogXaml
    $d.Owner = $Blob.Gui.Window
    $d.FindName('DlgTitle').Text = "$($App.Name) left $($Items.Count) thing(s) behind"
    $d.FindName('DlgSub').Text = 'Untick anything you want to keep. Folders and shortcuts go to the Recycle Bin; registry keys are backed up first.'
    $body = $d.FindName('DlgBody')
    $boxes = New-Object System.Collections.ArrayList
    foreach ($it in $Items) {
        $cb = [Windows.Controls.CheckBox]::new()
        $cb.IsChecked = $true; $cb.Margin = '0,0,0,12'
        $sp = New-BlobStack
        [void]$sp.Children.Add((New-BlobText $it.Type.ToUpper() 11.5 'Ink3' 'Normal' -Display))
        [void]$sp.Children.Add((New-BlobText $it.Path 12.5 'Ink' 'Normal' '0,1,0,0' -Mono))
        if ($it.Detail) { [void]$sp.Children.Add((New-BlobText $it.Detail 12 'Ink2' 'Normal' '0,1,0,0')) }
        $cb.Content = $sp
        $cb.Tag = $it
        [void]$body.Children.Add($cb)
        [void]$boxes.Add($cb)
    }
    $ok = $d.FindName('DlgOk'); $cancel = $d.FindName('DlgCancel')
    $ok.Content = 'Remove selected'; $cancel.Content = 'Keep everything'
    $d.Tag = $false
    $ok.Add_Click({ param($s, $e) $w = [Windows.Window]::GetWindow($s); $w.Tag = $true; $w.Close() })
    $cancel.Add_Click({ param($s, $e) [Windows.Window]::GetWindow($s).Close() })
    $d.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Escape') { $s.Close() } })
    $null = $d.ShowDialog()
    if (-not $d.Tag) { return @() }
    return @($boxes | Where-Object { $_.IsChecked } | ForEach-Object { $_.Tag })
}

function Invoke-BlobGuiUninstall {
    param([string]$Id)
    $app = @($Blob.Gui.AppsData) | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    if (-not $app) { return }
    if ($app.Protected) { Show-BlobGuiMessage -Title 'Windows depends on this' -Lines @('{Gray}Removing it can break Windows features or other apps, so BLOB does not offer it.'); return }
    if ($app.NeedsAdmin -and -not $Blob.IsAdmin) { Show-BlobGuiAdminRequired "$($app.Name) is installed for all users; removing it needs administrator rights."; return }

    $lines = @(
        "{Gray}Program     {White}$($app.Name)",
        "{Gray}Publisher   {White}$($app.Publisher)",
        "{Gray}Version     {White}$($app.Version)")
    if ($app.SizeBytes -gt 0) { $lines += "{Gray}Size        {White}$(Format-BlobSize $app.SizeBytes)" }
    if ($app.InstallLocation) { $lines += "{Gray}Location    {White}$($app.InstallLocation)" }
    $lines += ''
    if ($app.Kind -eq 'Store') {
        $lines += '{White}Windows removes this Store app together with its app data. Nothing else is touched.'
    } else {
        $lines += '{White}1. The program''s own uninstaller opens. Follow its steps.'
        $lines += '{White}2. When Windows no longer lists the program, BLOB looks for leftovers.'
        $lines += '{White}3. You choose what to remove. Nothing is removed without your OK.'
    }
    if ($app.Shared) { $lines += ''; $lines += '{Yellow}This is a shared component. Other programs, games or drivers may need it.' }
    $canRp = $Blob.IsAdmin -and -not $Blob.DryRun
    $rpText = if ($canRp) { 'Create a System Restore point first' } else { 'Create a System Restore point first (needs administrator, not in dry run)' }
    $ok = Show-BlobGuiDialog -Title "Uninstall $($app.Name)?" -Lines $lines -OkText 'Uninstall' -Danger:$app.Shared -CheckText $rpText -CheckDefault ($canRp -and $app.Shared) -CheckEnabled $canRp
    if (-not $ok) { return }
    if ($Blob.Gui.DialogCheck) { Invoke-BlobGuiRestorePointStep "BLOB OPTIMIZER - before removing $($app.Name)" }

    Start-BlobGuiTask "Uninstalling $($app.Name)"
    Set-BlobGuiStatus "Waiting for the uninstaller of $($app.Name)..."
    $r = Invoke-BlobAppUninstall -App $app -Log { param($m) Add-BlobGuiLog $m } -Pump { Update-BlobGui; Start-Sleep -Milliseconds 120 }
    if ($r -eq 'DryRun') { return }
    if ($r -notin @('Finished', 'Removed')) { Show-BlobGuiMessage -Title "Could not uninstall $($app.Name)" -Kind Error -Lines @("{Gray}$($r -replace '[{}]', '')"); return }
    if ($r -eq 'Removed') {
        $Blob.PrefetchValid = $false
        Show-BlobGuiMessage -Title "$($app.Name) is removed" -Kind Success -Lines @('{Gray}Windows removed the app and its app data.')
        Update-BlobGuiPage
        return
    }

    # Only scan for leftovers once Windows no longer lists the program.
    while (Test-BlobAppInstalled $app) {
        $again = Show-BlobGuiDialog -Title "$($app.Name) is still installed" -OkText 'Check again' -CancelText 'Stop' -Lines @(
            '{Gray}The uninstaller may still be open, or it was cancelled.',
            '{Gray}Finish it, then choose Check again.', '',
            '{White}BLOB only looks for leftovers after Windows stops listing the program,',
            '{White}so nothing that belongs to an installed program is ever removed.')
        if (-not $again) { Add-BlobGuiLog "{Yellow}$($app.Name) is still installed - leftover scan skipped."; Update-BlobGuiPage; return }
    }
    Add-BlobGuiLog "{White}$($app.Name) {Gray}is no longer installed. Looking for leftovers..."
    Set-BlobGuiStatus 'Looking for leftovers...'
    $left = @(Find-BlobAppLeftovers $app)
    if ($left.Count -eq 0) {
        Add-BlobGuiLog "{White}$($app.Name) {Gray}left nothing behind."
        Show-BlobGuiMessage -Title "$($app.Name) is fully removed" -Kind Success -Lines @('{Gray}The uninstaller cleaned up after itself. No leftover folders, registry keys, shortcuts or startup entries were found.')
        Update-BlobGuiPage
        return
    }
    $chosen = @(Show-BlobGuiLeftovers $app $left)
    if ($chosen.Count -eq 0) { Add-BlobGuiLog "{Gray}Leftovers of $($app.Name) kept."; Update-BlobGuiPage; return }
    Start-BlobGuiTask "Removing leftovers of $($app.Name)"
    $backup = Join-Path $Blob.RegBackupDir ("{0}-apps-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), (($app.Name -replace '[^\w-]', '') | ForEach-Object { $_.Substring(0, [Math]::Min(30, $_.Length)) }))
    foreach ($it in $chosen) { Add-BlobGuiLog (Remove-BlobLeftover $it $backup $app.Name) }
    Add-BlobGuiLog "{White}$($app.Name) {Gray}is fully removed. Folders are in the Recycle Bin; registry keys can be restored from Restore."
    Update-BlobGuiPage
}
