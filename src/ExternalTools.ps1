# ============================================================================
#  BLOB OPTIMIZER - ExternalTools.ps1
#  Optional launchers for well-known third-party tools. Nothing here runs
#  unless the user clicks it and confirms. The exact source URL is always
#  shown first, downloads come only from the vendors' official addresses,
#  and executables must carry a valid Authenticode signature from the
#  expected publisher before they are started.
#  Changes made by these tools are NOT recorded or undoable by BLOB OPTIMIZER.
# ============================================================================

$Blob.ExternalTools = @(
    @{
        Id = 'winutil'; Name = "Chris Titus Tech's Windows Utility (WinUtil)"
        Publisher = 'Chris Titus Tech (open source, MIT licence)'
        Url = 'https://christitus.com/win'
        Home = 'https://github.com/ChrisTitusTech/winutil'
        Kind = 'Script'
        Summary = 'Popular open-source utility to install programs, apply tweaks, configure Windows Update and fix common problems.'
        Command = 'irm https://christitus.com/win | iex'
    }
    @{
        Id = 'shutup10'; Name = 'O&O ShutUp10++'
        Publisher = 'O&O Software GmbH (free, closed source)'
        Url = 'https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe'
        Home = 'https://www.oo-software.com/en/shutup10'
        Kind = 'Exe'; Signer = 'O&O Software'
        Summary = 'Free privacy tool with hundreds of individual Windows and Microsoft app privacy switches, each with a recommendation.'
    }
)

function Get-BlobExternalTool { param([string]$Id) return ($Blob.ExternalTools | Where-Object { $_.Id -eq $Id } | Select-Object -First 1) }

function Get-BlobExternalToolLines {
    param($Tool)
    $lines = @(
        "{Gray}Tool        {White}$($Tool.Name)",
        "{Gray}Publisher   {White}$($Tool.Publisher)",
        "{Gray}Source      {Cyan}$($Tool.Url)",
        "{Gray}Website     {White}$($Tool.Home)", '')
    if ($Tool.Kind -eq 'Script') {
        $lines += '{Gray}What happens:'
        $lines += '{White}  A new PowerShell window opens with administrator rights (Windows asks for permission)'
        $lines += "{White}  and runs: {Cyan}$($Tool.Command)"
        $lines += '{White}  The script is downloaded from the source above at that moment and runs in that window.'
    } else {
        $lines += '{Gray}What happens:'
        $lines += '{White}  1. The program is downloaded from the source above to a temporary folder.'
        $lines += "{White}  2. Its digital signature is checked; it must be valid and signed by {Cyan}$($Tool.Signer){White}."
        $lines += '{White}  3. Only then is it started. Windows asks for administrator permission.'
    }
    $lines += ''
    $lines += '{Yellow}This is third-party software. Changes it makes are NOT recorded by BLOB OPTIMIZER'
    $lines += '{Yellow}and cannot be undone from the Restore page. Use its own undo / restore options.'
    $lines += '{Gray}A System Restore point before using it is strongly recommended.'
    return $lines
}

# Launches a tool. -Log receives colour-tagged progress lines. Returns $true on start.
function Start-BlobExternalTool {
    param($Tool, [scriptblock]$Log = { param($m) })
    if ($Blob.DryRun) { & $Log "{Magenta}Dry run - would launch $($Tool.Name) from $($Tool.Url)"; return $false }
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }

    if ($Tool.Kind -eq 'Script') {
        $exe = if ($PSVersionTable.PSEdition -eq 'Core' -and (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) { 'pwsh.exe' } else { 'powershell.exe' }
        $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"$($Tool.Command)`""
        try {
            Start-Process -FilePath $exe -ArgumentList $arg -Verb RunAs -ErrorAction Stop
            & $Log "{Green} OK   {White}$($Tool.Name) {Gray}started in a separate administrator window."
            Add-BlobActionRecord -Source 'external' -Label "Launched $($Tool.Name)" -Target $Tool.Url -Detail 'Third-party tool; its changes are not tracked by BLOB OPTIMIZER.'
            return $true
        } catch {
            & $Log "{Yellow} SKIP {White}$($Tool.Name) {Gray}not started ($($_.Exception.Message -replace '[{}]', ''))"
            return $false
        }
    }

    $dir = Join-Path ([IO.Path]::GetTempPath()) 'BLOB-OPTIMIZER-tools'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $file = Join-Path $dir ([IO.Path]::GetFileName(([uri]$Tool.Url).AbsolutePath))
    & $Log "{Gray}Downloading {Cyan}$($Tool.Url)"
    $old = $ProgressPreference
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Tool.Url -OutFile $file -UseBasicParsing -ErrorAction Stop
    } catch {
        & $Log "{Red} FAIL {White}Download failed {Gray}($($_.Exception.Message -replace '[{}]', ''))"
        return $false
    } finally { $ProgressPreference = $old }

    $sig = Get-AuthenticodeSignature -FilePath $file
    $subject = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { '(none)' }
    if ($sig.Status -ne 'Valid' -or $subject -notmatch [regex]::Escape($Tool.Signer)) {
        Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
        & $Log "{Red} FAIL {White}Signature check failed {Gray}(status: $($sig.Status), signer: $($subject -replace '[{}]', '')). The file was deleted and not started."
        return $false
    }
    & $Log "{Green} OK   {White}Signature valid {Gray}($($subject -replace '[{}]', ''))"
    try {
        Start-Process -FilePath $file -ErrorAction Stop
        & $Log "{Green} OK   {White}$($Tool.Name) {Gray}started. Downloaded file: $file"
        Add-BlobActionRecord -Source 'external' -Label "Launched $($Tool.Name)" -Target $Tool.Url -Detail "Signed by $subject. Third-party tool; its changes are not tracked by BLOB OPTIMIZER."
        return $true
    } catch {
        & $Log "{Yellow} SKIP {White}$($Tool.Name) {Gray}not started ($($_.Exception.Message -replace '[{}]', ''))"
        return $false
    }
}

# Terminal UI screen for the external tools.
function Show-BlobExternalTools {
    $crumb = 'External Tools'
    while ($true) {
        $items = @($Blob.ExternalTools | ForEach-Object { @{ Label = $_.Name; Right = "{DarkGray}$($_.Publisher)"; Detail = @($_.Summary, "Source: $($_.Url)"); Tool = $_ } })
        $res = Show-BlobMenu -Crumb $crumb -Items $items -Intro @('{White}External tools',
            '{Yellow}Third-party software. Changes made by these tools are not tracked and cannot be undone from Restore.')
        if ($res.Action -ne 'Select') { return }
        $t = $items[$res.Index].Tool
        if (-not (Confirm-BlobAction -Crumb $crumb -Question "Launch $($t.Name)?" -Lines (Get-BlobExternalToolLines $t) -Danger)) { continue }
        Start-BlobWork $crumb
        if ($Blob.IsAdmin -and -not $Blob.DryRun) {
            Write-BlobWork '{Gray}Creating System Restore point first (can take a minute)...'
            Write-BlobWork (New-BlobRestorePoint "BLOB OPTIMIZER - before $($t.Name)")
        }
        $null = Start-BlobExternalTool -Tool $t -Log { param($m) Write-BlobWork $m }
        Complete-BlobWork 'Done.'
    }
}
