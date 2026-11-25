# ============================================================================
#  BLOB OPTIMIZER - PrivacyData1.ps1
#  Privacy catalogue, sections 1-7.
#  Order: Group, Id, Name, O&O ID, Recommendation, Privacy impact, Ops,
#         Does, Data, Benefit, Lose, Issues
# ============================================================================

# ---- 1. Privacy -------------------------------------------------------------
$g = 'Privacy'
Add-BlobPrivacyItem $g 'wer' 'Windows Error Reporting' '' 'Disable' 'Medium' @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting|Disabled|1', 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting|Disabled|1') `
    'Sends a report to Microsoft whenever a program or Windows itself crashes or hangs.' `
    'Crash details, the program and module names, memory snapshots that can contain fragments of open documents, and hardware details.' `
    'Crash reports and the memory contents they may include stay on your PC.' `
    'Microsoft no longer receives your crashes, so you will not get the rare "solution available" messages.' `
    'None for normal use. Some vendors ask for crash reports when you contact their support.'
Add-BlobPrivacyItem $g 'tips' 'Tips, tricks and suggestions' '' 'Disable' 'Low' @("$pcCDM|SubscribedContent-338389Enabled|0", "$pcCDM|SoftLandingEnabled|0") `
    'Shows pop-up tips about Windows features while you use the PC.' `
    'Which features you use, so the tips can be targeted.' `
    'Fewer interruptions and less usage tracking for tip targeting.' `
    'You no longer see occasional hints about new features.' 'None.'
Add-BlobPrivacyItem $g 'settingsads' 'Suggested content in Settings' '' 'Disable' 'Low' @("$pcCDM|SubscribedContent-338393Enabled|0", "$pcCDM|SubscribedContent-353694Enabled|0", "$pcCDM|SubscribedContent-353696Enabled|0") `
    'Shows suggested apps, services and articles inside the Settings app.' `
    'Your settings activity and account type, used to choose suggestions.' `
    'Settings shows only settings, not promotions.' 'Promotional cards in Settings disappear.' 'None.'
Add-BlobPrivacyItem $g 'timelinesugg' 'Timeline suggestions' '' 'Disable' 'Low' @("$pcCDM|SubscribedContent-353698Enabled|0") `
    'Shows suggested apps and activities in Task View and the old Timeline.' `
    'Your activity history, used to suggest what to open next.' `
    'No suggestions built from your activity.' 'Suggestions in Task View.' 'None.'
Add-BlobPrivacyItem $g 'toasts' 'App notifications' '' 'Optional' 'Low' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications|ToastEnabled|0') `
    'Lets apps and Windows show notification pop-ups (toasts).' `
    'Notification content passes through the Windows notification service; some apps use cloud push channels.' `
    'No pop-ups that can show private content (messages, mail previews) on screen.' `
    'All app notifications, including messages, reminders and download-complete alerts.' `
    'You may miss alarms, calendar reminders or security notices from apps.'
Add-BlobPrivacyItem $g 'adid' 'Advertising and promotional content' '' 'Disable' 'Medium' @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo|Enabled|0', 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo|DisabledByGroupPolicy|1') `
    'Gives every user an advertising ID that apps can read to personalise ads and measure them across apps.' `
    'A unique ID linked to your app usage and ad interactions.' `
    'Apps can no longer link your activity across apps for advertising.' `
    'Ads in apps become generic instead of personalised.' 'None.'

# ---- 2. Telemetry and User Behavior -----------------------------------------
$g = 'Telemetry and User Behavior'
Add-BlobPrivacyItem $g 'apptel' 'Application Telemetry' '' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat|AITEnable|0') `
    'The Application Impact Telemetry agent records how programs use Windows components.' `
    'Which programs you run and which system parts they use.' `
    'Program usage is no longer reported for compatibility analysis.' `
    'Microsoft gets less data to fix compatibility problems.' 'None for normal use.'
Add-BlobPrivacyItem $g 'diagpers' 'Diagnostic data personalisation' '' 'Disable' 'Medium' @('HKCU:\Software\Policies\Microsoft\Windows\CloudContent|DisableTailoredExperiencesWithDiagnosticData|1', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled|0') `
    'Lets Microsoft use your diagnostic data to personalise tips, ads and recommendations.' `
    'Your diagnostic data, combined with your account.' `
    'Diagnostic data is not used to target you.' 'Personalised tips and recommendations.' 'None.'
