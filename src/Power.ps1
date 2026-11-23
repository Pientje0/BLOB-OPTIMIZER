# ============================================================================
#  BLOB OPTIMIZER - Power.ps1
#  Power plans and documented power settings through powercfg.exe.
# ============================================================================

$Blob.KnownPlans = @{
    HighPerformance     = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    UltimatePerformance = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
}
$guidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
$Blob.GuidPattern = $guidPattern

# powercfg output is localised, so parse by GUID / parentheses / asterisk only.
function Get-BlobPowerPlans {
    $plans = @()
    foreach ($line in (powercfg.exe /list 2>$null)) {
        if ($line -match "($($Blob.GuidPattern))\s+\((.+)\)(\s*\*)?") {
            $plans += @{ Guid = $Matches[1].ToLower(); Name = $Matches[2]; Active = [bool]$Matches[3] }
        }
    }
    return $plans
}

function Get-BlobActivePowerPlan {
    $out = powercfg.exe /getactivescheme 2>$null
    if ("$out" -match "($($Blob.GuidPattern))\s+\((.+)\)") { return @{ Guid = $Matches[1].ToLower(); Name = $Matches[2] } }
    return @{ Guid = ''; Name = 'Unknown' }
}

function Set-BlobPowerPlan {
    param([string]$Guid, [string]$Name)
    $old = Get-BlobActivePowerPlan
    $target = 'Active power plan'
    if ($old.Guid -eq $Guid) { return New-BlobResult $target 'Unchanged' 'Already active.' $old.Name $Name }
    if ($Blob.DryRun) { return New-BlobResult $target 'DryRun' 'Dry run - nothing changed.' $old.Name $Name }
    $rec = New-BlobChangeRecord -Kind 'PowerPlan' -Source 'power.plan' -Label "Power plan: $Name" -Target $target `
        -Data @{ OldGuid = $old.Guid; OldName = $old.Name; NewGuid = $Guid }
    $null = powercfg.exe /setactive $Guid 2>&1
    if ((Get-BlobActivePowerPlan).Guid -eq $Guid) { $rec.Status = 'Applied' } else { $rec.Status = 'Failed'; $rec.Error = 'powercfg could not activate the plan.' }
    Add-BlobChange $rec
    return New-BlobResult $target $rec.Status $(if ($rec.Error) { $rec.Error } else { 'Applied and verified.' }) $old.Name $Name
}

function Add-BlobPowerPlan {
    param([string]$TemplateGuid, [string]$Name)
    if ($Blob.DryRun) { return New-BlobResult "Create '$Name' plan" 'DryRun' 'Dry run - nothing changed.' }
    $out = powercfg.exe /duplicatescheme $TemplateGuid 2>&1
    if ("$out" -match "($($Blob.GuidPattern))") {
        $guid = $Matches[1].ToLower()
        $rec = New-BlobChangeRecord -Kind 'PowerPlanCreated' -Source 'power.plan' -Label "Created power plan: $Name" -Target "Power plan $guid" -Data @{ Guid = $guid }
        $rec.Status = 'Applied'
        Add-BlobChange $rec
        return @{ Guid = $guid; Result = (New-BlobResult "Create '$Name' plan" 'Applied' 'Plan created.') }
    }
    return @{ Guid = $null; Result = (New-BlobResult "Create '$Name' plan" 'Failed' ("$out".Trim())) }
}

# Reads AC / DC values (in seconds) of a power setting from powercfg /q.
function Get-BlobPowerSetting {
    param([string]$Sub, [string]$Setting)
    $hex = @(powercfg.exe /q SCHEME_CURRENT $Sub $Setting 2>$null | ForEach-Object { if ($_ -match '0x([0-9a-fA-F]{8})\s*$') { [Convert]::ToInt64($Matches[1], 16) } })
    if ($hex.Count -ge 2) { return @{ AC = $hex[-2]; DC = $hex[-1] } }
    return $null
}

$Blob.PowerTimeouts = @(
    @{ Key = 'monitor-timeout-ac'; Name = 'Turn off display (plugged in)'; Sub = 'SUB_VIDEO'; Setting = 'VIDEOIDLE'; Side = 'AC' }
    @{ Key = 'monitor-timeout-dc'; Name = 'Turn off display (on battery)'; Sub = 'SUB_VIDEO'; Setting = 'VIDEOIDLE'; Side = 'DC' }
    @{ Key = 'standby-timeout-ac'; Name = 'Sleep after (plugged in)'; Sub = 'SUB_SLEEP'; Setting = 'STANDBYIDLE'; Side = 'AC' }
    @{ Key = 'standby-timeout-dc'; Name = 'Sleep after (on battery)'; Sub = 'SUB_SLEEP'; Setting = 'STANDBYIDLE'; Side = 'DC' }
)

function Get-BlobTimeoutMinutes {
    param($T)
    $v = Get-BlobPowerSetting $T.Sub $T.Setting
    if (-not $v) { return $null }
    return [int][Math]::Round($v[$T.Side] / 60)
}

function Format-BlobMinutes { param($M) if ($null -eq $M) { 'unknown' } elseif ($M -eq 0) { 'Never' } else { "$M min" } }

function Set-BlobPowerTimeout {
    param($T, [int]$Minutes)
    $old = Get-BlobTimeoutMinutes $T
    $target = $T.Name
    if ($old -eq $Minutes) { return New-BlobResult $target 'Unchanged' 'Already set.' (Format-BlobMinutes $old) (Format-BlobMinutes $Minutes) }
    if ($Blob.DryRun) { return New-BlobResult $target 'DryRun' 'Dry run - nothing changed.' (Format-BlobMinutes $old) (Format-BlobMinutes $Minutes) }
    $plan = Get-BlobActivePowerPlan
    $rec = New-BlobChangeRecord -Kind 'PowerTimeout' -Source 'power.settings' -Label "$($T.Name) ($($plan.Name))" -Target "$target [$($plan.Name)]" `
        -Data @{ Key = $T.Key; Old = $old; New = $Minutes; PlanGuid = $plan.Guid }
    $null = powercfg.exe /change $T.Key $Minutes 2>&1
    if ((Get-BlobTimeoutMinutes $T) -eq $Minutes) { $rec.Status = 'Applied' } else { $rec.Status = 'Failed'; $rec.Error = 'Value did not change (setting may be managed or unsupported).' }
    Add-BlobChange $rec
    return New-BlobResult $target $rec.Status $(if ($rec.Error) { $rec.Error } else { 'Applied and verified.' }) (Format-BlobMinutes $old) (Format-BlobMinutes $Minutes)
}

