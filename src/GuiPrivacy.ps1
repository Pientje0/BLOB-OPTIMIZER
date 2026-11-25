# ============================================================================
#  BLOB OPTIMIZER - GuiPrivacy.ps1
#  The Privacy page: every section of the privacy catalogue, each item with
#  a switch (on = that Windows feature is turned off), privacy impact,
#  recommendation, state and a full explanation on hover.
#  Uses the same choose-then-apply flow as the Tweaks page.
# ============================================================================

$Blob.GuiShared.PrivacyTip = { param($el) New-BlobPrivacyTooltip (Get-BlobTweak $el.DataContext) }
$Blob.PcRecFilters = [ordered]@{ All = 'All'; Disable = 'Recommended off'; Optional = 'Your choice'; Keep = 'Better kept on' }

function New-BlobPrivacyTooltip {
    param($Tweak)
    $p = $Tweak.Privacy
    $s = New-BlobStack
    $s.MaxWidth = 500
    $head = New-BlobStack 'Horizontal' '0,0,0,8'
    [void]$head.Children.Add((New-BlobText $Tweak.Name 16 'Ink' 'SemiBold' -Display))
    if ($p.Oo) { $b = New-BlobBadge "O&O $($p.Oo)" 'Ink2'; $b.Margin = '10,2,0,0'; [void]$head.Children.Add($b) }
    [void]$s.Children.Add($head)
    $rows = @(
        @('What it does', $p.Does),
        @('What Windows or Microsoft can collect', $p.Data),
        @('Benefit of turning it off', $p.Benefit),
        @('What you lose', $p.Lose),
        @('Possible problems', $p.Issues))
    foreach ($r in $rows) {
        [void]$s.Children.Add((New-BlobText $r[0].ToUpper() 11 'Ink3' 'Normal' '0,4,0,1' -Display))
        [void]$s.Children.Add((New-BlobText $r[1] 12.5 'Ink' 'Normal' '0,0,0,4'))
    }
    $recWord = switch ($p.Rec) { 'Disable' { 'DISABLE - good privacy benefit, minimal downside' } 'Optional' { 'OPTIONAL - depends on how you use the PC' } default { 'KEEP ENABLED - important for security or everyday use' } }
    $line = New-BlobStack 'Horizontal' '0,6,0,0'
    [void]$line.Children.Add((New-BlobText 'RECOMMENDATION  ' 11 'Ink3' 'Normal' '0,1,0,0' -Display))
    [void]$line.Children.Add((New-BlobText $recWord 12.5 $(if ($p.Rec -eq 'Keep') { 'SignalText' } else { 'Ink' }) 'SemiBold'))
    [void]$s.Children.Add($line)
    $line2 = New-BlobStack 'Horizontal' '0,4,0,0'
    [void]$line2.Children.Add((New-BlobText 'PRIVACY IMPACT  ' 11 'Ink3' 'Normal' '0,1,0,0' -Display))
    [void]$line2.Children.Add((New-BlobText $p.Impact.ToUpper() 12.5 $(if ($p.Impact -eq 'High') { 'SignalText' } else { 'Ink' }) 'SemiBold'))
    [void]$s.Children.Add($line2)
    [void]$s.Children.Add((New-BlobText 'EXACT CHANGE (CURRENT -> NEW)' 11 'Ink3' 'Normal' '0,10,0,3' -Display))
    foreach ($m in @(Get-BlobTweakPreview @($Tweak) | Select-Object -Skip 1 | Where-Object { $_ -match '^\{(Gray|DarkGray)\} {4}' -and $_ -notmatch 'Note:' })) {
        [void]$s.Children.Add((ConvertTo-BlobTextBlock $m -Mono -Size 11.5))
    }
    [void]$s.Children.Add((New-BlobText 'The original value is saved first; undo it here or on the Restore page.' 12 'Ink2' 'Normal' '0,6,0,0'))
    return $s
}

# Privacy impact meter: three bars, HIGH in signal orange.
function New-BlobImpactMeter {
    param([string]$Impact)
    $lvl = switch ($Impact) { 'High' { 3 } 'Medium' { 2 } default { 1 } }
    $sp = New-BlobStack 'Horizontal'
    $sp.VerticalAlignment = 'Center'
    $fill = if ($Impact -eq 'High') { Get-BlobBrush 'Signal' } else { Get-BlobBrush 'Ink' }
    for ($i = 1; $i -le 3; $i++) {
        $bar = [Windows.Shapes.Rectangle]::new()
        $bar.Width = 5; $bar.Height = 4 + 3 * $i; $bar.Margin = '0,0,2,0'; $bar.VerticalAlignment = 'Bottom'
        $bar.Fill = if ($i -le $lvl) { $fill } else { Get-BlobBrush 'Rule' }
        [void]$sp.Children.Add($bar)
    }
    $w = New-BlobText $(switch ($Impact) { 'High' { 'HIGH' } 'Medium' { 'MED' } default { 'LOW' } }) 11.5 $(if ($Impact -eq 'High') { 'SignalText' } else { 'Ink2' }) 'SemiBold' '6,0,0,0' -Display
    $w.VerticalAlignment = 'Bottom'
    [void]$sp.Children.Add($w)
    return $sp
}

