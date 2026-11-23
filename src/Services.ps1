# ============================================================================
#  BLOB OPTIMIZER - Services.ps1
#  Lists services with status, startup type and explanations. Only startup
#  types are changed (with confirmation + backup); services are never deleted.
# ============================================================================

# Services that are never modified, whatever the user selects.
$Blob.ProtectedServices = @(
    'WinDefend', 'WdNisSvc', 'Sense', 'SecurityHealthService', 'wscsvc', 'mpssvc', 'BFE', 'MpsSvc',
    'RpcSs', 'RpcEptMapper', 'DcomLaunch', 'LSM', 'SamSs', 'EventLog', 'Schedule', 'Power', 'PlugPlay',
    'ProfSvc', 'Winmgmt', 'CryptSvc', 'Dhcp', 'Dnscache', 'nsi', 'NlaSvc', 'netprofm', 'AudioSrv',
    'AudioEndpointBuilder', 'BrokerInfrastructure', 'CoreMessagingRegistrar', 'gpsvc', 'SystemEventsBroker',
    'TimeBrokerSvc', 'UserManager', 'StateRepository', 'wuauserv', 'UsoSvc', 'WaaSMedicSvc', 'TrustedInstaller',
    'BITS', 'AppIDSvc', 'Appinfo', 'KeyIso', 'VaultSvc', 'EFS', 'TokenBroker', 'msiserver', 'Themes',
    'FontCache', 'ShellHWDetection', 'LanmanWorkstation', 'WlanSvc', 'Wcmsvc', 'iphlpsvc', 'DeviceInstall'
)

# Curated, explained recommendations. Rec = recommended startup type.
$Blob.ServiceGuide = @(
    @{ Name = 'DiagTrack'; Rec = 'Disabled'; Info = 'Connected User Experiences and Telemetry. Uploads diagnostic data. Not needed for Windows to work.' }
    @{ Name = 'dmwappushservice'; Rec = 'Manual'; Info = 'Device management WAP push routing. Used by MDM / work accounts; idle otherwise.' }
    @{ Name = 'MapsBroker'; Rec = 'Manual'; Info = 'Downloaded Maps Manager. Only needed by the Maps app for offline maps.' }
    @{ Name = 'RetailDemo'; Rec = 'Disabled'; Info = 'Retail Demo service for store display PCs. Never needed at home.' }
    @{ Name = 'Fax'; Rec = 'Manual'; Info = 'Fax service. Only needed if you send faxes from this PC.' }
    @{ Name = 'RemoteRegistry'; Rec = 'Disabled'; Info = 'Lets remote users edit this registry. Disabled by default; keep it that way.' }
    @{ Name = 'WerSvc'; Rec = 'Manual'; Info = 'Windows Error Reporting. Starts only when a program crashes.' }
    @{ Name = 'wisvc'; Rec = 'Manual'; Info = 'Windows Insider service. Keep Manual unless you never use Insider builds.' }
    @{ Name = 'PhoneSvc'; Rec = 'Manual'; Info = 'Telephony state for Phone Link calls. Starts on demand.' }
    @{ Name = 'lfsvc'; Rec = 'Manual'; Info = 'Geolocation service. Needed for location-aware apps; starts on demand.' }
    @{ Name = 'XblAuthManager'; Rec = 'Manual'; Info = 'Xbox Live Auth Manager. Required for Xbox app / Game Pass sign-in - keep Manual.' }
    @{ Name = 'XblGameSave'; Rec = 'Manual'; Info = 'Xbox Live cloud saves. Required by Game Pass titles - keep Manual.' }
    @{ Name = 'XboxNetApiSvc'; Rec = 'Manual'; Info = 'Xbox Live networking. Required for Xbox multiplayer - keep Manual.' }
    @{ Name = 'SysMain'; Rec = 'Automatic'; Info = 'SysMain (Superfetch) preloads frequently used apps. Keep on SSD systems; may be disabled on slow HDDs with constant disk use.' }
    @{ Name = 'WSearch'; Rec = 'AutomaticDelayed'; Info = 'Windows Search indexer. Disabling makes Start and Explorer search slow. Keep on.' }
    @{ Name = 'Spooler'; Rec = 'Automatic'; Info = 'Print Spooler. Required for printing and PDF printing. Set Manual/Disabled only if you never print.' }
    @{ Name = 'TrkWks'; Rec = 'Automatic'; Info = 'Distributed Link Tracking Client. Keeps shortcuts working when files move across NTFS volumes.' }
    @{ Name = 'DPS'; Rec = 'Automatic'; Info = 'Diagnostic Policy Service. Powers built-in troubleshooters. Keep on.' }
)

