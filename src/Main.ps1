# ============================================================================
#  BLOB OPTIMIZER - Main.ps1
#  Entry point. Validates the host, initialises state, runs the UI and always
#  restores the console - even on errors or Ctrl+C.
# ============================================================================

function Invoke-BlobSelfTest {
    # Non-interactive smoke test: reads everything, changes nothing.
    # Usage: $env:BLOB_SELFTEST = '1'; .\BLOB.ps1
    $Blob.DryRun = $true
    $fail = 0
    $check = {
        param($name, $block)
        try { $r = & $block; Write-Host ("  [ OK ] {0} {1}" -f $name, $r) -ForegroundColor Cyan }
        catch { Write-Host ("  [FAIL] {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Cyan; $Blob.SelfTestFailed = $true }
    }
    $Blob.SelfTestFailed = $false
    Write-Host "BLOB OPTIMIZER $($Blob.Version) self-test (read-only)" -ForegroundColor Cyan
    & $check 'System summary'  { $s = Get-BlobSystemSummary; "- $($s.OS)" }
    & $check 'Tweak catalogue' { $bad = @($Blob.Tweaks | Group-Object { $_.Id } | Where-Object { $_.Count -gt 1 }); if ($bad) { throw "duplicate ids: $($bad.Name -join ',')" }; "- $($Blob.Tweaks.Count) tweaks" }
    & $check 'Privacy catalogue' {
        $pc = @(Get-BlobPrivacyItems)
        $missing = @($Blob.PrivacyGroups | Where-Object { $g = $_; -not @($pc | Where-Object { $_.Group -eq $g }).Count })
        if ($missing) { throw "sections without items: $($missing -join ', ')" }
        foreach ($t in $pc) {
            foreach ($op in $t.Registry) { if ($op.Path -notmatch '^(HKCU|HKLM):\\') { throw "bad path in $($t.Id): $($op.Path)" } }
            foreach ($f in 'Does', 'Data', 'Benefit', 'Lose', 'Issues') { if (-not $t.Privacy[$f]) { throw "$($t.Id) has no '$f' text" } }
        }
        "- $($pc.Count) settings in $($Blob.PrivacyGroups.Count) sections, $(@($pc | Where-Object InfoOnly).Count) information only"
    }
    & $check 'Tweak states'    { $st = @($Blob.Tweaks | ForEach-Object { Get-BlobTweakState $_ }); "- $(@($st | Where-Object { $_ -eq 'Applied' }).Count) applied" }
    & $check 'Presets'         { $p = @(Get-BlobPresets); foreach ($x in $p) { foreach ($id in $x.Ids) { if (-not (Get-BlobTweak $id)) { throw "preset $($x.Name) references unknown tweak '$id'" } } }; "- $(($p | ForEach-Object { "$($_.Name)=$($_.Ids.Count)" }) -join ' ')" }
    & $check 'Preset safety'   { foreach ($x in @(Get-BlobPresets)) { foreach ($id in $x.Ids) { if ((Get-BlobTweak $id).Risk -eq 'Optional') { throw "optional tweak '$id' in preset $($x.Name)" } } }; '' }
    & $check 'Dry-run apply'   { $r = Set-BlobRegValue -Path 'HKCU:\Software\BLOB-OPTIMIZER-SelfTest' -Name 'Probe' -Value 1; if ($r.Status -ne 'DryRun') { throw "expected DryRun, got $($r.Status)" }; if (Test-Path 'HKCU:\Software\BLOB-OPTIMIZER-SelfTest') { throw 'dry run wrote to the registry' }; '' }
    & $check 'Startup entries' { "- $(@(Get-BlobStartupEntries).Count) entries" }
    & $check 'Power plans'     { "- active: $((Get-BlobActivePowerPlan).Name)" }
    & $check 'Services'        { "- $((Get-BlobServiceList).Count) services" }
    & $check 'Journal'         { "- $($Blob.Changes.Count) records at $($Blob.JournalPath)" }
    & $check 'Window UI'       {
        $why = Test-BlobGuiSupported
        if ($why) { return "- skipped: $why" }
        $null = New-BlobGuiWindow $Blob.GuiDialogXaml
        Initialize-BlobGuiWindow
        $built = 0
        foreach ($p in $Blob.Gui.Pages) {
            try { $c = & $p.Build; if (-not $c) { throw 'no content' }; $built++ }
            catch { throw "page '$($p.Key)': $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
        }
        $Blob.Gui.Window.Close()
        "- XAML ok, $built/$($Blob.Gui.Pages.Count) pages built"
    }
    & $check 'Cleanup scan'    { $t = $Blob.CleanupTargets[0]; $m = Measure-BlobCleanupTarget $t; "- $($t.Name): $(Format-BlobSize $m.Bytes)" }
    if ($Blob.SelfTestFailed) { Write-Host 'Self-test FAILED' -ForegroundColor Cyan } else { Write-Host 'Self-test passed' -ForegroundColor Cyan }
}

# Relaunches BLOB OPTIMIZER through the standard Windows administrator prompt (UAC).
# Returns 'Started', 'Declined' or 'NoSource'. Never bypasses the prompt.
function Request-BlobElevation {
    param([bool]$DryRun, [bool]$Tui, [string]$ScriptPath)
    $exe = try { (Get-Process -Id $PID).Path } catch { $null }
    if (-not $exe) { $exe = 'powershell.exe' }
    $extra = @()
    if ($DryRun) { $extra += '-DryRun' }
    if ($Tui) { $extra += '-Tui' }
    if ($ScriptPath -and (Test-Path -LiteralPath $ScriptPath)) {
        $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $($extra -join ' ')"
    } elseif ($Blob.ReleaseUrl) {
        # Started with irm | iex: run the same pinned release URL again, elevated.
        $argList = "-NoProfile -ExecutionPolicy Bypass -Command `"& ([scriptblock]::Create((irm '$($Blob.ReleaseUrl)'))) $($extra -join ' ')`""
    } else { return 'NoSource' }
    try {
        Start-Process -FilePath $exe -ArgumentList $argList -Verb RunAs -ErrorAction Stop
        Write-BlobLog "Relaunched elevated: $exe $argList"
        return 'Started'
    } catch { return 'Declined' }
}

function Start-BlobOptimizer {
    param([bool]$DryRun, [bool]$Tui, [bool]$NoElevate, [string]$ScriptPath)

    if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Host 'BLOB OPTIMIZER requires PowerShell 5.1 or newer.' -ForegroundColor Cyan; return }
    if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) { Write-Host 'BLOB OPTIMIZER only runs on Windows.' -ForegroundColor Cyan; return }

    Initialize-BlobState -DryRun $DryRun
    $Blob.SysInfo = Get-BlobSystemSummary

    if ($env:BLOB_SELFTEST -eq '1') { Invoke-BlobSelfTest; return }

    # Always run as administrator: ask Windows (UAC) to relaunch elevated.
    if (-not $Blob.IsAdmin -and -not $NoElevate -and $env:BLOB_NOELEVATE -ne '1') {
        Write-Host '  BLOB OPTIMIZER needs administrator rights - Windows will ask for permission...' -ForegroundColor Cyan
        $elev = Request-BlobElevation -DryRun $Blob.DryRun -Tui $Tui -ScriptPath $ScriptPath
        if ($elev -eq 'Started') {
            Write-Host '  BLOB OPTIMIZER opened in a new administrator window. You can close this one.' -ForegroundColor Cyan
            return
        }
        if ($elev -eq 'Declined') { Write-Host '  Administrator permission was not given - continuing in read-only mode.' -ForegroundColor DarkCyan }
        else { Write-Host '  Could not relaunch automatically - continuing in read-only mode.' -ForegroundColor DarkCyan }
    }

    # Window interface (default). Falls back to the terminal UI when WPF is unavailable.
    if (-not $Tui -and $env:BLOB_TUI -ne '1') {
        $why = Test-BlobGuiSupported
        if (-not $why) {
            Write-Host ''
            Write-Host '  BLOB OPTIMIZER window is open.' -ForegroundColor Cyan -NoNewline
            Write-Host ' Close it to return to this prompt. (Terminal version: add -Tui)' -ForegroundColor DarkCyan
            $failure = $null
            try { Start-BlobGui } catch { $failure = $_ }
            if ($failure) {
                Write-BlobLog "Fatal (window): $($failure.Exception.Message) $($failure.InvocationInfo.PositionMessage)" 'ERROR'
                Write-Host 'BLOB OPTIMIZER window stopped because of an unexpected error:' -ForegroundColor Cyan
                Write-Host "  $($failure.Exception.Message)" -ForegroundColor Cyan
                Write-Host "  $($failure.InvocationInfo.PositionMessage)" -ForegroundColor DarkCyan
            }
            Write-BlobExitSummary
            return
        }
        Write-Host "  Window interface unavailable ($why) - starting the terminal interface." -ForegroundColor Cyan
    }

    if ($Host.Name -match 'ISE') { Write-Host 'Please run BLOB OPTIMIZER in Windows Terminal or a PowerShell console (the ISE has no interactive console).' -ForegroundColor Cyan; return }
    try { $null = [Console]::KeyAvailable; $null = [Console]::WindowWidth } catch {
        Write-Host 'BLOB OPTIMIZER needs an interactive console window (input is redirected).' -ForegroundColor Cyan; return
    }

    $failure = $null
    Initialize-BlobConsole
    try {
        Show-BlobDashboard
    } catch {
        if ($_.Exception.Message -ne 'BLOB_WINDOW_TOO_SMALL') { $failure = $_ }
    } finally {
        Restore-BlobConsole
    }

    if ($failure) {
        Write-BlobLog "Fatal: $($failure.Exception.Message) $($failure.InvocationInfo.PositionMessage)" 'ERROR'
        Write-Host 'BLOB OPTIMIZER stopped because of an unexpected error:' -ForegroundColor Cyan
        Write-Host "  $($failure.Exception.Message)" -ForegroundColor Cyan
        Write-Host "  $($failure.InvocationInfo.PositionMessage)" -ForegroundColor DarkCyan
    }
    Write-BlobExitSummary
}

function Write-BlobExitSummary {
    $session = @($Blob.Changes | Where-Object { $_.SessionId -eq $Blob.SessionId })
    Write-Host ''
    Write-Host '  BLOB OPTIMIZER closed.' -ForegroundColor Cyan -NoNewline
    Write-Host ' Nothing is left running.' -ForegroundColor DarkCyan
    if ($session.Count -gt 0) {
        Write-Host ("  {0} change(s) recorded this session. Undo them any time from Restore." -f $session.Count) -ForegroundColor DarkCyan
        Write-Host "  Backups and logs: $($Blob.DataRoot)" -ForegroundColor DarkCyan
    }
    Write-Host ''
}