Add-BlobPrivacyItem $g 'difflogs' 'Diagnostic log collection' '' 'Disable' 'Medium' @("$pcDC|LimitDiagnosticLogCollection|1", "$pcDC|LimitDumpCollection|1") `
    'Allows Microsoft to collect extra diagnostic logs and memory dumps on request.' `
    'Detailed logs and crash dumps that can contain personal data.' `
    'Only basic diagnostic data is sent, no extra logs or full dumps.' 'Microsoft has less data to diagnose rare problems.' 'None.'
Add-BlobPrivacyItem $g 'onesettings' 'OneSettings configuration downloads' '' 'Disable' 'Low' @("$pcDC|DisableOneSettingsDownloads|1") `
    'Downloads configuration from Microsoft that controls what diagnostic data is collected.' `
    'Your device ID is sent to fetch the configuration.' `
    'Microsoft cannot change data collection on your PC remotely.' `
    'Some remotely delivered diagnostic fixes are not received.' 'Rarely, a Microsoft-pushed workaround for a bug may not arrive.'
Add-BlobPrivacyItem $g 'diaglevel' 'Diagnostic data level' '' 'Disable' 'High' @("$pcDC|AllowTelemetry|1", "$pcDC|MaxTelemetryAllowed|1") `
    'Sets how much diagnostic data Windows sends. This sets it to Required, the minimum Home and Pro allow.' `
    'Required: device and update health. Optional: also browsing in Edge, app usage and inking data.' `
    'Optional diagnostic data (app usage, browsing, inking) is no longer sent.' `
    'Windows Insider builds need Optional data; some feedback features stop.' 'None for normal use. Settings will say the option is managed by your organisation.'
Add-BlobPrivacyItem $g 'feedback' 'Feedback requests' '' 'Disable' 'Low' @('HKCU:\Software\Microsoft\Siuf\Rules|NumberOfSIUFInPeriod|0', "$pcDC|DoNotShowFeedbackNotifications|1") `
    'Windows periodically asks you to rate features or answer surveys.' `
    'Your answers and the context they were asked in.' 'No more survey pop-ups.' 'You can still send feedback with Feedback Hub.' 'None.'
Add-BlobPrivacyItem $g 'ddv' 'Diagnostic Data Viewer collection' '' 'Optional' 'Low' @("$pcDC|DisableDiagnosticDataViewer|1") `
    'The Diagnostic Data Viewer keeps a local copy of the data Windows sends so you can inspect it.' `
    'Nothing extra is sent; it stores a local copy (up to 1 GB) on your PC.' `
    'Removes the local copy and the viewer. It does not reduce what is sent.' `
    'You can no longer see what Windows sends.' 'None.'
Add-BlobPrivacyItem $g 'wer2' 'Windows Error Reporting' '' 'Disable' 'Medium' @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting|Disabled|1', 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting|Disabled|1') `
    'Same switch as Windows Error Reporting in the Privacy section: crash and hang reports to Microsoft.' `
    'Crash details and memory snapshots.' 'Crash data stays on your PC.' 'Microsoft solution messages after crashes.' 'None for normal use.'
Add-BlobPrivacyItem $g 'devicename' 'Device name in diagnostic data' 'U008' 'Disable' 'Medium' @("$pcDC|AllowDeviceNameInTelemetry|0") `
    'Includes your computer name in the diagnostic data Windows sends.' `
    'Your device name, which often contains your own name (for example "Johns-Laptop").' `
    'Diagnostic data no longer carries a name that can identify you.' 'Nothing you will notice.' 'None.'

