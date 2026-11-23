# ============================================================================
#  BLOB OPTIMIZER - Core.ps1
#  Session state, admin detection, logging and the change journal that powers
#  backup / restore. Every modification in the tool goes through this file:
#     read current value -> save original -> record -> apply -> verify
# ============================================================================

# Single state object shared by every module. It is created inside the
# release script block, so it disappears when the tool exits.
$Blob = @{
    Version   = '1.2.0'
    Tweaks    = New-Object System.Collections.ArrayList
    Changes   = New-Object System.Collections.ArrayList
    LogBuffer = New-Object System.Collections.ArrayList
    DryRun    = $false
    IsAdmin   = $false
    StorageReady = $false
}

function Test-BlobAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($id)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Initialize-BlobState {
    param([bool]$DryRun)
    $Blob.DryRun       = $DryRun -or ($env:BLOB_DRYRUN -eq '1')
    $Blob.SessionId    = Get-Date -Format 'yyyyMMdd-HHmmss'
    $Blob.IsAdmin      = Test-BlobAdmin
    $Blob.DataRoot     = Join-Path $env:LOCALAPPDATA 'BLOB-OPTIMIZER'
    $Blob.JournalPath  = Join-Path $Blob.DataRoot 'changes.json'
    $Blob.LogDir       = Join-Path $Blob.DataRoot 'logs'
    $Blob.RegBackupDir = Join-Path $Blob.DataRoot 'registry-backups'
    $Blob.LogPath      = Join-Path $Blob.LogDir ("session-{0}.log" -f $Blob.SessionId)
    $Blob.StorageReady = $false
    $Blob.Changes.Clear()
    $Blob.LogBuffer.Clear()
    Import-BlobJournal
    Write-BlobLog ("BLOB OPTIMIZER {0} started. Admin={1} DryRun={2} PS={3}" -f `
        $Blob.Version, $Blob.IsAdmin, $Blob.DryRun, $PSVersionTable.PSVersion)
}

# ---------------------------------------------------------------------------
#  Storage and logging. Nothing is written to disk until the first real
#  change is made, so read-only browsing leaves no files behind.
# ---------------------------------------------------------------------------
function Initialize-BlobStorage {
    if ($Blob.StorageReady -or $Blob.DryRun) { return }
    foreach ($dir in @($Blob.DataRoot, $Blob.LogDir, $Blob.RegBackupDir)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    $Blob.StorageReady = $true
    if ($Blob.LogBuffer.Count -gt 0) {
        Add-Content -LiteralPath $Blob.LogPath -Value $Blob.LogBuffer.ToArray() -Encoding UTF8
    }
}

function Write-BlobLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    [void]$Blob.LogBuffer.Add($line)
    if ($Blob.StorageReady) {
        try { Add-Content -LiteralPath $Blob.LogPath -Value $line -Encoding UTF8 } catch { }
    }
}

function Import-BlobJournal {
    if (-not (Test-Path -LiteralPath $Blob.JournalPath)) { return }
    try {
        $raw = Get-Content -LiteralPath $Blob.JournalPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return }
        $data = $raw | ConvertFrom-Json -ErrorAction Stop
        foreach ($item in $data) { [void]$Blob.Changes.Add($item) }
        $Blob.StorageReady = $true
    } catch {
        # Never destroy a journal we cannot parse - keep a copy aside.
        $bad = $Blob.JournalPath + '.unreadable-' + $Blob.SessionId
        try { Copy-Item -LiteralPath $Blob.JournalPath -Destination $bad -Force } catch { }
        Write-BlobLog "Journal could not be read and was copied to $bad : $($_.Exception.Message)" 'ERROR'
    }
}

function Save-BlobJournal {
    if ($Blob.DryRun) { return }
    Initialize-BlobStorage
    $json = ConvertTo-Json -InputObject @($Blob.Changes.ToArray()) -Depth 8
    $tmp = $Blob.JournalPath + '.tmp'
    [IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $Blob.JournalPath -Force
}

function New-BlobChangeRecord {
    param([string]$Kind, [string]$Source, [string]$Label, [string]$Target,
          [hashtable]$Data, [bool]$Reversible = $true)
    [pscustomobject]@{
        Id         = ([guid]::NewGuid().ToString('N')).Substring(0, 10)
        SessionId  = $Blob.SessionId
        Time       = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Kind       = $Kind
        Source     = $Source
        Label      = $Label
        Target     = $Target
        Data       = $Data
        Reversible = $Reversible
        Status     = 'Pending'
        Error      = $null
        RestoredAt = $null
    }
}

function Add-BlobChange {
    param($Record)
    [void]$Blob.Changes.Add($Record)
    Write-BlobLog ("{0} {1} [{2}] {3} -> {4}" -f $Record.Status, $Record.Kind, $Record.Source, $Record.Target, $Record.Label)
    Save-BlobJournal
}

# Record an operation that cannot be undone (cleanup, DNS flush, resets).
function Add-BlobActionRecord {
    param([string]$Source, [string]$Label, [string]$Target, [string]$Status = 'Applied', [string]$Detail)
    if ($Blob.DryRun) { Write-BlobLog "[DRY RUN] $Label ($Target)"; return }
    $rec = New-BlobChangeRecord -Kind 'Action' -Source $Source -Label $Label -Target $Target `
        -Data @{ Detail = $Detail } -Reversible $false
    $rec.Status = $Status
    Add-BlobChange $rec
}

function New-BlobResult {
    param([string]$Target, [string]$Status, [string]$Message, [string]$Old, [string]$New)
    [pscustomobject]@{ Target = $Target; Status = $Status; Message = $Message; Old = $Old; New = $New }
}

# ---------------------------------------------------------------------------
#  Registry helpers
# ---------------------------------------------------------------------------
function Format-BlobRegPath {
    param([string]$Path, [string]$Name)
    $p = $Path -replace '^HKCU:\\', 'HKCU\' -replace '^HKLM:\\', 'HKLM\'
    if ($Name) { return "$p\$Name" } else { return $p }
}

function Test-BlobNeedsAdmin {
    param([string]$Path)
    return ($Path -like 'HKLM:*') -or ($Path -like '*\Policies\*')
}

function Get-BlobRegValueName { param([string]$Name) if ($Name -eq '(default)') { return '' } return $Name }

function Get-BlobRegState {
    param([string]$Path, [string]$Name)
    $state = @{ KeyExists = $false; Exists = $false; Value = $null; Kind = $null }
    try { $key = Get-Item -LiteralPath $Path -ErrorAction Stop } catch { return $state }
    $state.KeyExists = $true
    $n = Get-BlobRegValueName $Name
    if (@($key.GetValueNames()) -contains $n) {
        $state.Exists = $true
        $state.Kind   = $key.GetValueKind($n).ToString()
        $state.Value  = $key.GetValue($n, $null, 'DoNotExpandEnvironmentNames')
    }
    return $state
}

function ConvertTo-BlobRegValue {
    param($Value, [string]$Type)
    switch ($Type) {
        'DWord' {
            $v = [int64]$Value
            if ($v -gt [int32]::MaxValue) { return [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$v), 0) }
            return [int32]$v
        }
        'QWord'       { return [int64]$Value }
        'Binary'      { return [byte[]]@($Value | ForEach-Object { [byte]$_ }) }
        'MultiString' { return [string[]]@($Value) }
        default       { return [string]$Value }
    }
}

