# ============================================================================
#  BLOB OPTIMIZER - Tweaks.ps1
#  File Explorer, taskbar, Start menu and general Windows behaviour.
# ============================================================================

$advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

# --- Essential: File Explorer ----------------------------------------------
Register-BlobTweak @{
    Id = 'tw.fileext'; Section = 'Tweaks'; Group = 'Essential - File Explorer'; Risk = 'Minimal'; RestartExplorer = $true
    Name = 'Show file extensions'
    Description = 'Always show extensions such as .exe and .pdf. Helps spot disguised files like "invoice.pdf.exe".'
    Registry = @(@{ Path = $advKey; Name = 'HideFileExt'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'tw.thispc'; Section = 'Tweaks'; Group = 'Essential - File Explorer'; Risk = 'Minimal'; RestartExplorer = $true
    Name = 'Open File Explorer to This PC'
    Description = 'File Explorer starts on This PC (drives) instead of Home / Quick access.'
    Registry = @(@{ Path = $advKey; Name = 'LaunchTo'; Value = 1 })
}
Register-BlobTweak @{
    Id = 'tw.hidden'; Section = 'Tweaks'; Group = 'Essential - File Explorer'; Risk = 'Optional'; RestartExplorer = $true
    Name = 'Show hidden files and folders'
    Description = 'Shows items marked hidden (protected operating system files stay hidden).'
    Registry = @(@{ Path = $advKey; Name = 'Hidden'; Value = 1 })
}
Register-BlobTweak @{
    Id = 'tw.recent'; Section = 'Tweaks'; Group = 'Essential - File Explorer'; Risk = 'Standard'; RestartExplorer = $true
    Name = 'Hide recent files in Quick access'
    Description = 'Stops Explorer Home from listing recently used files and frequently used folders.'
    Registry = @(
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowRecent'; Value = 0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowFrequent'; Value = 0 })
}

# --- Essential: Taskbar ------------------------------------------------------
Register-BlobTweak @{
    Id = 'tw.searchicon'; Section = 'Tweaks'; Group = 'Essential - Taskbar'; Risk = 'Minimal'; RestartExplorer = $true
    Name = 'Taskbar search as icon only'
    Description = 'Replaces the wide search box on the taskbar with a compact search icon.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Value = 1 })
}
Register-BlobTweak @{
    Id = 'tw.taskview'; Section = 'Tweaks'; Group = 'Essential - Taskbar'; Risk = 'Standard'; RestartExplorer = $true
    Name = 'Hide Task View button'
    Description = 'Removes the Task View button. Win+Tab still opens Task View.'
    Registry = @(@{ Path = $advKey; Name = 'ShowTaskViewButton'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'tw.widgets'; Category = 'Performance'; Section = 'Tweaks'; Group = 'Essential - Taskbar'; Risk = 'Standard'
    Name = 'Disable Widgets (news and interests)'
    Description = 'Turns off the Widgets board and its taskbar button via the documented Windows policy.'
    Registry = @(@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Value = 0 })
    Note = 'Applies after sign-out or restart.'
}
Register-BlobTweak @{
    Id = 'tw.endtask'; Section = 'Tweaks'; Group = 'Essential - Taskbar'; Risk = 'Optional'; RestartExplorer = $true
    Name = 'Add "End task" to taskbar right-click'
    Description = 'Windows 11 23H2+: right-click a taskbar app to force-close it without Task Manager.'
    Registry = @(@{ Path = "$advKey\TaskbarDeveloperSettings"; Name = 'TaskbarEndTask'; Value = 1 })
}
Register-BlobTweak @{
    Id = 'tw.leftalign'; Section = 'Tweaks'; Group = 'Essential - Taskbar'; Risk = 'Optional'; RestartExplorer = $true
    Name = 'Align taskbar to the left'
    Description = 'Windows 11: places the Start button and apps on the left, like Windows 10.'
    Registry = @(@{ Path = $advKey; Name = 'TaskbarAl'; Value = 0 })
}

# --- Essential: Start menu ---------------------------------------------------
Register-BlobTweak @{
    Id = 'tw.startrecs'; Section = 'Tweaks'; Group = 'Essential - Start menu'; Risk = 'Standard'; RestartExplorer = $true
    Name = 'Fewer Start menu recommendations'
    Description = 'Stops Start from showing recently opened files and promoted recommendations.'
    Registry = @(
        @{ Path = $advKey; Name = 'Start_TrackDocs'; Value = 0 },
        @{ Path = $advKey; Name = 'Start_IrisRecommendations'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'tw.websearch'; Category = 'Privacy & Security'; Section = 'Tweaks'; Group = 'Essential - Start menu'; Risk = 'Standard'
    Name = 'Disable web results in Start search'
    Description = 'Start search shows only local apps, files and settings - no Bing web suggestions.'
    Registry = @(@{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Value = 1 })
    Note = 'Applies after sign-out.'
}

# --- Advanced ----------------------------------------------------------------
Register-BlobTweak @{
    Id = 'tw.classicmenu'; Section = 'Tweaks'; Group = 'Advanced'; Risk = 'Optional'; RestartExplorer = $true
    Name = 'Classic right-click menu (Windows 11)'
    Description = 'Shows the full classic context menu immediately instead of "Show more options".'
    Registry = @(@{ Path = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name = '(default)'; Value = ''; Type = 'String' })
    Note = 'Undo removes the keys again. A future Windows update may ignore this setting.'
}
Register-BlobTweak @{
    Id = 'tw.verbose'; Section = 'Tweaks'; Group = 'Advanced'; Risk = 'Optional'
    Name = 'Detailed status messages at sign-in/shutdown'
    Description = 'Shows what Windows is doing (e.g. "Stopping services") instead of a generic "Please wait".'
    Registry = @(@{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'VerboseStatus'; Value = 1 })
}
Register-BlobTweak @{
    Id = 'tw.longpaths'; Section = 'Tweaks'; Group = 'Advanced'; Risk = 'Advanced'
    Name = 'Enable Win32 long paths'
    Description = 'Allows supporting applications to use file paths longer than 260 characters.'
    Registry = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'LongPathsEnabled'; Value = 1 })
    Warning = 'Older applications that do not support long paths are unaffected but may still fail on them.'
}

# --- Windows behaviour -------------------------------------------------------
Register-BlobTweak @{
    Id = 'tw.snapsuggest'; Section = 'Tweaks'; Group = 'Windows behaviour'; Risk = 'Optional'
    Name = 'Disable Snap Assist suggestions'
    Description = 'When snapping a window, Windows no longer suggests other windows to fill the rest of the screen.'
    Registry = @(@{ Path = $advKey; Name = 'SnapAssist'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'tw.settingsads'; Section = 'Tweaks'; Group = 'Windows behaviour'; Risk = 'Minimal'
    Name = 'No "finish setting up your device" prompts'
    Description = 'Stops the recurring full-screen prompts suggesting Microsoft account and service setup.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'; Name = 'ScoobeSystemSettingEnabled'; Value = 0 })
}

function Show-BlobTweaks {
    Show-BlobTweakSection -Section 'Tweaks' -Crumb 'Tweaks' -Intro @(
        '{White}Windows tweaks',
        '{Gray}Essential tweaks are safe everyday settings. OPTIONAL items are personal preferences (never in presets).') -Extras @(
        @{ Label = 'Restart Windows Explorer'; Detail = 'Reloads the taskbar and Explorer so layout changes appear immediately.'
           Action = { Request-BlobExplorerRestart 'Tweaks' } }
    )
}
