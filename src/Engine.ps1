# ============================================================================
#  BLOB OPTIMIZER - Engine.ps1
#  Tweak catalogue, state detection, preview, apply / undo and presets.
#
#  A tweak is a declarative hashtable:
#    Id, Section, Group, Name, Description, Risk (Minimal|Standard|Advanced|Optional)
#    Registry = @( @{ Path; Name; Value; Type = 'DWord'; Delete = $false } )
#    Services = @( @{ Name; Startup } )
#    Note, Warning, RestartExplorer
#  'Optional' tweaks are personal preferences and are never part of a preset.
# ============================================================================

function Register-BlobTweak {
    param([hashtable]$Tweak)
    foreach ($k in @('Group', 'Note', 'Warning')) { if (-not $Tweak.ContainsKey($k)) { $Tweak[$k] = '' } }
    if (-not $Tweak.Risk)     { $Tweak.Risk = 'Standard' }
    if (-not $Tweak.Registry) { $Tweak.Registry = @() }
    if (-not $Tweak.Services) { $Tweak.Services = @() }
    foreach ($op in $Tweak.Registry) { if (-not $op.Type) { $op.Type = 'DWord' } }
    $Tweak.Admin = (@($Tweak.Registry | Where-Object { Test-BlobNeedsAdmin $_.Path }).Count -gt 0) -or ($Tweak.Services.Count -gt 0)
    [void]$Blob.Tweaks.Add($Tweak)
}

function Get-BlobTweak { param([string]$Id) return ($Blob.Tweaks | Where-Object { $_.Id -eq $Id } | Select-Object -First 1) }

function Get-BlobTweakState {
    param($Tweak)
    $total = 0; $match = 0
    foreach ($op in $Tweak.Registry) {
        $total++
        $s = Get-BlobRegState $op.Path $op.Name
        if ($op.Delete) { if (-not $s.Exists) { $match++ } }
        elseif ($s.Exists -and (Test-BlobValueEqual (ConvertTo-BlobJsonValue $s.Value) $op.Value)) { $match++ }
    }
    foreach ($sv in $Tweak.Services) {
        $cur = Get-BlobServiceStartup $sv.Name
        if (-not $cur) { continue }
        $total++
        if ($cur -eq $sv.Startup) { $match++ }
    }
    if ($total -eq 0) { return 'N/A' }
    if ($match -eq $total) { return 'Applied' }
    if ($match -eq 0) { return 'Default' }
    return 'Partial'
}

function Format-BlobState {
    param([string]$State)
    switch ($State) {
        'Applied' { '{Green}APPLIED' }
        'Partial' { '{Yellow}PARTIAL' }
        'Default' { '{DarkGray}NOT SET' }
        default   { '{DarkGray}N/A' }
    }
}

function Format-BlobRisk {
    param([string]$Risk)
    $r = $Blob.RiskInfo[$Risk]
    if (-not $r) { return '{Gray}' + $Risk.ToUpper() }
    return "{$($r.Color)}" + $r.Label.PadRight(11)
}

# Lines describing exactly what applying the given tweaks will change.
function Get-BlobTweakPreview {
    param([array]$Tweaks)
    $lines = New-Object System.Collections.ArrayList
    foreach ($t in $Tweaks) {
        [void]$lines.Add("{Cyan}$($Blob.Ch.On) {White}$($t.Name)  $(Format-BlobRisk $t.Risk)")
        if ($t.Admin -and -not $Blob.IsAdmin) { [void]$lines.Add('{Yellow}    Requires administrator rights - machine-wide parts will be skipped.') }
        foreach ($op in $t.Registry) {
            $s = Get-BlobRegState $op.Path $op.Name
            $old = Format-BlobValue $s.Value $s.Exists
            $new = if ($op.Delete) { '(removed)' } else { Format-BlobValue $op.Value }
            $same = if ($op.Delete) { -not $s.Exists } else { $s.Exists -and (Test-BlobValueEqual (ConvertTo-BlobJsonValue $s.Value) $op.Value) }
            $suffix = if ($same) { '  {DarkGray}(already set)' } else { '' }
            [void]$lines.Add("{Gray}    $(Format-BlobRegPath $op.Path $op.Name)")
            [void]$lines.Add("{DarkGray}        $old {White}-> {Green}$new$suffix")
        }
        foreach ($sv in $t.Services) {
            $cur = Get-BlobServiceStartup $sv.Name
            if (-not $cur) { [void]$lines.Add("{DarkGray}    Service $($sv.Name): not present, skipped"); continue }
            [void]$lines.Add("{Gray}    Service $($sv.Name) startup type")
            [void]$lines.Add("{DarkGray}        $cur {White}-> {Green}$($sv.Startup)")
        }
        if ($t.Warning) { [void]$lines.Add("{Yellow}    ! $($t.Warning)") }
        if ($t.Note)    { [void]$lines.Add("{DarkGray}    Note: $($t.Note)") }
        [void]$lines.Add('')
    }
    [void]$lines.Add('{Gray}Every original value is saved to the change journal before it is modified,')
    [void]$lines.Add('{Gray}and the affected registry keys are exported to .reg files first.')
    return $lines.ToArray()
}