function Get-BlobServiceList {
    $all = @(Get-BlobPrefetch 'Services')
    if ($all.Count -eq 0) { try { $all = @(Get-CimInstance Win32_Service -ErrorAction Stop) } catch { $all = @() } }
    $map = @{}
    foreach ($s in $all) { $map[$s.Name] = $s }
    return $map
}

function Format-BlobServiceState {
    param([string]$State)
    switch ($State) { 'Running' { '{Green}Running' } 'Stopped' { '{DarkGray}Stopped' } default { "{Yellow}$State" } }
}

function Show-BlobServiceChange {
    param([string]$Name, [string]$DisplayName, [string]$Crumb, [string]$Info, [string]$Rec)
    if ($Name -in $Blob.ProtectedServices) {
        Show-BlobNotice -Crumb $Crumb -Kind Warning -Title "$DisplayName is a protected service" -Lines @(
            '{Gray}This service is critical to Windows security, networking or stability.',
            '{Gray}BLOB OPTIMIZER never modifies it.')
        return
    }
    if (-not $Blob.IsAdmin) { Show-BlobAdminRequired $Crumb 'Changing a service startup type is a machine-wide change.'; return }
    $cur = Get-BlobServiceStartup $Name
    if ($cur -in @('Boot', 'System', $null, 'Unknown')) {
        Show-BlobNotice -Crumb $Crumb -Kind Warning -Title 'Not supported' -Lines @("{Gray}$Name is a driver-level or per-user service and is not modified.")
        return
    }
    $opts = @('Automatic', 'AutomaticDelayed', 'Manual', 'Disabled')
    $items = @($opts | ForEach-Object {
            $r = if ($_ -eq $Rec) { '{Green}recommended' } elseif ($_ -eq $cur) { '{DarkGray}current' } else { '' }
            if ($_ -eq $Rec -and $_ -eq $cur) { $r = '{Green}recommended {DarkGray}(current)' }
            @{ Label = $_; Right = $r } })
    $intro = @("{White}$DisplayName {DarkGray}($Name)", "{Gray}Current startup type: {White}$cur")
    if ($Info) { $intro += "{Gray}$Info" }
    $res = Show-BlobMenu -Crumb "$Crumb $($Blob.Ch.Arrow) $Name" -Items $items -Intro $intro -Start ([array]::IndexOf($opts, $cur))
    if ($res.Action -ne 'Select') { return }
    $new = $opts[$res.Index]
    if ($new -eq $cur) { return }
    $danger = ($new -eq 'Disabled') -and -not ($Rec -eq 'Disabled')
    $lines = @("{Gray}Service       {White}$DisplayName ($Name)", "{Gray}Startup type  {DarkGray}$cur {White}-> {Green}$new", '',
        '{Gray}The original startup type is saved and can be restored from the Restore section.',
        '{Gray}Running services are not stopped; the change takes full effect after a restart.')
    if ($danger) { $lines += ''; $lines += '{Yellow}Disabling a service that is not recommended for disabling can break features that depend on it.' }
    if (-not (Confirm-BlobAction -Crumb $Crumb -Question 'Change this service startup type?' -Lines $lines -Danger:$danger)) { return }
    $r = Set-BlobServiceStartup -Name $Name -StartupType $new -Source 'services' -Label "$DisplayName startup type"
    Show-BlobNotice -Crumb $Crumb -Kind $(if ($r.Status -in @('Applied', 'DryRun', 'Unchanged')) { 'Success' } else { 'Error' }) -Title $r.Status -Lines @((Format-BlobResult $r), '', "{Gray}$($r.Message)")
}