function New-BlobPrivacyRow {
    param($Tweak, [string]$State, [string]$Pending)
    $p = $Tweak.Privacy
    $wantOn = if ($Pending) { $Pending -eq 'On' } else { $State -eq 'Applied' }
    $row = [Windows.Controls.Border]::new()
    $row.BorderBrush = Get-BlobBrush 'Rule'; $row.BorderThickness = '0,0,0,1'
    $row.Background = if ($Pending) { Get-BlobBrush 'SignalSoft' } else { [Windows.Media.Brushes]::Transparent }
    $row.Uid = $(if ($Pending) { 'P' } else { '' })
    $row.Add_MouseEnter({ param($s, $e) if ($s.Uid -ne 'P') { $s.Background = Get-BlobBrush 'Hover' } })
    $row.Add_MouseLeave({ param($s, $e) if ($s.Uid -ne 'P') { $s.Background = [Windows.Media.Brushes]::Transparent } })
    $g = [Windows.Controls.Grid]::new()
    foreach ($w in @('4', '58', '*', '86', '108', '112', '34')) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = $w; $g.ColumnDefinitions.Add($cd) }

    $marker = [Windows.Controls.Border]::new()
    $marker.Background = if ($Pending) { Get-BlobBrush 'Signal' } else { [Windows.Media.Brushes]::Transparent }
    [void]$g.Children.Add($marker)

    if ($Tweak.InfoOnly) {
        $dash = New-BlobText ([string][char]0x2014) 14 'Ink3' 'Normal' -Display
        $dash.HorizontalAlignment = 'Center'; $dash.VerticalAlignment = 'Center'
        [Windows.Controls.Grid]::SetColumn($dash, 1); [void]$g.Children.Add($dash)
    } else {
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
            $sw.ToolTip = 'On = turn this Windows feature off. Nothing changes until you review and apply.'
            Register-BlobClick $sw $Blob.GuiShared.SwitchClick
            [Windows.Controls.Grid]::SetColumn($sw, 1); [void]$g.Children.Add($sw)
        }
    }

    $text = New-BlobStack
    $text.Margin = '6,0,16,0'; $text.VerticalAlignment = 'Center'
    $title = New-BlobStack 'Horizontal'
    [void]$title.Children.Add((New-BlobText $Tweak.Name 14 $(if ($p.Rec -eq 'N/A') { 'Ink3' } else { 'Ink' }) 'SemiBold'))
    if ($p.Oo) { $b = New-BlobBadge $p.Oo 'Ink2'; $b.Margin = '10,1,0,0'; [void]$title.Children.Add($b) }
    if ($Tweak.Admin -and -not $Tweak.InfoOnly) { $ad = New-BlobBadge 'ADMIN' 'Ink3'; $ad.Margin = '6,1,0,0'; [void]$title.Children.Add($ad) }
    [void]$text.Children.Add($title)
    $desc = New-BlobText $p.Does 12.5 'Ink2' 'Normal' '0,2,0,0'
    $desc.TextWrapping = 'NoWrap'; $desc.TextTrimming = 'CharacterEllipsis'
    [void]$text.Children.Add($desc)
    [Windows.Controls.Grid]::SetColumn($text, 2); [void]$g.Children.Add($text)

    $impact = New-BlobImpactMeter $p.Impact
    [Windows.Controls.Grid]::SetColumn($impact, 3); [void]$g.Children.Add($impact)

    $recText = switch ($p.Rec) { 'Disable' { 'DISABLE' } 'Optional' { 'OPTIONAL' } 'Keep' { 'KEEP ON' } default { 'N/A' } }
    $rec = New-BlobText $recText 12 $(switch ($p.Rec) { 'Disable' { 'Ink' } 'Keep' { 'SignalText' } default { 'Ink3' } }) $(if ($p.Rec -eq 'Disable') { 'SemiBold' } else { 'Normal' }) -Display
    $rec.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($rec, 4); [void]$g.Children.Add($rec)

    $arrow = [string][char]0x2192
    $stText = if ($Tweak.InfoOnly) { 'Info only' } elseif ($Pending -eq 'On') { "$arrow OFF" } elseif ($Pending -eq 'Off') { "$arrow BACK ON" } else {
        switch ($State) { 'Applied' { 'Turned off' } 'Partial' { 'Partly off' } default { 'Windows default' } } }
    $stColor = if ($Pending) { 'SignalText' } elseif ($State -eq 'Applied') { 'Ink' } else { 'Ink3' }
    $st = New-BlobText $stText 12.5 $stColor $(if ($Pending -or $State -eq 'Applied') { 'SemiBold' } else { 'Normal' }) -Display
    $st.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($st, 5); [void]$g.Children.Add($st)

    $help = New-BlobHelpIcon -Builder $Blob.GuiShared.PrivacyTip
    $help.DataContext = $Tweak.Id
    $help.Margin = '0'; $help.HorizontalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($help, 6); [void]$g.Children.Add($help)

    $g.Margin = '0,9,0,9'
    $row.Child = $g
    return $row
}