function Get-BlobHibernateEnabled {
    $s = Get-BlobRegState 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled'
    return ($s.Exists -and [int]$s.Value -eq 1)
}

function Set-BlobHibernate {
    param([bool]$Enable)
    $target = 'Hibernation (hiberfil.sys / Fast Startup)'
    $old = Get-BlobHibernateEnabled
    $fmt = { param($b) if ($b) { 'On' } else { 'Off' } }
    if (-not $Blob.IsAdmin) { return New-BlobResult $target 'Skipped' 'Administrator rights required.' }
    if ($old -eq $Enable) { return New-BlobResult $target 'Unchanged' 'Already set.' (& $fmt $old) (& $fmt $Enable) }
    if ($Blob.DryRun) { return New-BlobResult $target 'DryRun' 'Dry run - nothing changed.' (& $fmt $old) (& $fmt $Enable) }
    $rec = New-BlobChangeRecord -Kind 'Hibernate' -Source 'power.hibernate' -Label "Hibernation $(& $fmt $Enable)" -Target $target -Data @{ Old = $old; New = $Enable }
    $null = powercfg.exe /hibernate $(if ($Enable) { 'on' } else { 'off' }) 2>&1
    if ((Get-BlobHibernateEnabled) -eq $Enable) { $rec.Status = 'Applied' } else { $rec.Status = 'Failed'; $rec.Error = 'powercfg did not change hibernation.' }
    Add-BlobChange $rec
    return New-BlobResult $target $rec.Status $(if ($rec.Error) { $rec.Error } else { 'Applied and verified.' }) (& $fmt $old) (& $fmt $Enable)
}