function Invoke-BlobTweakSet {
    param([array]$Tweaks, [string]$Crumb, [string]$Tag = 'tweaks', [switch]$SkipConfirm)
    $Tweaks = @($Tweaks | Where-Object { $_ })
    if ($Tweaks.Count -eq 0) { Show-BlobNotice -Crumb $Crumb -Title 'Nothing selected' -Lines @('{Gray}Use Space to select items first.'); return }
    if (-not $SkipConfirm) {
        $danger = @($Tweaks | Where-Object { $_.Risk -eq 'Advanced' }).Count -gt 0
        $q = 'Apply {0} optimization(s)? These exact settings will change:' -f $Tweaks.Count
        if (-not (Confirm-BlobAction -Crumb $Crumb -Question $q -Lines (Get-BlobTweakPreview $Tweaks) -Danger:$danger)) { return }
    }
    Start-BlobWork $Crumb
    $outcome = Invoke-BlobTweakCore -Tweaks $Tweaks -Tag $Tag -Log { param($m) Write-BlobWork $m }
    Complete-BlobWork $outcome.Summary
    if ($outcome.NeedsExplorer) { Request-BlobExplorerRestart $Crumb }
}

# UI-agnostic apply loop shared by the terminal UI and the window UI.
# -Log receives one colour-tagged line at a time.
function Invoke-BlobTweakCore {
    param([array]$Tweaks, [string]$Tag = 'tweaks', [scriptblock]$Log = { param($m) })
    $snap = Backup-BlobRegistryKeys -Paths @($Tweaks | ForEach-Object { $_.Registry } | ForEach-Object { $_.Path }) -Tag $Tag
    if ($snap) { & $Log "{DarkGray}Registry snapshot saved to $snap" }
    $count = @{ ok = 0; same = 0; skip = 0; fail = 0; dry = 0 }
    foreach ($t in $Tweaks) {
        & $Log "{Cyan}$($Blob.Ch.On) {White}$($t.Name)"
        $results = @()
        foreach ($op in $t.Registry) {
            if ($op.Delete) { $results += Set-BlobRegValue -Path $op.Path -Name $op.Name -Delete -Source $t.Id -Label $t.Name }
            else { $results += Set-BlobRegValue -Path $op.Path -Name $op.Name -Value $op.Value -Type $op.Type -Source $t.Id -Label $t.Name }
        }
        foreach ($sv in $t.Services) { $results += Set-BlobServiceStartup -Name $sv.Name -StartupType $sv.Startup -Source $t.Id -Label $t.Name }
        foreach ($r in $results) {
            & $Log ('   ' + (Format-BlobResult $r))
            switch ($r.Status) { 'Applied' { $count.ok++ } 'Unchanged' { $count.same++ } 'Skipped' { $count.skip++ } 'DryRun' { $count.dry++ } default { $count.fail++ } }
        }
    }
    $summary = "Done: {0} changed, {1} already set, {2} skipped, {3} failed." -f $count.ok, $count.same, $count.skip, $count.fail
    if ($Blob.DryRun) { $summary = "Dry run: {0} setting(s) would change. Nothing was modified." -f $count.dry }
    if ($count.ok -gt 0) { & $Log '{Gray}Some settings apply after Explorer restarts, you sign out, or the PC restarts.' }
    return @{ Count = $count; Summary = $summary
              NeedsExplorer = ($count.ok -gt 0 -and @($Tweaks | Where-Object { $_.RestartExplorer }).Count -gt 0) }
}