# Byte arrays become int arrays so they survive the JSON journal.
function ConvertTo-BlobJsonValue {
    param($Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [byte[]]) { return @($Value | ForEach-Object { [int]$_ }) }
    if ($Value -is [array])  { return @($Value) }
    return $Value
}

function Test-BlobValueEqual {
    param($A, $B)
    if ($null -eq $A -and $null -eq $B) { return $true }
    if ($null -eq $A -or $null -eq $B)  { return $false }
    if ($A -is [array] -or $B -is [array]) { return ((@($A) -join ',') -eq (@($B) -join ',')) }
    if ($A -is [int] -and "$B" -match '^\d+$' -and [int64]$B -gt [int32]::MaxValue) {
        return ([uint32][BitConverter]::ToUInt32([BitConverter]::GetBytes([int32]$A), 0) -eq [uint32]$B)
    }
    return ("$A" -eq "$B")
}

function Format-BlobValue {
    param($Value, [bool]$Exists = $true)
    if (-not $Exists -or $null -eq $Value) { return '(not set)' }
    if ($Value -is [array]) {
        $items = @($Value)
        if ($items.Count -gt 0 -and ($items[0] -is [byte] -or $items[0] -is [int])) {
            $hex = ($items | Select-Object -First 8 | ForEach-Object { '{0:X2}' -f [int]$_ }) -join ' '
            if ($items.Count -gt 8) { $hex += ' ...' }
            return "hex: $hex"
        }
        return ($items -join '; ')
    }
    if ($Value -is [string]) { return '"' + $Value + '"' }
    return "$Value"
}

