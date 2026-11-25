# ============================================================================
#  BLOB OPTIMIZER - Gui.ps1
#  Window interface shell: window creation, navigation, dialogs, activity log
#  and small control factories. Uses WPF, which is part of Windows - nothing
#  is installed. All work goes through the same engine as the terminal UI.
# ============================================================================

# Shared, pre-compiled handlers: per-element data lives in DataContext, so
# building many cards does not compile a new script block for each one.
$Blob.GuiShared = @{
    RiskTip     = { param($el) New-BlobTooltipPanel -Title $Blob.RiskInfo[$el.DataContext].Label -Paragraphs @($Blob.RiskInfo[$el.DataContext].Text) }
    TweakTip    = { param($el) New-BlobTweakTooltip (Get-BlobTweak $el.DataContext) }
    SwitchClick = { Switch-BlobGuiTweak $Blob.Gui.Sender.DataContext }
    SelectClick = { Switch-BlobGuiSelect $Blob.Gui.Sender.DataContext }
}

# Black and green only. Severity is shown with words and inverted badges.
$Blob.GuiColors = @{
    Cyan = '#3DFF6A'; DarkCyan = '#0F6A24'; White = '#3DFF6A'; Gray = '#2EDB55'; DarkGray = '#1E9A3E'
    Green = '#3DFF6A'; Yellow = '#3DFF6A'; Red = '#3DFF6A'; DarkYellow = '#2EDB55'; Magenta = '#3DFF6A'; Black = '#000000'
}

function Test-BlobGuiSupported {
    if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { return 'PowerShell is not running in STA mode (required by WPF).' }
    try { Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction Stop } catch { return 'WPF is not available on this system.' }
    return $null
}

function New-BlobGuiWindow {
    param([string]$Xaml)
    $full = $Xaml.Replace('<!--THEME-->', "<Window.Resources>$($Blob.GuiTheme)</Window.Resources>")
    return [Windows.Markup.XamlReader]::Parse($full)
}

function Get-BlobBrush {
    param([string]$Color)
    if (-not $Blob.GuiBrushCache) { $Blob.GuiBrushCache = @{} }
    $hex = if ($Blob.GuiColors.ContainsKey($Color)) { $Blob.GuiColors[$Color] } else { $Color }
    if (-not $Blob.GuiBrushCache.ContainsKey($hex)) {
        $b = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($hex))
        $b.Freeze()
        $Blob.GuiBrushCache[$hex] = $b
    }
    return $Blob.GuiBrushCache[$hex]
}

# Turns a colour-tagged line ("{Gray}a {White}b") into a TextBlock of Runs.
function ConvertTo-BlobTextBlock {
    param([string]$Markup, [double]$Size = 13, [switch]$Mono, [string]$Default = 'White')
    $tb = [Windows.Controls.TextBlock]::new()
    $tb.FontSize = $Size
    $tb.TextWrapping = 'Wrap'
    if ($Mono) { $tb.FontFamily = [Windows.Media.FontFamily]::new('Consolas') }
    $parts = [regex]::Split($Markup, $Blob.ColorTag)
    $color = $Default
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { $color = $parts[$i]; continue }
        if ($parts[$i].Length -eq 0) { continue }
        $run = [Windows.Documents.Run]::new($parts[$i])
        $run.Foreground = Get-BlobBrush $color
        $tb.Inlines.Add($run)
    }
    if ($Markup.Length -eq 0) { $tb.Height = 8 }
    return $tb
}

# ---------------------------------------------------------------------------
#  Control factories
# ---------------------------------------------------------------------------
function New-BlobText {
    param([string]$Text, [double]$Size = 13, [string]$Color = 'White', [string]$Weight = 'Normal', [string]$Margin = '0')
    $t = [Windows.Controls.TextBlock]::new()
    $t.Text = $Text; $t.FontSize = $Size; $t.Foreground = Get-BlobBrush $Color
    $t.FontWeight = $Weight; $t.Margin = $Margin; $t.TextWrapping = 'Wrap'
    return $t
}

function New-BlobButton {
    param([string]$Label, [scriptblock]$Action, [ValidateSet('Normal', 'Accent', 'Danger')][string]$Kind = 'Normal', [string]$ToolTip, [string]$Margin)
    $b = [Windows.Controls.Button]::new()
    $b.Content = $Label
    if ($Kind -eq 'Accent') { $b.Style = $Blob.Gui.Window.FindResource('AccentButton') }
    if ($Kind -eq 'Danger') { $b.Style = $Blob.Gui.Window.FindResource('DangerButton') }
    if ($ToolTip) { $b.ToolTip = $ToolTip }
    if ($Margin) { $b.Margin = $Margin }
    Register-BlobClick $b $Action
    return $b
}

