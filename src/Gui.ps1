# ============================================================================
#  BLOB OPTIMIZER - Gui.ps1
#  Window interface shell: window creation, navigation, dialogs, activity log
#  and small control factories. Uses WPF, which is part of Windows - nothing
#  is installed. All work goes through the same engine as the terminal UI.
# ============================================================================

$Blob.GuiColors = @{
    Cyan = '#22D3EE'; DarkCyan = '#0E7490'; White = '#E6EDF3'; Gray = '#A3AFBF'; DarkGray = '#64748B'
    Green = '#4ADE80'; Yellow = '#FACC15'; Red = '#F87171'; DarkYellow = '#CA8A04'; Magenta = '#E879F9'; Black = '#03141A'
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
    $tb = New-Object Windows.Controls.TextBlock
    $tb.FontSize = $Size
    $tb.TextWrapping = 'Wrap'
    if ($Mono) { $tb.FontFamily = New-Object Windows.Media.FontFamily 'Cascadia Mono, Consolas' }
    $parts = [regex]::Split($Markup, $Blob.ColorTag)
    $color = $Default
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { $color = $parts[$i]; continue }
        if ($parts[$i].Length -eq 0) { continue }
        $run = New-Object Windows.Documents.Run $parts[$i]
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
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $Text; $t.FontSize = $Size; $t.Foreground = Get-BlobBrush $Color
    $t.FontWeight = $Weight; $t.Margin = $Margin; $t.TextWrapping = 'Wrap'
    return $t
}

function New-BlobButton {
    param([string]$Label, [scriptblock]$Action, [ValidateSet('Normal', 'Accent', 'Danger')][string]$Kind = 'Normal', [string]$ToolTip, [string]$Margin)
    $b = New-Object Windows.Controls.Button
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
    $Control.Add_Click({ param($s, $e) Invoke-BlobGuiAction $s.Tag })
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
    $c = New-Object Windows.Controls.Border
    $c.Background = Get-BlobBrush '#151D27'; $c.BorderBrush = Get-BlobBrush '#223041'
    $c.BorderThickness = 1; $c.CornerRadius = 10; $c.Padding = $Padding; $c.Margin = $Margin
    if (-not [double]::IsNaN($Width)) { $c.Width = $Width }
    $c.Child = $Child
    return $c
}

function New-BlobBadge {
    param([string]$Text, [string]$Color = 'Gray')
    $b = New-Object Windows.Controls.Border
    $b.CornerRadius = 4; $b.Padding = '7,1'; $b.Margin = '8,0,0,0'; $b.VerticalAlignment = 'Center'
    $b.BorderBrush = Get-BlobBrush $Color; $b.BorderThickness = 1
    $t = New-BlobText $Text 10.5 $Color 'SemiBold'
    $b.Child = $t
    return $b
}

function New-BlobStack {
    param([string]$Orientation = 'Vertical', [string]$Margin = '0')
    $s = New-Object Windows.Controls.StackPanel
    $s.Orientation = $Orientation; $s.Margin = $Margin
    return $s
}

function New-BlobHeading {
    param([string]$Text, [string]$Margin = '0,6,0,10')
    return (New-BlobText $Text.ToUpper() 11.5 'DarkGray' 'Bold' $Margin)
}

function New-BlobBar {
    param([double]$Fraction, [double]$Width = 260)
    $p = New-Object Windows.Controls.ProgressBar
    $p.Minimum = 0; $p.Maximum = 1; $p.Value = [Math]::Min(1, [Math]::Max(0, $Fraction)); $p.Width = $Width
    $p.Foreground = if ($Fraction -ge 0.9) { Get-BlobBrush 'Red' } elseif ($Fraction -ge 0.75) { Get-BlobBrush 'Yellow' } else { Get-BlobBrush 'Cyan' }
    return $p
}

function New-BlobCombo {
    param([string[]]$Items, [int]$Selected = 0, [double]$Width = 220)
    $c = New-Object Windows.Controls.ComboBox
    foreach ($i in $Items) { [void]$c.Items.Add($i) }
    if ($Items.Count -gt 0) { $c.SelectedIndex = [Math]::Max(0, $Selected) }
    $c.Width = $Width; $c.Margin = '0,0,8,0'
    return $c
}