function Get-BlobMissingKeys {
    param([string]$Path)
    $missing = New-Object System.Collections.ArrayList
    $p = $Path
    while ($p -and -not (Test-Path -LiteralPath $p)) {
        [void]$missing.Insert(0, $p)
        $parent = Split-Path -Path $p -Parent
        if (-not $parent -or $parent -eq $p) { break }
        $p = $parent
    }
    return $missing.ToArray()
}

# The single entry point for every registry modification in the tool.
function Set-BlobRegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord',
          [string]$Source = 'manual', [string]$Label = '', [switch]$Delete)

    $target = Format-BlobRegPath $Path $Name
    if ((Test-BlobNeedsAdmin $Path) -and -not $Blob.IsAdmin) {
        return New-BlobResult $target 'Skipped' 'Administrator rights required (machine-wide setting).'
    }
    $cur = Get-BlobRegState $Path $Name
    $oldText = Format-BlobValue $cur.Value $cur.Exists
    $newText = if ($Delete) { '(removed)' } else { Format-BlobValue (ConvertTo-BlobJsonValue $Value) $true }

    if ($Delete -and -not $cur.Exists) { return New-BlobResult $target 'Unchanged' 'Already absent.' $oldText $newText }
    if (-not $Delete -and $cur.Exists -and (Test-BlobValueEqual (ConvertTo-BlobJsonValue $cur.Value) (ConvertTo-BlobJsonValue $Value))) {
        return New-BlobResult $target 'Unchanged' 'Already set.' $oldText $newText
    }
    if ($Blob.DryRun) {
        Write-BlobLog "[DRY RUN] would set $target : $oldText -> $newText"
        return New-BlobResult $target 'DryRun' 'Dry run - nothing changed.' $oldText $newText
    }

    $rec = New-BlobChangeRecord -Kind 'Registry' -Source $Source -Label $Label -Target $target -Data @{
        Path        = $Path
        Name        = $Name
        Type        = $Type
        Delete      = [bool]$Delete
        NewValue    = ConvertTo-BlobJsonValue $Value
        OldExists   = $cur.Exists
        OldValue    = ConvertTo-BlobJsonValue $cur.Value
        OldKind     = $cur.Kind
        CreatedKeys = @(Get-BlobMissingKeys $Path)
    }
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        if ($Delete) {
            Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
            $ok = -not (Get-BlobRegState $Path $Name).Exists
        } else {
            New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType $Type `
                -Value (ConvertTo-BlobRegValue $Value $Type) -Force -ErrorAction Stop | Out-Null
            $after = Get-BlobRegState $Path $Name
            $ok = $after.Exists -and (Test-BlobValueEqual (ConvertTo-BlobJsonValue $after.Value) (ConvertTo-BlobJsonValue $Value))
        }
        if ($ok) { $rec.Status = 'Applied' } else { $rec.Status = 'Failed'; $rec.Error = 'Verification failed: value did not match after writing.' }
    } catch {
        $rec.Status = 'Failed'; $rec.Error = $_.Exception.Message
    }
    Add-BlobChange $rec
    return New-BlobResult $target $rec.Status $(if ($rec.Error) { $rec.Error } else { 'Applied and verified.' }) $oldText $newText
}

function Restore-BlobRegistryChange {
    param($Record)
    $d = $Record.Data
    if ($d.OldExists) {
        if (-not (Test-Path -LiteralPath $d.Path)) { New-Item -Path $d.Path -Force -ErrorAction Stop | Out-Null }
        $kind = if ($d.OldKind -and $d.OldKind -notin @('Unknown', 'None')) { $d.OldKind } else { $d.Type }
        New-ItemProperty -LiteralPath $d.Path -Name $d.Name -PropertyType $kind `
            -Value (ConvertTo-BlobRegValue $d.OldValue $kind) -Force -ErrorAction Stop | Out-Null
        $after = Get-BlobRegState $d.Path $d.Name
        if (-not ($after.Exists -and (Test-BlobValueEqual (ConvertTo-BlobJsonValue $after.Value) $d.OldValue))) {
            throw 'Verification failed after restoring the original value.'
        }
    } else {
        if ((Get-BlobRegState $d.Path $d.Name).Exists) {
            Remove-ItemProperty -LiteralPath $d.Path -Name $d.Name -ErrorAction Stop
        }
        # Remove keys this tool created, deepest first, only if they are empty.
        $created = @($d.CreatedKeys)
        [array]::Reverse($created)
        foreach ($k in $created) {
            if (-not $k) { continue }
            try {
                $item = Get-Item -LiteralPath $k -ErrorAction Stop
                if ($item.SubKeyCount -eq 0 -and $item.ValueCount -eq 0) { Remove-Item -LiteralPath $k -ErrorAction Stop }
            } catch { }
        }
    }
}

