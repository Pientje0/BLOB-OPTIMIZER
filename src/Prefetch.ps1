# ============================================================================
#  BLOB OPTIMIZER - Prefetch.ps1
#  Collects slow system information (WMI/CIM, network, disks, services,
#  cleanup sizes) on a background thread inside this PowerShell process while
#  the window is already usable. Pages use the snapshot for their first build
#  and query live data again after any change. The thread is disposed when
#  the window closes - nothing keeps running afterwards. Read-only.
# ============================================================================

# Three groups run in parallel; the slowest group sets the total time.
$Blob.PrefetchGroups = @(
    @('Adapters', 'IPConfig', 'Profiles', 'Dns'),
    @('Firewall', 'Defender', 'PhysicalDisks', 'Video', 'BIOS', 'Board', 'Memory'),
    @('OS', 'CPU', 'CS', 'LogicalDisks', 'Services', 'CleanupSizes', 'StoreApps')
)

$Blob.PrefetchScript = {
    param($CleanupTargets, $IsAdmin, $Names, $StoreFn, $StoreProtected)
    $r = @{}
    function Try-Get([string]$Name, [scriptblock]$Block) {
        if ($Names -notcontains $Name) { return }
        try { $r[$Name] = & $Block } catch { $r[$Name] = $null }
    }

    Try-Get 'OS'           { Get-CimInstance Win32_OperatingSystem -ErrorAction Stop }
    Try-Get 'CPU'          { @(Get-CimInstance Win32_Processor -ErrorAction Stop) }
    Try-Get 'CS'           { Get-CimInstance Win32_ComputerSystem -ErrorAction Stop }
    Try-Get 'Memory'       { @(Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop) }
    Try-Get 'Video'        { @(Get-CimInstance Win32_VideoController -ErrorAction Stop) }
    Try-Get 'BIOS'         { Get-CimInstance Win32_BIOS -ErrorAction Stop }
    Try-Get 'Board'        { Get-CimInstance Win32_BaseBoard -ErrorAction Stop }
    Try-Get 'LogicalDisks' { @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop) }
    Try-Get 'Services'     { @(Get-CimInstance Win32_Service -ErrorAction Stop) }
    Try-Get 'PhysicalDisks' {
        @(Get-PhysicalDisk -ErrorAction Stop | ForEach-Object {
                [pscustomobject]@{ DeviceId = $_.DeviceId; FriendlyName = $_.FriendlyName; MediaType = [string]$_.MediaType
                                   Size = $_.Size; HealthStatus = [string]$_.HealthStatus } })
    }
    Try-Get 'Defender' { Get-MpComputerStatus -ErrorAction Stop | Select-Object RealTimeProtectionEnabled, AntivirusSignatureLastUpdated }
    Try-Get 'Firewall' { @(Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object { [pscustomobject]@{ Name = [string]$_.Name; Enabled = [bool]$_.Enabled } }) }
    Try-Get 'Adapters' {
        @(Get-NetAdapter -ErrorAction Stop | ForEach-Object {
                [pscustomobject]@{ Name = $_.Name; InterfaceDescription = $_.InterfaceDescription; ifIndex = $_.ifIndex
                                   Status = [string]$_.Status; LinkSpeed = [string]$_.LinkSpeed; MacAddress = $_.MacAddress
                                   InterfaceGuid = [string]$_.InterfaceGuid } })
    }
    Try-Get 'IPConfig' {
        # Get-NetIPAddress + Get-NetRoute: the same data as Get-NetIPConfiguration, much faster.
        $h = @{}
        $addr = @(Get-NetIPAddress -ErrorAction Stop | Where-Object { $_.AddressState -eq 'Preferred' })
        $gw = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue)
        foreach ($idx in @($addr | ForEach-Object { [int]$_.InterfaceIndex } | Select-Object -Unique)) {
            $h[$idx] = [pscustomobject]@{
                IPv4    = (@($addr | Where-Object { [int]$_.InterfaceIndex -eq $idx -and [string]$_.AddressFamily -eq 'IPv4' } | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ', ')
                IPv6    = (@($addr | Where-Object { [int]$_.InterfaceIndex -eq $idx -and [string]$_.AddressFamily -eq 'IPv6' } | ForEach-Object { $_.IPAddress }) -join ', ')
                Gateway = (@($gw | Where-Object { [int]$_.InterfaceIndex -eq $idx } | ForEach-Object { $_.NextHop }) -join ', ') }
        }
        $h
    }
    Try-Get 'Profiles' {
        $h = @{}
        foreach ($p in @(Get-NetConnectionProfile -ErrorAction Stop)) { $h[[int]$p.InterfaceIndex] = [pscustomobject]@{ Name = $p.Name; NetworkCategory = [string]$p.NetworkCategory } }
        $h
    }
    Try-Get 'Dns' {
        $h = @{}
        foreach ($d in @(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop)) { $h[[int]$d.InterfaceIndex] = @($d.ServerAddresses) }
        $h
    }
    if ($Names -contains 'StoreApps' -and $StoreFn) {
        . ([scriptblock]::Create("function Get-BlobStoreAppsLive {`n$StoreFn`n}"))
        Try-Get 'StoreApps' { @(Get-BlobStoreAppsLive -Protected $StoreProtected) }
    }
    Try-Get 'CleanupSizes' {
        $sizes = @{}
        foreach ($t in $CleanupTargets) {
            if ($t.Admin -and -not $IsAdmin) { $sizes[$t.Id] = @{ Bytes = 0; Count = 0; Note = 'admin required' }; continue }
            if ($t.Special -eq 'Recycle') {
                try {
                    $shell = New-Object -ComObject Shell.Application
                    $items = @($shell.Namespace(10).Items()); $bytes = 0
                    foreach ($i in $items) { $bytes += [double]$i.Size }
                    $sizes[$t.Id] = @{ Bytes = $bytes; Count = $items.Count; Note = '' }
                } catch { $sizes[$t.Id] = @{ Bytes = 0; Count = 0; Note = 'unavailable' } }
                continue
            }
            $cutoff = (Get-Date).AddHours(-1 * [double]$t.MinAgeHours)
            $bytes = 0; $count = 0
            foreach ($p in $t.Paths) {
                if (-not $p -or -not (Test-Path -LiteralPath $p)) { continue }
                $params = @{ LiteralPath = $p; File = $true; Force = $true; ErrorAction = 'SilentlyContinue' }
                if ($t.Filter) { $params.Filter = $t.Filter } else { $params.Recurse = $true }
                foreach ($f in (Get-ChildItem @params)) { if ($f.LastWriteTime -lt $cutoff) { $bytes += $f.Length; $count++ } }
            }
            $sizes[$t.Id] = @{ Bytes = [double]$bytes; Count = $count; Note = '' }
        }
        $sizes
    }
    return $r
}