function Get-BlobGuiFilteredPrivacy {
    $list = @(Get-BlobPrivacyItems)
    if ($Blob.Gui.PcSection -and $Blob.Gui.PcSection -ne 'All sections') { $list = @($list | Where-Object { $_.Group -eq $Blob.Gui.PcSection }) }
    if ($Blob.Gui.PcRec -and $Blob.Gui.PcRec -ne 'All') { $list = @($list | Where-Object { $_.Privacy.Rec -eq $Blob.Gui.PcRec }) }
    $q = ([string]$Blob.Gui.PcSearch).Trim()
    if ($q) { $list = @($list | Where-Object { $_.Name -like "*$q*" -or $_.Privacy.Does -like "*$q*" -or $_.Privacy.Oo -like "*$q*" -or $_.Group -like "*$q*" }) }
    return $list
}

function Update-BlobGuiPrivacyList {
    $g = $Blob.Gui.CardGrid
    if (-not $g) { return }
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    $g.Children.Clear()
    $items = @(Get-BlobPrivacyItems)
    $states = @{}
    foreach ($t in $items) { $states[$t.Id] = Get-BlobTweakState $t }
    $list = @(Get-BlobGuiFilteredPrivacy)
    $n = 0
    foreach ($grp in $Blob.PrivacyGroups) {
        $inGrp = @($list | Where-Object { $_.Group -eq $grp })
        if ($inGrp.Count -eq 0) { continue }
        $n++
        $switchable = @($inGrp | Where-Object { -not $_.InfoOnly })
        $off = @($switchable | Where-Object { $states[$_.Id] -eq 'Applied' }).Count
        $num = [array]::IndexOf($Blob.PrivacyGroups, $grp) + 1
        [void]$g.Children.Add((New-BlobGroupHeader "$num. $grp" "$off of $($switchable.Count) turned off"))
        foreach ($t in $inGrp) { [void]$g.Children.Add((Get-BlobGuiCard $t $states[$t.Id])) }
    }
    if ($list.Count -eq 0) { [void]$g.Children.Add((New-BlobText 'Nothing matches these filters.' 14 'Ink3' 'Normal' '0,30,0,0')) }
    $switchAll = @($items | Where-Object { -not $_.InfoOnly })
    $offAll = @($switchAll | Where-Object { $states[$_.Id] -eq 'Applied' }).Count
    $dot = [string][char]0x00B7
    $Blob.Gui.CardCount.Text = "$($list.Count) shown  $dot  $offAll of $($switchAll.Count) turned off  $dot  $($Blob.Gui.Pending.Count) waiting"
    Update-BlobGuiPendingBar
    $Blob.Gui.PageScroll.UpdateLayout(); $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
}