function Show-BlobServiceGuide {
    $crumb = 'Services > Recommended review'
    $pos = -1
    while ($true) {
        $map = Get-BlobServiceList
        $items = @()
        foreach ($g in $Blob.ServiceGuide) {
            $s = $map[$g.Name]
            if (-not $s) { continue }
            $cur = Get-BlobServiceStartup $g.Name
            $flag = if ($cur -eq $g.Rec) { '{Green}OK  ' } else { '{Yellow}DIFF' }
            $items += @{ Label = ('{0,-44}' -f $s.DisplayName); Right = ((Format-BlobServiceState $s.State) + '  {Gray}' + ([string]$cur).PadRight(16) + ' {DarkGray}rec {White}' + $g.Rec.PadRight(16) + " $flag")
                         Detail = @($g.Info, "Service name: $($g.Name). Enter to change the startup type."); Guide = $g; Svc = $s }
        }
        $res = Show-BlobMenu -Crumb $crumb -Items $items -Start $pos -Intro @(
            '{White}Recommended review', '{Gray}Explained services with a recommended startup type. DIFF means current differs from the recommendation.')
        if ($res.Action -ne 'Select') { return }
        $pos = $res.Index
        $it = $items[$res.Index]
        Show-BlobServiceChange -Name $it.Guide.Name -DisplayName $it.Svc.DisplayName -Crumb 'Services' -Info $it.Guide.Info -Rec $it.Guide.Rec
    }
}

function Show-BlobAllServices {
    $crumb = 'Services > All services'
    $pos = -1; $filter = 'all'
    while ($true) {
        $map = Get-BlobServiceList
        $svcs = @($map.Values | Sort-Object DisplayName)
        if ($filter -eq 'running') { $svcs = @($svcs | Where-Object { $_.State -eq 'Running' }) }
        $items = @()
        foreach ($s in $svcs) {
            $lock = if ($s.Name -in $Blob.ProtectedServices) { '{DarkGray}protected' } else { '         ' }
            $desc = if ($s.Description) { ($s.Description -replace '\s+', ' ') } else { 'No description provided.' }
            $items += @{ Label = ('{0}' -f $s.DisplayName); Right = ((Format-BlobServiceState $s.State) + '  {Gray}' + ([string]$s.StartMode).PadRight(9) + " $lock")
                         Detail = @("$($s.Name): $desc"); Svc = $s }
        }
        $res = Show-BlobMenu -Crumb $crumb -Items $items -Start $pos -Keys @{ F = 'Filter' } -Intro @(
            "{White}All services {DarkGray}($($items.Count) shown, filter: $filter)", '{Gray}Read-only browsing works without admin. Protected services cannot be changed.') `
            -FooterPairs @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Move", 'PgUp/PgDn|Page', 'Enter|Change startup', 'F|Running only / all', 'Esc|Back')
        if ($res.Action -eq 'Back') { return }
        $pos = $res.Index
        if ($res.Action -eq 'Filter') { $filter = if ($filter -eq 'all') { 'running' } else { 'all' }; $pos = -1; continue }
        $s = $items[$res.Index].Svc
        $guide = $Blob.ServiceGuide | Where-Object { $_.Name -eq $s.Name } | Select-Object -First 1
        $rec = if ($guide) { $guide.Rec } else { '' }
        $info = if ($guide) { $guide.Info } else { 'No BLOB OPTIMIZER recommendation for this service. Only change it if you know what it does.' }
        Show-BlobServiceChange -Name $s.Name -DisplayName $s.DisplayName -Crumb 'Services' -Info $info -Rec $rec
    }
}

function Show-BlobServices {
    while ($true) {
        $res = Show-BlobMenu -Crumb 'Services' -Items @(
            @{ Label = 'Recommended review'; Detail = @('Curated services with explanations and recommended startup types.') },
            @{ Label = 'Browse all services'; Detail = @('Every service with status and startup type. Changes require confirmation.') },
            @{ Label = 'Open Windows Services console'; Detail = @('Launches services.msc for manual management.') }
        ) -Intro @('{White}Services', '{Gray}Only startup types are changed. Services are never deleted, and critical ones are protected.')
        if ($res.Action -ne 'Select') { return }
        switch ($res.Index) {
            0 { Show-BlobServiceGuide }
            1 { Show-BlobAllServices }
            2 { Start-Process 'services.msc' -ErrorAction SilentlyContinue }
        }
    }
}
