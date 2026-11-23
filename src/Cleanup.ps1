# ============================================================================
#  BLOB OPTIMIZER - Cleanup.ps1
#  Safe cleanup of temporary files and caches with a size preview.
#  Only files older than the listed age are removed and locked files are
#  skipped. Deleted files are NOT recoverable - this is stated before running.
# ============================================================================

$Blob.CleanupTargets = @(
    @{ Id = 'usertemp'; Name = 'User temporary files'; Paths = @($env:TEMP); MinAgeHours = 24
       Detail = 'Leftovers from installers and apps in your TEMP folder.' }
    @{ Id = 'wintemp'; Name = 'Windows temporary files'; Paths = @("$env:windir\Temp"); MinAgeHours = 24; Admin = $true
       Detail = 'System-wide temporary files in C:\Windows\Temp.' }
    @{ Id = 'thumbs'; Name = 'Thumbnail cache'; Paths = @("$env:LOCALAPPDATA\Microsoft\Windows\Explorer"); Filter = 'thumbcache_*.db'; MinAgeHours = 0
       Detail = 'Explorer rebuilds thumbnails when needed. Files in use are skipped.' }
    @{ Id = 'crashdumps'; Name = 'Application crash dumps'; Paths = @("$env:LOCALAPPDATA\CrashDumps"); MinAgeHours = 0
       Detail = 'Memory dumps written when programs crash. Only useful for debugging.' }
    @{ Id = 'wer'; Name = 'Windows Error Reporting files'; Paths = @("$env:ProgramData\Microsoft\Windows\WER\ReportArchive", "$env:ProgramData\Microsoft\Windows\WER\ReportQueue"); MinAgeHours = 0; Admin = $true
       Detail = 'Archived and queued error reports.' }
    @{ Id = 'd3dcache'; Name = 'DirectX shader cache'; Paths = @("$env:LOCALAPPDATA\D3DSCache"); MinAgeHours = 0
       Detail = 'Rebuilt automatically. Games may stutter briefly the first time they run afterwards.' }
    @{ Id = 'wucache'; Name = 'Windows Update download cache'; Paths = @("$env:windir\SoftwareDistribution\Download"); MinAgeHours = 72; Admin = $true; Warn = $true
       Detail = 'Already-installed update packages. Run only when no update is installing.' }
    @{ Id = 'recycle'; Name = 'Recycle Bin'; Special = 'Recycle'; MinAgeHours = 0
       Detail = 'Permanently empties the Recycle Bin for all drives.' }
)

function Get-BlobCleanupFiles {
    param($Target)
    $cutoff = (Get-Date).AddHours(-1 * [double]$Target.MinAgeHours)
    foreach ($p in $Target.Paths) {
        if (-not $p -or -not (Test-Path -LiteralPath $p)) { continue }
        $params = @{ LiteralPath = $p; File = $true; Force = $true; ErrorAction = 'SilentlyContinue' }
        if ($Target.Filter) { $params.Filter = $Target.Filter } else { $params.Recurse = $true }
        Get-ChildItem @params | Where-Object { $_.LastWriteTime -lt $cutoff }
    }
}

function Measure-BlobCleanupTarget {
    param($Target)
    if ($Target.Admin -and -not $Blob.IsAdmin) { return @{ Bytes = 0; Count = 0; Note = 'admin required' } }
    if ($Target.Special -eq 'Recycle') {
        try {
            $shell = New-Object -ComObject Shell.Application
            $items = @($shell.Namespace(10).Items())
            $bytes = 0; foreach ($i in $items) { $bytes += [double]$i.Size }
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
            return @{ Bytes = $bytes; Count = $items.Count; Note = '' }
        } catch { return @{ Bytes = 0; Count = 0; Note = 'unavailable' } }
    }
    $m = Get-BlobCleanupFiles $Target | Measure-Object -Property Length -Sum
    return @{ Bytes = [double]$m.Sum; Count = [int]$m.Count; Note = '' }
}

