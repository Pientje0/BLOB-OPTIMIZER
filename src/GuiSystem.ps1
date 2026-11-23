# ============================================================================
#  BLOB OPTIMIZER - GuiSystem.ps1
#  Window pages: Services, Startup, Cleanup, Network, Power, Restore.
# ============================================================================

# ---------------------------------------------------------------------------
#  Services
# ---------------------------------------------------------------------------
function Get-BlobGuiServiceRows {
    param([string]$Filter = 'Recommended review', [string]$Search = '')
    $guide = @{}
    foreach ($g in $Blob.ServiceGuide) { $guide[$g.Name] = $g }
    $rows = foreach ($s in (Get-BlobServiceList).Values) {
        $g = $guide[$s.Name]
        if ($Filter -eq 'Recommended review' -and -not $g) { continue }
        if ($Filter -eq 'Running only' -and $s.State -ne 'Running') { continue }
        if ($Search -and -not ($s.DisplayName -like "*$Search*" -or $s.Name -like "*$Search*")) { continue }
        $start = Get-BlobServiceStartup $s.Name
        if (-not $start) { $start = [string]$s.StartMode }
        $info = if ($g) { $g.Info } elseif ($s.Description) { ($s.Description -replace '\s+', ' ') } else { 'No description provided.' }
        [pscustomobject]@{
            DisplayName = $s.DisplayName; Name = $s.Name; Status = [string]$s.State; Startup = $start
            Recommended = $(if ($g) { $g.Rec } else { '' })
            Check = $(if ($g) { if ($start -eq $g.Rec) { 'OK' } else { 'Differs' } } else { '' })
            Note = $(if ($s.Name -in $Blob.ProtectedServices) { 'Protected' } else { '' })
            Info = $info
        }
    }
    return @($rows | Sort-Object DisplayName)
}

function Update-BlobGuiServiceGrid {
    try {
        $P = $Blob.Gui.P
        $P.Grid.ItemsSource = @(Get-BlobGuiServiceRows -Filter ([string]$P.Filter.SelectedItem) -Search $P.Search.Text.Trim())
        $P.Count.Text = "$(@($P.Grid.ItemsSource).Count) services shown"
    } catch { Add-BlobGuiLog "{Red}Could not list services: $($_.Exception.Message -replace '[{}]', '')" }
}

function New-BlobGuiServices {
    $P = @{}
    $Blob.Gui.P = $P
    $root = New-BlobStack
    $bar = New-BlobStack 'Horizontal' '0,0,0,12'
    $P.Filter = New-BlobCombo @('Recommended review', 'All services', 'Running only') 0 200
    $P.Search = New-Object Windows.Controls.TextBox
    $P.Search.Width = 260; $P.Search.Margin = '0,0,8,0'; $P.Search.ToolTip = 'Search by name'
    $P.Count = New-BlobText '' 12 'DarkGray' 'Normal' '8,8,0,0'
    [void]$bar.Children.Add($P.Filter)
    [void]$bar.Children.Add((New-BlobText 'Search' 12 'Gray' 'Normal' '8,8,8,0'))
    [void]$bar.Children.Add($P.Search)
    [void]$bar.Children.Add($P.Count)
    [void]$root.Children.Add($bar)

    $P.Grid = New-BlobGrid @(
        @{ Header = 'Service'; Path = 'DisplayName'; Width = 1 }, @{ Header = 'Name'; Path = 'Name'; Width = 150 },
        @{ Header = 'Status'; Path = 'Status'; Width = 90 }, @{ Header = 'Startup'; Path = 'Startup'; Width = 130 },
        @{ Header = 'Recommended'; Path = 'Recommended'; Width = 130 }, @{ Header = 'Check'; Path = 'Check'; Width = 80 },
        @{ Header = 'Note'; Path = 'Note'; Width = 90 }) 380
    [void]$root.Children.Add($P.Grid)
    $P.Detail = New-BlobText 'Select a service to see what it does.' 13 'Gray'
    [void]$root.Children.Add((New-BlobCard $P.Detail '0,12,0,12'))

    $act = New-BlobStack 'Horizontal'
    [void]$act.Children.Add((New-BlobText 'Set startup type to' 13 'Gray' 'Normal' '0,8,10,0'))
    $P.Type = New-BlobCombo @('Automatic', 'AutomaticDelayed', 'Manual', 'Disabled') 2 180
    [void]$act.Children.Add($P.Type)
    [void]$act.Children.Add((New-BlobButton 'Apply to selected' { Set-BlobGuiServices 'Chosen' } 'Accent'))
    [void]$act.Children.Add((New-BlobButton 'Apply recommended to selected' { Set-BlobGuiServices 'Recommended' }))
    [void]$act.Children.Add((New-BlobButton 'Open services.msc' { Start-Process 'services.msc' -ErrorAction SilentlyContinue }))
    [void]$root.Children.Add((New-BlobCard $act))
    [void]$root.Children.Add((New-BlobText 'Only the startup type changes; running services are not stopped. Changes take full effect after a restart and can be undone from Restore.' 12 'DarkGray'))

    $P.Filter.Add_SelectionChanged({ Update-BlobGuiServiceGrid })
    $P.Search.Add_TextChanged({ Update-BlobGuiServiceGrid })
    $P.Grid.Add_SelectionChanged({
            $r = $Blob.Gui.P.Grid.SelectedItem
            if ($r) {
                $t = "$($r.DisplayName) ($($r.Name)): $($r.Info)"
                if ($r.Recommended) { $t += "  Recommended: $($r.Recommended)." }
                if ($r.Note) { $t += '  This service is protected and cannot be changed.' }
                $Blob.Gui.P.Detail.Text = $t
            }
        })
    Set-BlobGuiPageActions @((New-BlobButton 'Refresh' { Update-BlobGuiServiceGrid } -Margin '0'))
    Update-BlobGuiServiceGrid
    return $root
}