# ---- 3. App Privacy -----------------------------------------------------------
$g = 'App Privacy'
$pcApps = @(
    @('account', 'Account information access', 'userAccountInformation', 'Disable', 'Medium', 'your name, picture and account details', 'apps that show your profile picture or name'),
    @('calendar', 'Calendar access', 'appointments', 'Optional', 'Medium', 'your appointments and meeting details', 'calendar and mail apps that show your schedule'),
    @('camera', 'Camera access', 'webcam', 'Optional', 'High', 'live video from your camera', 'video calls, Windows Hello face sign-in in apps, and camera apps'),
    @('mic', 'Microphone access', 'microphone', 'Optional', 'High', 'audio from your microphone', 'voice and video calls, dictation and voice recorder'),
    @('contacts', 'Contacts access', 'contacts', 'Disable', 'Medium', 'names, numbers and addresses of your contacts', 'apps that pick contacts from your address book'),
    @('callhistory', 'Call history access', 'phoneCallHistory', 'Disable', 'Medium', 'who you called and when', 'phone apps that show call history'),
    @('email', 'Email access', 'email', 'Disable', 'High', 'your email messages', 'apps other than your mail app that read mail'),
    @('messages', 'Messages access', 'chat', 'Disable', 'High', 'your SMS/MMS messages', 'apps that read or send text messages'),
    @('notifaccess', 'Notifications access', 'userNotificationListener', 'Disable', 'Medium', 'the content of every notification you receive', 'apps that mirror or manage notifications (for example smartwatch apps)'),
    @('pictures', 'Pictures access', 'picturesLibrary', 'Optional', 'Medium', 'your Pictures folder', 'photo viewers and editors from the Store'),
    @('videos', 'Videos access', 'videosLibrary', 'Optional', 'Medium', 'your Videos folder', 'video players and editors from the Store'),
    @('documents', 'Documents and files access', 'documentsLibrary', 'Optional', 'High', 'your Documents folder', 'Store apps that open documents directly'),
    @('location', 'Location access', 'location', 'Optional', 'High', 'your precise location', 'maps, weather, find-my-device and automatic time zone in apps'),
    @('genai', 'Generative AI access', 'systemAIModels', 'Disable', 'Medium', 'the on-device AI models and what you feed them', 'apps that use Windows AI features'),
    @('presence', 'Presence detection', 'humanPresence', 'Optional', 'Low', 'whether someone is in front of the screen (presence sensor)', 'apps that wake or lock based on presence'),
    @('passkeys', 'Passkeys', 'passkeys', 'Keep', 'Low', 'use of your saved passkeys to sign in', 'passwordless passkey sign-in in apps - a security feature'),
    @('bt', 'Bluetooth devices', 'bluetoothSync', 'Optional', 'Low', 'communication with paired Bluetooth devices', 'apps that sync with Bluetooth devices'),
    @('hid', 'Input devices (HID)', 'humanInterfaceDevice', 'Optional', 'Low', 'direct access to keyboards, game controllers and other HID devices', 'apps that configure controllers or special keyboards'),
    @('passkeylist', 'Saved passkey lists', 'passkeysEnumeration', 'Disable', 'Low', 'the list of passkeys saved on this PC', 'apps that list or manage your passkeys'),
    @('sensors', 'Custom sensors', 'sensors.custom', 'Disable', 'Low', 'readings from extra sensors on the device', 'apps that read special sensors'),
    @('serial', 'Serial ports', 'serialCommunication', 'Optional', 'Low', 'devices connected to serial ports', 'apps that talk to serial devices (for example microcontrollers)'),
    @('usb', 'USB devices', 'usb', 'Optional', 'Low', 'direct access to USB devices', 'apps that talk to special USB hardware'),
    @('wifidata', 'Wi-Fi information', 'wifiData', 'Disable', 'Medium', 'nearby Wi-Fi networks, which can reveal your location', 'apps that scan for Wi-Fi networks'),
    @('wifidirect', 'Wi-Fi Direct', 'wiFiDirect', 'Optional', 'Low', 'direct Wi-Fi connections to other devices', 'apps that connect to printers or screens over Wi-Fi Direct'))
