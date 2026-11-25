# ============================================================================
#  BLOB OPTIMIZER - PrivacyData3.ps1
#  Privacy catalogue, sections 14-20.
# ============================================================================

# ---- 14. Lock Screen --------------------------------------------------------------
$g = 'Lock Screen'
Add-BlobPrivacyItem $g 'spotlight' 'Windows Spotlight' '' 'Optional' 'Low' @("$pcCCU|DisableWindowsSpotlightFeatures|1") `
    'Downloads daily background pictures and facts from Bing for the lock screen and desktop.' 'Your region and how you react to the images.' `
    'No Bing content is fetched for your backgrounds.' 'Changing Spotlight images; you pick your own picture instead.' 'None.'
Add-BlobPrivacyItem $g 'lockads' 'Lock-screen advertisements' '' 'Disable' 'Low' @("$pcCDM|RotatingLockScreenOverlayEnabled|0", "$pcCDM|RotatingLockScreenEnabled|0") `
    'Shows promotional overlays on the lock screen.' 'Interaction with the ads.' 'No ads before you sign in.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'lockfacts' 'Fun facts and tips' '' 'Disable' 'Low' @("$pcCDM|SubscribedContent-338387Enabled|0") `
    'Shows "fun facts, tips, tricks and more" on the lock screen.' 'Interaction with the tips.' 'A clean lock screen.' 'Lock-screen trivia.' 'None.'
Add-BlobPrivacyItem $g 'locknotify' 'Lock-screen notifications' '' 'Optional' 'Medium' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings|NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK|0') `
    'Shows notifications on the lock screen.' 'Nothing is sent, but message previews are visible to anyone near the PC.' `
    'Private messages are not shown on a locked PC.' 'Seeing notifications without unlocking.' 'None.'
Add-BlobPrivacyItem $g 'thirdparty' 'Promotional recommendations' '' 'Disable' 'Low' @("$pcCCU|DisableThirdPartySuggestions|1") `
    'Lets Windows show suggestions from third-party publishers in Spotlight and other places.' 'Interaction with suggestions.' `
    'No third-party promotions.' 'Nothing.' 'None.'

# ---- 15. Taskbar -------------------------------------------------------------------
$g = 'Taskbar'
Add-BlobPrivacyItem $g 'widgets' 'Windows Widgets' '' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Policies\Microsoft\Dsh|AllowNewsAndInterests|0') `
    'The Widgets board with news, weather and stocks.' 'Your interests, location for weather, and what you read.' `
    'No news feed tracking and no background loading.' 'Widgets board and its taskbar button.' 'None.'
Add-BlobPrivacyItem $g 'searchbox' 'Search box' '' 'Optional' 'Low' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Search|SearchboxTaskbarMode|0') `
    'Shows the search box or icon on the taskbar (this hides it).' 'Nothing extra; search itself is covered in the Search section.' `
    'Less temptation to send searches to the web.' 'One-click search on the taskbar; the Windows key still opens search.' 'None.'
Add-BlobPrivacyItem $g 'news' 'News and interests' '' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds|EnableFeeds|0') `
    'Windows 10 taskbar weather and news feed.' 'Interests and location for weather.' 'No feed tracking.' 'Weather on the taskbar.' 'Applies to Windows 10.'
Add-BlobPrivacyItem $g 'people' 'People icon' '' 'Disable' 'Low' @('HKCU:\Software\Policies\Microsoft\Windows\Explorer|HidePeopleBar|1') `
    'Windows 10 People bar for pinned contacts.' 'Contacts you pin.' 'No contact bar.' 'Pinned contacts.' 'Applies to Windows 10.'
Add-BlobPrivacyItem $g 'taskbarrec' 'Taskbar recommendations' '' 'Disable' 'Low' @("$pcAdv|Start_AccountNotifications|0", "$pcAdv|Start_IrisRecommendations|0") `
    'Shows account notifications and promoted recommendations in Start and the taskbar.' 'Account status and usage.' `
    'No account nags or promotions.' 'Backup and account reminders.' 'None.'

# ---- 16. Activity History and Clipboard ---------------------------------------------
$g = 'Activity History and Clipboard'
Add-BlobPrivacyItem $g 'actsend' 'Sending activity history to Microsoft' '' 'Disable' 'High' @("$pcSys|UploadUserActivities|0") `
    'Uploads the list of apps, files and sites you used to your Microsoft account.' 'Detailed activity history.' `
    'Your activity stays on this PC.' 'Continuing activities on other devices.' 'None.'
Add-BlobPrivacyItem $g 'actstore' 'Storing activity history' '' 'Disable' 'Medium' @("$pcSys|PublishUserActivities|0") `
    'Records what you do on this PC for Timeline-style features.' 'App, file and site usage stored locally.' 'No activity log is kept.' 'Resume suggestions.' 'None.'
