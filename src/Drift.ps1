# ============================================================================
#  BLOB OPTIMIZER - Drift.ps1
#  "Did Windows undo my settings?" Feature updates (or you, in Settings) can
#  put values back. BLOB compares every change it still owns with the PC.
#  Re-applying writes the wanted value again but KEEPS the original record,
#  so a later undo still returns to how the PC was before BLOB.
# ============================================================================

# Latest applied, reversible registry/service change per target.
function Get-BlobOwnedChanges {
    $latest = @{}
    foreach ($r in $Blob.Changes) {
        if ($r.Status -eq 'Applied' -and $r.Reversible -and $r.Kind -in @('Registry', 'Service')) { $latest[$r.Target] = $r }
    }
    return @($latest.Values)
}

function Get-BlobDrift {
    $out = New-Object System.Collections.ArrayList
    foreach ($r in (Get-BlobOwnedChanges)) {
        $d = $r.Data
        if ($r.Kind -eq 'Registry') {
            $s = Get-BlobRegState $d.Path $d.Name
            $ok = if ($d.Delete) { -not $s.Exists } else { $s.Exists -and (Test-BlobValueEqual (ConvertTo-BlobJsonValue $s.Value) $d.NewValue) }
            if (-not $ok) {
                $want = if ($d.Delete) { '(removed)' } else { Format-BlobValue $d.NewValue }
                [void]$out.Add([pscustomobject]@{ Record = $r; Label = $r.Label; Target = $r.Target; Now = (Format-BlobValue $s.Value $s.Exists); Want = $want })
            }
        } else {
            $cur = Get-BlobServiceStartup $d.Name
            if ($cur -and $cur -ne $d.New) { [void]$out.Add([pscustomobject]@{ Record = $r; Label = $r.Label; Target = $r.Target; Now = $cur; Want = $d.New }) }
        }
    }
    return $out.ToArray()
}

# Writes the wanted value again. Returns a result line.
function Repair-BlobDrift {
    param($Item)
    $r = $Item.Record; $d = $r.Data
    if ($Blob.DryRun) { return "{Magenta} DRY  {White}$($r.Target) {Gray}would be set back to $($Item.Want)" }
    try {
        if ($r.Kind -eq 'Registry') {
            if ((Test-BlobNeedsAdmin $d.Path) -and -not $Blob.IsAdmin) { throw 'administrator rights required' }
            if ($d.Delete) {
                if ((Get-BlobRegState $d.Path $d.Name).Exists) { Remove-ItemProperty -LiteralPath $d.Path -Name $d.Name -ErrorAction Stop }
            } else {
                if (-not (Test-Path -LiteralPath $d.Path)) { New-Item -Path $d.Path -Force -ErrorAction Stop | Out-Null }
                New-ItemProperty -LiteralPath $d.Path -Name $d.Name -PropertyType $d.Type -Value (ConvertTo-BlobRegValue $d.NewValue $d.Type) -Force -ErrorAction Stop | Out-Null
            }
        } else {
            if (-not $Blob.IsAdmin) { throw 'administrator rights required' }
            Invoke-BlobScConfig $d.Name $d.New
        }
        $still = @(Get-BlobDrift | Where-Object { $_.Target -eq $r.Target }).Count
        if ($still) { throw 'the value did not stick (a policy or Windows may be enforcing it)' }
        Add-BlobActionRecord -Source 'drift' -Label "Re-applied after it was changed back: $($r.Label)" -Target $r.Target -Detail "$($Item.Now) -> $($Item.Want)"
        return "{White} OK   {White}$($r.Target) {Gray}$($Item.Now) -> $($Item.Want)"
    } catch { return "{Red} FAIL {White}$($r.Target) {Gray}($($_.Exception.Message -replace '[{}]', ''))" }
}

# Accept the value Windows put back: the record stops counting as BLOB's change.
function Set-BlobDriftAccepted {
    param($Item)
    if ($Blob.DryRun) { return }
    $Item.Record.Status = 'Superseded'
    $Item.Record.RestoredAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Save-BlobJournal
    Write-BlobLog "Accepted the current value for $($Item.Target) (was changed back outside BLOB)."
}