function Restore-BlobPowerChange {
    param($Record)
    $d = $Record.Data
    switch ($Record.Kind) {
        'PowerPlan' {
            $null = powercfg.exe /setactive $d.OldGuid 2>&1
            if ((Get-BlobActivePowerPlan).Guid -ne $d.OldGuid) { throw 'Could not re-activate the previous power plan.' }
        }
        'PowerPlanCreated' {
            if ((Get-BlobActivePowerPlan).Guid -eq $d.Guid) { throw 'This plan is active. Switch to another plan first, then remove it.' }
            $null = powercfg.exe /delete $d.Guid 2>&1
            if (@(Get-BlobPowerPlans | Where-Object { $_.Guid -eq $d.Guid }).Count -gt 0) { throw 'powercfg could not delete the plan.' }
        }
        'PowerTimeout' {
            if ($null -eq $d.Old) { throw 'The original value was unknown, so it cannot be restored reliably.' }
            if ((Get-BlobActivePowerPlan).Guid -ne $d.PlanGuid) { throw 'A different power plan is active now. Activate the original plan first.' }
            $null = powercfg.exe /change $d.Key $d.Old 2>&1
        }
        'Hibernate' {
            if (-not $Blob.IsAdmin) { throw 'Administrator rights required.' }
            $null = powercfg.exe /hibernate $(if ($d.Old) { 'on' } else { 'off' }) 2>&1
            if ((Get-BlobHibernateEnabled) -ne [bool]$d.Old) { throw 'Hibernation state did not change.' }
        }
    }
}

function Get-BlobPowerInfo {
    $lines = @('{Cyan}Current power configuration', '')
    $active = Get-BlobActivePowerPlan
    $lines += "{Gray}Active plan          {White}$($active.Name) {DarkGray}$($active.Guid)"
    foreach ($t in $Blob.PowerTimeouts) { $lines += ('{{Gray}}{0,-34} {{White}}{1}' -f $t.Name, (Format-BlobMinutes (Get-BlobTimeoutMinutes $t))) }
    $lines += "{Gray}Hibernation                        {White}$(if (Get-BlobHibernateEnabled) { 'On' } else { 'Off' })"
    try {
        $bat = Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object -First 1
        if ($bat) { $lines += "{Gray}Battery                            {White}$($bat.EstimatedChargeRemaining)%" }
    } catch { }
    $lines += ''; $lines += '{Cyan}Installed plans'; $lines += ''
    foreach ($p in Get-BlobPowerPlans) { $lines += "$(if ($p.Active) { '{Green}* ' } else { '{DarkGray}  ' }){White}$($p.Name) {DarkGray}$($p.Guid)" }
    return $lines
}

function Show-BlobPowerTimeouts {
    $crumb = 'Power > Timeouts'
    $choices = @(0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 120)
    while ($true) {
        $items = @($Blob.PowerTimeouts | ForEach-Object { @{ Label = $_.Name; Right = "{White}$(Format-BlobMinutes (Get-BlobTimeoutMinutes $_))"; T = $_ } })
        $r = Show-BlobMenu -Crumb $crumb -Items $items -Intro @('{White}Display and sleep timeouts', "{Gray}Applies to the active plan: {White}$((Get-BlobActivePowerPlan).Name)")
        if ($r.Action -ne 'Select') { return }
        $t = $items[$r.Index].T
        $cur = Get-BlobTimeoutMinutes $t
        $vItems = @($choices | ForEach-Object { @{ Label = (Format-BlobMinutes $_); Right = $(if ($_ -eq $cur) { '{DarkGray}current' } else { '' }) } })
        $v = Show-BlobMenu -Crumb $crumb -Items $vItems -Intro @("{White}$($t.Name)", "{Gray}Current: {White}$(Format-BlobMinutes $cur)")
        if ($v.Action -ne 'Select') { continue }
        $m = $choices[$v.Index]
        if (-not (Confirm-BlobAction -Crumb $crumb -Question "Set '$($t.Name)' to $(Format-BlobMinutes $m)?" -Lines @("{Gray}$(Format-BlobMinutes $cur) {White}-> {Green}$(Format-BlobMinutes $m)", '', '{Gray}The previous value is saved and can be restored.'))) { continue }
        $res = Set-BlobPowerTimeout $t $m
        Show-BlobNotice -Crumb $crumb -Kind $(if ($res.Status -in @('Applied', 'DryRun', 'Unchanged')) { 'Success' } else { 'Error' }) -Title $res.Status -Lines @((Format-BlobResult $res))
    }
}