Add-BlobPrivacyItem $g 'timeline' 'Timeline' '' 'Disable' 'Medium' @("$pcSys|EnableActivityFeed|0") `
    'The Timeline view of past activities (Windows 10).' 'Your activity history.' 'No activity feed.' 'Timeline in Task View.' 'None.'
Add-BlobPrivacyItem $g 'cliphistory' 'Clipboard history' '' 'Optional' 'Medium' @("$pcSys|AllowClipboardHistory|0") `
    'Keeps a list of things you copied (Win+V).' 'Everything you copy, including passwords, stored locally.' `
    'Copied passwords and texts do not pile up in a history.' 'Win+V clipboard history.' 'None.'
Add-BlobPrivacyItem $g 'clipcloud' 'Clipboard cloud synchronisation' '' 'Disable' 'High' @("$pcSys|AllowCrossDeviceClipboard|0") `
    'Syncs your clipboard across devices through your Microsoft account.' 'Everything you copy, uploaded to Microsoft.' `
    'Copied content never leaves the PC.' 'Copy on one PC, paste on another.' 'None.'
Add-BlobPrivacyItem $g 'clipshare' 'Sharing clipboard data across devices' '' 'Disable' 'High' @('HKCU:\Software\Microsoft\Clipboard|EnableCloudClipboard|0') `
    'Your personal switch for clipboard sync (Settings > System > Clipboard).' 'Copied content uploaded for sync.' `
    'Clipboard sync off for your account.' 'Cross-device paste.' 'None.'

# ---- 17. Microsoft Copilot and Windows AI ------------------------------------------
$g = 'Microsoft Copilot and Windows AI'
Add-BlobPrivacyItem $g 'copilot' 'Windows Copilot' '' 'Disable' 'High' @('HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot|TurnOffWindowsCopilot|1', 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot|TurnOffWindowsCopilot|1') `
    'The Copilot assistant built into Windows.' 'Your prompts, and screen or file content you share with it.' `
    'Copilot cannot run from Windows.' 'Copilot in Windows (newer Copilot app versions may ignore the policy).' 'The separate Copilot app can still be uninstalled from the Apps page.'
Add-BlobPrivacyItem $g 'copilotbtn' 'Copilot taskbar button' '' 'Disable' 'Low' @("$pcAdv|ShowCopilotButton|0") `
    'Shows the Copilot button on the taskbar.' 'Nothing until used.' 'No accidental Copilot launches.' 'The taskbar button.' 'None.'
Add-BlobPrivacyItem $g 'paintcreator' 'Image Creator in Microsoft Paint' '' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint|DisableImageCreator|1') `
    'Creates images in Paint from a text prompt using a cloud service.' 'Your prompts, linked to your account.' 'Prompts are not sent.' 'AI image creation in Paint.' 'None.'
Add-BlobPrivacyItem $g 'paintfill' 'AI image filling in Paint' '' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint|DisableGenerativeFill|1', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint|DisableGenerativeErase|1') `
    'Generative fill and erase in Paint.' 'Image content and prompts.' 'Images are not processed by the AI service.' 'Generative fill and erase.' 'None.'
Add-BlobPrivacyItem $g 'clicktodo' 'Click to Do' 'C208' 'Disable' 'High' @('HKCU:\Software\Policies\Microsoft\Windows\WindowsAI|DisableClickToDo|1') `
    'Analyses what is on your screen to suggest actions (Copilot+ PCs).' 'Screenshots of your screen, analysed on the device.' `
    'Your screen is not analysed.' 'Context actions from Click to Do.' 'Only exists on Copilot+ PCs.'
Add-BlobPrivacyItem $g 'settingsagent' 'Settings Agent' 'C209' 'Disable' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI|DisableSettingsAgent|1') `
    'An AI agent in Settings that changes settings from a typed request.' 'What you type into Settings search.' `
    'Settings search works without the agent.' 'Natural-language changes in Settings.' 'Only on supported devices.'
Add-BlobPrivacyItem $g 'notepadai' 'AI features in Notepad' 'C210' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Policies\WindowsNotepad|DisableAIFeatures|1') `
    'Rewrite, summarise and write features in Notepad.' 'Text you select, sent to the AI service.' 'Your notes are not sent anywhere.' 'AI writing help in Notepad.' 'None.'
Add-BlobPrivacyItem $g 'explorerai' 'AI actions in File Explorer' 'C211' 'Disable' 'Medium' @('HKCU:\Software\Policies\Microsoft\Windows\Explorer|HideAIActionsMenu|1') `
    'AI actions in the right-click menu of files (for example blur background, summarise).' 'Files you run actions on.' `
    'Files are not sent to AI features from Explorer.' 'AI actions in the context menu.' 'Applies on builds that support it.'

# ---- 18. Mobile Devices ---------------------------------------------------------------
$g = 'Mobile Devices'
Add-BlobPrivacyItem $g 'phonelink' 'Phone Link' '' 'Optional' 'High' @("$pcSys|EnableMmx|0") `
    'Links an Android or iPhone to the PC for messages, calls, photos and notifications.' 'Messages, contacts, photos and notifications from your phone.' `
    'Your phone data is not mirrored to the PC.' 'Texting, calls and photos from the PC.' 'None.'