# Handlers store their action in Tag and run through Invoke-BlobGuiAction,
# which guards against re-entry and reports errors instead of crashing.
function Register-BlobClick {
    param($Control, [scriptblock]$Action)
    $Control.Tag = $Action
    $Control.Add_Click({ param($s, $e) $Blob.Gui.Sender = $s; Invoke-BlobGuiAction $s.Tag })
}

function Invoke-BlobGuiAction {
    param([scriptblock]$Action)
    if ($Blob.Gui.Busy -or -not $Action) { return }
    $Blob.Gui.Busy = $true
    $Blob.Gui.Window.Cursor = [Windows.Input.Cursors]::Wait
    try { & $Action }
    catch {
        $msg = $_.Exception.Message
        Write-BlobLog "GUI error: $msg $($_.InvocationInfo.PositionMessage)" 'ERROR'
        Add-BlobGuiLog "{Red}Error: $($msg -replace '[{}]', '')"
        Show-BlobGuiMessage -Title 'Something went wrong' -Kind Error -Lines @("{Gray}$($msg -replace '[{}]', '')", '', '{Gray}No further changes were made. Details are in the session log.')
    } finally {
        $Blob.Gui.Busy = $false
        $Blob.Gui.Window.Cursor = $null
        Set-BlobGuiStatus 'Ready'
    }
}

function New-BlobCard {
    param($Child, [string]$Margin = '0,0,0,12', [string]$Padding = '18,14', [double]$Width = [double]::NaN)
    $c = [Windows.Controls.Border]::new()
    $c.Background = Get-BlobBrush '#000000'; $c.BorderBrush = Get-BlobBrush '#0F6A24'
    $c.BorderThickness = 1; $c.CornerRadius = 0; $c.Padding = $Padding; $c.Margin = $Margin
    if (-not [double]::IsNaN($Width)) { $c.Width = $Width }
    $c.Child = $Child
    return $c
}

function New-BlobBadge {
    param([string]$Text, [string]$Color = 'Gray')
    $b = [Windows.Controls.Border]::new()
    $b.CornerRadius = 0; $b.Padding = '7,1'; $b.Margin = '8,0,0,0'; $b.VerticalAlignment = 'Center'
    $b.BorderBrush = Get-BlobBrush $Color; $b.BorderThickness = 1
    $t = New-BlobText $Text 10.5 $Color 'SemiBold'
    $b.Child = $t
    return $b
}

function New-BlobStack {
    param([string]$Orientation = 'Vertical', [string]$Margin = '0')
    $s = [Windows.Controls.StackPanel]::new()
    $s.Orientation = $Orientation; $s.Margin = $Margin
    return $s
}

function New-BlobHeading {
    param([string]$Text, [string]$Margin = '0,6,0,10')
    return (New-BlobText $Text.ToUpper() 11.5 'DarkGray' 'Bold' $Margin)
}

function New-BlobBar {
    param([double]$Fraction, [double]$Width = 260)
    $p = [Windows.Controls.ProgressBar]::new()
    $p.Minimum = 0; $p.Maximum = 1; $p.Value = [Math]::Min(1, [Math]::Max(0, $Fraction)); $p.Width = $Width
    $p.Foreground = if ($Fraction -ge 0.9) { Get-BlobBrush 'Red' } elseif ($Fraction -ge 0.75) { Get-BlobBrush 'Yellow' } else { Get-BlobBrush 'Cyan' }
    return $p
}

function New-BlobCombo {
    param([string[]]$Items, [int]$Selected = 0, [double]$Width = 220)
    $c = [Windows.Controls.ComboBox]::new()
    foreach ($i in $Items) { [void]$c.Items.Add($i) }
    if ($Items.Count -gt 0) { $c.SelectedIndex = [Math]::Max(0, $Selected) }
    $c.Width = $Width; $c.Margin = '0,0,8,0'
    return $c
}

function New-BlobGrid {
    param([array]$Columns, [double]$Height = 420)
    # Columns: @( @{ Header; Path; Width } )
    $g = [Windows.Controls.DataGrid]::new()
    $g.Height = $Height
    foreach ($col in $Columns) {
        $c = [Windows.Controls.DataGridTextColumn]::new()
        $c.Header = $col.Header
        $c.Binding = New-Object Windows.Data.Binding $col.Path
        if ($col.Width) { $c.Width = New-Object Windows.Controls.DataGridLength($col.Width, $(if ($col.Width -le 1) { 'Star' } else { 'Pixel' })) }
        else { $c.Width = New-Object Windows.Controls.DataGridLength(1, 'Star') }
        [void]$g.Columns.Add($c)
    }
    return $g
}

