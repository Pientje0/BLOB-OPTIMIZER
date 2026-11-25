# ============================================================================
#  BLOB OPTIMIZER - Appearance.ps1
#  How Windows looks: dark mode, accent colour, taskbar, Start, File Explorer
#  and desktop. Every item is a per-user setting (no administrator rights),
#  goes through the same backup / undo journal as every other tweak, and is
#  never part of a preset. After a change Windows is told to refresh its
#  colours, so dark mode switches without signing out.
# ============================================================================

$Blob.AppearanceGroups = @('Colours and theme', 'Taskbar', 'Start menu', 'File Explorer', 'Desktop and scrolling')

$apPers = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$apAdv  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

function Add-BlobAppearanceItem {
    param([string]$Group, [string]$Id, [string]$Name, [string]$Description, [array]$Registry, [string]$Detail,
          [string]$Note, [switch]$RestartExplorer)
    Register-BlobTweak @{
        Id = "app.$Id"; Section = 'Appearance'; Group = $Group; Category = 'Appearance'; Risk = 'Optional'
        Name = $Name; Description = $Description; Registry = $Registry; Note = $Note; RestartExplorer = [bool]$RestartExplorer
    }
    if ($Detail) { $Blob.TweakDetails["app.$Id"] = $Detail }
}

# --- Colours and theme ---------------------------------------------------------
Add-BlobAppearanceItem 'Colours and theme' 'darkapps' 'Dark mode for apps' `
    'Settings, File Explorer, Microsoft Store and apps that follow Windows use dark colours.' `
    @(@{ Path = $apPers; Name = 'AppsUseLightTheme'; Value = 0; Off = 1 }) `
    'The same switch as Settings > Personalization > Colours > Choose your app mode: Dark. Apps that follow the Windows theme switch at once; others (some older programs) keep their own colours. Turning it off returns to light mode.'
Add-BlobAppearanceItem 'Colours and theme' 'darksystem' 'Dark mode for Windows' `
    'Taskbar, Start, notifications and the Action Center use dark colours.' `
    @(@{ Path = $apPers; Name = 'SystemUsesLightTheme'; Value = 0; Off = 1 }) `
    'The same switch as Settings > Personalization > Colours > Choose your Windows mode: Dark. It affects the taskbar, Start, search and notifications, not the apps themselves (that is the switch above).'
Add-BlobAppearanceItem 'Colours and theme' 'autoaccent' 'Pick the accent colour from the wallpaper' `
    'Windows chooses an accent colour that matches your desktop background, and updates it when the wallpaper changes.' `
    @(@{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'AutoColorization'; Value = 1; Off = 0 }) `
    'The same switch as Settings > Personalization > Colours > Accent colour: Automatic. Turn it off to keep a fixed colour; choose that colour in Windows colour settings (link on this page).'
Add-BlobAppearanceItem 'Colours and theme' 'accentbars' 'Accent colour on title bars and window borders' `
    'Active windows get their title bar and border in your accent colour instead of white or black.' `
    @(@{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'ColorPrevalence'; Value = 1; Off = 0 }) `
    'The same switch as Settings > Personalization > Colours > Show accent colour on title bars and window borders. Makes it easier to see which window is active.'
Add-BlobAppearanceItem 'Colours and theme' 'accentstart' 'Accent colour on Start and taskbar' `
    'Start, the taskbar and notifications take on your accent colour.' `
    @(@{ Path = $apPers; Name = 'ColorPrevalence'; Value = 1; Off = 0 }) `
    'The same switch as Settings > Personalization > Colours > Show accent colour on Start and taskbar. Windows only shows it while Windows mode is Dark.' `
    -Note 'Only visible while dark mode for Windows is on.'

# --- Taskbar -------------------------------------------------------------------
Add-BlobAppearanceItem 'Taskbar' 'clockseconds' 'Show seconds in the taskbar clock' `
    'The clock in the corner shows hh:mm:ss.' `
    @(@{ Path = $apAdv; Name = 'ShowSecondsInSystemClock'; Value = 1; Off = 0 }) `
    'Windows 11 23H2 and later (also Windows 10). Uses a tiny bit more power on laptops because the clock redraws every second.' -RestartExplorer
Add-BlobAppearanceItem 'Taskbar' 'nocombine' 'Never combine taskbar buttons' `
    'Every open window gets its own taskbar button with its title, instead of one icon per app.' `
    @(@{ Path = $apAdv; Name = 'TaskbarGlomLevel'; Value = 2; Off = 0 }) `
    'The same as Settings > Personalization > Taskbar > Combine taskbar buttons and hide labels: Never. Windows 11 23H2 and later, and Windows 10.' -RestartExplorer

# --- Start menu ----------------------------------------------------------------
Add-BlobAppearanceItem 'Start menu' 'morepins' 'More pins in Start' `
    'Start shows an extra row of pinned apps and a smaller Recommended section.' `
    @(@{ Path = $apAdv; Name = 'Start_Layout'; Value = 1; Off = 0 }) `
    'The same as Settings > Personalization > Start > Layout: More pins. Windows 11 22H2 and later; ignored on Windows 10.' -RestartExplorer

# --- File Explorer -------------------------------------------------------------
Add-BlobAppearanceItem 'File Explorer' 'compact' 'Compact view in File Explorer' `
    'Less space between files and folders, so more fits on screen (Windows 11 adds extra spacing for touch).' `
    @(@{ Path = $apAdv; Name = 'UseCompactMode'; Value = 1; Off = 0 }) `
    'The same as View > Compact view in File Explorer. Applies to new File Explorer windows.'
