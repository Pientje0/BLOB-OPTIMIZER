# ============================================================================
#  BLOB OPTIMIZER - Restore.ps1
#  Change history, individual / session restore, registry snapshots,
#  System Restore points and configuration export / import (JSON).
# ============================================================================

function Format-BlobStatus {
    param([string]$Status)
    switch ($Status) {
        'Applied'  { '{Green}APPLIED ' }
        'Restored' { '{Cyan}RESTORED' }
        'Failed'   { '{Red}FAILED  ' }
        default    { "{DarkGray}$($Status.ToUpper().PadRight(8))" }
    }
}

function Get-BlobChangeDetail {
    param($R)
    $d = $R.Data
    $lines = @("{White}$($R.Label)", '',
        "{Gray}Target      {White}$($R.Target)",
        "{Gray}Kind        {White}$($R.Kind)",
        "{Gray}Status      $(Format-BlobStatus $R.Status)",
        "{Gray}Time        {White}$($R.Time)  {DarkGray}session $($R.SessionId)",
        "{Gray}Source      {White}$($R.Source)",
        "{Gray}Reversible  $(if ($R.Reversible) { '{Green}yes' } else { '{Yellow}no - this operation cannot be undone' })")
    switch ($R.Kind) {
        'Registry' {
            $lines += "{Gray}Original    {White}$(Format-BlobValue $d.OldValue $d.OldExists) {DarkGray}$($d.OldKind)"
            $lines += "{Gray}Changed to  {White}$(if ($d.Delete) { '(removed)' } else { Format-BlobValue $d.NewValue })"
        }
        'Service'      { $lines += "{Gray}Original    {White}$($d.Old)"; $lines += "{Gray}Changed to  {White}$($d.New)" }
        'PowerPlan'    { $lines += "{Gray}Original    {White}$($d.OldName) {DarkGray}$($d.OldGuid)" }
        'PowerTimeout' { $lines += "{Gray}Original    {White}$(Format-BlobMinutes $d.Old)"; $lines += "{Gray}Changed to  {White}$(Format-BlobMinutes $d.New)" }
        'Hibernate'    { $lines += "{Gray}Original    {White}$(if ($d.Old) { 'On' } else { 'Off' })" }
        'Dns'          { $lines += "{Gray}Original    {White}$(if ($d.OldStatic) { @($d.OldServers) -join ', ' } else { 'automatic (DHCP)' })" }
        'RegKeyDelete' { $lines += "{Gray}Backup      {White}$($d.BackupFile)"; $lines += '{Gray}Restoring imports this .reg file, putting the whole key back.' }
        'Action'       { if ($d.Detail) { $lines += "{Gray}Detail      {White}$($d.Detail)" } }
    }
    if ($R.Error) { $lines += "{Red}Error       $($R.Error)" }
    if ($R.RestoredAt) { $lines += "{Gray}Restored at {White}$($R.RestoredAt)" }
    return $lines
}