# Lines of markup rendered in a card (used for info pages).
function New-BlobInfoCard {
    param([string[]]$Lines, [switch]$Mono)
    $s = New-BlobStack
    foreach ($l in $Lines) { [void]$s.Children.Add((ConvertTo-BlobTextBlock $l -Mono:$Mono -Size 13)) }
    return (New-BlobCard $s)
}

# ---------------------------------------------------------------------------
#  Help ("?") icons, rich tooltips and risk badges
# ---------------------------------------------------------------------------
function New-BlobTooltipPanel {
    param([string]$Title, [string[]]$Paragraphs = @(), [string[]]$Mono = @(), [string]$MonoTitle = '')
    $s = New-BlobStack
    $s.MaxWidth = 490
    [void]$s.Children.Add((New-BlobText $Title 14 'White' 'SemiBold' '0,0,0,6'))
    foreach ($p in $Paragraphs) {
        if (-not $p) { continue }
        [void]$s.Children.Add((ConvertTo-BlobTextBlock $p -Size 12.5 -Default 'Gray'))
        $s.Children[$s.Children.Count - 1].Margin = '0,0,0,6'
    }
    if ($Mono.Count -gt 0) {
        if ($MonoTitle) { [void]$s.Children.Add((New-BlobText $MonoTitle.ToUpper() 10.5 'DarkGray' 'Bold' '0,4,0,4')) }
        foreach ($m in $Mono) { [void]$s.Children.Add((ConvertTo-BlobTextBlock $m -Mono -Size 11.5)) }
    }
    return $s
}

function Set-BlobTooltip {
    param($Element, $Content)
    $Element.ToolTip = $Content
    [Windows.Controls.ToolTipService]::SetInitialShowDelay($Element, 120)
    [Windows.Controls.ToolTipService]::SetShowDuration($Element, 120000)
    [Windows.Controls.ToolTipService]::SetPlacement($Element, 'Bottom')
}

# A round "?" icon that shows detailed help when hovered.
function New-BlobHelpIcon {
    param($Tooltip, [scriptblock]$Builder)
    $b = [Windows.Controls.Border]::new()
    $b.Width = 20; $b.Height = 20; $b.CornerRadius = 0
    $b.BorderThickness = 1.5; $b.BorderBrush = Get-BlobBrush '#1E9A3E'; $b.Background = Get-BlobBrush '#000000'
    $b.Margin = '8,0,0,0'; $b.VerticalAlignment = 'Center'; $b.Cursor = [Windows.Input.Cursors]::Help
    $t = New-BlobText '?' 12 'Gray' 'Bold'
    $t.HorizontalAlignment = 'Center'; $t.VerticalAlignment = 'Center'; $t.Margin = '0,-1,0,0'
    $b.Child = $t
    $b.Add_MouseEnter({ param($s, $e) $s.BorderBrush = Get-BlobBrush 'Cyan'; $s.Child.Foreground = Get-BlobBrush 'Cyan' })
    $b.Add_MouseLeave({ param($s, $e) $s.BorderBrush = Get-BlobBrush '#1E9A3E'; $s.Child.Foreground = Get-BlobBrush 'Gray' })
    if ($Builder) { Set-BlobLazyTooltip $b $Builder } else { Set-BlobTooltip $b $Tooltip }
    return $b
}

# Tooltip content built on first hover (keeps pages with many cards fast).
function Set-BlobLazyTooltip {
    param($Element, [scriptblock]$Builder)
    Set-BlobTooltip $Element 'Loading...'
    $Element.Tag = $Builder
    $Element.Add_ToolTipOpening({ param($s, $e) if ($s.Tag -is [scriptblock]) { $sb = $s.Tag; $s.Tag = $null; $s.ToolTip = & $sb $s } })
}

function New-BlobRiskBadge {
    param([string]$Risk)
    $r = $Blob.RiskInfo[$Risk]
    $badge = New-BlobBadge $r.Label $r.Color
    if ($Risk -eq 'Advanced') {    # inverted so higher risk stands out without extra colours
        $badge.Background = Get-BlobBrush 'Green'; $badge.Child.Foreground = Get-BlobBrush 'Black'
    }
    $badge.DataContext = $Risk
    Set-BlobLazyTooltip $badge $Blob.GuiShared.RiskTip
    return $badge
}