function Set-BlobGuiServices {
    param([string]$Mode)
    $P = $Blob.Gui.P
    $sel = @($P.Grid.SelectedItems)
    if ($sel.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select one or more services in the list (Ctrl/Shift for several).'); return }
    if (-not $Blob.IsAdmin) { Show-BlobGuiAdminRequired 'Changing a service startup type is a machine-wide change.'; return }
    $plan = @(); $lines = @(); $notes = @()
    foreach ($r in $sel) {
        if ($r.Note -eq 'Protected') { $notes += "{Yellow}  $($r.DisplayName): protected, skipped"; continue }
        $new = if ($Mode -eq 'Recommended') { $r.Recommended } else { [string]$P.Type.SelectedItem }
        if (-not $new) { $notes += "{DarkGray}  $($r.DisplayName): no recommendation, skipped"; continue }
        if ($new -eq $r.Startup) { $notes += "{DarkGray}  $($r.DisplayName): already $new"; continue }
        if ($r.Startup -in @('Boot', 'System')) { $notes += "{Yellow}  $($r.DisplayName): driver-level, skipped"; continue }
        $plan += @{ Row = $r; New = $new }
        $lines += "{White}$($r.DisplayName) {DarkGray}($($r.Name))"
        $lines += "{Gray}    $($r.Startup) {White}-> {Green}$new"
    }
    if ($plan.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing to change' -Lines $notes; return }
    $danger = @($plan | Where-Object { $_.New -eq 'Disabled' -and $_.Row.Recommended -ne 'Disabled' }).Count -gt 0
    if ($notes) { $lines += ''; $lines += $notes }
    if ($danger) { $lines += ''; $lines += '{Yellow}Disabling a service that is not recommended for disabling can break features that depend on it.' }
    if (-not (Confirm-BlobGui -Title "Change $($plan.Count) service startup type(s)?" -Subtitle 'Original startup types are saved and can be restored.' -Lines $lines -Danger:$danger)) { return }
    Start-BlobGuiTask 'Changing service startup types'
    foreach ($x in $plan) { Add-BlobGuiLog (Format-BlobResult (Set-BlobServiceStartup -Name $x.Row.Name -StartupType $x.New -Source 'services' -Label "$($x.Row.DisplayName) startup type")) }
    Update-BlobGuiServiceGrid
}

# ---------------------------------------------------------------------------
#  Startup
# ---------------------------------------------------------------------------
function New-BlobGuiStartup {
    $P = @{}
    $Blob.Gui.P = $P
    $root = New-BlobStack
    $entries = @(Get-BlobStartupEntries | Sort-Object { $_.Scope }, { $_.Name })
    $rows = foreach ($e in $entries) {
        $src = "startup:" + $e.Approved + '|' + $e.Name
        [pscustomobject]@{ Name = $e.Name; Scope = $e.Scope; Status = $(if ($e.Enabled) { 'Enabled' } else { 'Disabled' })
                           Saved = $(if (@(Get-BlobAppliedChanges -Source $src).Count -gt 0) { 'Yes' } else { '' }); Command = $e.Command; Entry = $e }
    }
    $enabled = @($entries | Where-Object { $_.Enabled }).Count
    [void]$root.Children.Add((New-BlobText "$enabled of $($entries.Count) startup programs are enabled. Select rows (Ctrl/Shift for several) and choose an action." 13 'Gray' 'Normal' '0,0,0,12'))
    $P.Grid = New-BlobGrid @(
        @{ Header = 'Program'; Path = 'Name'; Width = 230 }, @{ Header = 'Scope'; Path = 'Scope'; Width = 150 },
        @{ Header = 'Status'; Path = 'Status'; Width = 90 }, @{ Header = 'Original saved'; Path = 'Saved'; Width = 110 },
        @{ Header = 'Command'; Path = 'Command'; Width = 1 }) 420
    $P.Grid.ItemsSource = @($rows)
    [void]$root.Children.Add($P.Grid)
    [void]$root.Children.Add((New-BlobText 'Disabling only stops a program from launching at sign-in - nothing is uninstalled or deleted. Task Manager shows the same state.' 12 'DarkGray' 'Normal' '0,12,0,0'))
    Set-BlobGuiPageActions @(
        (New-BlobButton 'Task Manager' { Start-Process 'taskmgr.exe' -ArgumentList '/7 /startup' -ErrorAction SilentlyContinue }),
        (New-BlobButton 'Restore original' { Restore-BlobGuiStartup }),
        (New-BlobButton 'Enable' { Set-BlobGuiStartup $true }),
        (New-BlobButton 'Disable' { Set-BlobGuiStartup $false } 'Accent' -Margin '0'))
    return $root
}

function Set-BlobGuiStartup {
    param([bool]$Enable)
    $sel = @($Blob.Gui.P.Grid.SelectedItems | ForEach-Object { $_.Entry })
    $verb = if ($Enable) { 'Enable' } else { 'Disable' }
    if ($sel.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select one or more programs first.'); return }
    $targets = @($sel | Where-Object { $_.Enabled -ne $Enable })
    if ($targets.Count -eq 0) { Show-BlobGuiMessage -Title "Already $($verb.ToLower())d" -Lines @('{Gray}The selected programs are already in that state.'); return }
    $blocked = @($targets | Where-Object { $_.Admin -and -not $Blob.IsAdmin })
    $targets = @($targets | Where-Object { -not ($_.Admin -and -not $Blob.IsAdmin) })
    if ($targets.Count -eq 0) { Show-BlobGuiAdminRequired 'These programs start for all users; their settings are machine-wide.'; return }
    $lines = @()
    foreach ($t in $targets) { $lines += "{White}$($t.Name)  {DarkGray}[$($t.Scope)]"; $lines += "{DarkGray}    $($t.Command)" }
    if ($blocked.Count -gt 0) { $lines += ''; $lines += "{Yellow}$($blocked.Count) all-users entr$(if ($blocked.Count -eq 1) { 'y needs' } else { 'ies need' }) administrator rights and will be skipped." }
    $lines += ''; $lines += '{Gray}Original flags are saved and can be restored at any time.'
    if (-not (Confirm-BlobGui -Title "$verb $($targets.Count) startup program(s)?" -Lines $lines -OkText $verb)) { return }
    Start-BlobGuiTask "$verb startup programs"
    foreach ($t in $targets) { Add-BlobGuiLog (Format-BlobResult (Set-BlobStartupEntry $t $Enable)) }
    Add-BlobGuiLog '{Gray}Changes take effect at the next sign-in.'
    Update-BlobGuiPage
}

function Restore-BlobGuiStartup {
    $sel = @($Blob.Gui.P.Grid.SelectedItems | ForEach-Object { $_.Entry })
    if ($sel.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select the programs to restore first.'); return }
    $recs = @($sel | ForEach-Object { Get-BlobAppliedChanges -Source ("startup:" + $_.Approved + '|' + $_.Name) })
    if ($recs.Count -eq 0) { Show-BlobGuiMessage -Title 'No saved original' -Kind Warning -Lines @('{Gray}BLOB OPTIMIZER has not changed the selected programs, so there is nothing to restore.'); return }
    if (-not (Confirm-BlobGui -Title 'Restore original startup state?' -OkText 'Restore' -Lines @($recs | ForEach-Object { "{Gray}$($_.Target)" }))) { return }
    Start-BlobGuiTask 'Restoring startup entries'
    $null = Invoke-BlobRestoreCore -Records $recs -Log { param($m) Add-BlobGuiLog $m }
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  Cleanup
# ---------------------------------------------------------------------------
function Update-BlobGuiCleanupTotal {
    $P = $Blob.Gui.P
    $total = 0
    foreach ($c in $P.Checks) { if ($c.IsChecked) { $total += $P.Sizes[$c.Tag.Id].Bytes } }
    $P.Total.Text = Format-BlobSize $total
}

function New-BlobGuiCleanup {
    $P = @{ Checks = @(); Sizes = @{} }
    $Blob.Gui.P = $P
    Set-BlobGuiStatus 'Scanning cleanup locations (read-only)...'
    foreach ($t in $Blob.CleanupTargets) { $P.Sizes[$t.Id] = Measure-BlobCleanupTarget $t }
    $root = New-BlobStack

    $head = New-BlobStack 'Horizontal'
    [void]$head.Children.Add((New-BlobText 'Selected for cleanup' 14 'Gray' 'Normal' '0,6,14,0'))
    $P.Total = New-BlobText '' 24 'Cyan' 'Bold'
    [void]$head.Children.Add($P.Total)
    [void]$root.Children.Add((New-BlobCard $head))

    [void]$root.Children.Add((New-BlobHeading 'Locations'))
    $list = New-BlobStack
    foreach ($t in $Blob.CleanupTargets) {
        $s = $P.Sizes[$t.Id]
        $grid = New-Object Windows.Controls.Grid
        $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = '*'
        $c1 = New-Object Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
        $grid.ColumnDefinitions.Add($c0); $grid.ColumnDefinitions.Add($c1); $grid.Margin = '0,6,0,6'
        $cb = New-Object Windows.Controls.CheckBox
        $content = New-BlobStack
        [void]$content.Children.Add((New-BlobText $t.Name 14 'White' 'SemiBold'))
        $age = if ($t.MinAgeHours -gt 0) { " Only files older than $($t.MinAgeHours) hours." } else { '' }
        [void]$content.Children.Add((New-BlobText ($t.Detail + $age) 12.5 $(if ($t.Warn) { 'Yellow' } else { 'Gray' }) 'Normal' '0,2,0,0'))
        [void]$content.Children.Add((New-BlobText $(if ($t.Paths) { $t.Paths -join '; ' } else { 'Recycle Bin (all drives)' }) 11.5 'DarkGray' 'Normal' '0,2,0,0'))
        $cb.Content = $content; $cb.Tag = $t
        if ($s.Note) { $cb.IsEnabled = $false } else { $cb.IsChecked = (-not $t.Warn -and $t.Special -ne 'Recycle') }
        $cb.Add_Checked({ Update-BlobGuiCleanupTotal }); $cb.Add_Unchecked({ Update-BlobGuiCleanupTotal })
        [Windows.Controls.Grid]::SetColumn($cb, 0); [void]$grid.Children.Add($cb)
        $size = if ($s.Note) { New-BlobText $s.Note 13 'Yellow' } else { New-BlobText ("{0}   {1} items" -f (Format-BlobSize $s.Bytes), $s.Count) 13 'White' 'SemiBold' }
        $size.Margin = '16,2,0,0'
        $right = New-BlobStack 'Horizontal'
        $right.VerticalAlignment = 'Top'
        [void]$right.Children.Add($size)
        $tipParas = @($t.Detail + $age,
            '{Yellow}Deleted files are removed permanently - they do not go to the Recycle Bin and cannot be restored.',
            '{Gray}Files that are currently in use are skipped automatically.',
            $(if ($t.Admin) { '{Yellow}Requires administrator rights.' } else { '{Green}Works without administrator rights.' }),
            '{DarkGray}Risk: LOW - these are temporary files and caches that Windows or apps recreate when needed.')
        $tipMono = if ($t.Paths) { @($t.Paths | ForEach-Object { "{White}$_" }) } else { @('{White}Recycle Bin on all drives') }
        [void]$right.Children.Add((New-BlobHelpIcon (New-BlobTooltipPanel -Title $t.Name -Paragraphs $tipParas -Mono $tipMono -MonoTitle 'Location')))
        [Windows.Controls.Grid]::SetColumn($right, 1); [void]$grid.Children.Add($right)
        [void]$list.Children.Add($grid)
        $P.Checks += $cb
    }
    [void]$root.Children.Add((New-BlobCard $list))

    [void]$root.Children.Add((New-BlobHeading 'Storage'))
    $st = New-BlobStack
    try {
        foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop)) {
            if (-not $d.Size) { continue }
            $row = New-BlobStack 'Horizontal' '0,4,0,4'
            [void]$row.Children.Add((New-BlobText "$($d.DeviceID)" 14 'White' 'SemiBold' '0,0,14,0'))
            $bar = New-BlobBar (1 - $d.FreeSpace / $d.Size) 320; $bar.VerticalAlignment = 'Center'
            [void]$row.Children.Add($bar)
            [void]$row.Children.Add((New-BlobText ("  {0} free of {1}" -f (Format-BlobSize $d.FreeSpace), (Format-BlobSize $d.Size)) 13 'Gray' 'Normal' '12,0,0,0'))
            [void]$st.Children.Add($row)
        }
        foreach ($pd in (Get-PhysicalDisk -ErrorAction Stop)) {
            [void]$st.Children.Add((New-BlobText ("{0}  -  {1}, {2}, health: {3}" -f $pd.FriendlyName, $pd.MediaType, (Format-BlobSize $pd.Size), $pd.HealthStatus) 12 'DarkGray' 'Normal' '0,6,0,0'))
        }
    } catch { }
    [void]$root.Children.Add((New-BlobCard $st))
    Update-BlobGuiCleanupTotal
    Set-BlobGuiPageActions @(
        (New-BlobButton 'Storage Sense' { Start-Process 'ms-settings:storagesense' -ErrorAction SilentlyContinue }),
        (New-BlobButton 'Rescan' { Update-BlobGuiPage }),
        (New-BlobButton 'Clean selected' { Invoke-BlobGuiCleanup } 'Accent' -Margin '0'))
    return $root
}

function Invoke-BlobGuiCleanup {
    $P = $Blob.Gui.P
    $sel = @($P.Checks | Where-Object { $_.IsChecked -and $_.IsEnabled } | ForEach-Object { $_.Tag })
    if ($sel.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Tick the locations to clean first.'); return }
    $lines = @($sel | ForEach-Object { ("{{White}}{0,-36} {{Green}}{1}" -f $_.Name, (Format-BlobSize $P.Sizes[$_.Id].Bytes)) })
    $lines += ''; $lines += '{Yellow}Files are permanently deleted (not moved to the Recycle Bin) and cannot be restored.'
    $lines += '{Gray}Files that are in use are skipped automatically.'
    $danger = @($sel | Where-Object { $_.Warn -or $_.Special }).Count -gt 0
    if (-not (Confirm-BlobGui -Title 'Delete these files?' -Lines $lines -OkText 'Delete files' -Danger:$danger)) { return }
    Start-BlobGuiTask 'Cleaning up'
    $sum = 0
    foreach ($t in $sel) {
        Set-BlobGuiStatus "Cleaning $($t.Name)..."
        $r = Invoke-BlobCleanupTarget $t
        $sum += $r.Freed
        Add-BlobGuiLog ("{{Green}} OK   {{White}}{0}  {{Gray}}freed {1}, {2} files, {3} in use / skipped" -f $t.Name, (Format-BlobSize $r.Freed), $r.Deleted, $r.Failed)
        Add-BlobActionRecord -Source 'cleanup' -Label "Cleanup: $($t.Name)" -Target ($t.Paths -join '; ') -Detail ("freed {0}, {1} files" -f (Format-BlobSize $r.Freed), $r.Deleted)
    }
    Add-BlobGuiLog ("{Cyan}" + $(if ($Blob.DryRun) { 'Dry run - would free ' } else { 'Total freed: ' }) + (Format-BlobSize $sum))
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  Network
# ---------------------------------------------------------------------------
function New-BlobGuiNetwork {
    $P = @{ Adapters = @(Get-BlobAdapters) }
    $Blob.Gui.P = $P
    $root = New-BlobStack
    [void]$root.Children.Add((New-BlobHeading 'Current configuration'))
    [void]$root.Children.Add((New-BlobInfoCard (Get-BlobNetworkInfo | Select-Object -Skip 2) -Mono))

    [void]$root.Children.Add((New-BlobHeading 'DNS servers'))
    $dns = New-BlobStack
    $row = New-BlobStack 'Horizontal'
    $P.Adapter = New-BlobCombo @($P.Adapters | ForEach-Object { $_.Name }) 0 220
    $P.Preset = New-BlobCombo @($Blob.DnsPresets | ForEach-Object { $_.Name }) 0 240
    $P.Custom = New-Object Windows.Controls.TextBox
    $P.Custom.Width = 230; $P.Custom.Margin = '0,0,8,0'; $P.Custom.ToolTip = 'Custom servers, e.g. 1.1.1.1, 9.9.9.9'
    [void]$row.Children.Add($P.Adapter); [void]$row.Children.Add($P.Preset); [void]$row.Children.Add($P.Custom)
    [void]$row.Children.Add((New-BlobButton 'Apply DNS' { Set-BlobGuiDns } 'Accent'))
    [void]$dns.Children.Add($row)
    [void]$dns.Children.Add((New-BlobText 'The custom box is used when "Custom..." is chosen. The current servers are saved and can be restored from Restore. Requires administrator.' 12 'DarkGray' 'Normal' '0,10,0,0'))
    [void]$root.Children.Add((New-BlobCard $dns))

    [void]$root.Children.Add((New-BlobHeading 'Tools'))
    $tools = New-BlobStack 'Horizontal'
    [void]$tools.Children.Add((New-BlobButton 'Run diagnostics' {
                $ok = Confirm-BlobGui -Title 'Run network diagnostics?' -OkText 'Run' -Lines @(
                    '{Gray}The following checks will be made:', '{White}  1. Ping your default gateway (router)',
                    '{White}  2. Ping 1.1.1.1 (Cloudflare) to test internet reachability', '{White}  3. Resolve www.microsoft.com through your DNS',
                    '', '{DarkGray}Only standard ping and DNS queries are sent.')
                if ($ok) { Start-BlobGuiTask 'Network diagnostics'; Invoke-BlobNetworkDiagnosticsCore -Log { param($m) Add-BlobGuiLog $m } } }))
    [void]$tools.Children.Add((New-BlobButton 'Flush DNS cache' {
                Invoke-BlobGuiNetCommand 'Flush DNS cache' @('{Gray}Removes cached DNS entries; they are rebuilt on demand.') { ipconfig.exe /flushdns } }))
    [void]$tools.Children.Add((New-BlobButton 'Renew IP address' {
                Invoke-BlobGuiNetCommand 'Renew IP address' @('{Gray}Runs ipconfig /release and /renew. The connection drops for a few seconds.') { ipconfig.exe /release | Out-Null; ipconfig.exe /renew } -NeedsAdmin }))
    [void]$tools.Children.Add((New-BlobButton 'Reset Winsock and TCP/IP' {
                Invoke-BlobGuiNetCommand 'Reset Winsock and TCP/IP' @('{Gray}Runs: netsh winsock reset  and  netsh int ip reset',
                    '{Gray}Static IP settings and some VPN software may need to be set up again.', '{Yellow}A restart is required afterwards.') { netsh.exe winsock reset; netsh.exe int ip reset } -NeedsAdmin -Danger } 'Danger'))
    [void]$root.Children.Add((New-BlobCard $tools))
    Set-BlobGuiPageActions @((New-BlobButton 'Refresh' { Update-BlobGuiPage } -Margin '0'))
    return $root
}

function Invoke-BlobGuiNetCommand {
    param([string]$Title, [string[]]$Explain, [scriptblock]$Action, [switch]$NeedsAdmin, [switch]$Danger)
    if ($NeedsAdmin -and -not $Blob.IsAdmin) { Show-BlobGuiAdminRequired "$Title changes system network configuration."; return }
    if (-not (Confirm-BlobGui -Title "$Title?" -OkText 'Run' -Danger:$Danger -Lines ($Explain + @('', '{Yellow}This operation cannot be undone automatically.')))) { return }
    Start-BlobGuiTask $Title
    if ($Blob.DryRun) { Add-BlobGuiLog "{Magenta}Dry run - would run: $Title" }
    else {
        try { foreach ($line in (& $Action 2>&1)) { if ("$line".Trim()) { Add-BlobGuiLog ('{Gray}  ' + ("$line".Trim() -replace '[{}]', '')) } } }
        catch { Add-BlobGuiLog "{Red}  $($_.Exception.Message -replace '[{}]', '')" }
    }
    Add-BlobActionRecord -Source 'network' -Label $Title -Target 'Network'
    Add-BlobGuiLog "{Cyan}$Title finished."
}

function Set-BlobGuiDns {
    $P = $Blob.Gui.P
    if (-not $Blob.IsAdmin) { Show-BlobGuiAdminRequired 'Changing DNS servers modifies network adapter settings for all users.'; return }
    if ($P.Adapters.Count -eq 0 -or $P.Adapter.SelectedIndex -lt 0) { Show-BlobGuiMessage -Title 'No connected adapter' -Kind Warning; return }
    $adapter = $P.Adapters[$P.Adapter.SelectedIndex]
    $preset = $Blob.DnsPresets[$P.Preset.SelectedIndex]
    $servers = $preset.Servers
    if ($null -eq $servers) {
        $servers = @($P.Custom.Text -split '[,; ]+' | Where-Object { $_ })
        if ($servers.Count -eq 0) { Show-BlobGuiMessage -Title 'Enter custom DNS servers' -Kind Warning -Lines @('{Gray}Type one or two IP addresses in the custom box, e.g. 1.1.1.1, 9.9.9.9'); return }
        foreach ($s in $servers) { $ip = $null; if (-not [Net.IPAddress]::TryParse($s, [ref]$ip)) { Show-BlobGuiMessage -Title 'Invalid address' -Kind Warning -Lines @("{Gray}'$s' is not a valid IP address."); return } }
    }
    $cur = Get-BlobDnsInfo $adapter
    $newText = if ($servers.Count -eq 0) { 'automatic (DHCP)' } else { $servers -join ', ' }
    if (-not (Confirm-BlobGui -Title 'Change DNS servers?' -Lines @(
                "{Gray}Adapter   {White}$($adapter.Name)",
                "{Gray}Current   {White}$(@($cur.Servers) -join ', ') {DarkGray}($(if ($cur.Static) { 'manual' } else { 'automatic' }))",
                "{Gray}New       {Green}$newText", '', '{Gray}The current configuration is saved and can be restored.'))) { return }
    Start-BlobGuiTask 'Changing DNS servers'
    Add-BlobGuiLog (Format-BlobResult (Set-BlobDns -Adapter $adapter -Servers $servers -Label "DNS: $($preset.Name)"))
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  Power
# ---------------------------------------------------------------------------
function New-BlobGuiPower {
    $P = @{ Timeouts = @() }
    $Blob.Gui.P = $P
    $root = New-BlobStack
    [void]$root.Children.Add((New-BlobHeading 'Power plans'))
    $plans = New-BlobStack
    foreach ($plan in @(Get-BlobPowerPlans)) {
        $row = New-Object Windows.Controls.DockPanel
        $row.Margin = '0,4,0,4'
        $btn = New-BlobButton 'Activate' ([scriptblock]::Create("Invoke-BlobGuiSetPlan '$($plan.Guid)'")) -Margin '0'
        if ($plan.Active) { $btn.IsEnabled = $false; $btn.Content = 'Active' }
        [Windows.Controls.DockPanel]::SetDock($btn, 'Right'); [void]$row.Children.Add($btn)
        $name = New-BlobStack 'Horizontal'
        [void]$name.Children.Add((New-BlobText $plan.Name 14 $(if ($plan.Active) { 'Cyan' } else { 'White' }) 'SemiBold'))
        if ($plan.Active) { [void]$name.Children.Add((New-BlobBadge 'ACTIVE' 'Green')) }
        [void]$name.Children.Add((New-BlobText "  $($plan.Guid)" 11 'DarkGray' 'Normal' '8,3,0,0'))
        $name.VerticalAlignment = 'Center'
        [void]$row.Children.Add($name)
        [void]$plans.Children.Add($row)
    }
    $add = New-BlobStack 'Horizontal' '0,12,0,0'
    $hasHigh = @(Get-BlobPowerPlans | Where-Object { $_.Guid -eq $Blob.KnownPlans.HighPerformance }).Count -gt 0
    if (-not $hasHigh) { [void]$add.Children.Add((New-BlobButton 'Add High Performance plan' { Invoke-BlobGuiAddPlan 'HighPerformance' })) }
    [void]$add.Children.Add((New-BlobButton 'Add Ultimate Performance plan' { Invoke-BlobGuiAddPlan 'UltimatePerformance' }))
    [void]$plans.Children.Add($add)
    [void]$root.Children.Add((New-BlobCard $plans))

    [void]$root.Children.Add((New-BlobHeading 'Display and sleep (active plan)'))
    $choices = @(0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 120)
    $tgrid = New-BlobStack
    foreach ($t in $Blob.PowerTimeouts) {
        $cur = Get-BlobTimeoutMinutes $t
        $row = New-BlobStack 'Horizontal' '0,4,0,4'
        $lbl = New-BlobText $t.Name 13.5 'White'; $lbl.Width = 260; $lbl.VerticalAlignment = 'Center'
        $opts = @($choices)
        if ($null -ne $cur -and $cur -notin $opts) { $opts = @($opts + $cur | Sort-Object) }
        $combo = New-BlobCombo @($opts | ForEach-Object { Format-BlobMinutes $_ }) ([array]::IndexOf($opts, $cur)) 160
        [void]$row.Children.Add($lbl); [void]$row.Children.Add($combo)
        [void]$row.Children.Add((New-BlobText "current: $(Format-BlobMinutes $cur)" 12 'DarkGray' 'Normal' '6,8,0,0'))
        [void]$tgrid.Children.Add($row)
        $P.Timeouts += @{ T = $t; Combo = $combo; Opts = $opts; Cur = $cur }
    }
    $apply = New-BlobButton 'Apply timeouts' { Set-BlobGuiTimeouts } 'Accent'
    $apply.HorizontalAlignment = 'Left'; $apply.Margin = '0,10,0,0'
    [void]$tgrid.Children.Add($apply)
    [void]$root.Children.Add((New-BlobCard $tgrid))

    [void]$root.Children.Add((New-BlobHeading 'Hibernation'))
    $hib = Get-BlobHibernateEnabled
    $hrow = New-Object Windows.Controls.DockPanel
    $hbtn = New-BlobButton $(if ($hib) { 'Turn off' } else { 'Turn on' }) { Invoke-BlobGuiHibernate } -Margin '0'
    [Windows.Controls.DockPanel]::SetDock($hbtn, 'Right'); [void]$hrow.Children.Add($hbtn)
    $hs = New-BlobStack
    [void]$hs.Children.Add((New-BlobText "Hibernation is $(if ($hib) { 'on' } else { 'off' })" 14 'White' 'SemiBold'))
    [void]$hs.Children.Add((New-BlobText 'Turning it off frees disk space (hiberfil.sys) but also disables Fast Startup and the Hibernate option. Requires administrator.' 12.5 'Gray' 'Normal' '0,2,12,0'))
    [void]$hrow.Children.Add($hs)
    [void]$root.Children.Add((New-BlobCard $hrow))
    Set-BlobGuiPageActions @((New-BlobButton 'Refresh' { Update-BlobGuiPage } -Margin '0'))
    return $root
}

function Invoke-BlobGuiSetPlan {
    param([string]$Guid)
    $plan = @(Get-BlobPowerPlans) | Where-Object { $_.Guid -eq $Guid } | Select-Object -First 1
    if (-not $plan) { return }
    if (-not (Confirm-BlobGui -Title "Activate '$($plan.Name)'?" -OkText 'Activate' -Lines @("{Gray}$((Get-BlobActivePowerPlan).Name) {White}-> {Green}$($plan.Name)", '', '{Gray}The previous plan is saved and can be re-activated from Restore.'))) { return }
    Start-BlobGuiTask 'Changing power plan'
    Add-BlobGuiLog (Format-BlobResult (Set-BlobPowerPlan $plan.Guid $plan.Name))
    Update-BlobGuiPage
}

function Invoke-BlobGuiAddPlan {
    param([string]$Which)
    $name = if ($Which -eq 'HighPerformance') { 'High Performance' } else { 'Ultimate Performance' }
    if (-not (Confirm-BlobGui -Title "Create and activate the $name plan?" -OkText 'Create plan' -Lines @(
                "{Gray}A new power plan is created from the built-in $name template and activated.",
                '{Gray}Higher performance plans use more power and produce more heat. No FPS gain is guaranteed.',
                '{Gray}Undo from Restore: re-activate the previous plan, then remove the created plan.'))) { return }
    Start-BlobGuiTask "Creating $name plan"
    $add = Add-BlobPowerPlan $Blob.KnownPlans[$Which] $name
    Add-BlobGuiLog (Format-BlobResult $add.Result)
    if ($add.Guid) { Add-BlobGuiLog (Format-BlobResult (Set-BlobPowerPlan $add.Guid $name)) }
    Update-BlobGuiPage
}

function Set-BlobGuiTimeouts {
    $changes = @()
    foreach ($x in $Blob.Gui.P.Timeouts) {
        if ($x.Combo.SelectedIndex -lt 0) { continue }
        $new = $x.Opts[$x.Combo.SelectedIndex]
        if ($new -ne $x.Cur) { $changes += @{ T = $x.T; New = $new; Cur = $x.Cur } }
    }
    if ($changes.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing changed' -Lines @('{Gray}Pick new values in the lists first.'); return }
    $lines = @($changes | ForEach-Object { "{White}$($_.T.Name)   {Gray}$(Format-BlobMinutes $_.Cur) {White}-> {Green}$(Format-BlobMinutes $_.New)" })
    if (-not (Confirm-BlobGui -Title 'Change power timeouts?' -Lines ($lines + @('', '{Gray}Previous values are saved and can be restored.')))) { return }
    Start-BlobGuiTask 'Changing power timeouts'
    foreach ($c in $changes) { Add-BlobGuiLog (Format-BlobResult (Set-BlobPowerTimeout $c.T $c.New)) }
    Update-BlobGuiPage
}

function Invoke-BlobGuiHibernate {
    if (-not $Blob.IsAdmin) { Show-BlobGuiAdminRequired 'Hibernation is a machine-wide setting.'; return }
    $target = -not (Get-BlobHibernateEnabled)
    $word = if ($target) { 'on' } else { 'off' }
    if (-not (Confirm-BlobGui -Title "Turn hibernation $word?" -OkText "Turn $word" -Lines @(
                '{Gray}Turning hibernation off deletes hiberfil.sys and disables Fast Startup and the Hibernate option.',
                '{Gray}It can be turned back on here or from Restore.'))) { return }
    Start-BlobGuiTask "Turning hibernation $word"
    Add-BlobGuiLog (Format-BlobResult (Set-BlobHibernate $target))
    Update-BlobGuiPage
}

# ---------------------------------------------------------------------------
#  Restore
# ---------------------------------------------------------------------------
function New-BlobGuiRestore {
    $P = @{}
    $Blob.Gui.P = $P
    $root = New-BlobStack
    $recs = @($Blob.Changes.ToArray()); [array]::Reverse($recs)
    $rows = foreach ($r in $recs) {
        [pscustomobject]@{ Time = $r.Time; Change = $r.Label; Target = $r.Target; Status = $r.Status
                           Undo = $(if ($r.Reversible) { 'Restorable' } else { 'One-way' }); Rec = $r }
    }
    $restorable = @(Get-BlobAppliedChanges).Count
    [void]$root.Children.Add((New-BlobText "$($recs.Count) recorded changes, $restorable can be restored. Select rows (Ctrl/Shift for several) and choose Restore selected." 13 'Gray' 'Normal' '0,0,0,12'))
    $P.Grid = New-BlobGrid @(
        @{ Header = 'Time'; Path = 'Time'; Width = 150 }, @{ Header = 'Change'; Path = 'Change'; Width = 1 },
        @{ Header = 'Target'; Path = 'Target'; Width = 1 }, @{ Header = 'Status'; Path = 'Status'; Width = 90 },
        @{ Header = 'Undo'; Path = 'Undo'; Width = 95 }) 330
    $P.Grid.ItemsSource = @($rows)
    $P.Grid.Add_MouseDoubleClick({ Show-BlobGuiChangeDetail })
    [void]$root.Children.Add($P.Grid)

    [void]$root.Children.Add((New-BlobHeading 'Undo a whole session' '0,16,0,10'))
    $sess = New-BlobStack 'Horizontal'
    $P.Sessions = @($Blob.Changes | Group-Object SessionId | Sort-Object Name -Descending)
    $labels = @($P.Sessions | ForEach-Object { "Session $($_.Name)  ($(@($_.Group | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible }).Count) restorable)" })
    $P.SessionCombo = New-BlobCombo $labels 0 340
    [void]$sess.Children.Add($P.SessionCombo)
    [void]$sess.Children.Add((New-BlobButton 'Undo session' { Undo-BlobGuiSession }))
    [void]$root.Children.Add((New-BlobCard $sess))

    [void]$root.Children.Add((New-BlobHeading 'Backups and configuration'))
    $b = New-BlobStack
    $row1 = New-BlobStack 'Horizontal'
    [void]$row1.Children.Add((New-BlobButton 'Create System Restore point' { Invoke-BlobGuiRestorePoint }))
    [void]$row1.Children.Add((New-BlobButton 'Export configuration' { Export-BlobGuiConfig }))
    [void]$row1.Children.Add((New-BlobButton 'Import configuration' { Import-BlobGuiConfig }))
    [void]$row1.Children.Add((New-BlobButton 'Open backup folder' {
                if (Test-Path -LiteralPath $Blob.DataRoot) { Start-Process explorer.exe -ArgumentList "`"$($Blob.DataRoot)`"" }
                else { Show-BlobGuiMessage -Title 'No files yet' -Lines @('{Gray}The folder is created when the first change is made.', "{DarkGray}$($Blob.DataRoot)") } }))
    [void]$b.Children.Add($row1)
    $row2 = New-BlobStack 'Horizontal' '0,12,0,0'
    $P.Snaps = @()
    if (Test-Path -LiteralPath $Blob.RegBackupDir) { $P.Snaps = @(Get-ChildItem -LiteralPath $Blob.RegBackupDir -Directory | Sort-Object Name -Descending) }
    [void]$row2.Children.Add((New-BlobText 'Registry snapshot' 13 'Gray' 'Normal' '0,8,10,0'))
    $P.SnapCombo = New-BlobCombo @($P.Snaps | ForEach-Object { $_.Name }) 0 300
    [void]$row2.Children.Add($P.SnapCombo)
    [void]$row2.Children.Add((New-BlobButton 'Import snapshot' { Import-BlobGuiSnapshot } 'Danger'))
    [void]$b.Children.Add($row2)
    [void]$b.Children.Add((New-BlobText 'Prefer the history above for precise per-setting restore. Snapshot import re-applies whole registry keys as they were.' 12 'DarkGray' 'Normal' '0,10,0,0'))
    [void]$root.Children.Add((New-BlobCard $b))

    Set-BlobGuiPageActions @(
        (New-BlobButton 'Details' { Show-BlobGuiChangeDetail }),
        (New-BlobButton 'Restore selected' { Restore-BlobGuiSelected } 'Accent' -Margin '0'))
    return $root
}

function Show-BlobGuiChangeDetail {
    $r = $Blob.Gui.P.Grid.SelectedItem
    if (-not $r) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select a change in the list first.'); return }
    Show-BlobGuiMessage -Title 'Change details' -Lines (Get-BlobChangeDetail $r.Rec)
}

function Restore-BlobGuiSelected {
    $sel = @($Blob.Gui.P.Grid.SelectedItems | ForEach-Object { $_.Rec })
    if ($sel.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing selected' -Lines @('{Gray}Select one or more changes first.'); return }
    $ok = @($sel | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible })
    if ($ok.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing restorable selected' -Kind Warning -Lines @('{Gray}The selected records are already restored, failed, or one-way operations.'); return }
    $lines = @($ok | ForEach-Object { "{Gray}$($_.Target)" })
    if ($sel.Count -gt $ok.Count) { $lines += ''; $lines += "{Yellow}$($sel.Count - $ok.Count) selected record(s) cannot be restored and will be skipped." }
    if (-not (Confirm-BlobGui -Title "Restore $($ok.Count) original value(s)?" -Lines $lines -OkText 'Restore')) { return }
    Start-BlobGuiTask 'Restoring changes'
    $a, $b = Invoke-BlobRestoreCore -Records $ok -Log { param($m) Add-BlobGuiLog $m }
    Add-BlobGuiLog ("{Cyan}Restore finished: {0} restored, {1} not restored." -f $a, $b)
    Update-BlobGuiPage
}

function Undo-BlobGuiSession {
    $P = $Blob.Gui.P
    if ($P.Sessions.Count -eq 0 -or $P.SessionCombo.SelectedIndex -lt 0) { Show-BlobGuiMessage -Title 'No sessions recorded yet'; return }
    $g = $P.Sessions[$P.SessionCombo.SelectedIndex]
    $recs = @($g.Group | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible })
    if ($recs.Count -eq 0) { Show-BlobGuiMessage -Title 'Nothing left to restore in this session'; return }
    if (-not (Confirm-BlobGui -Title "Restore all $($recs.Count) changes from session $($g.Name)?" -OkText 'Restore session' -Lines @($recs | ForEach-Object { "{Gray}$($_.Target)" }))) { return }
    Start-BlobGuiTask "Undoing session $($g.Name)"
    $a, $b = Invoke-BlobRestoreCore -Records $recs -Log { param($m) Add-BlobGuiLog $m }
    Add-BlobGuiLog ("{Cyan}Session restore finished: {0} restored, {1} not restored." -f $a, $b)
    Update-BlobGuiPage
}

function Import-BlobGuiSnapshot {
    $P = $Blob.Gui.P
    if ($P.Snaps.Count -eq 0 -or $P.SnapCombo.SelectedIndex -lt 0) { Show-BlobGuiMessage -Title 'No registry snapshots yet' -Lines @('{Gray}A snapshot is exported automatically before each batch of tweaks.'); return }
    $dir = $P.Snaps[$P.SnapCombo.SelectedIndex]
    $files = @(Get-ChildItem -LiteralPath $dir.FullName -Filter *.reg | Sort-Object Name)
    $lines = @($files | ForEach-Object { $k = Get-Content -LiteralPath $_.FullName -TotalCount 5 | Where-Object { $_ -match '^\[' } | Select-Object -First 1; "{Gray}$($_.Name)  {White}$k" })
    $lines += ''; $lines += '{Yellow}Importing writes every value from these files back into the registry.'
    $lines += '{Gray}Values created after the snapshot are not removed. Machine-wide keys need administrator rights.'
    if (-not (Confirm-BlobGui -Title 'Import this registry snapshot?' -Subtitle $dir.FullName -Lines $lines -OkText 'Import' -Danger)) { return }
    Start-BlobGuiTask 'Importing registry snapshot'
    foreach ($f in $files) {
        if ($Blob.DryRun) { Add-BlobGuiLog "{Magenta} DRY  {White}$($f.Name)"; continue }
        $out = & reg.exe import $f.FullName 2>&1
        if ($LASTEXITCODE -eq 0) { Add-BlobGuiLog "{Green} OK   {White}$($f.Name)" } else { Add-BlobGuiLog "{Red} FAIL {White}$($f.Name) {Gray}$(("$out" -replace '[{}]', '').Trim())" }
    }
    Add-BlobActionRecord -Source 'restore' -Label 'Imported registry snapshot' -Target $dir.FullName
    Add-BlobGuiLog '{Cyan}Snapshot import finished. Sign out or restart for all settings to apply.'
}

function Export-BlobGuiConfig {
    $applied = @($Blob.Tweaks | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' } | ForEach-Object { $_.Id })
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'BLOB OPTIMIZER configuration (*.json)|*.json'
    $dlg.FileName = "BLOB-config-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmm')
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if ($dlg.ShowDialog($Blob.Gui.Window) -ne $true) { return }
    $obj = [ordered]@{ tool = 'BLOB OPTIMIZER'; format = 1; version = $Blob.Version; exported = (Get-Date).ToString('s'); tweaks = $applied }
    [IO.File]::WriteAllText($dlg.FileName, (ConvertTo-Json -InputObject $obj -Depth 4), (New-Object Text.UTF8Encoding($false)))
    Add-BlobGuiLog "{Green}Configuration exported: {White}$($dlg.FileName) {Gray}($($applied.Count) tweaks, no personal data)"
}

function Import-BlobGuiConfig {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = 'BLOB OPTIMIZER configuration (*.json)|*.json'
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if ($dlg.ShowDialog($Blob.Gui.Window) -ne $true) { return }
    try {
        $cfg = Get-Content -LiteralPath $dlg.FileName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($cfg.tool -ne 'BLOB OPTIMIZER' -or -not $cfg.tweaks) { throw 'This is not a BLOB OPTIMIZER configuration file.' }
    } catch { Show-BlobGuiMessage -Title 'Cannot read configuration' -Kind Error -Lines @("{Gray}$($_.Exception.Message -replace '[{}]', '')"); return }
    $ids = @($cfg.tweaks | ForEach-Object { [string]$_ })
    $known = @($ids | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
    $unknown = @($ids | Where-Object { -not (Get-BlobTweak $_) })
    $extra = @()
    if ($unknown.Count -gt 0) { $extra = @("{Yellow}$($unknown.Count) unknown setting(s) will be ignored: $($unknown -join ', ')", '') }
    $null = Invoke-BlobGuiApply -Tweaks $known -Tag 'import' -ExtraLines $extra
}