# Starts the background collection (three parallel threads). Returns immediately.
function Start-BlobPrefetch {
    $Blob.Prefetch = $null; $Blob.PrefetchValid = $false; $Blob.PrefetchState = 'Running'
    $jobs = New-Object System.Collections.ArrayList
    try {
        foreach ($names in $Blob.PrefetchGroups) {
            $rs = [runspacefactory]::CreateRunspace()
            $rs.ApartmentState = 'STA'   # Shell.Application (Recycle Bin size) prefers STA
            $rs.Open()
            $ps = [powershell]::Create()
            $ps.Runspace = $rs
            [void]$ps.AddScript($Blob.PrefetchScript.ToString()).AddArgument($Blob.CleanupTargets).AddArgument($Blob.IsAdmin).AddArgument([string[]]$names).AddArgument(${function:Get-BlobStoreAppsLive}.ToString()).AddArgument([string[]]$Blob.StoreProtected)
            [void]$jobs.Add(@{ PS = $ps; RS = $rs; Handle = $ps.BeginInvoke() })
        }
        $Blob.PrefetchJob = @{ Jobs = $jobs; Started = Get-Date }
    } catch {
        $Blob.PrefetchJob = @{ Jobs = $jobs; Started = Get-Date }
        Stop-BlobPrefetch
        $Blob.PrefetchState = 'Failed'
        Write-BlobLog "Background data collection could not start: $($_.Exception.Message)" 'WARN'
    }
}

# Collects the results when all threads finished. Returns $true once nothing is running.
function Receive-BlobPrefetch {
    $job = $Blob.PrefetchJob
    if (-not $job) { return $true }
    foreach ($j in $job.Jobs) { if (-not $j.Handle.IsCompleted) { return $false } }
    $merged = @{}
    $ok = $false
    foreach ($j in $job.Jobs) {
        try {
            $out = $j.PS.EndInvoke($j.Handle)
            if ($out.Count -gt 0 -and $out[0] -is [hashtable]) { foreach ($k in $out[0].Keys) { $merged[$k] = $out[0][$k] }; $ok = $true }
        } catch { Write-BlobLog "Background data collection part failed: $($_.Exception.Message)" 'WARN' }
    }
    if ($ok) {
        $Blob.Prefetch = $merged; $Blob.PrefetchValid = $true; $Blob.PrefetchState = 'Ready'
        Write-BlobLog ("Background data collected in {0:N1}s" -f ((Get-Date) - $job.Started).TotalSeconds)
    } else { $Blob.PrefetchState = 'Failed' }
    Stop-BlobPrefetch
    return $true
}

function Stop-BlobPrefetch {
    $job = $Blob.PrefetchJob
    if (-not $job) { return }
    foreach ($j in @($job.Jobs)) {
        try { if (-not $j.Handle.IsCompleted) { $j.PS.Stop() } } catch { }
        try { $j.PS.Dispose() } catch { }
        try { $j.RS.Dispose() } catch { }
    }
    $Blob.PrefetchJob = $null
    if ($Blob.PrefetchState -eq 'Running') { $Blob.PrefetchState = 'Stopped' }
}

# Returns prefetched data while the snapshot is still valid, otherwise $null
# (callers then query live). Any change invalidates the snapshot.
function Get-BlobPrefetch {
    param([string]$Name)
    # Return nothing (not $null) when unavailable, so @(Get-BlobPrefetch ...) is empty
    # and callers fall back to a live query.
    if (-not $Blob.PrefetchValid -or -not $Blob.Prefetch) { return }
    $v = $Blob.Prefetch[$Name]
    if ($null -eq $v) { return }
    return $v
}