function New-BlobGrid {
    param([array]$Columns, [double]$Height = 420)
    # Columns: @( @{ Header; Path; Width } )
    $g = New-Object Windows.Controls.DataGrid
    $g.Height = $Height
    foreach ($col in $Columns) {
        $c = New-Object Windows.Controls.DataGridTextColumn
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
    param($Tooltip)
    $b = New-Object Windows.Controls.Border
    $b.Width = 20; $b.Height = 20; $b.CornerRadius = 10
    $b.BorderThickness = 1.5; $b.BorderBrush = Get-BlobBrush '#475569'; $b.Background = Get-BlobBrush '#0F172A'
    $b.Margin = '8,0,0,0'; $b.VerticalAlignment = 'Center'; $b.Cursor = [Windows.Input.Cursors]::Help
    $t = New-BlobText '?' 12 'Gray' 'Bold'
    $t.HorizontalAlignment = 'Center'; $t.VerticalAlignment = 'Center'; $t.Margin = '0,-1,0,0'
    $b.Child = $t
    $b.Add_MouseEnter({ param($s, $e) $s.BorderBrush = Get-BlobBrush 'Cyan'; $s.Child.Foreground = Get-BlobBrush 'Cyan' })
    $b.Add_MouseLeave({ param($s, $e) $s.BorderBrush = Get-BlobBrush '#475569'; $s.Child.Foreground = Get-BlobBrush 'Gray' })
    Set-BlobTooltip $b $Tooltip
    return $b
}

function New-BlobRiskBadge {
    param([string]$Risk)
    $r = $Blob.RiskInfo[$Risk]
    $badge = New-BlobBadge $r.Label $r.Color
    Set-BlobTooltip $badge (New-BlobTooltipPanel -Title $r.Label -Paragraphs @($r.Text))
    return $badge
}

function New-BlobRiskLegend {
    $wrap = New-Object Windows.Controls.WrapPanel
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
    $box = New-Object Windows.Controls.TextBox
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
        '{Gray}BLOB OPTIMIZER never elevates itself silently. To use this feature:',
        '{Gray}  1. Close BLOB OPTIMIZER.',
        '{Gray}  2. Right-click Windows Terminal and choose "Run as administrator".',
        '{Gray}  3. Run the launch command again.')
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
function Set-BlobGuiPageActions {
    param([array]$Buttons = @())
    $Blob.Gui.PageActions.Children.Clear()
    foreach ($b in $Buttons) { [void]$Blob.Gui.PageActions.Children.Add($b) }
}

function Show-BlobGuiPage {
    param([string]$Key, [switch]$KeepScroll)
    $page = $Blob.Gui.Pages | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
    if (-not $page) { return }
    $Blob.Gui.Current = $Key
    foreach ($p in $Blob.Gui.Pages) {
        $btn = $Blob.Gui.Nav[$p.Key]
        if ($p.Key -eq $Key) { $btn.Foreground = Get-BlobBrush 'Cyan'; $btn.BorderBrush = Get-BlobBrush 'Cyan' }
        else { $btn.Foreground = Get-BlobBrush '#94A3B8'; $btn.BorderBrush = [Windows.Media.Brushes]::Transparent }
    }
    $Blob.Gui.PageTitle.Text = $page.Label
    $Blob.Gui.PageSubtitle.Text = $page.Subtitle
    Set-BlobGuiPageActions @()
    Set-BlobGuiStatus "Loading $($page.Label)..."
    $Blob.Gui.CardGrid = $null
    $Blob.Gui.Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        $content = & $page.Build
        $Blob.Gui.PageHost.Content = $content
        Update-BlobGuiCardColumns
        if (-not $KeepScroll) { $Blob.Gui.PageScroll.ScrollToTop() }
    } catch {
        $Blob.Gui.PageHost.Content = New-BlobInfoCard @("{Red}This page could not be loaded: $($_.Exception.Message -replace '[{}]', '')")
        Write-BlobLog "GUI page '$Key' failed: $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" 'ERROR'
    } finally { $Blob.Gui.Window.Cursor = $null; Set-BlobGuiStatus 'Ready' }
}

