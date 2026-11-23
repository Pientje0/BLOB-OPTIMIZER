<#
.SYNOPSIS
    Round-trip test of the BLOB OPTIMIZER backup / restore engine.
    Only touches HKCU:\Software\BLOB-OPTIMIZER-Test (created and removed here)
    and writes its journal to a temporary folder. No admin rights needed.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Engine.ps1
#>
$ErrorActionPreference = 'Stop'
$src = Join-Path (Split-Path $PSScriptRoot -Parent) 'src'
. (Join-Path $src 'Core.ps1')

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("blob-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
Initialize-BlobState -DryRun $false
$Blob.DataRoot = $tmp
$Blob.JournalPath = Join-Path $tmp 'changes.json'
$Blob.LogDir = Join-Path $tmp 'logs'
$Blob.RegBackupDir = Join-Path $tmp 'reg'
$Blob.LogPath = Join-Path $Blob.LogDir 'test.log'
$Blob.StorageReady = $false
$Blob.Changes.Clear()

$base = 'HKCU:\Software\BLOB-OPTIMIZER-Test'
$deep = "$base\Deep\Er"
$script:failed = 0
function Assert($cond, $msg) {
    if ($cond) { Write-Host "  [ OK ] $msg" -ForegroundColor Green }
    else { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:failed++ }
}

try {
    if (Test-Path $base) { Remove-Item $base -Recurse -Force }
    New-Item -Path $base -Force | Out-Null
    New-ItemProperty -Path $base -Name 'Str' -Value 'original' -PropertyType String | Out-Null

    Write-Host 'Apply' -ForegroundColor Cyan
    $r1 = Set-BlobRegValue -Path $deep -Name 'Dw' -Value 1 -Type DWord -Source 'test.a' -Label 'new key'
    Assert ($r1.Status -eq 'Applied') "DWord in new nested key applied ($($r1.Status))"
    $r2 = Set-BlobRegValue -Path $base -Name 'Str' -Value 'changed' -Type String -Source 'test.b' -Label 'string'
    Assert ($r2.Status -eq 'Applied') 'Existing string changed'
    $r3 = Set-BlobRegValue -Path $base -Name 'Bin' -Value @(3, 0, 0, 0, 255) -Type Binary -Source 'test.c' -Label 'binary'
    Assert ($r3.Status -eq 'Applied') 'Binary value written'
    $r4 = Set-BlobRegValue -Path $base -Name 'Str' -Value 'changed' -Type String -Source 'test.b'
    Assert ($r4.Status -eq 'Unchanged') 'Re-applying same value is a no-op'
    $big = Set-BlobRegValue -Path $base -Name 'Big' -Value 4294967295 -Type DWord -Source 'test.d'
    Assert ($big.Status -eq 'Applied') 'DWord 0xFFFFFFFF handled'
    Assert (Test-Path $Blob.JournalPath) 'Journal file written'

    Write-Host 'Reload journal from disk' -ForegroundColor Cyan
    $Blob.Changes.Clear()
    Import-BlobJournal
    Assert ($Blob.Changes.Count -eq 4) "4 records reloaded ($($Blob.Changes.Count))"

    Write-Host 'Restore' -ForegroundColor Cyan
    foreach ($rec in @(Get-BlobAppliedChanges | Sort-Object { $Blob.Changes.IndexOf($_) } -Descending)) {
        $res = Restore-BlobChange $rec
        Assert ($res.Status -eq 'Restored') "Restored $($rec.Target) ($($res.Message))"
    }
    Assert (-not (Test-Path "$base\Deep")) 'Keys created by the tool were removed'
    Assert ((Get-ItemProperty $base).Str -eq 'original') 'String back to original'
    Assert ($null -eq (Get-ItemProperty $base -Name Bin -ErrorAction SilentlyContinue)) 'Binary value removed (did not exist before)'
    Assert (@(Get-BlobAppliedChanges).Count -eq 0) 'No restorable records left'
    $again = Restore-BlobChange $Blob.Changes[0]
    Assert ($again.Status -eq 'Skipped') 'Restoring twice is refused'

    Write-Host 'Dry run' -ForegroundColor Cyan
    $Blob.DryRun = $true
    $d = Set-BlobRegValue -Path "$base\Dry" -Name 'X' -Value 1
    Assert ($d.Status -eq 'DryRun' -and -not (Test-Path "$base\Dry")) 'Dry run writes nothing'
} finally {
    Remove-Item $base -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
if ($script:failed) { Write-Host "$($script:failed) test(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All engine tests passed' -ForegroundColor Green
