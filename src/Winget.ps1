# ============================================================================
#  BLOB OPTIMIZER - Winget.ps1
#  Installs popular apps with winget, the package manager built into
#  Windows 10/11 (App Installer). Packages come from the official winget
#  community repository; BLOB itself downloads nothing. Every install is
#  confirmed first and recorded in the journal; remove apps on the Apps page.
# ============================================================================

$Blob.WingetCatalog = @(
    # Browsers
    @{ Id = 'Mozilla.Firefox'; Name = 'Firefox'; Cat = 'Browsers' }
    @{ Id = 'Google.Chrome'; Name = 'Google Chrome'; Cat = 'Browsers' }
    @{ Id = 'Brave.Brave'; Name = 'Brave'; Cat = 'Browsers' }
    @{ Id = 'Opera.OperaGX'; Name = 'Opera GX'; Cat = 'Browsers' }
    @{ Id = 'LibreWolf.LibreWolf'; Name = 'LibreWolf'; Cat = 'Browsers' }
    # Gaming
    @{ Id = 'Valve.Steam'; Name = 'Steam'; Cat = 'Gaming' }
    @{ Id = 'EpicGames.EpicGamesLauncher'; Name = 'Epic Games Launcher'; Cat = 'Gaming' }
    @{ Id = 'GOG.Galaxy'; Name = 'GOG Galaxy'; Cat = 'Gaming' }
    @{ Id = 'Ubisoft.Connect'; Name = 'Ubisoft Connect'; Cat = 'Gaming' }
    @{ Id = 'ElectronicArts.EADesktop'; Name = 'EA app'; Cat = 'Gaming' }
    @{ Id = 'Playnite.Playnite'; Name = 'Playnite'; Cat = 'Gaming' }
    @{ Id = 'Guru3D.Afterburner'; Name = 'MSI Afterburner'; Cat = 'Gaming' }
    # Communication
    @{ Id = 'Discord.Discord'; Name = 'Discord'; Cat = 'Communication' }
    @{ Id = 'OpenWhisperSystems.Signal'; Name = 'Signal'; Cat = 'Communication' }
    @{ Id = 'Telegram.TelegramDesktop'; Name = 'Telegram'; Cat = 'Communication' }
    @{ Id = 'Zoom.Zoom'; Name = 'Zoom'; Cat = 'Communication' }
    @{ Id = 'SlackTechnologies.Slack'; Name = 'Slack'; Cat = 'Communication' }
    # Media
    @{ Id = 'VideoLAN.VLC'; Name = 'VLC media player'; Cat = 'Media' }
    @{ Id = 'Spotify.Spotify'; Name = 'Spotify'; Cat = 'Media' }
    @{ Id = 'OBSProject.OBSStudio'; Name = 'OBS Studio'; Cat = 'Media' }
    @{ Id = 'Audacity.Audacity'; Name = 'Audacity'; Cat = 'Media' }
    @{ Id = 'HandBrake.HandBrake'; Name = 'HandBrake'; Cat = 'Media' }
    @{ Id = 'GIMP.GIMP'; Name = 'GIMP'; Cat = 'Media' }
    # Utilities
    @{ Id = '7zip.7zip'; Name = '7-Zip'; Cat = 'Utilities' }
    @{ Id = 'voidtools.Everything'; Name = 'Everything (file search)'; Cat = 'Utilities' }
    @{ Id = 'Microsoft.PowerToys'; Name = 'PowerToys'; Cat = 'Utilities' }
    @{ Id = 'Notepad++.Notepad++'; Name = 'Notepad++'; Cat = 'Utilities' }
    @{ Id = 'ShareX.ShareX'; Name = 'ShareX'; Cat = 'Utilities' }
    @{ Id = 'WinDirStat.WinDirStat'; Name = 'WinDirStat'; Cat = 'Utilities' }
    @{ Id = 'Rufus.Rufus'; Name = 'Rufus'; Cat = 'Utilities' }
    # Hardware info
    @{ Id = 'CPUID.CPU-Z'; Name = 'CPU-Z'; Cat = 'Hardware info' }
    @{ Id = 'TechPowerUp.GPU-Z'; Name = 'GPU-Z'; Cat = 'Hardware info' }
    @{ Id = 'REALiX.HWiNFO'; Name = 'HWiNFO'; Cat = 'Hardware info' }
    @{ Id = 'CrystalDewWorld.CrystalDiskInfo'; Name = 'CrystalDiskInfo'; Cat = 'Hardware info' }
    @{ Id = 'CrystalDewWorld.CrystalDiskMark'; Name = 'CrystalDiskMark'; Cat = 'Hardware info' }
    # Security and passwords
    @{ Id = 'Bitwarden.Bitwarden'; Name = 'Bitwarden'; Cat = 'Passwords' }
    @{ Id = 'KeePassXCTeam.KeePassXC'; Name = 'KeePassXC'; Cat = 'Passwords' }
    # Documents
    @{ Id = 'TheDocumentFoundation.LibreOffice'; Name = 'LibreOffice'; Cat = 'Documents' }
    @{ Id = 'SumatraPDF.SumatraPDF'; Name = 'SumatraPDF'; Cat = 'Documents' }
    @{ Id = 'Adobe.Acrobat.Reader.64-bit'; Name = 'Adobe Acrobat Reader'; Cat = 'Documents' }
    @{ Id = 'Obsidian.Obsidian'; Name = 'Obsidian'; Cat = 'Documents' }
    # Development
    @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code'; Cat = 'Development' }
    @{ Id = 'Git.Git'; Name = 'Git'; Cat = 'Development' }
    @{ Id = 'Python.Python.3.12'; Name = 'Python 3.12'; Cat = 'Development' }
    @{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS'; Cat = 'Development' }
    @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7'; Cat = 'Development' }
    @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal'; Cat = 'Development' }
    # Runtimes
    @{ Id = 'Microsoft.VCRedist.2015+.x64'; Name = 'Visual C++ Redistributable (x64)'; Cat = 'Runtimes' }
    @{ Id = 'Microsoft.DotNet.DesktopRuntime.8'; Name = '.NET Desktop Runtime 8'; Cat = 'Runtimes' }
)

function Test-BlobWinget { return [bool](Get-Command winget.exe -ErrorAction SilentlyContinue) }

# Text of "winget list" (the background data thread collects it once).
function Get-BlobWingetListText {
    $pre = Get-BlobPrefetch 'WingetList'
    if ($pre) { return [string]$pre }
    if (-not (Test-BlobWinget)) { return '' }
    try { return ((& winget.exe list --accept-source-agreements --disable-interactivity 2>$null) | Out-String) } catch { return '' }
}

function Get-BlobWingetInstalledIds {
    param([string]$ListText)
    $found = @{}
    foreach ($a in $Blob.WingetCatalog) {
        if ($ListText -match ('(?im)(^|\s)' + [regex]::Escape($a.Id) + '(\s|$)')) { $found[$a.Id] = $true }
    }
    return $found
}

# winget result codes worth explaining (hex as shown in winget docs).
$Blob.WingetCodes = @{
    0 = 'installed'; -1978335135 = 'already installed'; -1978335189 = 'no matching installer for this PC'
    -1978335212 = 'package not found in the winget source'; -1978334967 = 'installer reported a restart is needed'
}

# Runs one winget command; -Pump keeps the window responsive. Returns @{ Code; Text; Last }.
function Invoke-BlobWingetCommand {
    param([string]$Arguments, [scriptblock]$Pump = { Start-Sleep -Milliseconds 200 })
    $log = Join-Path ([IO.Path]::GetTempPath()) ("blob-winget-{0}.log" -f ([guid]::NewGuid().ToString('N').Substring(0, 8)))
    $p = Start-Process -FilePath 'winget.exe' -ArgumentList $Arguments -PassThru -NoNewWindow -RedirectStandardOutput $log -ErrorAction Stop
    while (-not $p.HasExited) { & $Pump }
    $text = ''
    try { $text = Get-Content -LiteralPath $log -Raw -ErrorAction Stop } catch { }
    Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
    $last = @(($text -split "`r?`n") | ForEach-Object { ($_ -replace '[^\x20-\x7E]', '').Trim() } | Where-Object { $_ -and $_ -notmatch '^[-\\|/ ]+$' }) | Select-Object -Last 1
    return @{ Code = $p.ExitCode; Text = $text; Last = $last }
}

function Install-BlobWingetApp {
    param($App, [scriptblock]$Log = { param($m) }, [scriptblock]$Pump = { Start-Sleep -Milliseconds 200 })
    if ($Blob.DryRun) { & $Log "{Magenta} DRY  {White}$($App.Name) {Gray}would be installed ($($App.Id))"; return }
    & $Log "{Gray}Installing $($App.Name) ($($App.Id))..."
    try { $r = Invoke-BlobWingetCommand "install --id `"$($App.Id)`" --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity" $Pump }
    catch { & $Log "{Red} FAIL {White}$($App.Name) {Gray}($($_.Exception.Message -replace '[{}]', ''))"; return }
    $what = if ($Blob.WingetCodes.ContainsKey($r.Code)) { $Blob.WingetCodes[$r.Code] } else { "winget exit code $($r.Code): $($r.Last)" }
    if ($r.Code -in @(0, -1978335135, -1978334967)) {
        & $Log "{White} OK   {White}$($App.Name) {Gray}$what"
        if ($r.Code -eq 0) { Add-BlobActionRecord -Source 'install' -Label "Installed $($App.Name) with winget" -Target $App.Id -Detail 'Remove it from the Apps page if you no longer want it.' }
    } else { & $Log "{Red} FAIL {White}$($App.Name) {Gray}$($what -replace '[{}]', '')" }
}

function Update-BlobWingetAll {
    param([scriptblock]$Log = { param($m) }, [scriptblock]$Pump = { Start-Sleep -Milliseconds 200 })
    if ($Blob.DryRun) { & $Log '{Magenta} DRY  {White}winget upgrade --all would run'; return }
    & $Log '{Gray}Updating every app winget can update (this can take a while)...'
    $r = Invoke-BlobWingetCommand 'upgrade --all --accept-package-agreements --accept-source-agreements --disable-interactivity' $Pump
    $count = ([regex]::Matches($r.Text, '(?i)Successfully installed')).Count
    & $Log ("{White} OK   {White}Update finished {Gray}({0} package(s) updated, exit code {1})" -f $count, $r.Code)
    Add-BlobActionRecord -Source 'install' -Label 'Updated apps with winget' -Target 'winget upgrade --all' -Detail "$count package(s) updated"
}
