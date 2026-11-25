# ============================================================================
#  BLOB OPTIMIZER - Gui.ps1
#  Window interface shell: window creation, navigation, dialogs, activity log
#  and small control factories. Uses WPF, which is part of Windows - nothing
#  is installed. All work goes through the same engine as the terminal UI.
# ============================================================================

# Shared, pre-compiled handlers: per-element data lives in DataContext, so
# building many rows does not compile a new script block for each one.
$Blob.GuiShared = @{
    RiskTip     = { param($el) New-BlobTooltipPanel -Title $Blob.RiskInfo[$el.DataContext].Label -Paragraphs @($Blob.RiskInfo[$el.DataContext].Text) }
    TweakTip    = { param($el) New-BlobTweakTooltip (Get-BlobTweak $el.DataContext) }
    SwitchClick = { Switch-BlobGuiTweak $Blob.Gui.Sender.DataContext }
}

# Palette: paper, ink and one signal colour. The old colour-tag names used in
# log/preview lines map onto it: Cyan marks structure (signal), Yellow/Magenta
# warn (signal text), Red is reserved for failures.
$Blob.GuiColors = @{
    Paper = '#EFECE6'; Surface = '#F7F5F1'; Hover = '#E4E0D8'; Rule = '#D6D2CA'
    Ink = '#141414'; Ink2 = '#57544E'; Ink3 = '#8A867E'; Ghost = '#B8B3A9'
    Signal = '#FF4F00'; SignalText = '#B83A00'; SignalSoft = '#FBE4D7'; Error = '#B3261E'
    Cyan = '#B83A00'; DarkCyan = '#D6D2CA'; White = '#141414'; Gray = '#57544E'; DarkGray = '#8A867E'
    Green = '#141414'; Yellow = '#B83A00'; Red = '#B3261E'; DarkYellow = '#8A867E'; Magenta = '#B83A00'; Black = '#141414'
}
$Blob.GuiFonts = @{ Display = 'Bahnschrift, Segoe UI'; Mono = 'Cascadia Mono, Consolas'; Body = 'Segoe UI' }

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

function Get-BlobFont { param([string]$Kind) return [Windows.Media.FontFamily]::new($Blob.GuiFonts[$Kind]) }

# Turns a colour-tagged line ("{Gray}a {White}b") into a TextBlock of Runs.
function ConvertTo-BlobTextBlock {
    param([string]$Markup, [double]$Size = 13, [switch]$Mono, [string]$Default = 'White')
    $tb = [Windows.Controls.TextBlock]::new()
    $tb.FontSize = $Size
    $tb.TextWrapping = 'Wrap'
    if ($Mono) { $tb.FontFamily = Get-BlobFont 'Mono' }
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
    param([string]$Text, [double]$Size = 13, [string]$Color = 'Ink', [string]$Weight = 'Normal', [string]$Margin = '0', [switch]$Display, [switch]$Mono)
    $t = [Windows.Controls.TextBlock]::new()
    $t.Text = $Text; $t.FontSize = $Size; $t.Foreground = Get-BlobBrush $Color
    $t.FontWeight = $Weight; $t.Margin = $Margin; $t.TextWrapping = 'Wrap'
    if ($Display) { $t.FontFamily = Get-BlobFont 'Display' }
    if ($Mono) { $t.FontFamily = Get-BlobFont 'Mono' }
    return $t
}