function Restart-BlobExplorer {
    if ($Blob.DryRun) { return }
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1500
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Write-BlobLog 'Explorer restarted by user request.'
}

function Request-BlobExplorerRestart {
    param([string]$Crumb)
    $ok = Confirm-BlobAction -Crumb $Crumb -Question 'Restart Windows Explorer now so the changes appear?' -Lines @(
        '{Gray}The taskbar and open File Explorer windows will close and reopen.',
        '{Gray}Nothing else is affected. Press N to restart later (or sign out).')
    if ($ok) { Restart-BlobExplorer }
}

# Lists what undoing the given tweaks would restore. UI-agnostic.
function Get-BlobUndoPlan {
    param([array]$Tweaks)
    $plan = New-Object System.Collections.ArrayList
    $lines = New-Object System.Collections.ArrayList
    foreach ($t in @($Tweaks | Where-Object { $_ })) {
        $recs = @(Get-BlobAppliedChanges -Source $t.Id)
        [void]$lines.Add("{Cyan}$($Blob.Ch.On) {White}$($t.Name)")
        if ($recs.Count -eq 0) {
            [void]$lines.Add('{Yellow}    No backup recorded by BLOB OPTIMIZER - cannot reliably restore.')
            [void]$lines.Add('{DarkGray}    (The setting may have been changed by Windows or another tool.)')
            continue
        }
        foreach ($r in $recs) {
            $orig = if ($r.Kind -eq 'Service') { $r.Data.Old } else { Format-BlobValue $r.Data.OldValue $r.Data.OldExists }
            [void]$lines.Add("{Gray}    $($r.Target) {White}-> {Green}$orig")
            [void]$plan.Add($r)
        }
    }
    return @{ Records = $plan.ToArray(); Lines = $lines.ToArray() }
}

# Restores records newest-first. UI-agnostic; returns @(ok, failed).
function Invoke-BlobRestoreCore {
    param([array]$Records, [scriptblock]$Log = { param($m) })
    $ordered = @($Records | Sort-Object { $Blob.Changes.IndexOf($_) } -Descending)
    $ok = 0; $bad = 0
    foreach ($r in $ordered) {
        $res = Restore-BlobChange $r
        & $Log (Format-BlobResult $res)
        if ($res.Status -in @('Restored', 'DryRun')) { $ok++ } else { $bad++ }
    }
    return @($ok, $bad)
}

function Undo-BlobTweakSet {
    param([array]$Tweaks, [string]$Crumb)
    $undo = Get-BlobUndoPlan $Tweaks
    if ($undo.Records.Count -eq 0) { Show-BlobNotice -Crumb $Crumb -Kind Warning -Title 'Nothing to restore' -Lines $undo.Lines; return }
    if (-not (Confirm-BlobAction -Crumb $Crumb -Question 'Restore these original values?' -Lines $undo.Lines)) { return }
    Invoke-BlobRestoreRecords -Records $undo.Records -Crumb $Crumb
}

# Terminal wrapper around Invoke-BlobRestoreCore.
function Invoke-BlobRestoreRecords {
    param([array]$Records, [string]$Crumb)
    Start-BlobWork $Crumb
    $ok, $bad = Invoke-BlobRestoreCore -Records $Records -Log { param($m) Write-BlobWork $m }
    Complete-BlobWork ("Restore finished: {0} restored, {1} not restored." -f $ok, $bad)
}