# Export the given registry keys to .reg files before a batch of changes.
function Backup-BlobRegistryKeys {
    param([string[]]$Paths, [string]$Tag = 'batch')
    if ($Blob.DryRun -or -not $Paths) { return $null }
    Initialize-BlobStorage
    $dir = Join-Path $Blob.RegBackupDir ("{0}-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), ($Tag -replace '[^\w-]', ''))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $i = 0
    foreach ($p in ($Paths | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $p)) { continue }
        if ((Test-BlobNeedsAdmin $p) -and -not $Blob.IsAdmin) { continue }
        $i++
        $file = Join-Path $dir ('{0:D2}.reg' -f $i)
        $null = & reg.exe export (Format-BlobRegPath $p) $file /y 2>&1
    }
    Write-BlobLog "Registry snapshot saved: $dir ($i keys)"
    return $dir
}

# ---------------------------------------------------------------------------
#  Service startup helpers (startup type only - services are never stopped
#  or deleted by this tool).
# ---------------------------------------------------------------------------
function Get-BlobServiceStartup {
    param([string]$Name)
    $st = Get-BlobRegState "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" 'Start'
    if (-not $st.Exists) { return $null }
    switch ([int]$st.Value) {
        0 { return 'Boot' }
        1 { return 'System' }
        2 {
            $d = Get-BlobRegState "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" 'DelayedAutostart'
            if ($d.Exists -and [int]$d.Value -eq 1) { return 'AutomaticDelayed' }
            return 'Automatic'
        }
        3 { return 'Manual' }
        4 { return 'Disabled' }
        default { return 'Unknown' }
    }
}

function Invoke-BlobScConfig {
    param([string]$Name, [string]$StartupType)
    $map = @{ Automatic = 'auto'; AutomaticDelayed = 'delayed-auto'; Manual = 'demand'; Disabled = 'disabled' }
    if (-not $map.ContainsKey($StartupType)) { throw "Unsupported startup type '$StartupType'." }
    $out = & sc.exe config $Name start= $map[$StartupType] 2>&1
    if ($LASTEXITCODE -ne 0) { throw ("sc.exe failed ({0}): {1}" -f $LASTEXITCODE, (($out | Out-String).Trim())) }
}