Add-BlobPrivacyItem $g 'phonepc' 'Connecting PC to mobile devices' '' 'Optional' 'High' @("$pcSys|EnableMmx|0") `
    'Same policy as Phone Link: allows pairing the PC with phones.' 'Phone data.' 'No phone pairing.' 'Phone integration.' 'None.'
Add-BlobPrivacyItem $g 'mobileaccess' 'Mobile device access' '' 'Optional' 'Medium' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Mobility|CrossDeviceEnabled|0') `
    'Lets Windows use a linked phone in Explorer and Start (for example recent phone photos).' 'Phone content shown on the PC.' `
    'The phone does not appear in Windows features.' 'Phone access from Explorer and Start.' 'None.'
Add-BlobPrivacyItem $g 'mobilesugg' 'Suggestions for connecting mobile devices' '' 'Disable' 'Low' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Mobility|OptedIn|0') `
    'Suggests linking your phone in Settings and notifications.' 'Nothing extra.' 'No phone-linking nags.' 'Nothing.' 'None.'

# ---- 19. Miscellaneous ----------------------------------------------------------------
$g = 'Miscellaneous'
Add-BlobPrivacyItem $g 'feedback2' 'Feedback reminders' '' 'Disable' 'Low' @('HKCU:\Software\Microsoft\Siuf\Rules|NumberOfSIUFInPeriod|0', "$pcDC|DoNotShowFeedbackNotifications|1") `
    'Same as Feedback requests: Windows asking for your opinion.' 'Your answers.' 'No reminders.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'autoinstall' 'Automatic installation of recommended Store apps' '' 'Disable' 'Medium' @("$pcCDM|SilentInstalledAppsEnabled|0", "$pcCDM|PreInstalledAppsEnabled|0", "$pcCDM|OemPreInstalledAppsEnabled|0", "$pcCDM|ContentDeliveryAllowed|0") `
    'Windows silently installs promoted apps and games.' 'Your region and account, used to choose apps.' `
    'No apps appear without your consent.' 'Nothing.' 'Apps already installed stay; remove them on the Apps page.'
Add-BlobPrivacyItem $g 'wintips' 'Windows tips and suggestions' '' 'Disable' 'Low' @("$pcCC|DisableSoftLanding|1") `
    'Policy that turns off Windows tips everywhere.' 'Feature usage for targeting.' 'No tips.' 'Hints about new features.' 'None.'
Add-BlobPrivacyItem $g 'promofeatures' 'Promotional Windows features' '' 'Disable' 'Low' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement|ScoobeSystemSettingEnabled|0') `
    'Full-screen "finish setting up your device" prompts promoting Microsoft services.' 'Which offers you accept.' 'No setup nags.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'consumer' 'Consumer experience features' '' 'Disable' 'Medium' @("$pcCC|DisableWindowsConsumerFeatures|1", "$pcCC|DisableConsumerAccountStateContent|1") `
    'Microsoft consumer experiences: suggested apps, account promotions and third-party offers.' 'Usage and account state.' `
    'Fewer promotions everywhere.' 'Nothing.' 'Fully honoured on Enterprise/Education; partly on Home and Pro.'

# ---- 20. Gaming ------------------------------------------------------------------------
$g = 'Gaming'
Add-BlobPrivacyItem $g 'gamebar' 'Xbox Game Bar' '' 'Optional' 'Low' @('HKCU:\Software\Microsoft\GameBar|UseNexusForGameBarEnabled|0', 'HKCU:\Software\Microsoft\GameBar|ShowStartupPanel|0') `
    'The Win+G overlay with widgets, chat and performance stats.' 'Game and party chat data when used.' `
    'Game Bar no longer pops up from the controller or on game start.' 'Quick access with the Xbox button (Win+G still works).' 'None.'
Add-BlobPrivacyItem $g 'gamedvr' 'Game DVR' '' 'Optional' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR|AllowGameDVR|0') `
    'Policy that allows game recording and broadcasting.' 'Recorded clips stay local unless you share them.' `
    'Recording is turned off system-wide.' 'All Game Bar recording and screenshots.' 'None.'
Add-BlobPrivacyItem $g 'gamerec' 'Game recording' '' 'Optional' 'Low' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|AppCaptureEnabled|0') `
    'Lets you record game clips with Game Bar.' 'Clips stored locally.' 'No captures.' 'Recording clips.' 'None.'
Add-BlobPrivacyItem $g 'gamecapture' 'Game capture functionality' '' 'Optional' 'Low' @('HKCU:\System\GameConfigStore|GameDVR_Enabled|0') `
    'Background recording of the last minutes of gameplay.' 'Gameplay video kept in memory.' 'No background recording.' '"Record what happened".' 'None.'