Add-BlobAppearanceItem 'File Explorer' 'fullpath' 'Full path in the title bar' `
    'File Explorer shows the complete folder path (for example C:\Users\you\Documents) as its window title.' `
    @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState'; Name = 'FullPath'; Value = 1; Off = 0 }) `
    'The classic Folder Options setting "Display the full path in the title bar". Shows in the taskbar preview and Alt+Tab.'
Add-BlobAppearanceItem 'File Explorer' 'checkboxes' 'Check boxes to select files' `
    'A check box appears on files when you hover them, so you can select several without holding Ctrl.' `
    @(@{ Path = $apAdv; Name = 'AutoCheckSelect'; Value = 1; Off = 0 }) `
    'The same as View > Show > Item check boxes in File Explorer. Handy on touchpads and touch screens.'

# --- Desktop and scrolling -----------------------------------------------------
Add-BlobAppearanceItem 'Desktop and scrolling' 'thispcicon' 'Show This PC on the desktop' `
    'Adds the This PC icon to the desktop for quick access to drives.' `
    @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'; Name = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'; Value = 0; Off = 1 }) `
    'The same as Settings > Personalization > Themes > Desktop icon settings > Computer. Turning it off removes the icon again.' -RestartExplorer
Add-BlobAppearanceItem 'Desktop and scrolling' 'wallpaperquality' 'Full-quality wallpaper' `
    'Stops Windows from recompressing JPG wallpapers to 85% quality, which can cause blur and colour banding.' `
    @(@{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'JPEGImportQuality'; Value = 100; OffDelete = $true }) `
    'Windows normally re-saves a JPG wallpaper at 85% quality. With this on it keeps 100%. Takes effect the next time you set a wallpaper.' `
    -Note 'Set your wallpaper again afterwards to see the difference.'
Add-BlobAppearanceItem 'Desktop and scrolling' 'scrollbars' 'Always show scroll bars' `
    'Scroll bars in Settings and modern apps stay visible instead of shrinking to a thin line.' `
    @(@{ Path = 'HKCU:\Control Panel\Accessibility'; Name = 'DynamicScrollbars'; Value = 0; Off = 1 }) `
    'The same as Settings > Accessibility > Visual effects > Always show scrollbars. Apps that draw their own scroll bars are not affected.'

# Two existing tweaks belong here too: they keep their ids, so their history and undo stay intact.
foreach ($pair in @(@('perf.transparency', 'Colours and theme'), @('tw.leftalign', 'Taskbar'))) {
    $tw = Get-BlobTweak $pair[0]
    if ($tw) { $tw.Section = 'Appearance'; $tw.Group = $pair[1]; $tw.Category = 'Appearance'; $tw.Registry[0].Off = 1 }
}

# Appearance settings have a plain "off" value (the Windows default). When a
# setting was already on before BLOB (dark mode, for example) there is no
# backup to return to, so switching it off writes that value instead. It is
# recorded under "<id>.off", so it never mixes with the tweak's own undo.
function Get-BlobOffTweak {
    param($Tweak)
    if (-not $Tweak -or $Tweak.Section -ne 'Appearance' -or $Tweak.Services.Count) { return $null }
    $ops = @()
    foreach ($op in $Tweak.Registry) {
        if ($op.OffDelete) { $ops += @{ Path = $op.Path; Name = $op.Name; Delete = $true; Type = $op.Type } }
        elseif ($null -ne $op.Off) { $ops += @{ Path = $op.Path; Name = $op.Name; Value = $(if ($op.Type -eq 'String') { [string]$op.Off } else { $op.Off }); Type = $op.Type } }
        else { return $null }
    }
    return @{ Id = "$($Tweak.Id).off"; Name = "$($Tweak.Name): off"; Section = 'Appearance'; Group = $Tweak.Group; Risk = $Tweak.Risk
              Registry = $ops; Services = @(); RestartExplorer = $Tweak.RestartExplorer; Admin = $Tweak.Admin }
}

function Get-BlobAppearanceItems {
    $items = @($Blob.Tweaks | Where-Object { $_.Section -eq 'Appearance' })
    return @(foreach ($g in $Blob.AppearanceGroups) { $items | Where-Object { $_.Group -eq $g } })
}

# Tells running apps that colours and settings changed (what Settings does),
# so dark mode and accent colours update without signing out.
function Send-BlobThemeChange {
    if ($Blob.DryRun) { return }
    try {
        if (-not ('BlobNative.Broadcast' -as [type])) {
            Add-Type -Namespace BlobNative -Name Broadcast -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr hWnd, uint Msg, System.UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out System.UIntPtr lpdwResult);
'@
        }
        $r = [UIntPtr]::Zero
        foreach ($area in @('ImmersiveColorSet', 'WindowsThemeElement')) {
            [void][BlobNative.Broadcast]::SendMessageTimeout([IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, $area, 0x0002, 1000, [ref]$r)
        }
        Write-BlobLog 'Sent a theme refresh to running apps.'
    } catch { Write-BlobLog "Theme refresh broadcast failed: $($_.Exception.Message)" }
}