function Set-BlobServiceStartup {
    param([string]$Name, [string]$StartupType, [string]$Source = 'services', [string]$Label = '')
    $target = "Service $Name (startup type)"
    if (-not $Blob.IsAdmin) { return New-BlobResult $target 'Skipped' 'Administrator rights required to change services.' }
    $old = Get-BlobServiceStartup $Name
    if (-not $old) { return New-BlobResult $target 'Skipped' 'Service not present on this system.' }
    if ($old -eq $StartupType) { return New-BlobResult $target 'Unchanged' 'Already set.' $old $StartupType }
    if ($old -in @('Boot', 'System', 'Unknown')) { return New-BlobResult $target 'Skipped' 'Driver-level service; not modified.' $old $StartupType }
    if ($Blob.DryRun) { return New-BlobResult $target 'DryRun' 'Dry run - nothing changed.' $old $StartupType }

    $rec = New-BlobChangeRecord -Kind 'Service' -Source $Source -Label $Label -Target $target `
        -Data @{ Name = $Name; Old = $old; New = $StartupType }
    try {
        Invoke-BlobScConfig $Name $StartupType
        if ((Get-BlobServiceStartup $Name) -eq $StartupType) { $rec.Status = 'Applied' }
        else { $rec.Status = 'Failed'; $rec.Error = 'Verification failed: startup type did not change.' }
    } catch { $rec.Status = 'Failed'; $rec.Error = $_.Exception.Message }
    Add-BlobChange $rec
    return New-BlobResult $target $rec.Status $(if ($rec.Error) { $rec.Error } else { 'Applied and verified. Takes full effect after restart.' }) $old $StartupType
}

# ---------------------------------------------------------------------------
#  Restore dispatcher
# ---------------------------------------------------------------------------
function Restore-BlobChange {
    param($Record)
    $target = $Record.Target
    if ($Record.Status -ne 'Applied') { return New-BlobResult $target 'Skipped' "Record status is '$($Record.Status)'; nothing to restore." }
    if (-not $Record.Reversible)      { return New-BlobResult $target 'Skipped' 'This operation cannot be reliably reversed.' }
    if ($Blob.DryRun) { return New-BlobResult $target 'DryRun' 'Dry run - would restore original value.' }
    try {
        switch ($Record.Kind) {
            'Registry' {
                if ((Test-BlobNeedsAdmin $Record.Data.Path) -and -not $Blob.IsAdmin) { throw 'Administrator rights required.' }
                Restore-BlobRegistryChange $Record
            }
            'Service' {
                if (-not $Blob.IsAdmin) { throw 'Administrator rights required.' }
                Invoke-BlobScConfig $Record.Data.Name $Record.Data.Old
            }
            'PowerPlan'        { Restore-BlobPowerChange $Record }
            'PowerPlanCreated' { Restore-BlobPowerChange $Record }
            'PowerTimeout'     { Restore-BlobPowerChange $Record }
            'Hibernate'        { Restore-BlobPowerChange $Record }
            'Dns'              { Restore-BlobDnsChange $Record }
            default { throw "Unknown change kind '$($Record.Kind)'." }
        }
        $Record.Status = 'Restored'
        $Record.RestoredAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Save-BlobJournal
        Write-BlobLog "Restored [$($Record.Id)] $target"
        return New-BlobResult $target 'Restored' 'Original value restored and verified.'
    } catch {
        Write-BlobLog "Restore failed [$($Record.Id)] $target : $($_.Exception.Message)" 'ERROR'
        return New-BlobResult $target 'Failed' $_.Exception.Message
    }
}

function Get-BlobAppliedChanges {
    param([string]$Source)
    $list = @($Blob.Changes | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible })
    if ($Source) { $list = @($list | Where-Object { $_.Source -eq $Source }) }
    return $list
}
