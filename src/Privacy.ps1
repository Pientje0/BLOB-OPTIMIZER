# ============================================================================
#  BLOB OPTIMIZER - Privacy.ps1
#  Diagnostic data, advertising and activity settings.
#  Security protections (Defender, Firewall, SmartScreen, UAC, Windows Update)
#  are deliberately never touched.
# ============================================================================

$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

Register-BlobTweak @{
    Id = 'pv.adid'; Section = 'Privacy'; Group = 'Advertising'; Risk = 'Minimal'
    Name = 'Disable advertising ID'
    Description = 'Apps can no longer use your advertising ID to show personalised ads.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'pv.tailored'; Section = 'Privacy'; Group = 'Advertising'; Risk = 'Minimal'
    Name = 'Disable tailored experiences'
    Description = 'Microsoft will not use your diagnostic data to personalise tips, ads and recommendations.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'pv.suggestions'; Section = 'Privacy'; Group = 'Advertising'; Risk = 'Standard'
    Name = 'Disable suggestions, tips and auto-installed apps'
    Description = 'Turns off suggested content in Start and Settings, Windows tips, and silent installation of promoted apps.'
    Registry = @(
        @{ Path = $cdm; Name = 'SubscribedContent-338388Enabled'; Value = 0 },
        @{ Path = $cdm; Name = 'SubscribedContent-338389Enabled'; Value = 0 },
        @{ Path = $cdm; Name = 'SubscribedContent-353694Enabled'; Value = 0 },
        @{ Path = $cdm; Name = 'SubscribedContent-353696Enabled'; Value = 0 },
        @{ Path = $cdm; Name = 'SystemPaneSuggestionsEnabled'; Value = 0 },
        @{ Path = $cdm; Name = 'SilentInstalledAppsEnabled'; Value = 0 })
    Note = 'Apps already installed are not removed.'
}
Register-BlobTweak @{
    Id = 'pv.lockscreen'; Section = 'Privacy'; Group = 'Advertising'; Risk = 'Minimal'
    Name = 'No tips and ads on the lock screen'
    Description = 'Removes "fun facts, tips, tricks and more" from the lock screen.'
    Registry = @(
        @{ Path = $cdm; Name = 'RotatingLockScreenOverlayEnabled'; Value = 0 },
        @{ Path = $cdm; Name = 'SubscribedContent-338387Enabled'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'pv.diag'; Section = 'Privacy'; Group = 'Diagnostic data'; Risk = 'Standard'
    Name = 'Send only required diagnostic data'
    Description = 'Sets the documented policy to "Required" diagnostic data (the minimum supported on Home and Pro).'
    Registry = @(@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Value = 1 })
    Note = 'Settings will show "Some settings are managed by your organization" - that is expected for policies.'
}
Register-BlobTweak @{
    Id = 'pv.feedback'; Section = 'Privacy'; Group = 'Diagnostic data'; Risk = 'Minimal'
    Name = 'Never ask for feedback'
    Description = 'Sets feedback frequency to Never so Windows stops showing feedback surveys.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Siuf\Rules'; Name = 'NumberOfSIUFInPeriod'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'pv.inking'; Section = 'Privacy'; Group = 'Diagnostic data'; Risk = 'Standard'
    Name = 'Disable inking and typing personalisation'
    Description = 'Stops collecting typing and handwriting patterns to build a personal dictionary.'
    Registry = @(
        @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitInkCollection'; Value = 1 },
        @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitTextCollection'; Value = 1 },
        @{ Path = 'HKCU:\Software\Microsoft\Personalization\Settings'; Name = 'AcceptedPrivacyPolicy'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'pv.diagtrack'; Section = 'Privacy'; Group = 'Diagnostic data'; Risk = 'Advanced'
    Name = 'Disable Connected User Experiences and Telemetry service'
    Description = 'Sets the DiagTrack service to Disabled. It uploads diagnostic data; it is not a security component.'
    Services = @(@{ Name = 'DiagTrack'; Startup = 'Disabled' })
    Warning = 'Some Windows Insider and feedback features depend on it. Fully reversible from Restore.'
}
Register-BlobTweak @{
    Id = 'pv.activity'; Section = 'Privacy'; Group = 'Activity history'; Risk = 'Standard'
    Name = 'Disable activity history'
    Description = 'Windows stops collecting and uploading the list of apps, files and sites you used.'
    Registry = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities'; Value = 0 })
}
Register-BlobTweak @{
    Id = 'pv.apptracking'; Section = 'Privacy'; Group = 'Activity history'; Risk = 'Minimal'
    Name = 'Do not track app launches'
    Description = 'Windows stops tracking which apps you launch to personalise Start and search.'
    Registry = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Value = 0 })
    Note = 'The "Most used" list in Start will no longer update.'
}
Register-BlobTweak @{
    Id = 'pv.copilot'; Section = 'Privacy'; Group = 'Optional'; Risk = 'Optional'
    Name = 'Turn off Windows Copilot (policy)'
    Description = 'Applies the documented TurnOffWindowsCopilot user policy. Newer Copilot app versions may ignore it.'
    Registry = @(@{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Value = 1 })
}

function Get-BlobPrivacyOverview {
    $lines = @('{Cyan}Privacy overview', '')
    $t = Get-BlobRegState 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
    $level = if (-not $t.Exists) { 'Not set by policy (Windows default / Settings app)' } else {
        switch ([int]$t.Value) { 0 { 'Security / Off (Enterprise only)' } 1 { 'Required' } 2 { 'Enhanced (legacy)' } 3 { 'Optional / Full' } default { "$($t.Value)" } } }
    $lines += "{Gray}Diagnostic data policy   {White}$level"
    $svc = Get-BlobServiceStartup 'DiagTrack'
    $lines += "{Gray}DiagTrack service        {White}$(if ($svc) { $svc } else { 'not present' })"
    foreach ($id in @('pv.adid', 'pv.tailored', 'pv.suggestions', 'pv.lockscreen', 'pv.activity', 'pv.inking', 'pv.feedback')) {
        $tw = Get-BlobTweak $id
        $lines += ('{{Gray}}{0,-48} {1}' -f $tw.Name, (Format-BlobState (Get-BlobTweakState $tw)))
    }
    $lines += ''
    $lines += '{Green}Security features are never modified by BLOB OPTIMIZER:'
    $lines += '{DarkGray}Microsoft Defender, Windows Firewall, SmartScreen, UAC and Windows Update stay as they are.'
    return $lines
}

function Show-BlobPrivacy {
    Show-BlobTweakSection -Section 'Privacy' -Crumb 'Privacy' -Intro @(
        '{White}Privacy', '{Gray}Reduce advertising, suggestions and optional data collection. Security protections stay on.') -Extras @(
        @{ Label = 'Privacy overview'; Detail = 'Current diagnostic data level and the status of every privacy setting.'
           Action = { $null = Show-BlobText -Crumb 'Privacy > Overview' -Lines (Get-BlobPrivacyOverview) } },
        @{ Label = 'Open Windows privacy settings'; Detail = 'Opens Settings > Privacy & security for per-app permissions.'
           Action = { Start-Process 'ms-settings:privacy' -ErrorAction SilentlyContinue } }
    )
}