function New-BlobGuiPrivacy {
    $root = New-BlobStack
    if (-not $Blob.Gui.PcSection) { $Blob.Gui.PcSection = 'All sections' }
    if (-not $Blob.Gui.PcRec) { $Blob.Gui.PcRec = 'All' }
    $items = @(Get-BlobPrivacyItems)

    $top = [Windows.Controls.DockPanel]::new()
    $sbox = [Windows.Controls.Grid]::new()
    $sbox.Width = 240; $sbox.VerticalAlignment = 'Top'; $sbox.Margin = '24,0,0,0'
    $search = [Windows.Controls.TextBox]::new()
    $search.Text = [string]$Blob.Gui.PcSearch; $search.Padding = '22,5,2,5'
    $hint = New-BlobText 'Search, or an O&O ID' 13.5 'Ink3' 'Normal' '23,6,0,0'
    $hint.IsHitTestVisible = $false
    if ($search.Text) { $hint.Visibility = 'Collapsed' }
    $glass = New-BlobGlyph 0xE721 'Ink2' 15
    $glass.Margin = '1,0,0,2'; $glass.HorizontalAlignment = 'Left'; $glass.IsHitTestVisible = $false
    [void]$sbox.Children.Add($search); [void]$sbox.Children.Add($hint); [void]$sbox.Children.Add($glass)
    $Blob.Gui.SearchHint = $hint
    $search.Add_TextChanged({ param($s, $e) $Blob.Gui.PcSearch = $s.Text; $Blob.Gui.SearchHint.Visibility = if ($s.Text) { 'Collapsed' } else { 'Visible' }; Update-BlobGuiPrivacyList })
    [Windows.Controls.DockPanel]::SetDock($sbox, 'Right')
    [void]$top.Children.Add($sbox)

    $filters = New-BlobStack
    $secRow = [Windows.Controls.DockPanel]::new()
    $secRow.Margin = '0,0,0,8'
    $l = New-BlobText 'SECTION' 11.5 'Ink3' 'Normal' '0,8,0,0' -Display
    $l.Width = 86
    [void]$secRow.Children.Add($l)
    $names = @('All sections') + @($Blob.PrivacyGroups | ForEach-Object { $_ })
    $labels = @('All sections') + @(for ($i = 0; $i -lt $Blob.PrivacyGroups.Count; $i++) { '{0}. {1}' -f ($i + 1), $Blob.PrivacyGroups[$i] })
    $combo = New-BlobCombo $labels ([array]::IndexOf($names, $Blob.Gui.PcSection)) 320
    $combo.HorizontalAlignment = 'Left'
    $combo.Tag = $names
    $combo.Add_SelectionChanged({ param($s, $e) $Blob.Gui.PcSection = $s.Tag[$s.SelectedIndex]; Update-BlobGuiPrivacyList })
    [void]$secRow.Children.Add($combo)
    [void]$filters.Children.Add($secRow)
    $recs = [Windows.Controls.WrapPanel]::new()
    foreach ($k in $Blob.PcRecFilters.Keys) {
        $count = if ($k -eq 'All') { $items.Count } else { @($items | Where-Object { $_.Privacy.Rec -eq $k }).Count }
        [void]$recs.Children.Add((New-BlobGuiFilterChip "$($Blob.PcRecFilters[$k]) $count" ($Blob.Gui.PcRec -eq $k) ([scriptblock]::Create("`$Blob.Gui.PcRec = '$k'; Show-BlobGuiPage 'privacy' -Rebuild"))))
    }
    [void]$filters.Children.Add((New-BlobFilterRow 'Advice' $recs))
    [void]$top.Children.Add($filters)
    [void]$root.Children.Add($top)

    $Blob.Gui.CardCount = New-BlobText '' 12 'Ink3' 'Normal' '0,10,0,0' -Mono
    [void]$root.Children.Add($Blob.Gui.CardCount)

    # Column heads
    $head = [Windows.Controls.Grid]::new()
    $head.Margin = '0,16,0,0'
    foreach ($w in @('4', '58', '*', '86', '108', '112', '34')) { $cd = [Windows.Controls.ColumnDefinition]::new(); $cd.Width = $w; $head.ColumnDefinitions.Add($cd) }
    foreach ($h in @(@('TURN OFF', 1, '6,0,0,4'), @('SETTING', 2, '6,0,0,4'), @('PRIVACY', 3, '0,0,0,4'), @('ADVICE', 4, '0,0,0,4'), @('STATE', 5, '0,0,0,4'))) {
        $t = New-BlobText $h[0] 11 'Ink3' 'Normal' $h[2] -Display
        [Windows.Controls.Grid]::SetColumn($t, $h[1]); [void]$head.Children.Add($t)
    }
    [void]$root.Children.Add($head)

    $list = New-BlobStack
    $Blob.Gui.CardGrid = $list; $Blob.Gui.GridKind = 'privacy'
    [void]$root.Children.Add($list)
    [void]$root.Children.Add((New-BlobText 'Every switch uses a documented Windows, Edge or Office policy or setting. Microsoft Defender, security updates and Windows activation are never changed. O&O ShutUp10++ IDs are shown where known.' 12 'Ink3' 'Normal' '0,24,0,0'))

    Set-BlobGuiPageActions @(
        (New-BlobButton 'Choose all recommended' {
                foreach ($t in (Get-BlobGuiFilteredPrivacy)) {
                    if ($t.InfoOnly -or $t.Privacy.Rec -ne 'Disable') { continue }
                    if ($t.Admin -and -not $Blob.IsAdmin) { continue }
                    if ((Get-BlobTweakState $t) -ne 'Applied') { $Blob.Gui.Pending[$t.Id] = 'On' }
                }
                Update-BlobGuiPrivacyList } -ToolTip 'Marks every shown setting with advice DISABLE. Nothing changes until you review and apply.' -Margin '0'))
    Update-BlobGuiPrivacyList
    return $root
}
