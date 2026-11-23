# ============================================================================
#  BLOB OPTIMIZER - Dashboard.ps1
#  Logo, system summary, main menu grid and the System Info page.
# ============================================================================

$Blob.Logo = @(
    '#####   ##        #####   ##### ',
    '##  ##  ##       ##   ##  ##  ##',
    '#####   ##       ##   ##  ##### ',
    '##  ##  ##       ##   ##  ##  ##',
    '#####   #######   #####   ##### '
)

$Blob.MainMenu = @(
    @{ Key = '1'; Label = 'Performance'; Run = { Show-BlobPerformance }; Info = 'Responsiveness, background apps, visual effects and resource information.' }
    @{ Key = '2'; Label = 'Gaming'; Run = { Show-BlobGaming }; Info = 'Game Mode, Game DVR, input and GPU scheduling options. No FPS promises.' }
    @{ Key = '3'; Label = 'Tweaks'; Run = { Show-BlobTweaks }; Info = 'File Explorer, taskbar, Start menu and Windows behaviour settings.' }
    @{ Key = '4'; Label = 'Privacy'; Run = { Show-BlobPrivacy }; Info = 'Advertising, suggestions, diagnostic data and activity history.' }
    @{ Key = '5'; Label = 'Services'; Run = { Show-BlobServices }; Info = 'Review services with explanations. Critical services are protected.' }
    @{ Key = '6'; Label = 'Startup'; Run = { Show-BlobStartup }; Info = 'Disable or re-enable programs that launch at sign-in.' }
    @{ Key = '7'; Label = 'Cleanup'; Run = { Show-BlobCleanup }; Info = 'Temporary files, caches and Recycle Bin with a size preview.' }
    @{ Key = '8'; Label = 'Network'; Run = { Show-BlobNetwork }; Info = 'Network information, diagnostics, DNS and optional resets.' }
    @{ Key = '9'; Label = 'Power'; Run = { Show-BlobPower }; Info = 'Power plans, display / sleep timeouts and hibernation.' }
    @{ Key = '10'; Label = 'Restore'; Run = { Show-BlobRestore }; Info = 'Change history, undo, registry snapshots and config export/import.' }
    @{ Key = '11'; Label = 'System Info'; Run = { Show-BlobSystemInfo }; Info = 'Detailed hardware and Windows information (read-only).' }
    @{ Key = 'P'; Label = 'Presets'; Run = { Show-BlobPresets }; Info = 'MINIMAL, STANDARD or ADVANCED - every change previewed before applying.' }
    @{ Key = '0'; Label = 'Exit'; Run = $null; Info = 'Close BLOB OPTIMIZER. Nothing keeps running in the background.' }
)

function Get-BlobSystemSummary {
    $s = @{ OS = 'Windows'; CPU = 'Unknown'; RAM = 'Unknown'; GPU = 'Unknown'; Host = $env:COMPUTERNAME; Uptime = '' }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
        $caption = $os.Caption -replace '^Microsoft\s+', ''
        if ([int]$os.BuildNumber -ge 22000) { $caption = $caption -replace 'Windows 10', 'Windows 11' }
        $s.OS = "$caption $($cv.DisplayVersion) (build $($os.BuildNumber).$($cv.UBR))"
        $up = (Get-Date) - $os.LastBootUpTime
        $s.Uptime = '{0}d {1}h {2}m' -f $up.Days, $up.Hours, $up.Minutes
    } catch { }
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $s.CPU = ($cpu.Name -replace '\s+', ' ').Trim() + " ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T)"
    } catch { }
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $s.RAM = '{0:N1} GB' -f ($cs.TotalPhysicalMemory / 1GB)
        $s.Model = "$($cs.Manufacturer) $($cs.Model)"
    } catch { }
    try { $s.GPU = (@(Get-CimInstance Win32_VideoController -ErrorAction Stop | ForEach-Object { $_.Name } | Select-Object -Unique) -join ', ') } catch { }
    return $s
}