function New-BlobRiskLegend {
    $wrap = [Windows.Controls.WrapPanel]::new()
    [void]$wrap.Children.Add((New-BlobText 'Risk levels:' 12.5 'Gray' 'Normal' '0,2,4,0'))
    foreach ($k in @('Minimal', 'Standard', 'Advanced', 'Optional')) {
        $r = $Blob.RiskInfo[$k]
        $item = New-BlobStack 'Horizontal' '0,0,14,0'
        [void]$item.Children.Add((New-BlobRiskBadge $k))
        $short = switch ($k) { 'Minimal' { 'safe, minor' } 'Standard' { 'changes a feature' } 'Advanced' { 'test afterwards' } default { 'looks / taste' } }
        [void]$item.Children.Add((New-BlobText $short 12 'DarkGray' 'Normal' '6,2,0,0'))
        [void]$wrap.Children.Add($item)
    }
    [void]$wrap.Children.Add((New-BlobText 'Hover any ? for full details.' 12 'DarkGray' 'Normal' '0,2,0,0'))
    return (New-BlobCard $wrap '0,0,0,14' '16,10')
}

# Restore point step used before applying changes from the window.
function Invoke-BlobGuiRestorePointStep {
    param([string]$Description)
    Start-BlobGuiTask 'Creating System Restore point (this can take a minute)'
    Add-BlobGuiLog (New-BlobRestorePoint $Description)
}

# ---------------------------------------------------------------------------
#  Activity log and status
# ---------------------------------------------------------------------------
function Update-BlobGui {
    if ($Blob.Gui.Preloading) { return }
    try { $Blob.Gui.Window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background) } catch { }
}

function Add-BlobGuiLog {
    param([string]$Markup)
    $panel = $Blob.Gui.LogPanel
    if ($panel.Children.Count -gt 600) { $panel.Children.RemoveAt(0) }
    $stamp = '{DarkGray}' + (Get-Date -Format 'HH:mm:ss') + '  '
    [void]$panel.Children.Add((ConvertTo-BlobTextBlock ($stamp + $Markup) -Mono -Size 12))
    $Blob.Gui.LogScroll.ScrollToEnd()
    Update-BlobGui
}

function Set-BlobGuiStatus {
    param([string]$Text)
    if ($Blob.Gui.Preloading) { return }
    $Blob.Gui.StatusText.Text = $Text
    Update-BlobGui
}

# ---------------------------------------------------------------------------
#  Dialogs
# ---------------------------------------------------------------------------
function Show-BlobGuiDialog {
    param([string]$Title, [string]$Subtitle = '', [string[]]$Lines = @(), [string]$OkText = 'Confirm',
          [switch]$Danger, [switch]$InfoOnly, [string]$Kind = 'Info', [string]$CancelText = 'Cancel',
          [string]$CheckText, [bool]$CheckDefault = $false, [bool]$CheckEnabled = $true)
    $d = New-BlobGuiWindow $Blob.GuiDialogXaml
    $d.Owner = $Blob.Gui.Window
    $d.Title = $Title
    $d.FindName('DlgTitle').Text = $Title
    $d.FindName('DlgSub').Text = $Subtitle
    if (-not $Subtitle) { $d.FindName('DlgSub').Visibility = 'Collapsed' }
    $body = $d.FindName('DlgBody')
    if ($Blob.DryRun -and -not $InfoOnly) { [void]$body.Children.Add((ConvertTo-BlobTextBlock '{Magenta}DRY RUN is active: nothing will actually be changed.')); [void]$body.Children.Add((ConvertTo-BlobTextBlock '')) }
    foreach ($l in $Lines) { [void]$body.Children.Add((ConvertTo-BlobTextBlock $l -Mono -Size 12.5)) }
    $ok = $d.FindName('DlgOk'); $cancel = $d.FindName('DlgCancel')
    $ok.Content = $OkText
    $cancel.Content = $CancelText
    $accent = switch ($Kind) { 'Error' { 'Red' } 'Warning' { 'Yellow' } 'Success' { 'Green' } default { 'Cyan' } }
    if ($Danger) { $accent = 'Red'; $ok.Background = Get-BlobBrush 'Red'; $ok.BorderBrush = Get-BlobBrush 'Red' }
    $d.FindName('DlgBorder').BorderBrush = Get-BlobBrush $accent
    if ($InfoOnly) { $cancel.Visibility = 'Collapsed' }
    $check = $d.FindName('DlgCheck')
    if ($CheckText) {
        $check.Visibility = 'Visible'
        $d.FindName('DlgCheckText').Text = $CheckText
        $check.IsChecked = $CheckDefault
        $check.IsEnabled = $CheckEnabled
    }
    $d.Tag = $false
    $ok.Add_Click({ param($s, $e) $w = [Windows.Window]::GetWindow($s); $w.Tag = $true; $w.Close() })
    $cancel.Add_Click({ param($s, $e) [Windows.Window]::GetWindow($s).Close() })
    $d.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Escape') { $s.Close() } })
    if ($Lines.Count -le 6) { $d.Height = 300 }
    $null = $d.ShowDialog()
    $Blob.Gui.DialogCheck = ($CheckText -and $check.IsEnabled -and [bool]$check.IsChecked)
    return [bool]$d.Tag
}