function Get-BlobTweakDetail {
    param($Tweak)
    $lines = @("{White}$($Tweak.Name)", '')
    $lines += @(Split-BlobText (Get-BlobTweakExplanation $Tweak) | ForEach-Object { "{Gray}$_" })
    $lines += ''
    $lines += @(Split-BlobText $Blob.RiskInfo[$Tweak.Risk].Text | ForEach-Object { "{DarkGray}$_" })
    $lines += @('',
        ("{DarkGray}Risk      $(Format-BlobRisk $Tweak.Risk)"),
        ("{DarkGray}Status    $(Format-BlobState (Get-BlobTweakState $Tweak))"),
        ("{DarkGray}Admin     " + $(if ($Tweak.Admin) { '{Yellow}required' } else { '{Green}not required' })),
        ("{DarkGray}Undo      " + $(if (@(Get-BlobAppliedChanges -Source $Tweak.Id).Count -gt 0) { '{Green}backup available' } else { '{DarkGray}no backup recorded yet' })),
        '', '{Cyan}Settings changed:')
    return $lines + (Get-BlobTweakPreview @($Tweak) | Select-Object -Skip 1)
}

# ---------------------------------------------------------------------------
#  Generic section screen used by Performance, Gaming, Tweaks and Privacy.
#  Extras: @( @{ Label; Detail; Action = { ... } } ) shown under "Tools".
# ---------------------------------------------------------------------------
function Show-BlobTweakSection {
    param([string]$Section, [string]$Crumb, [string[]]$Intro = @(), [array]$Extras = @())
    $pos = -1
    while ($true) {
        $items = New-Object System.Collections.ArrayList
        $tweaks = @($Blob.Tweaks | Where-Object { $_.Section -eq $Section })
        $lastGroup = $null
        foreach ($t in $tweaks) {
            if ($t.Group -ne $lastGroup) { [void]$items.Add(@{ Header = $true; Label = $t.Group }); $lastGroup = $t.Group }
            $detail = @($t.Description)
            $second = @()
            if ($t.Admin) { $second += 'Requires administrator.' }
            if ($t.Warning) { $second += $t.Warning } elseif ($t.Note) { $second += $t.Note }
            $detail += ($second -join ' ')
            [void]$items.Add(@{ Label = $t.Name; Right = "$(Format-BlobRisk $t.Risk)  $(Format-BlobState (Get-BlobTweakState $t))"
                                Detail = $detail; Tweak = $t; Checked = $false })
        }
        if ($Extras.Count -gt 0) {
            [void]$items.Add(@{ Header = $true; Label = 'Tools' })
            foreach ($e in $Extras) { [void]$items.Add(@{ Label = $e.Label; Detail = @($e.Detail); Extra = $e }) }
        }
        $arr = $items.ToArray()
        $res = Show-BlobMenu -Crumb $Crumb -Items $arr -Intro $Intro -MultiSelect -Start $pos `
            -Keys @{ A = 'Apply'; U = 'Undo' } `
            -FooterPairs @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Move", 'Space|Select', 'A|Apply', 'U|Undo', 'Enter|Details', 'Tab|Group', 'Esc|Back')
        $pos = $res.Index
        if ($res.Action -eq 'Back') { return }
        $current = if ($res.Index -ge 0) { $arr[$res.Index] } else { $null }
        $checked = @($arr | Where-Object { $_.Checked -and $_.Tweak } | ForEach-Object { $_.Tweak })
        if ($checked.Count -eq 0 -and $current -and $current.Tweak) { $checked = @($current.Tweak) }
        switch ($res.Action) {
            'Apply' { Invoke-BlobTweakSet -Tweaks $checked -Crumb $Crumb -Tag $Section }
            'Undo'  { Undo-BlobTweakSet -Tweaks $checked -Crumb $Crumb }
            'Select' {
                if ($current.Extra) { & $current.Extra.Action; continue }
                $r = Show-BlobText -Crumb "$Crumb $($Blob.Ch.Arrow) Details" -Lines (Get-BlobTweakDetail $current.Tweak) `
                    -Keys @{ A = 'Apply'; U = 'Undo' } -FooterPairs @('A|Apply this', 'U|Undo this', "$($Blob.Ch.Up)$($Blob.Ch.Down)|Scroll", 'Esc|Back')
                if ($r -eq 'Apply') { Invoke-BlobTweakSet -Tweaks @($current.Tweak) -Crumb $Crumb -Tag $Section }
                if ($r -eq 'Undo')  { Undo-BlobTweakSet -Tweaks @($current.Tweak) -Crumb $Crumb }
            }
        }
    }
}

# ---------------------------------------------------------------------------
#  Presets
# ---------------------------------------------------------------------------
function Get-BlobPresets {
    if ($Blob.Presets) { return $Blob.Presets }
    $json = $Blob.EmbeddedPresets
    if (-not $json -and $Blob.SourceRoot) {
        $f = Join-Path $Blob.SourceRoot 'config\presets.json'
        if (Test-Path -LiteralPath $f) { $json = Get-Content -LiteralPath $f -Raw }
    }
    $list = New-Object System.Collections.ArrayList
    if ($json) {
        try {
            $data = $json | ConvertFrom-Json -ErrorAction Stop
            foreach ($p in $data.presets) {
                [void]$list.Add(@{ Name = $p.name; Description = $p.description; Warning = $p.warning; Ids = @($p.tweaks) })
            }
        } catch { Write-BlobLog "presets.json could not be parsed: $($_.Exception.Message)" 'ERROR' }
    }
    if ($list.Count -eq 0) {
        # Fallback derived from risk levels so the feature never breaks.
        $tiers = [ordered]@{ MINIMAL = @('Minimal'); STANDARD = @('Minimal', 'Standard'); ADVANCED = @('Minimal', 'Standard', 'Advanced') }
        foreach ($n in $tiers.Keys) {
            [void]$list.Add(@{ Name = $n; Description = "All $($n.ToLower()) tweaks."; Warning = ''
                               Ids = @($Blob.Tweaks | Where-Object { $_.Risk -in $tiers[$n] } | ForEach-Object { $_.Id }) })
        }
    }
    $Blob.Presets = $list.ToArray()
    return $Blob.Presets
}

function Show-BlobPresets {
    $crumb = 'Presets'
    while ($true) {
        $presets = @(Get-BlobPresets)
        $items = @()
        foreach ($p in $presets) {
            $tw = @($p.Ids | ForEach-Object { Get-BlobTweak $_ } | Where-Object { $_ })
            $applied = @($tw | Where-Object { (Get-BlobTweakState $_) -eq 'Applied' }).Count
            $items += @{ Label = $p.Name; Right = "{Gray}$($tw.Count) settings  {DarkGray}$applied applied"
                         Detail = @($p.Description, $(if ($p.Warning) { $p.Warning } else { 'Press Enter to review every change before anything is applied.' })); Preset = $p; Tweaks = $tw }
        }
        $res = Show-BlobMenu -Crumb $crumb -Items $items -Intro @(
            '{White}Optimization presets',
            '{Gray}Each preset shows the full list of settings it will change and asks for confirmation.',
            '{Gray}Nothing is ever applied silently. All changes can be undone from Restore.')
        if ($res.Action -eq 'Back') { return }
        $sel = $items[$res.Index]
        $lines = @()
        if ($sel.Preset.Warning) { $lines += "{Yellow}$($sel.Preset.Warning)"; $lines += '' }
        $lines += Get-BlobTweakPreview $sel.Tweaks
        $danger = $sel.Preset.Name -match 'ADVANCED'
        $q = "Apply the $($sel.Preset.Name) preset ($($sel.Tweaks.Count) optimizations)? Exact changes:"
        if (-not (Confirm-BlobAction -Crumb "$crumb $($Blob.Ch.Arrow) $($sel.Preset.Name)" -Question $q -Lines $lines -Danger:$danger)) { continue }
        if ($Blob.IsAdmin -and -not $Blob.DryRun) {
            if (Confirm-BlobAction -Crumb $crumb -Question 'Create a System Restore point first? (recommended)' -Lines @(
                    '{Gray}Y creates a restore point (may take a minute). N continues without one.',
                    '{DarkGray}Windows allows only one restore point per 24 hours by default.')) {
                Start-BlobWork $crumb
                Write-BlobWork '{Gray}Creating System Restore point...'
                $rp = New-BlobRestorePoint "BLOB OPTIMIZER - $($sel.Preset.Name) preset"
                Write-BlobWork $rp
                Complete-BlobWork 'Restore point step finished.'
            }
        }
        Invoke-BlobTweakSet -Tweaks $sel.Tweaks -Crumb "$crumb $($Blob.Ch.Arrow) $($sel.Preset.Name)" -Tag "preset-$($sel.Preset.Name)" -SkipConfirm
    }
}