function Show-BlobHistory {
    $crumb = 'Restore > History'
    $pos = -1
    while ($true) {
        $recs = @($Blob.Changes.ToArray())
        [array]::Reverse($recs)
        if ($recs.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Title 'No changes recorded yet' -Lines @('{Gray}Changes made by BLOB OPTIMIZER will appear here.'); return }
        $items = @($recs | ForEach-Object {
                $rev = if ($_.Reversible) { '' } else { ' {DarkGray}one-way' }
                @{ Label = $_.Label; Right = "$(Format-BlobStatus $_.Status) {DarkGray}$($_.Time)$rev"; Detail = @($_.Target, "$($_.Kind) - Enter for details, R to restore selected."); Rec = $_ } })
        $applied = @($recs | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible }).Count
        $res = Show-BlobMenu -Crumb $crumb -Items $items -MultiSelect -Start $pos -Keys @{ R = 'Restore' } -Intro @(
            "{White}Change history {DarkGray}($($recs.Count) records, $applied restorable)", '{Gray}Newest first. Space selects, R restores the selection to the original values.') `
            -FooterPairs @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Move", 'Space|Select', 'R|Restore', 'Enter|Details', 'Esc|Back')
        if ($res.Action -eq 'Back') { return }
        $pos = $res.Index
        $sel = @($items | Where-Object { $_.Checked } | ForEach-Object { $_.Rec })
        if ($res.Action -eq 'Select') {
            $rec = $items[$res.Index].Rec
            $k = Show-BlobText -Crumb "$crumb > Details" -Lines (Get-BlobChangeDetail $rec) -Keys @{ R = 'Restore' } -FooterPairs @('R|Restore this', 'Esc|Back')
            if ($k -ne 'Restore') { continue }
            $sel = @($rec)
        } elseif ($sel.Count -eq 0) { $sel = @($items[$res.Index].Rec) }
        $ok = @($sel | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible })
        $skip = $sel.Count - $ok.Count
        if ($ok.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Kind Warning -Title 'Nothing restorable selected' -Lines @('{Gray}Selected records are already restored, failed, or one-way operations.'); continue }
        $lines = @($ok | ForEach-Object { "{Gray}$($_.Target)" })
        if ($skip -gt 0) { $lines += ''; $lines += "{Yellow}$skip selected record(s) cannot be restored and will be skipped." }
        if (Confirm-BlobAction -Crumb $crumb -Question "Restore $($ok.Count) original value(s)?" -Lines $lines) { Invoke-BlobRestoreRecords -Records $ok -Crumb $crumb }
    }
}

function Show-BlobSessionRestore {
    $crumb = 'Restore > Sessions'
    $groups = @($Blob.Changes | Group-Object SessionId | Sort-Object Name -Descending)
    $items = @()
    foreach ($g in $groups) {
        $restorable = @($g.Group | Where-Object { $_.Status -eq 'Applied' -and $_.Reversible })
        $items += @{ Label = "Session $($g.Name)"; Right = "{White}$($restorable.Count) {DarkGray}restorable / $($g.Count) records"; Recs = $restorable
                     Detail = @((@($g.Group | Select-Object -First 3 | ForEach-Object { $_.Label }) -join ', ')) }
    }
    if ($items.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Title 'No sessions recorded yet'; return }
    $r = Show-BlobMenu -Crumb $crumb -Items $items -Intro @('{White}Undo a whole session', '{Gray}Restores every restorable change made during the chosen session, newest first.')
    if ($r.Action -ne 'Select') { return }
    $recs = $items[$r.Index].Recs
    if ($recs.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Title 'Nothing left to restore in this session'; return }
    if (Confirm-BlobAction -Crumb $crumb -Question "Restore all $($recs.Count) changes from this session?" -Lines @($recs | ForEach-Object { "{Gray}$($_.Target)" })) {
        Invoke-BlobRestoreRecords -Records $recs -Crumb $crumb
    }
}

function Show-BlobRegSnapshots {
    $crumb = 'Restore > Registry snapshots'
    if (-not (Test-Path -LiteralPath $Blob.RegBackupDir)) { Show-BlobNotice -Crumb $crumb -Title 'No registry snapshots yet' -Lines @('{Gray}A snapshot is exported automatically before each batch of tweaks.'); return }
    $dirs = @(Get-ChildItem -LiteralPath $Blob.RegBackupDir -Directory | Sort-Object Name -Descending)
    if ($dirs.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Title 'No registry snapshots yet'; return }
    $items = @($dirs | ForEach-Object { $n = @(Get-ChildItem -LiteralPath $_.FullName -Filter *.reg).Count; @{ Label = $_.Name; Right = "{Gray}$n keys"; Dir = $_ } })
    $r = Show-BlobMenu -Crumb $crumb -Items $items -Intro @('{White}Registry snapshots (.reg exports)',
        '{Gray}Prefer History for precise per-setting restore. Importing a snapshot re-applies the whole keys.')
    if ($r.Action -ne 'Select') { return }
    $dir = $items[$r.Index].Dir
    $files = @(Get-ChildItem -LiteralPath $dir.FullName -Filter *.reg | Sort-Object Name)
    $lines = @()
    foreach ($f in $files) {
        $key = (Get-Content -LiteralPath $f.FullName -TotalCount 5 | Where-Object { $_ -match '^\[' } | Select-Object -First 1)
        $lines += "{Gray}$($f.Name)  {White}$key"
    }
    $lines += ''; $lines += '{Yellow}Importing writes every value from these files back into the registry.'
    $lines += '{Gray}Values created after the snapshot are not removed. Machine-wide keys need administrator rights.'
    $lines += "{DarkGray}Folder: $($dir.FullName)"
    if (-not (Confirm-BlobAction -Crumb $crumb -Question 'Import this registry snapshot?' -Lines $lines -Danger)) { return }
    Start-BlobWork $crumb
    foreach ($f in $files) {
        if ($Blob.DryRun) { Write-BlobWork "{Magenta} DRY  {White}$($f.Name)"; continue }
        $out = & reg.exe import $f.FullName 2>&1
        if ($LASTEXITCODE -eq 0) { Write-BlobWork "{Green} OK   {White}$($f.Name)" } else { Write-BlobWork "{Red} FAIL {White}$($f.Name) {Gray}$(("$out" -replace '[{}]', '').Trim())" }
    }
    Add-BlobActionRecord -Source 'restore' -Label 'Imported registry snapshot' -Target $dir.FullName
    Complete-BlobWork 'Snapshot import finished. Sign out or restart for all settings to apply.'
}

function Get-BlobRestorePointCount {
    try { return @(Get-CimInstance -Namespace 'root/default' -ClassName 'SystemRestore' -ErrorAction Stop).Count } catch { return -1 }
}

# Creates a System Restore point and reports honestly whether Windows made one.
function New-BlobRestorePoint {
    param([string]$Description = 'BLOB OPTIMIZER')
    if (-not $Blob.IsAdmin) { return '{Yellow} SKIP {White}Restore point {Gray}(administrator rights required)' }
    if ($Blob.DryRun) { return '{Magenta} DRY  {White}Restore point not created (dry run)' }
    $before = Get-BlobRestorePointCount
    try {
        $r = Invoke-CimMethod -Namespace 'root/default' -ClassName 'SystemRestore' -MethodName 'CreateRestorePoint' -ErrorAction Stop `
            -Arguments @{ Description = $Description; RestorePointType = [uint32]12; EventType = [uint32]100 }
        if ($r.ReturnValue -ne 0) {
            return "{Yellow} SKIP {White}Restore point not created {Gray}(Windows returned $($r.ReturnValue) - System Protection may be off for the system drive)"
        }
        $after = Get-BlobRestorePointCount
        if ($before -ge 0 -and $after -le $before) {
            return '{Yellow} SKIP {White}Windows did not create a new restore point {Gray}(one was already made in the last 24 hours - that one still protects you)'
        }
        Add-BlobActionRecord -Source 'restore' -Label 'Created System Restore point' -Target $Description
        return "{Green} OK   {White}System Restore point created {Gray}('$Description')"
    } catch { return "{Red} FAIL {White}Restore point {Gray}($($_.Exception.Message -replace '[{}]', '') - is System Protection enabled?)" }
}