function Show-BlobGuiMessage {
    param([string]$Title, [string[]]$Lines = @(), [ValidateSet('Info', 'Success', 'Warning', 'Error')][string]$Kind = 'Info')
    $null = Show-BlobGuiDialog -Title $Title -Lines $Lines -OkText 'Close' -InfoOnly -Kind $Kind
}

function Confirm-BlobGui {
    param([string]$Title, [string[]]$Lines, [string]$Subtitle = '', [string]$OkText = 'Apply', [switch]$Danger)
    return Show-BlobGuiDialog -Title $Title -Subtitle $Subtitle -Lines $Lines -OkText $OkText -Danger:$Danger
}

function Show-BlobGuiInput {
    param([string]$Title, [string[]]$Prompt, [string]$Default = '', [scriptblock]$Validate)
    $d = New-BlobGuiWindow $Blob.GuiDialogXaml
    $d.Owner = $Blob.Gui.Window
    $d.Height = 300
    $d.FindName('DlgTitle').Text = $Title
    $d.FindName('DlgSub').Visibility = 'Collapsed'
    $body = $d.FindName('DlgBody')
    foreach ($p in $Prompt) { [void]$body.Children.Add((ConvertTo-BlobTextBlock $p)) }
    $box = [Windows.Controls.TextBox]::new()
    $box.Text = $Default; $box.Margin = '0,12,0,6'
    [void]$body.Children.Add($box)
    $err = New-BlobText '' 12 'Red'
    [void]$body.Children.Add($err)
    $d.FindName('DlgOk').Content = 'OK'
    $d.Tag = @{ Result = $null; Validate = $Validate; Box = $box; Err = $err }
    $d.FindName('DlgOk').Add_Click({
            param($s, $e)
            $w = [Windows.Window]::GetWindow($s); $st = $w.Tag
            $v = $st.Box.Text.Trim()
            $msg = if ($st.Validate) { & $st.Validate $v } else { $null }
            if ($msg) { $st.Err.Text = $msg } else { $st.Result = $v; $w.Close() }
        })
    $d.FindName('DlgCancel').Add_Click({ param($s, $e) [Windows.Window]::GetWindow($s).Close() })
    $d.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Escape') { $s.Close() } })
    $d.Add_ContentRendered({ param($s, $e) $s.Tag.Box.Focus(); $s.Tag.Box.SelectAll() })
    $null = $d.ShowDialog()
    return $d.Tag.Result
}

function Show-BlobGuiAdminRequired {
    param([string]$Why)
    Show-BlobGuiMessage -Title 'Administrator rights required' -Kind Warning -Lines @(
        "{White}$Why", '',
        '{Gray}BLOB OPTIMIZER asks for administrator rights when it starts.',
        '{Gray}Close it and start it again, then choose Yes in the Windows permission prompt.')
}

# Runs a list of operations with progress in the activity log.
function Start-BlobGuiTask {
    param([string]$Title)
    Set-BlobGuiStatus "$Title..."
    Add-BlobGuiLog "{Cyan}$($Blob.Ch.On) {White}$Title"
}

# ---------------------------------------------------------------------------
#  Window and navigation
# ---------------------------------------------------------------------------
# Per-page state that builders put on $Blob.Gui. It is saved with each cached
# page and restored when the page is shown, so pages never share state.
$Blob.GuiPageState = @('P', 'CardGrid', 'CardCount', 'ApplySelBtn', 'SearchHint', 'PendingActions')
# Pages that show setting / journal state: refreshed in the background after any change.
$Blob.GuiVolatilePages = @('dashboard', 'presets', 'optimize', 'services', 'startup', 'power', 'restore')
# Preload order, and pages that wait for the background data snapshot on their first build.
$Blob.GuiPreloadOrder = @('optimize', 'presets', 'startup', 'power', 'restore', 'tools', 'services', 'cleanup', 'network', 'sysinfo', 'dashboard')
$Blob.GuiHeavyPages = @('services', 'cleanup', 'network', 'sysinfo', 'dashboard')

function Set-BlobGuiPageActions {
    param([array]$Buttons = @())
    $Blob.Gui.PendingActions = @($Buttons)
}