foreach ($a in $pcApps) {
    Add-BlobPrivacyItem $g $a[0] $a[1] '' $a[3] $a[4] @("$pcCS\$($a[2])|Value|Deny") `
        "Controls whether apps may use $($a[5]). This is the same switch as in Settings > Privacy & security." `
        "Apps that are allowed can read $($a[5])." `
        "No app can access $($a[5]) until you allow it again in Settings." `
        "Features of $($a[6])." `
        'Apps that need this show an error or ask you to enable access; Windows itself keeps working.'
}
Add-BlobPrivacyItem $g 'voice' 'Voice activation' '' 'Disable' 'Medium' @('HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps|AgentActivationEnabled|0') `
    'Lets voice assistants listen for a wake word.' `
    'Audio is analysed locally for the keyword; after it, your voice goes to the assistant service.' `
    'The microphone is not kept listening for wake words.' 'Hands-free "Hey ..." activation of voice assistants.' 'None.'
Add-BlobPrivacyItem $g 'voicelock' 'Voice activation when locked' '' 'Disable' 'Medium' @('HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps|AgentActivationOnLockScreenEnabled|0') `
    'Lets voice assistants respond to the wake word while the PC is locked.' `
    'Voice commands from anyone near the locked PC.' 'Nobody can talk to the assistant on your locked PC.' 'Voice use while locked.' 'None.'

# ---- 4. Cortana and Input Personalisation -----------------------------------
$g = 'Cortana and Input Personalisation'
Add-BlobPrivacyItem $g 'cortana' 'Cortana' '' 'Disable' 'Low' @("$pcWS|AllowCortana|0") `
    'Microsoft voice assistant. It was retired on current Windows; this policy blocks it where it still exists.' `
    'Voice queries, contacts, calendar and location when Cortana is used.' 'Cortana cannot run.' 'Cortana (already retired on Windows 11).' 'None.'
Add-BlobPrivacyItem $g 'inputpers' 'Input personalisation' '' 'Disable' 'Medium' @(
    'HKCU:\Software\Microsoft\InputPersonalization|RestrictImplicitInkCollection|1', 'HKCU:\Software\Microsoft\InputPersonalization|RestrictImplicitTextCollection|1',
    'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore|HarvestContacts|0', 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization|AllowInputPersonalization|0') `
    'Learns from what you type and write to build a personal dictionary.' `
    'Typing history, handwriting samples and contact names.' 'Your typing and handwriting are not collected.' 'Personalised word suggestions.' 'None.'
Add-BlobPrivacyItem $g 'cortanaweb' 'Web search in Cortana' '' 'Disable' 'Medium' @("$pcWS|ConnectedSearchUseWeb|0", "$pcWS|DisableWebSearch|1") `
    'Sends what you type in Windows Search to Bing to show web results.' `
    'Every search term you type.' 'Your local searches stay local.' 'Web results in Windows Search.' 'None.'
Add-BlobPrivacyItem $g 'highlights' 'Search highlights' '' 'Disable' 'Low' @("$pcWS|EnableDynamicContentInWSB|0") `
    'Shows trending searches, illustrations and news in the search box.' `
    'Your region and search usage.' 'A cleaner search box, no trending content.' 'Daily illustrations and trending topics.' 'None.'
Add-BlobPrivacyItem $g 'voice2' 'Voice activation' '' 'Disable' 'Medium' @('HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps|AgentActivationEnabled|0') `
    'Same switch as Voice activation in App Privacy: listening for an assistant wake word.' `
    'Audio after the wake word.' 'No always-listening microphone.' 'Hands-free activation.' 'None.'

# ---- 5. Location Services ----------------------------------------------------
$g = 'Location Services'
Add-BlobPrivacyItem $g 'apploc' 'App access to location' '' 'Optional' 'High' @("$pcCS\location|Value|Deny") `
    'Controls whether apps may read your location.' 'Your precise position from GPS, Wi-Fi and IP.' `
    'Apps cannot track where you are.' 'Location in maps, weather and similar apps.' 'Apps that need it ask you to turn it back on.'
Add-BlobPrivacyItem $g 'winloc' 'Windows location functionality' '' 'Optional' 'High' @("$pcLoc|DisableLocation|1") `
    'Turns off the Windows location platform completely (policy).' 'Your location for Windows and all apps.' `
    'Nothing on the PC can determine your location.' `
    'Location in every app, Find My Device, automatic time zone and local weather.' 'Automatic time zone stops working; set the time zone manually.'
Add-BlobPrivacyItem $g 'lfsvc' 'Windows Geolocation Service' 'L005' 'Optional' 'High' @('svc:lfsvc=Disabled') `
    'The service that provides location to Windows and apps.' 'Your location while the service runs.' `
    'The location provider cannot start.' 'All location features.' 'Same effect as turning Windows location off; reversible from Restore.'
Add-BlobPrivacyItem $g 'locsensors' 'Location sensors' '' 'Optional' 'Medium' @("$pcLoc|DisableSensors|1") `
    'Turns off sensors (like GPS and ambient sensors) used for location.' 'Sensor readings that can reveal position and movement.' `
    'Sensor-based tracking stops.' 'Auto-rotate and brightness may stop on devices that use these sensors.' 'Screen auto-rotation can stop working on tablets.'
Add-BlobPrivacyItem $g 'locscript' 'Location scripting' '' 'Disable' 'Low' @("$pcLoc|DisableLocationScripting|1") `
    'Lets scripts query your location through the Windows location API.' 'Your location, to scripts running on the PC.' `
    'Scripts cannot read your location.' 'Nothing for normal use.' 'None.'
Add-BlobPrivacyItem $g 'findmy' 'Find My Device' 'L008' 'Optional' 'Medium' @('HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice|AllowFindMyDevice|0') `
    'Periodically sends the location of the PC to your Microsoft account so you can find it if it is lost.' `
    'Device location, linked to your account.' 'Your location is no longer stored with Microsoft.' `
    'You cannot locate or lock the PC remotely if it is lost or stolen.' 'Weakens theft recovery; keep it on for laptops you carry around.'

# ---- 6. Search ----------------------------------------------------------------
$g = 'Search'
Add-BlobPrivacyItem $g 'startweb' 'Web search in Start' '' 'Disable' 'Medium' @('HKCU:\Software\Policies\Microsoft\Windows\Explorer|DisableSearchBoxSuggestions|1', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search|BingSearchEnabled|0') `
    'Sends what you type in Start to Bing and shows web suggestions.' 'Every search term typed in Start.' `
    'Start search becomes local only, and faster.' 'Web results and suggestions in Start.' 'None.'
Add-BlobPrivacyItem $g 'msacloud' 'Microsoft account cloud search' 'M029' 'Disable' 'Medium' @("$pcSS|IsMSACloudSearchEnabled|0") `
    'Includes results from OneDrive, Outlook and Bing for your Microsoft account in Windows Search.' 'Your searches, matched against your cloud content.' `
    'Searches do not query your Microsoft cloud content.' 'Cloud files and mail in search results.' 'None.'
Add-BlobPrivacyItem $g 'aadcloud' 'Work or school cloud search' 'M030' 'Disable' 'Medium' @("$pcSS|IsAADCloudSearchEnabled|0") `
    'Includes results from your work or school account (SharePoint, OneDrive for Business) in Windows Search.' 'Your searches, matched against work content.' `
    'Searches do not query work cloud content.' 'Work files in search results.' 'Your organisation may manage this setting anyway.'
Add-BlobPrivacyItem $g 'searchhistory' 'Device search history' 'M031' 'Disable' 'Low' @("$pcSS|IsDeviceSearchHistoryEnabled|0") `
    'Keeps a history of your searches on this PC to improve suggestions.' 'Your past searches, stored locally.' `
    'No search history is kept.' 'Suggestions based on earlier searches.' 'None.'
Add-BlobPrivacyItem $g 'bingext' 'Windows Search Bing extension' 'M103' 'Disable' 'Medium' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Search|BingSearchEnabled|0', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search|CortanaConsent|0') `
    'The Bing integration that powers web results inside Windows Search.' 'Search terms sent to Bing.' `
    'Windows Search does not contact Bing.' 'Web answers in Windows Search.' 'None.'

# ---- 7. Synchronisation of Windows Settings ----------------------------------
$g = 'Synchronisation of Windows Settings'
Add-BlobPrivacyItem $g 'syncall' 'Synchronisation of all settings' '' 'Optional' 'Medium' @("$pcSync|DisableSettingSync|2", "$pcSync|DisableSettingSyncUserOverride|1") `
    'Syncs your Windows settings to your Microsoft account and other PCs.' 'Your preferences, themes, language and some passwords, stored in your account.' `
    'Your settings stay on this PC only.' 'Settings no longer follow you to other PCs.' 'None.'
Add-BlobPrivacyItem $g 'syncpw' 'Password synchronisation' '' 'Optional' 'High' @("$pcSync|DisableCredentialsSettingSync|2", "$pcSync|DisableCredentialsSettingSyncUserOverride|1") `
    'Syncs saved Wi-Fi and website passwords through your Microsoft account.' 'Encrypted credentials stored in the cloud.' `
    'Passwords never leave this PC through Windows sync.' 'Passwords do not appear on your other PCs.' 'None.'
Add-BlobPrivacyItem $g 'synclang' 'Language synchronisation' '' 'Optional' 'Low' @("$pcSync|DisableLanguageSettingSync|2", "$pcSync|DisableLanguageSettingSyncUserOverride|1") `
    'Syncs language, keyboard and dictionary preferences.' 'Your languages and custom dictionary words.' `
    'Language data stays local.' 'Language settings do not follow you.' 'None.'
Add-BlobPrivacyItem $g 'synctheme' 'Theme synchronisation' '' 'Optional' 'Low' @("$pcSync|DisableDesktopThemeSettingSync|2", "$pcSync|DisableDesktopThemeSettingSyncUserOverride|1", "$pcSync|DisablePersonalizationSettingSync|2", "$pcSync|DisablePersonalizationSettingSyncUserOverride|1") `
    'Syncs wallpaper, colours and theme.' 'Your wallpaper image and colour choices.' 'Theme data stays local.' 'The same look on all your PCs.' 'None.'
Add-BlobPrivacyItem $g 'syncother' 'Other Windows settings synchronisation' '' 'Optional' 'Low' @("$pcSync|DisableApplicationSettingSync|2", "$pcSync|DisableApplicationSettingSyncUserOverride|1", "$pcSync|DisableWindowsSettingSync|2", "$pcSync|DisableWindowsSettingSyncUserOverride|1") `
    'Syncs app settings and other Windows settings (like mouse and accessibility).' 'Assorted preferences.' `
    'These settings stay local.' 'They do not follow you to other PCs.' 'None.'