function Invoke-BlobCleanupTarget {
    param($Target)
    if ($Target.Special -eq 'Recycle') {
        $before = Measure-BlobCleanupTarget $Target
        if ($Blob.DryRun) { return @{ Freed = $before.Bytes; Deleted = $before.Count; Failed = 0 } }
        try { Clear-RecycleBin -Force -ErrorAction Stop } catch { }
        $after = Measure-BlobCleanupTarget $Target
        return @{ Freed = $before.Bytes - $after.Bytes; Deleted = $before.Count - $after.Count; Failed = $after.Count }
    }
    $freed = 0; $deleted = 0; $failed = 0
    foreach ($f in @(Get-BlobCleanupFiles $Target)) {
        if ($Blob.DryRun) { $freed += $f.Length; $deleted++; continue }
        try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $freed += $f.Length; $deleted++ } catch { $failed++ }
    }
    if (-not $Blob.DryRun -and -not $Target.Filter) {
        # Remove now-empty sub folders (never the root folder itself).
        foreach ($p in $Target.Paths) {
            if (-not (Test-Path -LiteralPath $p)) { continue }
            Get-ChildItem -LiteralPath $p -Directory -Recurse -Force -ErrorAction SilentlyContinue |
                Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
                    if (-not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1)) {
                        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
        }
    }
    return @{ Freed = $freed; Deleted = $deleted; Failed = $failed }
}

function Get-BlobStorageInfo {
    $lines = @('{Cyan}Storage', '')
    try {
        foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop)) {
            if (-not $d.Size) { continue }
            $used = [double]$d.Size - [double]$d.FreeSpace
            $lines += ('{{White}}{0}  {1}  {{White}}{2} free {{DarkGray}}of {3}  ({4})' -f $d.DeviceID, (Format-BlobBar ($used / $d.Size) 30),
                (Format-BlobSize $d.FreeSpace), (Format-BlobSize $d.Size), $(if ($d.VolumeName) { $d.VolumeName } else { 'Local Disk' }))
        }
    } catch { $lines += "{Red}Could not read drive information: $($_.Exception.Message)" }
    try {
        $lines += ''
        foreach ($pd in (Get-PhysicalDisk -ErrorAction Stop)) {
            $lines += ('{{Gray}}Disk {0}  {{White}}{1}  {{DarkGray}}{2}, {3}, health: {4}' -f $pd.DeviceId, $pd.FriendlyName, $pd.MediaType, (Format-BlobSize $pd.Size), $pd.HealthStatus)
        }
    } catch { }
    $lines += ''
    $lines += '{DarkGray}Tip: Windows Storage Sense can clean temporary files automatically (Settings > System > Storage).'
    return $lines
}

