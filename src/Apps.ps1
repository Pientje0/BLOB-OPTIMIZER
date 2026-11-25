# ============================================================================
#  BLOB OPTIMIZER - Apps.ps1
#  Complete app removal, done carefully:
#    1. the program's OWN uninstaller runs (it knows how to undo itself);
#    2. only once Windows no longer lists the program, BLOB looks for what
#       it left behind (folders, registry keys, shortcuts, startup entries);
#    3. you choose what to remove. Folders and shortcuts go to the Recycle
#       Bin, registry keys are exported to .reg before deletion, startup
#       entries go through the normal undo journal.
#  Shared locations (Microsoft, Common Files, WindowsApps ...) are never
#  touched, and components Windows depends on cannot be removed.
# ============================================================================

$Blob.AppUninstallRoots = @(
    @{ Hive = 'HKLM'; Sub = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'All users' }
    @{ Hive = 'HKLM'; Sub = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'All users (32-bit)' }
    @{ Hive = 'HKCU'; Sub = 'Software\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'This user' }
)

# Never removable: Windows depends on these.
$Blob.AppProtectedPattern = '^(Microsoft Edge|Microsoft Edge WebView2 Runtime|Microsoft Edge Update|Microsoft Update Health Tools|Windows PC Health Check|Microsoft GameInput)\b'
# Removable, but other programs or hardware may need them.
$Blob.AppSharedPattern = '(Visual C\+\+ .*Redistributable|\.NET (Runtime|Desktop Runtime|Framework|Core)|ASP\.NET Core|DirectX|Windows SDK|Windows Driver|Driver\b|Chipset|Runtime\b|Vulkan|PhysX)'
$Blob.StoreProtected = @('Microsoft.WindowsStore', 'Microsoft.DesktopAppInstaller', 'Microsoft.SecHealthUI', 'Microsoft.StorePurchaseApp',
                         'Microsoft.Winget.Source', 'Microsoft.WindowsTerminal', 'Microsoft.WindowsAppRuntime', 'Microsoft.Windows.ShellExperienceHost')

# Folder names that are shared by many programs and must never be removed.
$Blob.AppSharedFolders = @('microsoft', 'microsoft shared', 'windows', 'windows nt', 'windowsapps', 'common files', 'packages', 'temp', 'programs',
    'package cache', 'windows defender', 'windows mail', 'windows media player', 'windows photo viewer', 'windows portable devices',
    'windows sidebar', 'windowspowershell', 'internet explorer', 'microsoft.net', 'reference assemblies', 'msbuild', 'dotnet',
    'intel', 'nvidia', 'nvidia corporation', 'amd', 'realtek', 'google', 'mozilla', 'adobe', 'apple', 'oracle', 'java', 'blob-optimizer',
    'desktop', 'documents', 'downloads', 'start menu', 'startup', 'roaming', 'local', 'locallow', 'appdata', 'users', 'public')

function Read-BlobRegString {
    param($Key, [string]$Name)
    try { $v = $Key.GetValue($Name, $null); if ($null -eq $v) { return '' } return ([string]$v).Trim() } catch { return '' }
}

# Desktop programs from the three Uninstall registry locations (fast, .NET reads).
function Get-BlobDesktopApps {
    $list = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($r in $Blob.AppUninstallRoots) {
        $root = if ($r.Hive -eq 'HKCU') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine }
        $base = $null
        try { $base = $root.OpenSubKey($r.Sub, $false) } catch { }
        if (-not $base) { continue }
        try {
            foreach ($subName in $base.GetSubKeyNames()) {
                $k = $null
                try { $k = $base.OpenSubKey($subName, $false) } catch { }
                if (-not $k) { continue }
                try {
                    $name = Read-BlobRegString $k 'DisplayName'
                    if (-not $name) { continue }
                    if ($k.GetValue('SystemComponent', 0) -eq 1) { continue }
                    if (Read-BlobRegString $k 'ParentKeyName') { continue }
                    if ((Read-BlobRegString $k 'ReleaseType') -match 'Update|Hotfix') { continue }
                    $uninst = Read-BlobRegString $k 'UninstallString'
                    $msi = ($k.GetValue('WindowsInstaller', 0) -eq 1) -or ($uninst -match '(?i)msiexec')
                    if (-not $uninst -and -not $msi) { continue }
                    $ver = Read-BlobRegString $k 'DisplayVersion'
                    $dedupe = "$name|$ver"
                    if ($seen.ContainsKey($dedupe)) { continue }
                    $seen[$dedupe] = $true
                    $size = 0
                    try { $size = [double]$k.GetValue('EstimatedSize', 0) * 1KB } catch { }
                    $date = $null
                    $d = Read-BlobRegString $k 'InstallDate'
                    if ($d -match '^\d{8}$') { try { $date = [datetime]::ParseExact($d, 'yyyyMMdd', $null) } catch { } }
                    [void]$list.Add([pscustomobject]@{
                        Kind = 'Desktop'; Name = $name; Publisher = Read-BlobRegString $k 'Publisher'; Version = $ver
                        SizeBytes = $size; InstallDate = $date; Scope = $r.Scope
                        InstallLocation = (Read-BlobRegString $k 'InstallLocation').Trim('"').TrimEnd('\')
                        UninstallString = $uninst; Msi = $msi; ProductCode = $(if ($subName -match '^\{[0-9A-Fa-f-]{36}\}$') { $subName } else { '' })
                        KeyPath = "$($r.Hive):\$($r.Sub)\$subName"; Id = "$($r.Hive):\$($r.Sub)\$subName"
                        Protected = ($name -match $Blob.AppProtectedPattern); Shared = ($name -match $Blob.AppSharedPattern)
                        NeedsAdmin = ($r.Hive -eq 'HKLM')
                    })
                } finally { $k.Dispose() }
            }
        } finally { $base.Dispose() }
    }
    return $list.ToArray()
}

# Microsoft Store apps for this user. System and framework packages are left out.
# The same function text also runs on the background data thread.
function Get-BlobStoreAppsLive {
    param([string[]]$Protected = @())
    $pkgs = $null
    try { $pkgs = @(Get-AppxPackage -ErrorAction Stop) }
    catch {
        try { Import-Module Appx -UseWindowsPowerShell -ErrorAction Stop -WarningAction SilentlyContinue; $pkgs = @(Get-AppxPackage -ErrorAction Stop) } catch { return @() }
    }
    $out = New-Object System.Collections.ArrayList
    foreach ($p in $pkgs) {
        if ($p.IsFramework -or $p.IsResourcePackage -or $p.NonRemovable -or [string]$p.SignatureKind -eq 'System') { continue }
        $name = $null; $pubName = $null
        try {
            $m = [xml](Get-Content -LiteralPath (Join-Path $p.InstallLocation 'AppxManifest.xml') -Raw -ErrorAction Stop)
            $dn = [string]$m.Package.Properties.DisplayName
            if ($dn -and $dn -notlike 'ms-resource:*') { $name = $dn }
            $pdn = [string]$m.Package.Properties.PublisherDisplayName
            if ($pdn -and $pdn -notlike 'ms-resource:*') { $pubName = $pdn }
        } catch { }
        if (-not $name) { $name = (($p.Name -replace '^[^.]+\.', '') -creplace '([a-z])([A-Z])', '$1 $2') -replace '\.', ' ' }
        $pub = if ($pubName) { $pubName } elseif ([string]$p.Publisher -match 'CN=([^,]+)') { $Matches[1].Trim('"') } else { [string]$p.Publisher }
        $pubName = $null
        $date = $null
        try { $date = (Get-Item -LiteralPath $p.InstallLocation -ErrorAction Stop).CreationTime } catch { }
        [void]$out.Add([pscustomobject]@{
            Kind = 'Store'; Name = $name; Publisher = $pub; Version = [string]$p.Version; SizeBytes = 0; InstallDate = $date; Scope = 'This user'
            InstallLocation = [string]$p.InstallLocation; UninstallString = ''; Msi = $false; ProductCode = ''
            FullName = [string]$p.PackageFullName; PackageName = [string]$p.Name; KeyPath = ''; Id = "appx:$($p.PackageFullName)"
            Protected = ($p.Name -in $Protected); Shared = $false; NeedsAdmin = $false
        })
    }
    return $out.ToArray()
}

function Get-BlobStoreApps {
    $pre = @(Get-BlobPrefetch 'StoreApps')
    if ($pre.Count -gt 0) { return $pre }
    return @(Get-BlobStoreAppsLive -Protected $Blob.StoreProtected)
}

# ---------------------------------------------------------------------------
#  Uninstall
# ---------------------------------------------------------------------------
# Splits an UninstallString into program + arguments. MSI installs are turned
# into an uninstall (/X) of the product code.
function Split-BlobCommand {
    param($App)
    $cmd = [Environment]::ExpandEnvironmentVariables([string]$App.UninstallString).Trim()
    if ($App.Msi) {
        $code = $App.ProductCode
        if (-not $code -and $cmd -match '(\{[0-9A-Fa-f-]{36}\})') { $code = $Matches[1] }
        if ($code) { return @{ Exe = 'msiexec.exe'; Args = "/X$code" } }
    }
    if ($cmd -match '^"([^"]+)"\s*(.*)$') { return @{ Exe = $Matches[1]; Args = $Matches[2] } }
    if ($cmd -match '^(.+?\.exe)\s*(.*)$') { return @{ Exe = $Matches[1]; Args = $Matches[2] } }
    return @{ Exe = $cmd; Args = '' }
}

function Test-BlobAppInstalled {
    param($App)
    if ($App.Kind -eq 'Store') { return [bool](@(Get-AppxPackage -Name $App.PackageName -ErrorAction SilentlyContinue).Count) }
    return (Get-BlobRegState $App.KeyPath 'DisplayName').Exists
}

# Starts the app's own uninstaller and waits for it. -Pump keeps the window
# responsive while waiting. Returns 'Finished', 'Removed' (Store) or an error text.
function Invoke-BlobAppUninstall {
    param($App, [scriptblock]$Log = { param($m) }, [scriptblock]$Pump = { Start-Sleep -Milliseconds 200 })
    if ($Blob.DryRun) { & $Log "{Magenta}Dry run - would uninstall $($App.Name)"; return 'DryRun' }
    if ($App.Kind -eq 'Store') {
        try {
            Remove-AppxPackage -Package $App.FullName -ErrorAction Stop
            Add-BlobActionRecord -Source 'apps' -Label "Uninstalled $($App.Name) (Store app)" -Target $App.FullName -Detail 'Windows removed the app and its data.'
            & $Log "{White} OK   {White}$($App.Name) {Gray}removed together with its app data."
            return 'Removed'
        } catch { return "Could not remove the app: $($_.Exception.Message)" }
    }
    $c = Split-BlobCommand $App
    & $Log "{Gray}Starting the uninstaller: $($c.Exe) $($c.Args)"
    try {
        $p = if ($c.Args) { Start-Process -FilePath $c.Exe -ArgumentList $c.Args -PassThru -ErrorAction Stop } else { Start-Process -FilePath $c.Exe -PassThru -ErrorAction Stop }
    } catch { return "The uninstaller could not be started: $($_.Exception.Message)" }
    while (-not $p.HasExited) { & $Pump }
    Add-BlobActionRecord -Source 'apps' -Label "Ran the uninstaller of $($App.Name)" -Target $App.KeyPath -Detail "$($c.Exe) $($c.Args) (exit code $($p.ExitCode))"
    & $Log "{Gray}Uninstaller closed (exit code $($p.ExitCode))."
    return 'Finished'
}

# ---------------------------------------------------------------------------
#  Leftovers
# ---------------------------------------------------------------------------
function Get-BlobAppNameVariants {
    param($App)
    $n = [string]$App.Name
    $v = New-Object System.Collections.ArrayList
    [void]$v.Add($n)
    $short = $n -replace '\s*\((x64|x86|64-bit|32-bit|64 bit|32 bit|amd64|arm64)\)', '' -replace '\s+v?\d+(\.\d+)+.*$', '' -replace '\s+(x64|x86|64-bit|32-bit)$', ''
    [void]$v.Add($short.Trim())
    $pub = Get-BlobCleanPublisher $App.Publisher
    if ($pub -and $short -like "$pub *") { [void]$v.Add($short.Substring($pub.Length).Trim()) }
    return @($v | Where-Object { $_ -and $_.Length -ge 3 -and $_.ToLower() -notin $Blob.AppSharedFolders } | Select-Object -Unique)
}

function Get-BlobCleanPublisher {
    param([string]$Publisher)
    $p = ($Publisher -replace ',?\s+(Inc\.?|LLC|Ltd\.?|Limited|Corporation|Corp\.?|GmbH|Co\.?|S\.A\.|B\.V\.|AB|Software|Technologies)$', '').Trim()
    $p = ($p -replace ',?\s+(Inc\.?|LLC|Ltd\.?|Corporation)$', '').Trim()
    return $p
}

# True only for folders that are clearly one program's own, never shared roots.
function Test-BlobSafeAppFolder {
    param([string]$Path)
    if (-not $Path) { return $false }
    try { $full = [IO.Path]::GetFullPath($Path).TrimEnd('\') } catch { return $false }
    $leaf = (Split-Path $full -Leaf).ToLower()
    if ($leaf -in $Blob.AppSharedFolders -or $leaf -like 'microsoft*' -or $leaf -like 'windows*') { return $false }
    $roots = @(($env:SystemDrive + '\'), $env:windir, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData, $env:APPDATA, $env:LOCALAPPDATA,
               (Join-Path $env:LOCALAPPDATA 'Programs'), $env:USERPROFILE, $env:PUBLIC, (Join-Path $env:ProgramFiles 'Common Files'),
               [Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('CommonPrograms'),
               [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktopDirectory')) |
             Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
    foreach ($r in $roots) {
        if ($full -ieq $r) { return $false }
        if ($r -like "$full\*") { return $false }          # a parent of a protected root
    }
    if ($full -like "$($env:windir)\*") { return $false }
    if ($full -like '*\WindowsApps*' -or $full -like '*\Common Files*' -or $full -like '*\Microsoft\Windows*') { return $false }
    if ($Blob.DataRoot -and $full -like "$($Blob.DataRoot)*") { return $false }
    # must sit at least one level inside a known root
    foreach ($r in $roots) { if ($full -like "$r\*") { return $true } }
    return $false
}

function Test-BlobSafeAppKey {
    param([string]$Path)
    $parts = @($Path -split '\\' | Where-Object { $_ })
    if ($parts.Count -lt 3) { return $false }
    $leaf = $parts[-1].ToLower()
    if ($leaf -in @('microsoft', 'classes', 'policies', 'wow6432node', 'windows', 'clients', 'registeredapplications') -or $leaf -in $Blob.AppSharedFolders) { return $false }
    return $true
}

function Get-BlobFolderSize {
    param([string]$Path)
    try {
        $m = Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
        return @{ Bytes = [double]$m.Sum; Count = [int]$m.Count }
    } catch { return @{ Bytes = 0; Count = 0 } }
}

# Finds what a removed program left behind. Only exact name matches.
function Find-BlobAppLeftovers {
    param($App)
    $items = New-Object System.Collections.ArrayList
    $seen = @{}
    $add = {
        param($Type, $Path, $Detail, $Data)
        $key = "$Type|$Path".ToLower()
        if ($seen.ContainsKey($key)) { return }
        $seen[$key] = $true
        [void]$items.Add([pscustomobject]@{ Type = $Type; Path = $Path; Detail = $Detail; Data = $Data })
    }
    $names = @(Get-BlobAppNameVariants $App)
    $pub = Get-BlobCleanPublisher $App.Publisher
    $pubs = @($pub, $App.Publisher) | Where-Object { $_ -and $_.Length -ge 2 } | Select-Object -Unique

    # Folders
    $folderRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData, $env:APPDATA, $env:LOCALAPPDATA, (Join-Path $env:LOCALAPPDATA 'Programs')) | Where-Object { $_ }
    $candidates = New-Object System.Collections.ArrayList
    if ($App.InstallLocation) { [void]$candidates.Add($App.InstallLocation) }
    foreach ($r in $folderRoots) {
        foreach ($n in $names) {
            [void]$candidates.Add((Join-Path $r $n))
            foreach ($p in $pubs) { [void]$candidates.Add((Join-Path (Join-Path $r $p) $n)) }
        }
    }
    foreach ($c in $candidates) {
        if (-not (Test-Path -LiteralPath $c -PathType Container)) { continue }
        if (-not (Test-BlobSafeAppFolder $c)) { continue }
        $sz = Get-BlobFolderSize $c
        & $add 'Folder' ([IO.Path]::GetFullPath($c).TrimEnd('\')) ("{0}, {1} files" -f (Format-BlobSize $sz.Bytes), $sz.Count) $null
    }

    # Registry keys
    $regRoots = @('HKCU:\Software', 'HKLM:\SOFTWARE', 'HKLM:\SOFTWARE\WOW6432Node')
    foreach ($r in $regRoots) {
        foreach ($n in $names) {
            $paths = @("$r\$n") + @($pubs | ForEach-Object { "$r\$_\$n" })
            foreach ($k in $paths) {
                if (-not (Test-Path -LiteralPath $k)) { continue }
                if (-not (Test-BlobSafeAppKey $k)) { continue }
                & $add 'Registry key' $k 'exported to a .reg backup before removal' $null
            }
        }
    }

    # Shortcuts (Start menu folders and .lnk files, desktops)
    $menus = @([Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('CommonPrograms')) | Where-Object { $_ }
    $desks = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktopDirectory')) | Where-Object { $_ }
    foreach ($n in $names) {
        foreach ($m in $menus) {
            $dir = Join-Path $m $n
            if ((Test-Path -LiteralPath $dir -PathType Container) -and (Test-BlobSafeAppFolder $dir)) { & $add 'Start menu folder' $dir 'shortcuts' $null }
            $lnk = Join-Path $m "$n.lnk"
            if (Test-Path -LiteralPath $lnk -PathType Leaf) { & $add 'Shortcut' $lnk 'Start menu' $null }
        }
        foreach ($d in $desks) {
            $lnk = Join-Path $d "$n.lnk"
            if (Test-Path -LiteralPath $lnk -PathType Leaf) { & $add 'Shortcut' $lnk 'Desktop' $null }
        }
    }

    # Startup entries that still point into the program's folder
    if ($App.InstallLocation -and $App.InstallLocation.Length -gt 6) {
        foreach ($src in $Blob.StartupSources) {
            if (-not $src.Key) { continue }
            $st = $null
            try { $st = Get-Item -LiteralPath $src.Key -ErrorAction Stop } catch { continue }
            foreach ($vn in $st.GetValueNames()) {
                if (-not $vn) { continue }
                $val = [string]$st.GetValue($vn, '')
                if ($val -like "*$($App.InstallLocation)*") { & $add 'Startup entry' "$(Format-BlobRegPath $src.Key)\$vn" $val @{ Path = $src.Key; Name = $vn } }
            }
        }
    }
    return $items.ToArray()
}

# Removes one leftover in a recoverable way. Returns a result line.
function Remove-BlobLeftover {
    param($Item, [string]$BackupDir, [string]$AppName)
    if ($Blob.DryRun) { return "{Magenta} DRY  {White}$($Item.Type): {Gray}$($Item.Path)" }
    try {
        switch -Wildcard ($Item.Type) {
            'Registry key' {
                if ((Test-BlobNeedsAdmin $Item.Path) -and -not $Blob.IsAdmin) { throw 'administrator rights required' }
                Initialize-BlobStorage
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                $file = Join-Path $BackupDir ('{0:D2}.reg' -f (@(Get-ChildItem -LiteralPath $BackupDir -Filter *.reg).Count + 1))
                $null = & reg.exe export (Format-BlobRegPath $Item.Path) $file /y 2>&1
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $file)) { throw 'backup export failed, key not removed' }
                Remove-Item -LiteralPath $Item.Path -Recurse -Force -ErrorAction Stop
                $rec = New-BlobChangeRecord -Kind 'RegKeyDelete' -Source 'apps' -Label "Removed leftover key of $AppName" -Target (Format-BlobRegPath $Item.Path) -Data @{ Path = $Item.Path; BackupFile = $file }
                $rec.Status = 'Applied'
                Add-BlobChange $rec
                return "{White} OK   {White}Registry key removed {Gray}$(Format-BlobRegPath $Item.Path)  (backup: $file)"
            }
            'Startup entry' {
                $r = Set-BlobRegValue -Path $Item.Data.Path -Name $Item.Data.Name -Delete -Source 'apps' -Label "Removed leftover startup entry of $AppName"
                return (Format-BlobResult $r)
            }
            default {
                Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction SilentlyContinue
                if (Test-Path -LiteralPath $Item.Path -PathType Container) {
                    if (-not (Test-BlobSafeAppFolder $Item.Path)) { throw 'refused: not a program-specific folder' }
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Item.Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
                } else {
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Item.Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
                }
                Add-BlobActionRecord -Source 'apps' -Label "Moved leftover of $AppName to the Recycle Bin" -Target $Item.Path -Detail 'Restore it from the Recycle Bin if needed.'
                return "{White} OK   {White}$($Item.Type) moved to the Recycle Bin {Gray}$($Item.Path)"
            }
        }
    } catch { return "{Red} FAIL {White}$($Item.Type) {Gray}$($Item.Path) ($($_.Exception.Message -replace '[{}]', ''))" }
}

function Restore-BlobRegKeyDelete {
    param($Record)
    $file = $Record.Data.BackupFile
    if (-not (Test-Path -LiteralPath $file)) { throw "The backup file is missing: $file" }
    $null = & reg.exe import $file 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Record.Data.Path)) { throw 'reg import did not restore the key.' }
}