function Show-BlobDashboard {
    $sel = 0
    $cols = 2
    $pendingDigit = $null
    while ($true) {
        $plan = (Get-BlobActivePowerPlan).Name
        $si = $Blob.SysInfo
        $L = Write-BlobFrame -Crumb 'Dashboard' -Footer (Format-BlobFooter @("$($Blob.Ch.Up)$($Blob.Ch.Down)$([char]0x2190)$([char]0x2192)|Navigate", 'Enter|Open', '1-11 / P|Jump', 'Esc|Exit'))
        $menuRows = [Math]::Ceiling($Blob.MainMenu.Count / $cols)
        $needFull = $Blob.Logo.Count + 2 + 5 + 2 + $menuRows + 2
        $showLogo = $L.BodyH -ge $needFull
        $row = $L.BodyTop
        $lines = New-Object System.Collections.ArrayList
        if ($showLogo) {
            $pad = [Math]::Max(0, [int](($L.Inner - $Blob.Logo[0].Length) / 2))
            foreach ($logoLine in $Blob.Logo) { [void]$lines.Add('{Cyan}' + (' ' * $pad) + ($logoLine -replace '#', $Blob.Ch.Block)) }
            $sub = "O P T I M I Z E R   {DarkGray}v$($Blob.Version)"
            [void]$lines.Add(' ' * [Math]::Max(0, [int](($L.Inner - (Get-BlobPlainText $sub).Length) / 2)) + '{White}' + $sub)
        } else {
            [void]$lines.Add("{Cyan}BLOB OPTIMIZER {DarkGray}v$($Blob.Version)")
        }
        [void]$lines.Add('')
        $half = [int]($L.Inner / 2)
        $kv = { param($k, $v, $c = 'White') ("{DarkGray}$($k.PadRight(8)){$c}$v") }
        $pairs = @(
            @((& $kv 'OS' $si.OS), (& $kv 'HOST' $si.Host)),
            @((& $kv 'CPU' $si.CPU), (& $kv 'RAM' $si.RAM)),
            @((& $kv 'GPU' $si.GPU), (& $kv 'POWER' $plan)),
            @((& $kv 'ADMIN' $(if ($Blob.IsAdmin) { 'Administrator' } else { 'Standard user (read-only features)' }) $(if ($Blob.IsAdmin) { 'Green' } else { 'Yellow' })),
              (& $kv 'STATUS' $(if ($Blob.DryRun) { 'DRY RUN - no changes' } else { 'READY' }) $(if ($Blob.DryRun) { 'Magenta' } else { 'Green' })))
        )
        [void]$lines.Add("{DarkCyan}$($Blob.Ch.S)$($Blob.Ch.S) {Cyan}SYSTEM {DarkCyan}" + ($Blob.Ch.S * ($L.Inner - 10)))
        foreach ($p in $pairs) {
            $left = $p[0]; $plainLen = (Get-BlobPlainText $left).Length
            if ($plainLen -gt $half - 2) { $left = '{DarkGray}' + (Get-BlobPlainText $left).Substring(0, 8) + '{White}' + (Get-BlobPlainText $left).Substring(8, $half - 13) + '...'; $plainLen = $half - 2 }
            [void]$lines.Add($left + (' ' * ($half - $plainLen)) + $p[1])
        }
        [void]$lines.Add('')
        [void]$lines.Add("{DarkCyan}$($Blob.Ch.S)$($Blob.Ch.S) {Cyan}MENU {DarkCyan}" + ($Blob.Ch.S * ($L.Inner - 8)))
        foreach ($textLine in $lines) { if ($row -lt $L.BodyTop + $L.BodyH) { Write-BlobRow $L $row $textLine; $row++ } }

        $cellW = [int](($L.Inner - 4) / $cols)
        for ($r = 0; $r -lt $menuRows; $r++) {
            if ($row -ge $L.BodyTop + $L.BodyH - 2) { break }
            $L2 = $L
            Write-BlobRow $L2 $row ''
            for ($c = 0; $c -lt $cols; $c++) {
                $i = $r + $c * $menuRows
                if ($i -ge $Blob.MainMenu.Count) { continue }
                $m = $Blob.MainMenu[$i]
                $text = (" [{0}] {1}" -f $m.Key, $m.Label).PadRight($cellW - 2)
                $x = $L.L + 4 + $c * $cellW
                if ($i -eq $sel) { Write-BlobAt $x $row $text 'Black' 'Cyan' }
                else {
                    Write-BlobAt $x $row (" [{0}]" -f $m.Key) 'Cyan'
                    Write-BlobAt ($x + (" [{0}]" -f $m.Key).Length) $row (" $($m.Label)") $(if ($m.Key -eq '0') { 'Gray' } else { 'White' })
                }
            }
            $row++
        }
        while ($row -lt $L.BodyTop + $L.BodyH - 1) { Write-BlobRow $L $row ''; $row++ }
        Write-BlobRow $L $row ("{Gray}" + $Blob.MainMenu[$sel].Info)

        $k = Read-BlobKey
        if (-not $k) { continue }
        $count = $Blob.MainMenu.Count
        $r0 = $sel % $menuRows; $c0 = [Math]::Floor($sel / $menuRows)
        $choose = $null
        switch ($k.Key) {
            'UpArrow'    { $sel = ($sel - 1 + $count) % $count }
            'DownArrow'  { $sel = ($sel + 1) % $count }
            'LeftArrow'  { if ($c0 -gt 0) { $sel = $sel - $menuRows } }
            'RightArrow' { if ($sel + $menuRows -lt $count) { $sel = $sel + $menuRows } }
            'Tab'        { $sel = ($sel + $menuRows) % $count; if ($sel -ge $count) { $sel = $r0 } }
            'Home'       { $sel = 0 }
            'End'        { $sel = $count - 1 }
            'Enter'      { $choose = $sel }
            'Escape'     { $choose = $count - 1 }
        }
        $ch = ([string]$k.KeyChar).ToUpperInvariant()
        if ($ch -match '^[0-9P]$') {
            $key = $ch
            if ($ch -eq '1') {
                # Wait briefly for a second digit so 10 and 11 can be typed.
                $deadline = (Get-Date).AddMilliseconds(450)
                while ((Get-Date) -lt $deadline -and -not [Console]::KeyAvailable) { Start-Sleep -Milliseconds 25 }
                if ([Console]::KeyAvailable) {
                    $k2 = [Console]::ReadKey($true)
                    if ($k2.KeyChar -in @([char]'0', [char]'1')) { $key = '1' + $k2.KeyChar }
                }
            }
            for ($i = 0; $i -lt $count; $i++) { if ($Blob.MainMenu[$i].Key -eq $key) { $sel = $i; $choose = $i } }
        }
        if ($null -ne $choose) {
            $m = $Blob.MainMenu[$choose]
            if (-not $m.Run) { return }
            try { & $m.Run }
            catch {
                if ($_.Exception.Message -eq 'BLOB_WINDOW_TOO_SMALL') { continue }
                Write-BlobLog "Unhandled error in $($m.Label): $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" 'ERROR'
                Show-BlobNotice -Crumb $m.Label -Kind Error -Title 'Something went wrong' -Lines @(
                    "{Gray}$($_.Exception.Message -replace '[{}]', '')", '',
                    '{Gray}No further changes were made. Details were written to the session log.')
            }
        }
    }
}