# Re-renders the current page after a change, keeping the scroll position.
function Update-BlobGuiPage {
    $offset = $Blob.Gui.PageScroll.VerticalOffset
    Show-BlobGuiPage $Blob.Gui.Current -KeepScroll
    $Blob.Gui.PageScroll.UpdateLayout()
    $Blob.Gui.PageScroll.ScrollToVerticalOffset($offset)
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
        $Blob.Gui.AdminBadge.Background = Get-BlobBrush '#052E1C'; $Blob.Gui.AdminBadgeText.Text = 'ADMINISTRATOR'; $Blob.Gui.AdminBadgeText.Foreground = Get-BlobBrush 'Green'
    } else {
        $Blob.Gui.AdminBadge.Background = Get-BlobBrush '#3A2E05'; $Blob.Gui.AdminBadgeText.Text = 'STANDARD USER - READ ONLY FOR SYSTEM SETTINGS'; $Blob.Gui.AdminBadgeText.Foreground = Get-BlobBrush 'Yellow'
    }
    if ($Blob.DryRun) { $Blob.Gui.DryRunBadge.Visibility = 'Visible' }
    $Blob.Gui.StatusRight.Text = "$($Blob.SysInfo.Host)  -  PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)  -  No installation, nothing left running  -  Backups: $($Blob.DataRoot)"

    $Blob.Gui.BtnMin.Add_Click({ $Blob.Gui.Window.WindowState = 'Minimized' })
    $Blob.Gui.BtnMax.Add_Click({ $win = $Blob.Gui.Window; if ($win.WindowState -eq 'Maximized') { $win.WindowState = 'Normal' } else { $win.WindowState = 'Maximized' } })
    $Blob.Gui.BtnClose.Add_Click({ $Blob.Gui.Window.Close() })
    # A chromeless maximised window overhangs the screen edge; pad it.
    $w.Add_StateChanged({
            $win = $Blob.Gui.Window
            if ($win.WindowState -eq 'Maximized') { $Blob.Gui.RootBorder.Margin = '7'; $Blob.Gui.BtnMax.Content = [string][char]0xE923 }
            else { $Blob.Gui.RootBorder.Margin = '0'; $Blob.Gui.BtnMax.Content = [string][char]0xE922 }
        })
    $Blob.Gui.BtnClearLog.Add_Click({ $Blob.Gui.LogPanel.Children.Clear() })
    $Blob.Gui.BtnToggleLog.Add_Click({
            $Blob.Gui.LogVisible = -not $Blob.Gui.LogVisible
            $Blob.Gui.LogScroll.Visibility = if ($Blob.Gui.LogVisible) { 'Visible' } else { 'Collapsed' }
            $Blob.Gui.BtnToggleLog.Content = if ($Blob.Gui.LogVisible) { 'Hide' } else { 'Show' }
        })

    $Blob.Gui.Pages = Get-BlobGuiPages
    foreach ($p in $Blob.Gui.Pages) {
        $btn = New-Object Windows.Controls.Button
        $btn.Style = $w.FindResource('TabButton')
        $sp = New-BlobStack 'Horizontal'
        $icon = New-Object Windows.Controls.TextBlock
        $icon.Text = [string][char]$p.Icon
        $icon.FontFamily = New-Object Windows.Media.FontFamily 'Segoe MDL2 Assets'
        $icon.FontSize = 13; $icon.Margin = '0,1,8,0'; $icon.VerticalAlignment = 'Center'
        $icon.SetBinding([Windows.Controls.TextBlock]::ForegroundProperty, (New-Object Windows.Data.Binding 'Foreground' -Property @{ Source = $btn })) | Out-Null
        $label = New-Object Windows.Controls.TextBlock
        $label.Text = $p.Label; $label.VerticalAlignment = 'Center'
        $label.SetBinding([Windows.Controls.TextBlock]::ForegroundProperty, (New-Object Windows.Data.Binding 'Foreground' -Property @{ Source = $btn })) | Out-Null
        [void]$sp.Children.Add($icon); [void]$sp.Children.Add($label)
        $btn.Content = $sp
        $btn.Tag = $p.Key
        $btn.Add_Click({ param($s, $e) if (-not $Blob.Gui.Busy) { Show-BlobGuiPage $s.Tag } })
        [void]$Blob.Gui.NavPanel.Children.Add($btn)
        $Blob.Gui.Nav[$p.Key] = $btn
    }
    $Blob.Gui.PageScroll.Add_SizeChanged({ Update-BlobGuiCardColumns })
    $Blob.Gui.Selected = @{}
    if (-not $Blob.Gui.OptFilter) { $Blob.Gui.OptFilter = 'All' }

    $w.Add_ContentRendered({
            Add-BlobGuiLog "{Cyan}BLOB OPTIMIZER $($Blob.Version) {Gray}started. Every change is previewed first and can be undone from Restore."
            if (-not $Blob.IsAdmin) { Add-BlobGuiLog '{Yellow}Running without administrator rights: machine-wide settings are read-only.' }
            if ($Blob.DryRun) { Add-BlobGuiLog '{Magenta}Dry run: nothing will be modified.' }
        })
}

function Start-BlobGui {
    Initialize-BlobGuiWindow
    Show-BlobGuiPage 'dashboard'
    $null = $Blob.Gui.Window.ShowDialog()
}