function Show-BlobPower {
    $crumb = 'Power'
    while ($true) {
        $plans = @(Get-BlobPowerPlans)
        $items = @(@{ Header = $true; Label = 'Power plans' })
        foreach ($p in $plans) {
            $items += @{ Label = $p.Name; Right = $(if ($p.Active) { '{Green}ACTIVE' } else { '' }); Plan = $p; Detail = @("GUID $($p.Guid). Enter to activate.") }
        }
        $items += @{ Header = $true; Label = 'Add plans' }
        $hasHigh = @($plans | Where-Object { $_.Guid -eq $Blob.KnownPlans.HighPerformance }).Count -gt 0
        if (-not $hasHigh) { $items += @{ Label = 'Add High Performance plan'; Add = 'HighPerformance'; Detail = @('Restores the hidden High Performance plan. Uses more power.') } }
        $items += @{ Label = 'Add Ultimate Performance plan'; Add = 'UltimatePerformance'; Detail = @('Creates a copy of the Ultimate Performance plan. Best for desktops; increases power use and heat.') }
        $items += @{ Header = $true; Label = 'Settings' }
        $items += @{ Label = 'Display and sleep timeouts'; Tool = 'timeouts'; Detail = @('Change when the display turns off and the PC sleeps.') }
        $hib = Get-BlobHibernateEnabled
        $items += @{ Label = "Turn hibernation $(if ($hib) { 'off' } else { 'on' })"; Right = $(if ($hib) { '{Green}on' } else { '{DarkGray}off' }); Tool = 'hibernate'
                     Detail = @('Off frees disk space (hiberfil.sys) but also disables Fast Startup and hibernate.', 'Requires administrator.') }
        $items += @{ Label = 'Current power configuration'; Tool = 'info'; Detail = @('All plans, timeouts, hibernation and battery level.') }
        $r = Show-BlobMenu -Crumb $crumb -Items $items -Intro @('{White}Power', "{Gray}Active plan: {White}$((Get-BlobActivePowerPlan).Name)")
        if ($r.Action -ne 'Select') { return }
        $it = $items[$r.Index]
        if ($it.Plan) {
            if ($it.Plan.Active) { continue }
            if (-not (Confirm-BlobAction -Crumb $crumb -Question "Activate '$($it.Plan.Name)'?" -Lines @("{Gray}$((Get-BlobActivePowerPlan).Name) {White}-> {Green}$($it.Plan.Name)", '', '{Gray}The previous plan is saved and can be re-activated from Restore.'))) { continue }
            $res = Set-BlobPowerPlan $it.Plan.Guid $it.Plan.Name
            Show-BlobNotice -Crumb $crumb -Kind $(if ($res.Status -in @('Applied', 'DryRun', 'Unchanged')) { 'Success' } else { 'Error' }) -Title $res.Status -Lines @((Format-BlobResult $res))
        } elseif ($it.Add) {
            $name = if ($it.Add -eq 'HighPerformance') { 'High Performance' } else { 'Ultimate Performance' }
            if (-not (Confirm-BlobAction -Crumb $crumb -Question "Create and activate the $name plan?" -Lines @(
                        "{Gray}A new power plan is created from the built-in $name template and activated.",
                        '{Gray}Higher performance plans keep the CPU at higher clocks: more power use and heat, no guaranteed FPS gain.',
                        '{Gray}Undo from Restore: re-activate the previous plan, then remove the created plan.'))) { continue }
            Start-BlobWork $crumb
            $add = Add-BlobPowerPlan $Blob.KnownPlans[$it.Add] $name
            Write-BlobWork (Format-BlobResult $add.Result)
            if ($add.Guid) { Write-BlobWork (Format-BlobResult (Set-BlobPowerPlan $add.Guid $name)) }
            Complete-BlobWork 'Power plan step finished.'
        } elseif ($it.Tool -eq 'timeouts') { Show-BlobPowerTimeouts }
        elseif ($it.Tool -eq 'info') { $null = Show-BlobText -Crumb "$crumb > Configuration" -Lines (Get-BlobPowerInfo) }
        elseif ($it.Tool -eq 'hibernate') {
            if (-not $Blob.IsAdmin) { Show-BlobAdminRequired $crumb 'Hibernation is a machine-wide setting.'; continue }
            $target = -not $hib
            if (-not (Confirm-BlobAction -Crumb $crumb -Question "Turn hibernation $(if ($target) { 'on' } else { 'off' })?" -Lines @(
                        '{Gray}Turning hibernation off deletes hiberfil.sys and disables Fast Startup and the Hibernate option.',
                        '{Gray}It can be turned back on at any time here or from Restore.'))) { continue }
            $res = Set-BlobHibernate $target
            Show-BlobNotice -Crumb $crumb -Kind $(if ($res.Status -in @('Applied', 'DryRun', 'Unchanged')) { 'Success' } else { 'Error' }) -Title $res.Status -Lines @((Format-BlobResult $res))
        }
    }
}