function Show-BlobCleanup {
    $crumb = 'Cleanup'
    $sizes = $null; $pos = -1
    $checked = @{}
    while ($true) {
        if (-not $sizes) {
            Start-BlobWork $crumb
            Write-BlobWork '{Gray}Scanning cleanup locations (read-only)...'
            $sizes = @{}
            foreach ($t in $Blob.CleanupTargets) {
                $sizes[$t.Id] = Measure-BlobCleanupTarget $t
                Write-BlobWork ("{{DarkGray}}  {0,-34} {{White}}{1}" -f $t.Name, (Format-BlobSize $sizes[$t.Id].Bytes))
            }
        }
        $items = @(); $total = 0
        foreach ($t in $Blob.CleanupTargets) {
            $s = $sizes[$t.Id]
            $right = if ($s.Note) { "{Yellow}$($s.Note)" } else { "{White}$((Format-BlobSize $s.Bytes).PadLeft(9)) {DarkGray}$("$($s.Count) items".PadLeft(12))" }
            $isChecked = if ($checked.ContainsKey($t.Id)) { $checked[$t.Id] } else { -not $t.Warn -and -not $s.Note -and $t.Special -ne 'Recycle' }
            if ($isChecked) { $total += $s.Bytes }
            $age = if ($t.MinAgeHours -gt 0) { " Only files older than $($t.MinAgeHours) hours." } else { '' }
            $items += @{ Label = $t.Name; Right = $right; Checked = $isChecked; Target = $t; Disabled = [bool]$s.Note
                         Detail = @($t.Detail + $age, $(if ($t.Paths) { ($t.Paths -join '; ') } else { 'Shell Recycle Bin' })) }
        }
        $items += @{ Header = $true; Label = 'Tools' }
        $items += @{ Label = 'Storage information'; Detail = @('Drive usage, free space and physical disk health.'); Tool = 'storage' }
        $items += @{ Label = 'Open Storage Sense settings'; Detail = @('Windows built-in automatic cleanup.'); Tool = 'sense' }
        $res = Show-BlobMenu -Crumb $crumb -Items $items -MultiSelect -Start $pos -Keys @{ C = 'Clean'; R = 'Rescan' } -Intro @(
            "{White}Cleanup {DarkGray}- estimated total for selected items: {Green}$(Format-BlobSize $total)",
            '{Gray}Space selects, C cleans the selection (with confirmation), R rescans. Deleted files cannot be restored.') `
            -FooterPairs @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Move", 'Space|Select', 'C|Clean', 'R|Rescan', 'Enter|Open tool', 'Esc|Back')
        foreach ($it in $items) { if ($it.Target) { $checked[$it.Target.Id] = [bool]$it.Checked } }
        $pos = $res.Index
        switch ($res.Action) {
            'Back'   { return }
            'Rescan' { $sizes = $null }
            'Select' {
                $it = $items[$res.Index]
                if ($it.Tool -eq 'storage') { $null = Show-BlobText -Crumb 'Cleanup > Storage' -Lines (Get-BlobStorageInfo) }
                elseif ($it.Tool -eq 'sense') { Start-Process 'ms-settings:storagesense' -ErrorAction SilentlyContinue }
                else { $checked[$it.Target.Id] = -not $checked[$it.Target.Id] }
            }
            'Clean' {
                $sel = @($items | Where-Object { $_.Checked -and $_.Target -and -not $_.Disabled } | ForEach-Object { $_.Target })
                if ($sel.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Title 'Nothing selected' -Lines @('{Gray}Select locations with Space first.'); continue }
                $lines = @($sel | ForEach-Object { ("{{White}}{0,-36} {{Green}}{1}" -f $_.Name, (Format-BlobSize $sizes[$_.Id].Bytes)) })
                $lines += ''; $lines += '{Yellow}Files are permanently deleted (not moved to the Recycle Bin) and cannot be restored.'
                $lines += '{Gray}Files that are in use are skipped automatically.'
                $danger = @($sel | Where-Object { $_.Warn -or $_.Special }).Count -gt 0
                if (-not (Confirm-BlobAction -Crumb $crumb -Question 'Delete these files?' -Lines $lines -Danger:$danger)) { continue }
                Start-BlobWork $crumb
                $sum = 0
                foreach ($t in $sel) {
                    Write-BlobWork "{Cyan}$($Blob.Ch.On) {White}$($t.Name)"
                    $r = Invoke-BlobCleanupTarget $t
                    $sum += $r.Freed
                    Write-BlobWork ("{{Green}}   freed {0}  {{DarkGray}}{1} files removed, {2} in use / skipped" -f (Format-BlobSize $r.Freed), $r.Deleted, $r.Failed)
                    Add-BlobActionRecord -Source 'cleanup' -Label "Cleanup: $($t.Name)" -Target ($t.Paths -join '; ') -Detail ("freed {0}, {1} files" -f (Format-BlobSize $r.Freed), $r.Deleted)
                }
                $verb = if ($Blob.DryRun) { 'Dry run - would free' } else { 'Total freed:' }
                Complete-BlobWork "$verb $(Format-BlobSize $sum)"
                $sizes = $null
            }
        }
    }
}
