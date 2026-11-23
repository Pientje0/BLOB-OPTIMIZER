# ============================================================================
#  BLOB OPTIMIZER - Startup.ps1
#  Startup programs. Entries are disabled the same way Task Manager does it
#  (StartupApproved flags), so nothing is deleted and every change can be
#  undone - either here, in Task Manager, or from the Restore section.
# ============================================================================

$Blob.StartupSources = @(
    @{ Scope = 'User'; Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
       Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' },
    @{ Scope = 'All users'; Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
       Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' },
    @{ Scope = 'All users (32-bit)'; Key = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
       Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' },
    @{ Scope = 'User folder'; Folder = 'Startup'
       Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' },
    @{ Scope = 'All users folder'; Folder = 'CommonStartup'
       Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' }
)

function Get-BlobStartupEntries {
    $list = New-Object System.Collections.ArrayList
    foreach ($src in $Blob.StartupSources) {
        $entries = @()
        if ($src.Key) {
            try {
                $key = Get-Item -LiteralPath $src.Key -ErrorAction Stop
                foreach ($n in $key.GetValueNames()) {
                    if (-not $n) { continue }
                    $entries += @{ Name = $n; Command = [string]$key.GetValue($n, '', 'DoNotExpandEnvironmentNames'); Location = Format-BlobRegPath $src.Key }
                }
            } catch { }
        } else {
            $dir = [Environment]::GetFolderPath($src.Folder)
            if ($dir -and (Test-Path -LiteralPath $dir)) {
                Get-ChildItem -LiteralPath $dir -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
                    $entries += @{ Name = $_.Name; Command = $_.FullName; Location = $dir }
                }
            }
        }
        foreach ($e in $entries) {
            $state = Get-BlobRegState $src.Approved $e.Name
            $enabled = $true
            if ($state.Exists -and $state.Value -is [byte[]] -and $state.Value.Length -gt 0) { $enabled = ($state.Value[0] % 2) -eq 0 }
            [void]$list.Add(@{ Name = $e.Name; Command = $e.Command; Location = $e.Location; Scope = $src.Scope
                               Approved = $src.Approved; Enabled = $enabled; Admin = (Test-BlobNeedsAdmin $src.Approved) })
        }
    }
    return $list.ToArray()
}

function Set-BlobStartupEntry {
    param($Entry, [bool]$Enable)
    if ($Enable) { $bytes = @(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) }
    else { $bytes = @(3, 0, 0, 0) + @([BitConverter]::GetBytes((Get-Date).ToFileTime()) | ForEach-Object { [int]$_ }) }
    $verb = if ($Enable) { 'Enable' } else { 'Disable' }
    return Set-BlobRegValue -Path $Entry.Approved -Name $Entry.Name -Value $bytes -Type 'Binary' `
        -Source ("startup:" + $Entry.Approved + '|' + $Entry.Name) -Label "$verb startup entry '$($Entry.Name)'"
}

function Invoke-BlobStartupToggle {
    param([array]$Entries, [bool]$Enable, [string]$Crumb)
    $targets = @($Entries | Where-Object { $_.Enabled -ne $Enable })
    $verb = if ($Enable) { 'Enable' } else { 'Disable' }
    if ($targets.Count -eq 0) { Show-BlobNotice -Crumb $Crumb -Title "Nothing to $($verb.ToLower())" -Lines @('{Gray}The selected entries are already in that state.'); return }
    $needAdmin = @($targets | Where-Object { $_.Admin }).Count -gt 0
    if ($needAdmin -and -not $Blob.IsAdmin) {
        Show-BlobAdminRequired $Crumb 'Some selected entries start for all users and are stored in machine-wide settings.'
        $targets = @($targets | Where-Object { -not $_.Admin })
        if ($targets.Count -eq 0) { return }
    }
    $lines = @($targets | ForEach-Object { "{White}$($_.Name)  {DarkGray}[$($_.Scope)]"; "{DarkGray}    $($_.Command)" })
    $lines += ''; $lines += '{Gray}Programs are not deleted or uninstalled. Original flags are saved and can be restored.'
    if (-not (Confirm-BlobAction -Crumb $Crumb -Question "$verb $($targets.Count) startup entr$(if ($targets.Count -eq 1) { 'y' } else { 'ies' })?" -Lines $lines)) { return }
    Start-BlobWork $Crumb
    foreach ($t in $targets) { Write-BlobWork (Format-BlobResult (Set-BlobStartupEntry $t $Enable)) }
    Complete-BlobWork 'Changes take effect at the next sign-in.'
}

function Show-BlobStartup {
    $crumb = 'Startup'
    $pos = -1
    while ($true) {
        $entries = @(Get-BlobStartupEntries | Sort-Object { $_.Scope }, { $_.Name })
        $items = @(); $lastScope = $null
        foreach ($e in $entries) {
            if ($e.Scope -ne $lastScope) { $items += @{ Header = $true; Label = $e.Scope }; $lastScope = $e.Scope }
            $st = if ($e.Enabled) { '{Green}ENABLED ' } else { '{DarkGray}DISABLED' }
            $hasBackup = @(Get-BlobAppliedChanges -Source ("startup:" + $e.Approved + '|' + $e.Name)).Count -gt 0
            $right = $st + $(if ($hasBackup) { ' {Cyan}*' } else { '  ' })
            $items += @{ Label = $e.Name; Right = $right; Detail = @($e.Command, "Location: $($e.Location)"); Entry = $e }
        }
        $enabledCount = @($entries | Where-Object { $_.Enabled }).Count
        $intro = @("{White}Startup programs {DarkGray}($enabledCount of $($entries.Count) enabled)",
            '{Gray}D disables, E enables, U restores the original state. {Cyan}*{Gray} = original saved by BLOB OPTIMIZER.')
        if ($items.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Title 'No startup programs found' -Lines @('{Gray}Nothing is configured to start automatically.'); return }
        $res = Show-BlobMenu -Crumb $crumb -Items $items -Intro $intro -MultiSelect -Start $pos -Keys @{ D = 'Disable'; E = 'Enable'; U = 'Undo'; T = 'TaskMgr' } `
            -FooterPairs @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Move", 'Space|Select', 'D|Disable', 'E|Enable', 'U|Restore', 'T|Task Manager', 'Esc|Back')
        if ($res.Action -eq 'Back') { return }
        $pos = $res.Index
        $sel = @($items | Where-Object { $_.Checked -and $_.Entry } | ForEach-Object { $_.Entry })
        if ($sel.Count -eq 0 -and $res.Index -ge 0 -and $items[$res.Index].Entry) { $sel = @($items[$res.Index].Entry) }
        switch ($res.Action) {
            'Disable' { Invoke-BlobStartupToggle $sel $false $crumb }
            'Enable'  { Invoke-BlobStartupToggle $sel $true $crumb }
            'TaskMgr' { Start-Process 'taskmgr.exe' -ArgumentList '/7 /startup' -ErrorAction SilentlyContinue }
            'Undo' {
                $recs = @($sel | ForEach-Object { Get-BlobAppliedChanges -Source ("startup:" + $_.Approved + '|' + $_.Name) })
                if ($recs.Count -eq 0) { Show-BlobNotice -Crumb $crumb -Kind Warning -Title 'No saved original' -Lines @('{Gray}BLOB OPTIMIZER has not changed the selected entries, so there is nothing to restore.') }
                elseif (Confirm-BlobAction -Crumb $crumb -Question "Restore the original state of $($sel.Count) entr$(if ($sel.Count -eq 1) { 'y' } else { 'ies' })?" -Lines @($recs | ForEach-Object { "{Gray}$($_.Target)" })) {
                    Invoke-BlobRestoreRecords -Records $recs -Crumb $crumb
                }
            }
            'Select' {
                $e = $items[$res.Index].Entry
                $r = Show-BlobText -Crumb "$crumb $($Blob.Ch.Arrow) $($e.Name)" -Keys @{ D = 'Disable'; E = 'Enable' } -FooterPairs @('D|Disable', 'E|Enable', 'Esc|Back') -Lines @(
                    "{White}$($e.Name)", '',
                    "{Gray}Status     $(if ($e.Enabled) { '{Green}Enabled' } else { '{DarkGray}Disabled' })",
                    "{Gray}Scope      {White}$($e.Scope)",
                    "{Gray}Location   {White}$($e.Location)",
                    "{Gray}Command    {White}$($e.Command)", '',
                    '{DarkGray}Disabling only stops automatic launch at sign-in; the program stays installed.')
                if ($r -eq 'Disable') { Invoke-BlobStartupToggle @($e) $false $crumb }
                if ($r -eq 'Enable')  { Invoke-BlobStartupToggle @($e) $true $crumb }
            }
        }
    }
}