# Builds a page into the cache without disturbing the page currently shown.
function New-BlobGuiPageEntry {
    param([string]$Key)
    $page = $Blob.Gui.Pages | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
    $saved = @{}
    foreach ($n in $Blob.GuiPageState) { $saved[$n] = $Blob.Gui[$n]; $Blob.Gui[$n] = $null }
    $Blob.Gui.PendingActions = @()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try { $content = & $page.Build }
    catch {
        $content = New-BlobInfoCard @("{Red}This page could not be loaded: $($_.Exception.Message -replace '[{}]', '')")
        Write-BlobLog "GUI page '$Key' failed: $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" 'ERROR'
    }
    $entry = @{ Content = $content; Stale = $false; Scroll = 0; Ms = $sw.ElapsedMilliseconds }
    foreach ($n in $Blob.GuiPageState) { $entry[$n] = $Blob.Gui[$n]; $Blob.Gui[$n] = $saved[$n] }
    $Blob.Gui.Cache[$Key] = $entry
    return $entry
}

function Show-BlobGuiPage {
    param([string]$Key, [switch]$KeepScroll, [switch]$Rebuild)
    $page = $Blob.Gui.Pages | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
    if (-not $page) { return }
    if ($Blob.Gui.Current -and $Blob.Gui.Current -ne $Key -and $Blob.Gui.Cache.ContainsKey($Blob.Gui.Current)) {
        $Blob.Gui.Cache[$Blob.Gui.Current].Scroll = $Blob.Gui.PageScroll.VerticalOffset
    }

    $entry = $Blob.Gui.Cache[$Key]
    if ($Rebuild -or -not $entry -or $entry.Stale) {
        $Blob.Gui.Window.Cursor = [Windows.Input.Cursors]::Wait
        $Blob.Gui.StatusText.Text = "Loading $($page.Label)..."
        $oldScroll = if ($entry) { $entry.Scroll } else { 0 }
        try { $entry = New-BlobGuiPageEntry $Key } finally { $Blob.Gui.Window.Cursor = $null }
        $entry.Scroll = $oldScroll
    }

    $Blob.Gui.Current = $Key
    foreach ($n in $Blob.GuiPageState) { $Blob.Gui[$n] = $entry[$n] }
    foreach ($p in $Blob.Gui.Pages) {
        $btn = $Blob.Gui.Nav[$p.Key]
        if ($p.Key -eq $Key) { $btn.Foreground = Get-BlobBrush 'Cyan'; $btn.BorderBrush = Get-BlobBrush 'Cyan' }
        else { $btn.Foreground = Get-BlobBrush '#2EDB55'; $btn.BorderBrush = [Windows.Media.Brushes]::Transparent }
    }
    $Blob.Gui.PageTitle.Text = $page.Label
    $Blob.Gui.PageSubtitle.Text = $page.Subtitle
    $Blob.Gui.PageActions.Children.Clear()
    foreach ($b in @($entry.PendingActions)) { if ($b) { [void]$Blob.Gui.PageActions.Children.Add($b) } }
    $Blob.Gui.PageHost.Content = $entry.Content
    Update-BlobGuiCardColumns
    if (-not $KeepScroll) { $Blob.Gui.PageScroll.UpdateLayout(); $Blob.Gui.PageScroll.ScrollToVerticalOffset($entry.Scroll) }
    if ($Blob.Gui.PreloadDone -or -not $Blob.Gui.PreloadTimer) { $Blob.Gui.StatusText.Text = 'Ready' }
}

# Re-renders the current page after a change (keeping the scroll position)
# and schedules a quiet background refresh of the other affected tabs.
function Update-BlobGuiPage {
    $Blob.PrefetchValid = $false        # data may have changed: query live from now on
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    foreach ($k in $Blob.GuiVolatilePages) {
        if ($k -ne $Blob.Gui.Current -and $Blob.Gui.Cache.ContainsKey($k)) { $Blob.Gui.Cache[$k].Stale = $true }
    }
    Show-BlobGuiPage $Blob.Gui.Current -KeepScroll -Rebuild
    $Blob.Gui.PageScroll.UpdateLayout()
    $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
    Start-BlobGuiPreload
}

function Start-BlobGuiPreload {
    if (-not $Blob.Gui.PreloadTimer) {
        $t = New-Object Windows.Threading.DispatcherTimer ([Windows.Threading.DispatcherPriority]::ApplicationIdle)
        $t.Interval = [TimeSpan]::FromMilliseconds(30)
        $t.Add_Tick({ Invoke-BlobGuiPreloadTick })
        $Blob.Gui.PreloadTimer = $t
    }
    $Blob.Gui.PreloadTimer.Start()
}