function New-BlobButton {
    param([string]$Label, [scriptblock]$Action, [ValidateSet('Normal', 'Accent', 'Danger', 'Link')][string]$Kind = 'Normal', [string]$ToolTip, [string]$Margin)
    $b = [Windows.Controls.Button]::new()
    $b.Content = $Label
    if ($Kind -eq 'Accent') { $b.Style = $Blob.Gui.Window.FindResource('AccentButton') }
    if ($Kind -eq 'Danger') { $b.Style = $Blob.Gui.Window.FindResource('DangerButton') }
    if ($Kind -eq 'Link') { $b.Style = $Blob.Gui.Window.FindResource('ChipButton'); $b.Foreground = Get-BlobBrush 'Ink'; $b.BorderBrush = Get-BlobBrush 'Ink' }
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

# A section on paper: hairline border, no rounding, no shadow.
function New-BlobCard {
    param($Child, [string]$Margin = '0,0,0,18', [string]$Padding = '18,14', [double]$Width = [double]::NaN)
    $c = [Windows.Controls.Border]::new()
    $c.Background = Get-BlobBrush 'Surface'; $c.BorderBrush = Get-BlobBrush 'Rule'
    $c.BorderThickness = 1; $c.Padding = $Padding; $c.Margin = $Margin
    if (-not [double]::IsNaN($Width)) { $c.Width = $Width }
    $c.Child = $Child
    return $c
}

function New-BlobBadge {
    param([string]$Text, [string]$Color = 'Ink2')
    $b = [Windows.Controls.Border]::new()
    $b.Padding = '6,0,6,1'; $b.Margin = '8,0,0,0'; $b.VerticalAlignment = 'Center'
    $b.BorderBrush = Get-BlobBrush $(if ($Color -in @('Gray', 'DarkGray', 'Ink2', 'Ink3')) { 'Rule' } else { $Color })
    $b.BorderThickness = 1
    $b.Child = New-BlobText $Text 11 $Color 'Normal' -Display
    return $b
}

function New-BlobStack {
    param([string]$Orientation = 'Vertical', [string]$Margin = '0')
    $s = [Windows.Controls.StackPanel]::new()
    $s.Orientation = $Orientation; $s.Margin = $Margin
    return $s
}

# Section heading: Bahnschrift capitals over a hairline.
function New-BlobHeading {
    param([string]$Text, [string]$Margin = '0,10,0,10')
    $b = [Windows.Controls.Border]::new()
    $b.BorderBrush = Get-BlobBrush 'Ink'; $b.BorderThickness = '0,0,0,1'; $b.Margin = $Margin; $b.Padding = '0,0,0,5'
    $b.Child = New-BlobText $Text.ToUpper() 12.5 'Ink' 'SemiBold' -Display
    return $b
}

function New-BlobBar {
    param([double]$Fraction, [double]$Width = 260)
    $p = [Windows.Controls.ProgressBar]::new()
    $p.Minimum = 0; $p.Maximum = 1; $p.Value = [Math]::Min(1, [Math]::Max(0, $Fraction)); $p.Width = $Width
    $p.Foreground = if ($Fraction -ge 0.9) { Get-BlobBrush 'Signal' } else { Get-BlobBrush 'Ink' }
    return $p
}

function New-BlobCombo {
    param([string[]]$Items, [int]$Selected = 0, [double]$Width = 220)
    $c = [Windows.Controls.ComboBox]::new()
    foreach ($i in $Items) { [void]$c.Items.Add($i) }
    if ($Items.Count -gt 0) { $c.SelectedIndex = [Math]::Max(0, $Selected) }
    $c.Width = $Width; $c.Margin = '0,0,16,0'
    return $c
}

function New-BlobGrid {
    param([array]$Columns, [double]$Height = 420)
    # Columns: @( @{ Header; Path; Width } )
    $g = [Windows.Controls.DataGrid]::new()
    $g.Height = $Height
    foreach ($col in $Columns) {
        $c = [Windows.Controls.DataGridTextColumn]::new()
        $c.Header = $col.Header.ToUpper()
        $c.Binding = New-Object Windows.Data.Binding $col.Path
        if ($col.Width) { $c.Width = New-Object Windows.Controls.DataGridLength($col.Width, $(if ($col.Width -le 1) { 'Star' } else { 'Pixel' })) }
        else { $c.Width = New-Object Windows.Controls.DataGridLength(1, 'Star') }
        [void]$g.Columns.Add($c)
    }
    return $g
}

# Lines of markup rendered in a section (used for info pages).
function New-BlobInfoCard {
    param([string[]]$Lines, [switch]$Mono)
    $s = New-BlobStack
    foreach ($l in $Lines) { [void]$s.Children.Add((ConvertTo-BlobTextBlock $l -Mono:$Mono -Size 12.5)) }
    return (New-BlobCard $s)
}

# ---------------------------------------------------------------------------
#  Help marks, tooltips and the risk meter
# ---------------------------------------------------------------------------
function New-BlobTooltipPanel {
    param([string]$Title, [string[]]$Paragraphs = @(), [string[]]$Mono = @(), [string]$MonoTitle = '')
    $s = New-BlobStack
    $s.MaxWidth = 490
    [void]$s.Children.Add((New-BlobText $Title 16 'Ink' 'SemiBold' '0,0,0,8' -Display))
    foreach ($p in $Paragraphs) {
        if (-not $p) { continue }
        [void]$s.Children.Add((ConvertTo-BlobTextBlock $p -Size 12.5 -Default 'Gray'))
        $s.Children[$s.Children.Count - 1].Margin = '0,0,0,6'
    }
    if ($Mono.Count -gt 0) {
        if ($MonoTitle) { [void]$s.Children.Add((New-BlobText $MonoTitle.ToUpper() 11 'Ink3' 'Normal' '0,6,0,4' -Display)) }
        foreach ($m in $Mono) { [void]$s.Children.Add((ConvertTo-BlobTextBlock $m -Mono -Size 11.5)) }
    }
    return $s
}

function Set-BlobTooltip {
    param($Element, $Content)
    $Element.ToolTip = $Content
    [Windows.Controls.ToolTipService]::SetInitialShowDelay($Element, 150)
    [Windows.Controls.ToolTipService]::SetShowDuration($Element, 120000)
    [Windows.Controls.ToolTipService]::SetPlacement($Element, 'Bottom')
}

# A small circled "?" that shows detailed help when hovered.
function New-BlobHelpIcon {
    param($Tooltip, [scriptblock]$Builder)
    $b = [Windows.Controls.Border]::new()
    $b.Width = 18; $b.Height = 18; $b.CornerRadius = 9
    $b.BorderThickness = 1.2; $b.BorderBrush = Get-BlobBrush 'Ink3'; $b.Background = [Windows.Media.Brushes]::Transparent
    $b.Margin = '8,0,0,0'; $b.VerticalAlignment = 'Center'; $b.Cursor = [Windows.Input.Cursors]::Help
    $t = New-BlobText '?' 11.5 'Ink2' 'SemiBold' -Display
    $t.HorizontalAlignment = 'Center'; $t.VerticalAlignment = 'Center'; $t.Margin = '0,-1,0,0'
    $b.Child = $t
    $b.Add_MouseEnter({ param($s, $e) $s.BorderBrush = Get-BlobBrush 'Ink'; $s.Child.Foreground = Get-BlobBrush 'Ink' })
    $b.Add_MouseLeave({ param($s, $e) $s.BorderBrush = Get-BlobBrush 'Ink3'; $s.Child.Foreground = Get-BlobBrush 'Ink2' })
    if ($Builder) { Set-BlobLazyTooltip $b $Builder } else { Set-BlobTooltip $b $Tooltip }
    return $b
}

# Tooltip content built on first hover (keeps long lists fast).
function Set-BlobLazyTooltip {
    param($Element, [scriptblock]$Builder)
    Set-BlobTooltip $Element 'Loading...'
    $Element.Tag = $Builder
    $Element.Add_ToolTipOpening({ param($s, $e) if ($s.Tag -is [scriptblock]) { $sb = $s.Tag; $s.Tag = $null; $s.ToolTip = & $sb $s } })
}

# Risk meter: three small bars and a word. HIGH is the only one in signal orange.
$Blob.RiskMeter = @{
    Minimal  = @{ Level = 1; Word = 'LOW' }
    Standard = @{ Level = 2; Word = 'MED' }
    Advanced = @{ Level = 3; Word = 'HIGH' }
    Optional = @{ Level = 0; Word = 'PREF' }
}

function New-BlobRiskBadge {
    param([string]$Risk)
    $m = $Blob.RiskMeter[$Risk]
    $sp = New-BlobStack 'Horizontal'
    $sp.VerticalAlignment = 'Center'; $sp.Background = [Windows.Media.Brushes]::Transparent; $sp.Cursor = [Windows.Input.Cursors]::Help
    $fill = if ($Risk -eq 'Advanced') { Get-BlobBrush 'Signal' } else { Get-BlobBrush 'Ink' }
    for ($i = 1; $i -le 3; $i++) {
        $bar = [Windows.Shapes.Rectangle]::new()
        $bar.Width = 5; $bar.Height = 4 + 3 * $i; $bar.Margin = '0,0,2,0'; $bar.VerticalAlignment = 'Bottom'
        $bar.Fill = if ($i -le $m.Level) { $fill } else { Get-BlobBrush 'Rule' }
        [void]$sp.Children.Add($bar)
    }
    $word = New-BlobText $m.Word 11.5 $(if ($Risk -eq 'Advanced') { 'SignalText' } else { 'Ink2' }) 'SemiBold' '6,0,0,0' -Display
    $word.VerticalAlignment = 'Bottom'
    [void]$sp.Children.Add($word)
    $sp.DataContext = $Risk
    Set-BlobLazyTooltip $sp $Blob.GuiShared.RiskTip
    return $sp
}

function New-BlobRiskLegend {
    $wrap = [Windows.Controls.WrapPanel]::new()
    foreach ($k in @('Minimal', 'Standard', 'Advanced', 'Optional')) {
        $item = New-BlobStack 'Horizontal' '0,0,22,0'
        [void]$item.Children.Add((New-BlobRiskBadge $k))
        $short = switch ($k) { 'Minimal' { 'safe, minor' } 'Standard' { 'changes a feature' } 'Advanced' { 'test afterwards' } default { 'taste only' } }
        [void]$item.Children.Add((New-BlobText $short 12 'Ink3' 'Normal' '8,0,0,0'))
        [void]$wrap.Children.Add($item)
    }
    return $wrap
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
    $Blob.Gui.LogLast.Text = (Get-BlobPlainText $Markup).Trim()
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
    # The stripe on top carries the mood: ink normally, signal for risky or failed things.
    $stripe = if ($Danger -or $Kind -in @('Error', 'Warning')) { 'Signal' } else { 'Ink' }
    $d.FindName('DlgStripe').Background = Get-BlobBrush $stripe
    if ($Danger) { $ok.Background = Get-BlobBrush 'Signal'; $ok.BorderBrush = Get-BlobBrush 'Signal'; $ok.Foreground = Get-BlobBrush 'Ink' }
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
$Blob.GuiVolatilePages = @('dashboard', 'presets', 'optimize', 'privacy', 'services', 'startup', 'apps', 'power', 'restore')
# Preload order, and pages that wait for the background data snapshot on their first build.
$Blob.GuiPreloadOrder = @('optimize', 'privacy', 'presets', 'startup', 'power', 'restore', 'tools', 'services', 'apps', 'cleanup', 'network', 'sysinfo', 'dashboard')
$Blob.GuiHeavyPages = @('services', 'apps', 'cleanup', 'network', 'sysinfo', 'dashboard')

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
    for ($i = 0; $i -lt $Blob.Gui.Pages.Count; $i++) {
        $p = $Blob.Gui.Pages[$i]
        $btn = $Blob.Gui.Nav[$p.Key]
        if ($p.Key -eq $Key) {
            $btn.Foreground = Get-BlobBrush 'Ink'; $btn.BorderBrush = Get-BlobBrush 'Signal'; $btn.FontWeight = 'SemiBold'
            $Blob.Gui.NavNum[$p.Key].Foreground = Get-BlobBrush 'SignalText'
            $Blob.Gui.PageNumber.Text = '{0:D2}' -f ($i + 1)
        } else {
            $btn.Foreground = Get-BlobBrush 'Ink2'; $btn.BorderBrush = [Windows.Media.Brushes]::Transparent; $btn.FontWeight = 'Normal'
            $Blob.Gui.NavNum[$p.Key].Foreground = Get-BlobBrush 'Ink3'
        }
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
    if (-not ($g -is [Windows.Controls.Primitives.UniformGrid])) { return }
    $w = $Blob.Gui.PageScroll.ViewportWidth
    if (-not $w -or $w -le 0) { $w = $Blob.Gui.Window.ActualWidth - 60 }
    if (-not $w -or $w -le 0) { $w = $Blob.Gui.Window.Width - 60 }
    $g.Columns = [Math]::Max(1, [int][Math]::Floor($w / 300))
}

# The black bar at the bottom appears whenever choices are waiting to be applied.
function Update-BlobGuiPendingBar {
    $n = $Blob.Gui.Pending.Count
    if ($n -gt 0) {
        $on = @($Blob.Gui.Pending.Values | Where-Object { $_ -eq 'On' }).Count
        $off = $n - $on
        $parts = @()
        if ($on) { $parts += "$on to switch on" }
        if ($off) { $parts += "$off to switch off" }
        $Blob.Gui.PendingText.Text = "$($parts -join ', ').  Nothing has been changed yet."
        $Blob.Gui.PendingApply.Content = "Review and apply $n"
        $Blob.Gui.PendingBar.Visibility = 'Visible'
    } else { $Blob.Gui.PendingBar.Visibility = 'Collapsed' }
}

function Initialize-BlobGuiWindow {
    $w = New-BlobGuiWindow $Blob.GuiXaml
    $Blob.Gui = @{ Window = $w; Busy = $false; Current = $null; Nav = @{}; NavNum = @{}; LogVisible = $false }
    foreach ($n in @('TitleVersion', 'AdminBadge', 'AdminBadgeText', 'DryRunBadge', 'BtnMin', 'BtnMax', 'BtnClose', 'CloseGlyph', 'NavPanel',
                     'PageActions', 'PageNumber', 'PageTitle', 'PageSubtitle', 'PageScroll', 'PageHost', 'BtnToggleLog', 'BtnClearLog',
                     'LogScroll', 'LogPanel', 'LogLast', 'StatusText', 'StatusRight', 'RootBorder',
                     'PendingBar', 'PendingText', 'PendingDiscard', 'PendingApply')) {
        $Blob.Gui[$n] = $w.FindName($n)
    }
    # Fit the window to the screen (taller when there is room, so the whole sidebar shows).
    try {
        $wa = [Windows.SystemParameters]::WorkArea
        $w.Height = [Math]::Max($w.MinHeight, [Math]::Min(880, $wa.Height - 40))
        $w.Width = [Math]::Max($w.MinWidth, [Math]::Min(1320, $wa.Width - 40))
    } catch { }
    $w.Title = "BLOB OPTIMIZER $($Blob.Version)"
    $Blob.Gui.TitleVersion.Text = $Blob.Version
    if ($Blob.IsAdmin) {
        $Blob.Gui.AdminBadge.BorderBrush = Get-BlobBrush 'Ink'; $Blob.Gui.AdminBadgeText.Text = 'ADMINISTRATOR'; $Blob.Gui.AdminBadgeText.Foreground = Get-BlobBrush 'Ink'
    } else {
        $Blob.Gui.AdminBadge.BorderBrush = Get-BlobBrush 'SignalText'; $Blob.Gui.AdminBadgeText.Text = 'LIMITED  -  SYSTEM SETTINGS READ-ONLY'; $Blob.Gui.AdminBadgeText.Foreground = Get-BlobBrush 'SignalText'
    }
    if ($Blob.DryRun) { $Blob.Gui.DryRunBadge.Visibility = 'Visible' }
    $Blob.Gui.StatusRight.Text = "$($Blob.SysInfo.Host)   PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)   backups $($Blob.DataRoot)"

    $Blob.Gui.BtnMin.Add_Click({ $Blob.Gui.Window.WindowState = 'Minimized' })
    $Blob.Gui.BtnMax.Add_Click({ $win = $Blob.Gui.Window; if ($win.WindowState -eq 'Maximized') { $win.WindowState = 'Normal' } else { $win.WindowState = 'Maximized' } })
    $Blob.Gui.BtnClose.Add_Click({ $Blob.Gui.Window.Close() })
    $Blob.Gui.BtnClose.Add_MouseEnter({ $Blob.Gui.CloseGlyph.Stroke = Get-BlobBrush 'Paper' })
    $Blob.Gui.BtnClose.Add_MouseLeave({ $Blob.Gui.CloseGlyph.Stroke = Get-BlobBrush 'Ink' })
    # A chromeless maximised window overhangs the screen edge; pad it.
    $w.Add_StateChanged({
            $win = $Blob.Gui.Window
            $Blob.Gui.RootBorder.Margin = if ($win.WindowState -eq 'Maximized') { '7' } else { '0' }
        })
    $Blob.Gui.BtnClearLog.Add_Click({ $Blob.Gui.LogPanel.Children.Clear() })
    $Blob.Gui.BtnToggleLog.Add_Click({
            $Blob.Gui.LogVisible = -not $Blob.Gui.LogVisible
            $Blob.Gui.LogScroll.Visibility = if ($Blob.Gui.LogVisible) { 'Visible' } else { 'Collapsed' }
            $Blob.Gui.BtnToggleLog.Content = if ($Blob.Gui.LogVisible) { 'Hide log' } else { 'Show log' }
        })

    $Blob.Gui.Pages = [System.Collections.ArrayList]@(Get-BlobGuiPages)
    foreach ($p in $Blob.Gui.Pages) {
        $btn = [Windows.Controls.Button]::new()
        $btn.Style = $w.FindResource('NavButton')
        $sp = New-BlobStack 'Horizontal'
        $num = New-BlobText ('{0:D2}' -f ($Blob.Gui.Pages.IndexOf($p) + 1)) 13 'Ink3' 'Normal' '0,1,12,0' -Display
        $num.Width = 22; $num.VerticalAlignment = 'Center'
        $Blob.Gui.NavNum[$p.Key] = $num
        $label = [Windows.Controls.TextBlock]::new()
        $label.Text = $p.Label; $label.VerticalAlignment = 'Center'
        $label.SetBinding([Windows.Controls.TextBlock]::ForegroundProperty, (New-Object Windows.Data.Binding 'Foreground' -Property @{ Source = $btn })) | Out-Null
        [void]$sp.Children.Add($num); [void]$sp.Children.Add($label)
        $btn.Content = $sp
        $btn.Tag = $p.Key
        $btn.Add_Click({ param($s, $e) if (-not $Blob.Gui.Busy) { Show-BlobGuiPage $s.Tag } })
        [void]$Blob.Gui.NavPanel.Children.Add($btn)
        $Blob.Gui.Nav[$p.Key] = $btn
    }
    $Blob.Gui.PageScroll.Add_SizeChanged({ Update-BlobGuiCardColumns })
    $Blob.Gui.Selected = @{}
    $Blob.Gui.Pending = @{}          # tweak id -> 'On' / 'Off', applied only with Apply changes
    if (-not $Blob.Gui.OptRisk) { $Blob.Gui.OptRisk = 'All' }
    $Blob.Gui.Cache = @{}
    $Blob.Gui.PreloadDone = $false
    $Blob.Gui.PreloadTimer = $null
    $Blob.Gui.CardsWarm = $false
    $Blob.Gui.CardQueue = $null
    $Blob.Gui.CardCache = @{}
    if (-not $Blob.Gui.OptFilter) { $Blob.Gui.OptFilter = 'All' }
    Register-BlobClick $Blob.Gui.PendingApply { Invoke-BlobGuiApplyPending }
    Register-BlobClick $Blob.Gui.PendingDiscard {
        $Blob.Gui.Pending.Clear()
        if ($Blob.Gui.Current -in @('optimize', 'privacy')) { Update-BlobGuiCardGrid }
        foreach ($k in @('optimize', 'privacy')) { if ($k -ne $Blob.Gui.Current -and $Blob.Gui.Cache.ContainsKey($k)) { $Blob.Gui.Cache[$k].Stale = $true } }
        Update-BlobGuiPendingBar
    }

    $w.Add_ContentRendered({
            Add-BlobGuiLog "{White}BLOB OPTIMIZER $($Blob.Version) {Gray}started. Every change is previewed first and can be undone from Restore."
            if (-not $Blob.IsAdmin) { Add-BlobGuiLog '{Yellow}Running without administrator rights: machine-wide settings are read-only.' }
            if ($Blob.DryRun) { Add-BlobGuiLog '{Magenta}Dry run: nothing will be modified.' }
        })
}

function Start-BlobGui {
    Initialize-BlobGuiWindow
    Start-BlobPrefetch                      # slow system data, collected on a background thread
    Show-BlobGuiPage 'dashboard'
    $Blob.Gui.Window.Add_ContentRendered({ Start-BlobGuiPreload })
    $Blob.Gui.Window.Add_Closing({
            param($s, $e)
            $n = $Blob.Gui.Pending.Count
            if ($n -gt 0) {
                $close = Show-BlobGuiDialog -Title "Close with $n unapplied change(s)?" -OkText 'Close without applying' -CancelText 'Go back' -Lines @(
                    '{Gray}You flipped switches but did not press Apply changes.',
                    '{Gray}Closing now leaves those settings exactly as they are.')
                if (-not $close) { $e.Cancel = $true }
            }
        })
    $Blob.Gui.Window.Add_Closed({
            if ($Blob.Gui.PreloadTimer) { $Blob.Gui.PreloadTimer.Stop() }
            Stop-BlobPrefetch
        })
    $null = $Blob.Gui.Window.ShowDialog()
    Stop-BlobPrefetch
}
