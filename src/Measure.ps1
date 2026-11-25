# ============================================================================
#  BLOB OPTIMIZER - Measure.ps1
#  Honest before/after numbers. Boot times come from Windows' own boot
#  performance log; snapshots record what is running right now. Nothing here
#  changes the PC. Snapshots are kept in measurements.json next to the journal.
# ============================================================================

# Recent boots from the Diagnostics-Performance log (event 100), newest first.
function Get-BlobBootTimes {
    param([int]$Max = 12)
    try {
        $ev = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100 } -MaxEvents $Max -ErrorAction Stop
    } catch { return @() }
    foreach ($e in $ev) {
        $d = @{}
        try { foreach ($n in ([xml]$e.ToXml()).Event.EventData.Data) { $d[$n.Name] = $n.'#text' } } catch { continue }
        [pscustomobject]@{
            Date = $e.TimeCreated; BootMs = [int]$d['BootTime']; MainPathMs = [int]$d['MainPathBootTime']; PostBootMs = [int]$d['BootPostBootTime']
        }
    }
}

function Get-BlobSnapshotPath { return (Join-Path $Blob.DataRoot 'measurements.json') }

function Get-BlobSnapshots {
    if (-not $Blob.Snapshots) {
        $Blob.Snapshots = New-Object System.Collections.ArrayList
        $p = Get-BlobSnapshotPath
        if (Test-Path -LiteralPath $p) {
            try { foreach ($s in (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)) { [void]$Blob.Snapshots.Add($s) } } catch { }
        }
    }
    return @($Blob.Snapshots)
}

# Records the current state. In dry run the snapshot is kept in memory only.
function New-BlobSnapshot {
    param([string]$Label = 'Snapshot')
    $null = Get-BlobSnapshots
    $os = $null; try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { }
    $ramMB = if ($os) { [int](([double]$os.TotalVisibleMemorySize - [double]$os.FreePhysicalMemory) / 1KB) } else { 0 }
    $boot = @(Get-BlobBootTimes 1) | Select-Object -First 1
    $free = 0
    try { $free = [Math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop).FreeSpace / 1GB, 1) } catch { }
    $snap = [pscustomobject]@{
        Time        = (Get-Date).ToString('yyyy-MM-dd HH:mm')
        Label       = $Label
        BootSec     = $(if ($boot) { [Math]::Round($boot.BootMs / 1000, 1) } else { $null })
        RamUsedMB   = $ramMB
        Processes   = @(Get-Process).Count
        Services    = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }).Count
        StartupApps = @(Get-BlobStartupEntries | Where-Object { $_.Enabled }).Count
        TweaksOn    = @(Get-BlobCoreTweaks | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
        PrivacyOff  = @(Get-BlobPrivacyItems | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
        FreeGB      = $free
        UptimeMin   = $(if ($os) { [int]((Get-Date) - $os.LastBootUpTime).TotalMinutes } else { $null })
    }
    [void]$Blob.Snapshots.Add($snap)
    if (-not $Blob.DryRun) {
        Initialize-BlobStorage
        [IO.File]::WriteAllText((Get-BlobSnapshotPath), (ConvertTo-Json -InputObject @($Blob.Snapshots.ToArray()) -Depth 4), (New-Object Text.UTF8Encoding($false)))
    }
    return $snap
}

# Plain-language comparison of two snapshots.
function Compare-BlobSnapshots {
    param($A, $B)
    $lines = @()
    $fmt = {
        param($name, $from, $to, $unit, [bool]$lowerIsBetter = $true)
        if ($null -eq $from -or $null -eq $to -or "$from" -eq '' -or "$to" -eq '') { return "{Gray}$($name.PadRight(22)){DarkGray}not measured in both snapshots" }
        $diff = [double]$to - [double]$from
        $pct = if ([double]$from -ne 0) { 100 * $diff / [double]$from } else { 0 }
        $better = if ($lowerIsBetter) { $diff -lt 0 } else { $diff -gt 0 }
        $word = if ([Math]::Abs($pct) -lt 5) { 'about the same' } elseif ($better) { 'better' } else { 'worse' }
        $sign = if ($diff -gt 0) { '+' } else { '' }
        return ("{{Gray}}{0}{{White}}{1} {2} -> {3} {2}  {{DarkGray}}({4}{5:N1} {2}, {6})" -f $name.PadRight(22), $from, $unit, $to, $sign, $diff, $word)
    }
    $lines += & $fmt 'Boot time' $A.BootSec $B.BootSec 's'
    $lines += & $fmt 'Memory in use' $A.RamUsedMB $B.RamUsedMB 'MB'
    $lines += & $fmt 'Running processes' $A.Processes $B.Processes ''
    $lines += & $fmt 'Running services' $A.Services $B.Services ''
    $lines += & $fmt 'Startup programs' $A.StartupApps $B.StartupApps ''
    $lines += & $fmt 'Free space on system drive' $A.FreeGB $B.FreeGB 'GB' $false
    return $lines
}