function Get-BlobSystemInfoLines {
    $lines = New-Object System.Collections.ArrayList
    $add = { param($t) [void]$lines.Add($t) }
    $kv = { param($k, $v) [void]$lines.Add("{Gray}$($k.PadRight(22)){White}$($v -replace '[{}]', '')") }
    & $add '{Cyan}Windows'
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
        & $kv 'Edition' $Blob.SysInfo.OS
        & $kv 'Architecture' $os.OSArchitecture
        & $kv 'Installed' $os.InstallDate.ToString('yyyy-MM-dd')
        & $kv 'Last boot' "$($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'))  (uptime $($Blob.SysInfo.Uptime))"
        & $kv 'Computer name' $env:COMPUTERNAME
        & $kv 'Locale' (Get-Culture).Name
    } catch { & $add "{Red}$($_.Exception.Message)" }
    & $add ''; & $add '{Cyan}Hardware'
    try {
        & $kv 'Model' $Blob.SysInfo.Model
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        & $kv 'Processor' ($cpu.Name -replace '\s+', ' ').Trim()
        & $kv 'Cores / threads' "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)  @ $($cpu.MaxClockSpeed) MHz"
        $mods = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop)
        & $kv 'Memory' ("{0} in {1} module(s), {2} MT/s" -f $Blob.SysInfo.RAM, $mods.Count, ($mods | Select-Object -First 1).Speed)
        foreach ($g in (Get-CimInstance Win32_VideoController -ErrorAction Stop)) { & $kv 'Graphics' "$($g.Name)  (driver $($g.DriverVersion))" }
        $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
        & $kv 'BIOS' "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"
        $bb = Get-CimInstance Win32_BaseBoard -ErrorAction Stop
        & $kv 'Motherboard' "$($bb.Manufacturer) $($bb.Product)"
    } catch { }
    try { foreach ($pd in (Get-PhysicalDisk -ErrorAction Stop)) { & $kv 'Disk' ("{0}  {1}  {2}  health {3}" -f $pd.FriendlyName, $pd.MediaType, (Format-BlobSize $pd.Size), $pd.HealthStatus) } } catch { }
    & $add ''; & $add '{Cyan}Security status (read-only)'
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        & $kv 'Defender real-time' $(if ($mp.RealTimeProtectionEnabled) { 'On' } else { 'Off' })
        & $kv 'Defender signatures' $mp.AntivirusSignatureLastUpdated
    } catch { & $kv 'Defender' 'status unavailable (third-party antivirus or no permission)' }
    try {
        $fw = @(Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object { "$($_.Name): $(if ($_.Enabled) { 'On' } else { 'Off' })" }) -join ', '
        & $kv 'Firewall' $fw
    } catch { }
    & $add ''; & $add '{Cyan}BLOB OPTIMIZER'
    & $kv 'Version' $Blob.Version
    & $kv 'PowerShell' "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
    & $kv 'Administrator' $(if ($Blob.IsAdmin) { 'yes' } else { 'no' })
    & $kv 'Dry run' $(if ($Blob.DryRun) { 'yes' } else { 'no' })
    & $kv 'Data folder' $Blob.DataRoot
    & $kv 'Recorded changes' $Blob.Changes.Count
    return $lines.ToArray()
}

function Show-BlobSystemInfo {
    Start-BlobWork 'System Info'
    Write-BlobWork '{Gray}Collecting system information...'
    $lines = Get-BlobSystemInfoLines
    $null = Show-BlobText -Crumb 'System Info' -Lines $lines
}
