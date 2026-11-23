# ============================================================================
#  BLOB OPTIMIZER - Network.ps1
#  Network information, diagnostics, DNS configuration and optional resets.
#  Network connections are only made when the user starts a diagnostic.
# ============================================================================

$Blob.DnsPresets = @(
    @{ Name = 'Automatic (DHCP / router)'; Servers = @() }
    @{ Name = 'Cloudflare'; Servers = @('1.1.1.1', '1.0.0.1') }
    @{ Name = 'Google Public DNS'; Servers = @('8.8.8.8', '8.8.4.4') }
    @{ Name = 'Quad9 (malware blocking)'; Servers = @('9.9.9.9', '149.112.112.112') }
    @{ Name = 'Custom...'; Servers = $null }
)

function Get-BlobAdapters {
    try { return @(Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' } | Sort-Object InterfaceMetric, Name) } catch { return @() }
}

function Get-BlobDnsInfo {
    param($Adapter)
    $servers = @()
    try { $servers = @((Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses) } catch { }
    $guid = $Adapter.InterfaceGuid
    $ns = Get-BlobRegState "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" 'NameServer'
    $static = $ns.Exists -and -not [string]::IsNullOrWhiteSpace([string]$ns.Value)
    return @{ Servers = $servers; Static = $static }
}

function Get-BlobNetworkInfo {
    $lines = @('{Cyan}Network configuration', '')
    $adapters = Get-BlobAdapters
    if ($adapters.Count -eq 0) { $lines += '{Yellow}No connected network adapters found.' }
    foreach ($a in $adapters) {
        $lines += "{White}$($a.Name)  {DarkGray}$($a.InterfaceDescription)"
        $lines += "{Gray}   Status       {Green}$($a.Status)  {Gray}Speed {White}$($a.LinkSpeed)  {Gray}MAC {White}$($a.MacAddress)"
        try {
            $cfg = Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction Stop
            $ipv4 = @($cfg.IPv4Address | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ', '
            $ipv6 = @($cfg.IPv6Address | ForEach-Object { $_.IPAddress }) -join ', '
            $gw = @($cfg.IPv4DefaultGateway | ForEach-Object { $_.NextHop }) -join ', '
            $lines += "{Gray}   IPv4         {White}$ipv4"
            if ($ipv6) { $lines += "{Gray}   IPv6         {White}$ipv6" }
            $lines += "{Gray}   Gateway      {White}$(if ($gw) { $gw } else { '-' })"
            $prof = Get-NetConnectionProfile -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue
            if ($prof) { $lines += "{Gray}   Network      {White}$($prof.Name)  {DarkGray}($($prof.NetworkCategory))" }
        } catch { }
        $dns = Get-BlobDnsInfo $a
        $mode = if ($dns.Static) { '{Yellow}manual' } else { '{Green}automatic' }
        $lines += "{Gray}   DNS          {White}$(@($dns.Servers) -join ', ')  $mode"
        $lines += ''
    }
    return $lines
}

function Invoke-BlobNetworkDiagnostics {
    $crumb = 'Network > Diagnostics'
    $ok = Confirm-BlobAction -Crumb $crumb -Question 'Run network diagnostics?' -Lines @(
        '{Gray}The following network checks will be made:',
        '{White}  1. Ping your default gateway (router)',
        '{White}  2. Ping 1.1.1.1 (Cloudflare) to test internet reachability',
        '{White}  3. Resolve www.microsoft.com through your configured DNS',
        '', '{DarkGray}No data other than standard ping / DNS queries is sent.')
    if (-not $ok) { return }
    Start-BlobWork $crumb
    $gw = $null
    try { $gw = (Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4DefaultGateway.NextHop } catch { }
    $tests = @()
    if ($gw) { $tests += @{ Name = "Gateway $gw"; Host = $gw } } else { Write-BlobWork '{Yellow}No default gateway found - you may be offline.' }
    $tests += @{ Name = 'Internet 1.1.1.1'; Host = '1.1.1.1' }
    foreach ($t in $tests) {
        $p = New-Object System.Net.NetworkInformation.Ping
        $times = @(); $lost = 0
        for ($i = 0; $i -lt 4; $i++) {
            try { $r = $p.Send($t.Host, 1500); if ($r.Status -eq 'Success') { $times += $r.RoundtripTime } else { $lost++ } } catch { $lost++ }
        }
        $p.Dispose()
        if ($times.Count -gt 0) {
            $avg = ($times | Measure-Object -Average).Average
            Write-BlobWork ("{{Green}} OK   {{White}}{0,-24} {{Gray}}avg {1:N0} ms  min {2} / max {3}  loss {4}/4" -f $t.Name, $avg, ($times | Measure-Object -Minimum).Minimum, ($times | Measure-Object -Maximum).Maximum, $lost)
        } else { Write-BlobWork ("{{Red}} FAIL {{White}}{0,-24} {{Gray}}no replies (4/4 lost)" -f $t.Name) }
    }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        $addr = [System.Net.Dns]::GetHostAddresses('www.microsoft.com') | Select-Object -First 1
        Write-BlobWork ("{{Green}} OK   {{White}}{0,-24} {{Gray}}{1} in {2} ms" -f 'DNS www.microsoft.com', $addr, $sw.ElapsedMilliseconds)
    } catch { Write-BlobWork ("{{Red}} FAIL {{White}}{0,-24} {{Gray}}{1}" -f 'DNS www.microsoft.com', $_.Exception.Message) }
    Complete-BlobWork 'Diagnostics finished.'
}

function Set-BlobDns {
    param($Adapter, [string[]]$Servers, [string]$Label)
    $target = "DNS servers on '$($Adapter.Name)'"
    $cur = Get-BlobDnsInfo $Adapter
    $newText = if ($Servers.Count -eq 0) { 'automatic (DHCP)' } else { $Servers -join ', ' }
    $oldText = if ($cur.Static) { @($cur.Servers) -join ', ' } else { 'automatic (DHCP)' }
    if ($Blob.DryRun) { return New-BlobResult $target 'DryRun' 'Dry run - nothing changed.' $oldText $newText }
    $rec = New-BlobChangeRecord -Kind 'Dns' -Source 'network.dns' -Label $Label -Target $target -Data @{
        InterfaceIndex = $Adapter.ifIndex; InterfaceGuid = [string]$Adapter.InterfaceGuid; Alias = $Adapter.Name
        OldStatic = $cur.Static; OldServers = @($cur.Servers); NewServers = @($Servers) }
    try {
        if ($Servers.Count -eq 0) { Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses -ErrorAction Stop }
        else { Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $Servers -ErrorAction Stop }
        $after = Get-BlobDnsInfo $Adapter
        $ok = if ($Servers.Count -eq 0) { -not $after.Static } else { (@($after.Servers) -join ',') -eq ($Servers -join ',') }
        if ($ok) { $rec.Status = 'Applied' } else { $rec.Status = 'Failed'; $rec.Error = 'Verification failed.' }
    } catch { $rec.Status = 'Failed'; $rec.Error = $_.Exception.Message }
    Add-BlobChange $rec
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    return New-BlobResult $target $rec.Status $(if ($rec.Error) { $rec.Error } else { 'Applied and verified.' }) $oldText $newText
}

function Restore-BlobDnsChange {
    param($Record)
    if (-not $Blob.IsAdmin) { throw 'Administrator rights required.' }
    $d = $Record.Data
    if ($d.OldStatic -and @($d.OldServers).Count -gt 0) { Set-DnsClientServerAddress -InterfaceIndex $d.InterfaceIndex -ServerAddresses @($d.OldServers) -ErrorAction Stop }
    else { Set-DnsClientServerAddress -InterfaceIndex $d.InterfaceIndex -ResetServerAddresses -ErrorAction Stop }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
}

function Show-BlobDnsConfig {
    $crumb = 'Network > DNS'
    if (-not $Blob.IsAdmin) { Show-BlobAdminRequired $crumb 'Changing DNS servers modifies network adapter settings for all users.'; return }
    $adapters = Get-BlobAdapters
    if ($adapters.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Kind Warning -Title 'No connected adapters'; return }
    $aItems = @($adapters | ForEach-Object {
            $d = Get-BlobDnsInfo $_
            @{ Label = $_.Name; Right = "{Gray}$(@($d.Servers) -join ', ')  $(if ($d.Static) { '{Yellow}manual' } else { '{Green}auto' })"; Detail = @($_.InterfaceDescription) } })
    $r = Show-BlobMenu -Crumb $crumb -Items $aItems -Intro @('{White}Choose the adapter to configure')
    if ($r.Action -ne 'Select') { return }
    $adapter = $adapters[$r.Index]
    $cur = Get-BlobDnsInfo $adapter
    $pItems = @($Blob.DnsPresets | ForEach-Object { @{ Label = $_.Name; Right = "{DarkGray}$(@($_.Servers) -join ', ')" } })
    $r = Show-BlobMenu -Crumb $crumb -Items $pItems -Intro @("{White}DNS for $($adapter.Name)",
        "{Gray}Current: {White}$(@($cur.Servers) -join ', ') {DarkGray}($(if ($cur.Static) { 'manual' } else { 'automatic' }))")
    if ($r.Action -ne 'Select') { return }
    $preset = $Blob.DnsPresets[$r.Index]
    $servers = $preset.Servers
    if ($null -eq $servers) {
        $ipCheck = { param($v) foreach ($s in ($v -split '[,; ]+' | Where-Object { $_ })) { $ip = $null; if (-not [System.Net.IPAddress]::TryParse($s, [ref]$ip)) { return "'$s' is not a valid IP address." } }; if (-not $v) { return 'Enter at least one address.' }; return $null }
        $v = Read-BlobInput -Crumb $crumb -Prompt @('{White}Custom DNS servers', '{Gray}Enter one or two IP addresses separated by a comma, e.g. 1.1.1.1, 9.9.9.9') -Validate $ipCheck
        if (-not $v) { return }
        $servers = @($v -split '[,; ]+' | Where-Object { $_ })
    }
    $newText = if ($servers.Count -eq 0) { 'automatic (DHCP)' } else { $servers -join ', ' }
    if (-not (Confirm-BlobAction -Crumb $crumb -Question 'Change DNS servers?' -Lines @(
                "{Gray}Adapter   {White}$($adapter.Name)",
                "{Gray}Current   {White}$(@($cur.Servers) -join ', ') {DarkGray}($(if ($cur.Static) { 'manual' } else { 'automatic' }))",
                "{Gray}New       {Green}$newText", '',
                '{Gray}The current configuration is saved and can be restored from the Restore section.'))) { return }
    $res = Set-BlobDns -Adapter $adapter -Servers $servers -Label "DNS: $($preset.Name)"
    Show-BlobNotice -Crumb $crumb -Kind $(if ($res.Status -in @('Applied', 'DryRun')) { 'Success' } else { 'Error' }) -Title $res.Status -Lines @((Format-BlobResult $res))
}

function Invoke-BlobNetCommand {
    param([string]$Crumb, [string]$Title, [string[]]$Explain, [scriptblock]$Action, [switch]$Danger, [switch]$NeedsAdmin)
    if ($NeedsAdmin -and -not $Blob.IsAdmin) { Show-BlobAdminRequired $Crumb "$Title changes system network configuration."; return }
    if (-not (Confirm-BlobAction -Crumb $Crumb -Question "$Title?" -Lines ($Explain + @('', '{Yellow}This operation cannot be undone automatically.')) -Danger:$Danger)) { return }
    Start-BlobWork $Crumb
    if ($Blob.DryRun) { Write-BlobWork "{Magenta}Dry run - would run: $Title" }
    else {
        try { foreach ($line in (& $Action 2>&1)) { if ("$line".Trim()) { Write-BlobWork ("{Gray}  " + ("$line" -replace '[{}]', '')) } } }
        catch { Write-BlobWork "{Red}  $($_.Exception.Message)" }
    }
    Add-BlobActionRecord -Source 'network' -Label $Title -Target 'Network'
    Complete-BlobWork "$Title finished."
}

function Show-BlobNetwork {
    $crumb = 'Network'
    while ($true) {
        $res = Show-BlobMenu -Crumb $crumb -Intro @('{White}Network', '{Gray}Current configuration is always shown before any change.') -Items @(
            @{ Header = $true; Label = 'Information' }
            @{ Label = 'Network information'; Detail = @('Adapters, IP addresses, gateway, DNS servers and link speed.') }
            @{ Label = 'Run diagnostics'; Detail = @('Ping the gateway and 1.1.1.1, and test DNS resolution. Asks first.') }
            @{ Header = $true; Label = 'Configuration' }
            @{ Label = 'Configure DNS servers'; Right = '{Yellow}admin'; Detail = @('Automatic, Cloudflare, Google, Quad9 or custom. Restorable.') }
            @{ Label = 'Flush DNS cache'; Detail = @('Clears cached DNS lookups. Harmless; fixes stale name resolution.') }
            @{ Header = $true; Label = 'Optional resets' }
            @{ Label = 'Renew IP address'; Right = '{Yellow}admin'; Detail = @('Releases and renews DHCP leases. Connection drops for a few seconds.') }
            @{ Label = 'Reset Winsock and TCP/IP stack'; Right = '{Red}restart'; Detail = @('Last-resort fix for broken networking. Requires a restart; custom adapter settings may be lost.') }
        )
        if ($res.Action -ne 'Select') { return }
        switch ($res.Index) {
            1 { $null = Show-BlobText -Crumb "$crumb > Information" -Lines (Get-BlobNetworkInfo) }
            2 { Invoke-BlobNetworkDiagnostics }
            4 { Show-BlobDnsConfig }
            5 { Invoke-BlobNetCommand -Crumb $crumb -Title 'Flush DNS cache' -Explain @('{Gray}Removes cached DNS entries; they are rebuilt on demand.') -Action { ipconfig.exe /flushdns } }
            7 { Invoke-BlobNetCommand -Crumb $crumb -Title 'Renew IP address' -NeedsAdmin -Explain @('{Gray}Runs ipconfig /release and ipconfig /renew. Downloads in progress may fail.') -Action { ipconfig.exe /release | Out-Null; ipconfig.exe /renew } }
            8 { Invoke-BlobNetCommand -Crumb $crumb -Title 'Reset Winsock and TCP/IP' -NeedsAdmin -Danger -Explain @(
                    '{Gray}Runs: netsh winsock reset  and  netsh int ip reset',
                    '{Gray}Static IP settings and some VPN / network software may need to be reconfigured.',
                    '{Gray}A restart is required afterwards.') -Action { netsh.exe winsock reset; netsh.exe int ip reset } }
        }
    }
}