function Export-BlobConfig {
    $crumb = 'Restore > Export'
    $applied = @($Blob.Tweaks | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' } | ForEach-Object { $_.Id })
    $default = Join-Path ([Environment]::GetFolderPath('MyDocuments')) ("BLOB-config-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
    $path = Read-BlobInput -Crumb $crumb -Default $default -Prompt @('{White}Export configuration',
        "{Gray}Saves the $($applied.Count) currently applied BLOB OPTIMIZER tweaks to a JSON file you can import on another PC.",
        '{Gray}No personal data, hostnames or user names are included.') -Validate {
        param($v) if (-not $v) { return 'Enter a file path.' }; if ($v -notmatch '\.json$') { return 'The file name must end in .json' }
        $dir = Split-Path -Path $v -Parent; if ($dir -and -not (Test-Path -LiteralPath $dir)) { return 'That folder does not exist.' }; return $null }
    if (-not $path) { return }
    $obj = [ordered]@{ tool = 'BLOB OPTIMIZER'; format = 1; version = $Blob.Version; exported = (Get-Date).ToString('s'); tweaks = $applied }
    try {
        [IO.File]::WriteAllText($path, (ConvertTo-Json -InputObject $obj -Depth 4), (New-Object Text.UTF8Encoding($false)))
        Show-BlobNotice -Crumb $crumb -Kind Success -Title 'Configuration exported' -Lines @("{White}$path", "{Gray}$($applied.Count) tweak(s) saved.")
    } catch { Show-BlobNotice -Crumb $crumb -Kind Error -Title 'Export failed' -Lines @("{Gray}$($_.Exception.Message)") }
}

function Import-BlobConfig {
    $crumb = 'Restore > Import'
    $path = Read-BlobInput -Crumb $crumb -Prompt @('{White}Import configuration', '{Gray}Path to a JSON file exported by BLOB OPTIMIZER.',
        '{Gray}You will see every setting before anything is applied.') -Validate {
        param($v) if (-not $v) { return 'Enter a file path.' }; if (-not (Test-Path -LiteralPath $v -PathType Leaf)) { return 'File not found.' }; return $null }
    if (-not $path) { return }
    try {
        $cfg = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($cfg.tool -ne 'BLOB OPTIMIZER' -or -not $cfg.tweaks) { throw 'This is not a BLOB OPTIMIZER configuration file.' }
    } catch { Show-BlobNotice -Crumb $crumb -Kind Error -Title 'Cannot read configuration' -Lines @("{Gray}$($_.Exception.Message -replace '[{}]', '')"); return }
    $ids = @($cfg.tweaks | ForEach-Object { [string]$_ })
    $known = @($ids | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
    $unknown = @($ids | Where-Object { -not (Get-BlobTweak $_) })
    if ($unknown.Count -gt 0) { Show-BlobNotice -Crumb $crumb -Kind Warning -Title "$($unknown.Count) unknown setting(s) will be ignored" -Lines @($unknown | ForEach-Object { "{Gray}$_" }) }
    Invoke-BlobTweakSet -Tweaks $known -Crumb $crumb -Tag 'import'
}

function Show-BlobRestore {
    while ($true) {
        $restorable = @(Get-BlobAppliedChanges).Count
        $res = Show-BlobMenu -Crumb 'Restore' -Intro @('{White}Restore and backups',
            "{Gray}Journal: {White}$($Blob.JournalPath) {DarkGray}($restorable restorable change(s))") -Items @(
            @{ Header = $true; Label = 'Undo changes' }
            @{ Label = 'Change history'; Right = "{White}$($Blob.Changes.Count)"; Detail = @('Every recorded change. Restore individual settings to their original values.') }
            @{ Label = 'Undo a whole session'; Detail = @('Restore all changes made during one run of BLOB OPTIMIZER.') }
            @{ Label = 'Registry snapshots'; Detail = @('.reg exports taken automatically before each batch of tweaks.') }
            @{ Label = 'Create System Restore point'; Right = '{Yellow}admin'; Detail = @('Windows-level safety net covering system files and registry.') }
            @{ Header = $true; Label = 'Configuration' }
            @{ Label = 'Export configuration (JSON)'; Detail = @('Save the list of applied tweaks to a JSON file.') }
            @{ Label = 'Import configuration (JSON)'; Detail = @('Apply tweaks from an exported file, with full preview.') }
            @{ Label = 'Open backup and log folder'; Detail = @("$($Blob.DataRoot)") }
        )
        if ($res.Action -ne 'Select') { return }
        switch ($res.Index) {
            1 { Show-BlobHistory }
            2 { Show-BlobSessionRestore }
            3 { Show-BlobRegSnapshots }
            4 {
                if (-not $Blob.IsAdmin) { Show-BlobAdminRequired 'Restore' 'Creating a System Restore point is a machine-wide operation.'; continue }
                if (Confirm-BlobAction -Crumb 'Restore' -Question 'Create a System Restore point now?' -Lines @('{Gray}This can take a minute. System Protection must be enabled for drive C:.')) {
                    Start-BlobWork 'Restore'; Write-BlobWork '{Gray}Creating restore point...'; Write-BlobWork (New-BlobRestorePoint 'BLOB OPTIMIZER manual restore point'); Complete-BlobWork 'Done.'
                }
            }
            6 { Export-BlobConfig }
            7 { Import-BlobConfig }
            8 {
                if (Test-Path -LiteralPath $Blob.DataRoot) { Start-Process explorer.exe -ArgumentList "`"$($Blob.DataRoot)`"" }
                else { Show-BlobNotice -Crumb 'Restore' -Title 'No files yet' -Lines @('{Gray}The folder is created when the first change is made.', "{DarkGray}$($Blob.DataRoot)") }
            }
        }
    }
}