# Builds at most one page per tick so the window stays responsive.
function Invoke-BlobGuiPreloadTick {
    if ($Blob.Gui.Preloading -or $Blob.Gui.Busy) { return }
    if ($Blob.Gui.Window.OwnedWindows.Count -gt 0) { return }      # a dialog is open
    if ($Blob.PrefetchState -eq 'Running') { $null = Receive-BlobPrefetch }
    $waiting = $Blob.PrefetchState -eq 'Running'
    # Warm the Optimizations cards a few at a time so the window never stalls.
    if (-not $Blob.Gui.CardsWarm -and -not $Blob.Gui.Cache.ContainsKey('optimize')) {
        if (-not $Blob.Gui.CardQueue) { $Blob.Gui.CardQueue = [Collections.Queue]::new([object[]]$Blob.Tweaks.ToArray()) }
        $Blob.Gui.Preloading = $true
        try {
            for ($i = 0; $i -lt 6 -and $Blob.Gui.CardQueue.Count -gt 0; $i++) {
                $t = $Blob.Gui.CardQueue.Dequeue()
                $null = Get-BlobGuiCard $t (Get-BlobTweakState $t)
            }
        } finally { $Blob.Gui.Preloading = $false }
        if ($Blob.Gui.CardQueue.Count -eq 0) { $Blob.Gui.CardsWarm = $true }
        $Blob.Gui.StatusText.Text = "Preloading settings... $($Blob.Tweaks.Count - $Blob.Gui.CardQueue.Count) of $($Blob.Tweaks.Count)"
        return
    }
    $next = $null
    foreach ($k in $Blob.GuiPreloadOrder) {
        $e = $Blob.Gui.Cache[$k]
        if ($e -and -not $e.Stale) { continue }
        if ($k -eq $Blob.Gui.Current) { continue }
        if ($waiting -and -not $e -and $k -in $Blob.GuiHeavyPages) { continue }
        $next = $k; break
    }
    $total = $Blob.Gui.Pages.Count
    if (-not $next) {
        if ($waiting) { $Blob.Gui.StatusText.Text = 'Collecting system information in the background...'; return }
        $Blob.Gui.PreloadTimer.Stop()
        if (-not $Blob.Gui.PreloadDone) {
            $Blob.Gui.PreloadDone = $true
            $ms = 0; foreach ($e in $Blob.Gui.Cache.Values) { $ms += $e.Ms }
            Write-BlobLog "All $total tabs preloaded ($ms ms of build time)."
        }
        $Blob.Gui.StatusText.Text = 'Ready - all tabs loaded'
        return
    }
    $Blob.Gui.Preloading = $true
    try { $null = New-BlobGuiPageEntry $next } finally { $Blob.Gui.Preloading = $false }
    $ready = @($Blob.Gui.Cache.Values | Where-Object { -not $_.Stale }).Count
    if (-not $Blob.Gui.PreloadDone) { $Blob.Gui.StatusText.Text = "Preloading tabs... $ready of $total ready" }
}

# Card grids use as many columns as fit (about 300 px per card).
function Update-BlobGuiCardColumns {
    $g = $Blob.Gui.CardGrid
    if (-not $g) { return }
    $w = $Blob.Gui.PageScroll.ViewportWidth
    if (-not $w -or $w -le 0) { $w = $Blob.Gui.Window.ActualWidth - 60 }
    if (-not $w -or $w -le 0) { $w = $Blob.Gui.Window.Width - 60 }
    $g.Columns = [Math]::Max(1, [int][Math]::Floor($w / 300))
}

function Initialize-BlobGuiWindow {
    $w = New-BlobGuiWindow $Blob.GuiXaml
    $Blob.Gui = @{ Window = $w; Busy = $false; Current = $null; Nav = @{}; LogVisible = $true }
    foreach ($n in @('TitleVersion', 'AdminBadge', 'AdminBadgeText', 'DryRunBadge', 'BtnMin', 'BtnMax', 'BtnClose', 'NavPanel',
                     'PageActions', 'PageTitle', 'PageSubtitle', 'PageScroll', 'PageHost', 'BtnToggleLog', 'BtnClearLog',
                     'LogScroll', 'LogPanel', 'StatusText', 'StatusRight', 'RootBorder')) {
        $Blob.Gui[$n] = $w.FindName($n)
    }
    # Fit the window to the screen (taller when there is room, so the whole sidebar shows).
    try {
        $wa = [Windows.SystemParameters]::WorkArea
        $w.Height = [Math]::Max($w.MinHeight, [Math]::Min(880, $wa.Height - 40))
        $w.Width = [Math]::Max($w.MinWidth, [Math]::Min(1240, $wa.Width - 40))
    } catch { }
    $w.Title = "BLOB OPTIMIZER $($Blob.Version)"
    $Blob.Gui.TitleVersion.Text = "v$($Blob.Version)"
    if ($Blob.IsAdmin) {
        $Blob.Gui.AdminBadge.Background = Get-BlobBrush '#062A10'; $Blob.Gui.AdminBadgeText.Text = 'ADMINISTRATOR'; $Blob.Gui.AdminBadgeText.Foreground = Get-BlobBrush 'Green'
    } else {
        $Blob.Gui.AdminBadge.Background = Get-BlobBrush '#062A10'; $Blob.Gui.AdminBadgeText.Text = 'STANDARD USER - READ ONLY FOR SYSTEM SETTINGS'; $Blob.Gui.AdminBadgeText.Foreground = Get-BlobBrush 'Yellow'
    }
    if ($Blob.DryRun) { $Blob.Gui.DryRunBadge.Visibility = 'Visible' }
    $Blob.Gui.StatusRight.Text = "$($Blob.SysInfo.Host)  -  PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)  -  No installation, nothing left running  -  Backups: $($Blob.DataRoot)"

    $Blob.Gui.BtnMin.Add_Click({ $Blob.Gui.Window.WindowState = 'Minimized' })
    $Blob.Gui.BtnMax.Add_Click({ $win = $Blob.Gui.Window; if ($win.WindowState -eq 'Maximized') { $win.WindowState = 'Normal' } else { $win.WindowState = 'Maximized' } })
    $Blob.Gui.BtnClose.Add_Click({ $Blob.Gui.Window.Close() })
    # A chromeless maximised window overhangs the screen edge; pad it.
    $w.Add_StateChanged({
            $win = $Blob.Gui.Window
            if ($win.WindowState -eq 'Maximized') { $Blob.Gui.RootBorder.Margin = '7'; $Blob.Gui.BtnMax.Content = '[-]' }
            else { $Blob.Gui.RootBorder.Margin = '0'; $Blob.Gui.BtnMax.Content = '[ ]' }
        })
    $Blob.Gui.BtnClearLog.Add_Click({ $Blob.Gui.LogPanel.Children.Clear() })
    $Blob.Gui.BtnToggleLog.Add_Click({
            $Blob.Gui.LogVisible = -not $Blob.Gui.LogVisible
            $Blob.Gui.LogScroll.Visibility = if ($Blob.Gui.LogVisible) { 'Visible' } else { 'Collapsed' }
            $Blob.Gui.BtnToggleLog.Content = if ($Blob.Gui.LogVisible) { 'Hide' } else { 'Show' }
        })

    $Blob.Gui.Pages = Get-BlobGuiPages
    foreach ($p in $Blob.Gui.Pages) {
        $btn = [Windows.Controls.Button]::new()
        $btn.Style = $w.FindResource('TabButton')
        $sp = New-BlobStack 'Horizontal'
        $label = [Windows.Controls.TextBlock]::new()
        $label.Text = $p.Label.ToUpper(); $label.VerticalAlignment = 'Center'
        $label.SetBinding([Windows.Controls.TextBlock]::ForegroundProperty, (New-Object Windows.Data.Binding 'Foreground' -Property @{ Source = $btn })) | Out-Null
        [void]$sp.Children.Add($label)
        $btn.Content = $sp
        $btn.Tag = $p.Key
        $btn.Add_Click({ param($s, $e) if (-not $Blob.Gui.Busy) { Show-BlobGuiPage $s.Tag } })
        [void]$Blob.Gui.NavPanel.Children.Add($btn)
        $Blob.Gui.Nav[$p.Key] = $btn
    }
    $Blob.Gui.PageScroll.Add_SizeChanged({ Update-BlobGuiCardColumns })
    $Blob.Gui.Selected = @{}
    $Blob.Gui.Cache = @{}
    $Blob.Gui.PreloadDone = $false
    $Blob.Gui.PreloadTimer = $null
    $Blob.Gui.CardsWarm = $false
    $Blob.Gui.CardQueue = $null
    $Blob.Gui.CardCache = @{}
    if (-not $Blob.Gui.OptFilter) { $Blob.Gui.OptFilter = 'All' }

    $w.Add_ContentRendered({
            Add-BlobGuiLog "{Cyan}BLOB OPTIMIZER $($Blob.Version) {Gray}started. Every change is previewed first and can be undone from Restore."
            if (-not $Blob.IsAdmin) { Add-BlobGuiLog '{Yellow}Running without administrator rights: machine-wide settings are read-only.' }
            if ($Blob.DryRun) { Add-BlobGuiLog '{Magenta}Dry run: nothing will be modified.' }
        })
}

function Start-BlobGui {
    Initialize-BlobGuiWindow
    Start-BlobPrefetch                      # slow system data, collected on a background thread
    Show-BlobGuiPage 'dashboard'
    $Blob.Gui.Window.Add_ContentRendered({ Start-BlobGuiPreload })
    $Blob.Gui.Window.Add_Closed({
            if ($Blob.Gui.PreloadTimer) { $Blob.Gui.PreloadTimer.Stop() }
            Stop-BlobPrefetch
        })
    $null = $Blob.Gui.Window.ShowDialog()
    Stop-BlobPrefetch
}
