# ============================================================================
#  BLOB OPTIMIZER - PrivacyData2.ps1
#  Privacy catalogue, sections 8-14.
# ============================================================================

# ---- 8. Security ----------------------------------------------------------------
$g = 'Security'
Add-BlobPrivacyItem $g 'wifisense' 'Wi-Fi Sense' '' 'Disable' 'Low' @('HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config|AutoConnectAllowedOEM|0') `
    'Old Windows 10 feature that connected automatically to open hotspots and networks shared by contacts.' `
    'Networks you connect to and hotspot quality data.' 'The PC never joins suggested open hotspots on its own.' `
    'Automatic hotspot connections (feature already removed in newer Windows).' 'None.'
Add-BlobPrivacyItem $g 'psr' 'User Steps Recorder' '' 'Disable' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat|DisableUAR|1') `
    'Steps Recorder captures screenshots and clicks to document a problem.' 'Screenshots and actions while recording.' `
    'The recorder cannot run.' 'Recording problem steps for support (the tool is deprecated).' 'None.'
Add-BlobPrivacyItem $g 'wmdrm' 'Windows Media DRM internet access' '' 'Optional' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\WMDRM|DisableOnline|1') `
    'Lets the old Windows Media DRM system get licences from the internet.' 'Licence requests that identify the content and device.' `
    'No DRM licence lookups online.' 'Playing protected WMA/WMV files that still need online licences.' 'Old protected media may refuse to play.'
Add-BlobPrivacyItem $g 'ceip' 'Customer Experience Improvement Program' '' 'Disable' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows|CEIPEnable|0') `
    'Legacy program that sends usage statistics to Microsoft.' 'How you use Windows features.' 'Usage statistics are not sent.' 'Nothing you will notice.' 'None.'
Add-BlobPrivacyItem $g 'nfc' 'NFC' '' 'Optional' 'Low' @("$pcCS\radios|Value|Deny") `
    'Lets apps turn radios such as NFC and Bluetooth on or off (radio control permission).' 'Nothing is sent; apps gain control of your radios.' `
    'Apps cannot switch your radios on behind your back.' 'Apps that toggle NFC or Bluetooth for you; use Settings instead.' 'None.'
Add-BlobPrivacyItem $g 'projection' 'Wireless Display' '' 'Optional' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Connect|AllowProjectionToPC|0') `
    'Lets other devices project (Miracast) their screen to this PC.' 'Nothing is sent; nearby devices can discover the PC.' `
    'The PC is not discoverable as a wireless display.' 'Projecting a phone or laptop to this PC.' 'Projecting FROM this PC still works.'
Add-BlobPrivacyItem $g 'cellular' 'Cellular broadband' '' 'Optional' 'Low' @("$pcCS\cellularData|Value|Deny") `
    'Lets apps use mobile data on PCs with a SIM or eSIM.' 'App traffic over your mobile connection.' `
    'Apps cannot use mobile data.' 'Mobile data for apps on LTE/5G laptops.' 'None on PCs without a SIM.'
Add-BlobPrivacyItem $g 'wifidirect2' 'Wi-Fi Direct' '' 'Optional' 'Low' @("$pcCS\wiFiDirect|Value|Deny") `
    'Same switch as Wi-Fi Direct in App Privacy: direct Wi-Fi connections from apps to other devices.' 'Device discovery data.' `
    'Apps cannot open Wi-Fi Direct connections.' 'Wi-Fi Direct printing and casting from apps.' 'None for most users.'
Add-BlobPrivacyItem $g 'btpair' 'Bluetooth pairing' '' 'Keep' 'Low' @() `
    'Pairing lets keyboards, mice, headsets and controllers connect to the PC.' 'Device names and addresses of paired devices, stored locally.' `
    'Little privacy gain; turn Bluetooth off in Settings when you do not use it.' 'All Bluetooth devices would stop working.' `
    'Disabling pairing breaks wireless peripherals, so BLOB does not offer a switch.'

# ---- 9. Windows Update ----------------------------------------------------------
$g = 'Windows Update'
Add-BlobPrivacyItem $g 'p2p' 'Peer-to-peer update sharing' '' 'Disable' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization|DODownloadMode|0') `
    'Delivery Optimization uploads Windows updates from your PC to other PCs.' 'Your IP address is visible to peers; upload bandwidth is used.' `
    'Updates come only from Microsoft; your connection is not used to serve others.' 'Slightly slower updates in homes with several PCs.' 'None.'
Add-BlobPrivacyItem $g 'p2plan' 'Update sharing restricted to local networks' '' 'Optional' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization|DODownloadMode|1') `
    'Allows update sharing only between PCs on your own network. Use this OR the switch above, not both.' 'Peers on your local network only.' `
    'No sharing with internet strangers, but home PCs still help each other.' 'Internet peers.' 'Choose one of the two Delivery Optimization switches; the last one applied wins.'
Add-BlobPrivacyItem $g 'drivers' 'Automatic driver updates' 'W010' 'Optional' 'Low' @("$pcWU|ExcludeWUDriversInQualityUpdate|1") `
    'Lets Windows Update install hardware drivers automatically.' 'Your hardware IDs, as with any update check.' `
    'Windows Update will not replace drivers you installed yourself (for example a GPU driver).' 'Automatic driver fixes; you must update drivers yourself.' 'New devices may need a manual driver download.'
Add-BlobPrivacyItem $g 'optional' 'Optional updates' '' 'Optional' 'Low' @("$pcWU|AllowOptionalContent|0") `
    'Lets Windows install optional non-security updates and feature switches early.' 'Nothing extra.' `
    'Only regular monthly updates are installed.' 'New features arrive later.' 'None; security updates are not affected.'
Add-BlobPrivacyItem $g 'preview' 'Preview updates' '' 'Disable' 'Low' @("$pcWU|ManagePreviewBuilds|1", "$pcWU|ManagePreviewBuildsPolicyValue|0") `
    'Allows Windows Insider preview builds on this PC.' 'Preview builds require optional diagnostic data.' `
    'The PC stays on stable releases.' 'Access to preview builds.' 'None.'
Add-BlobPrivacyItem $g 'deferfeature' 'Feature upgrade delays' '' 'Optional' 'Low' @("$pcWU|DeferFeatureUpdates|1", "$pcWU|DeferFeatureUpdatesPeriodInDays|180") `
    'Delays big yearly feature upgrades by 180 days (security updates still arrive).' 'Nothing extra.' `
    'You get feature upgrades after early problems are fixed.' 'New features arrive six months later.' 'Windows Home may ignore this policy.'
Add-BlobPrivacyItem $g 'autoupdate' 'Automatic update behaviour' '' 'Keep' 'Low' @() `
    'Windows downloads and installs security updates automatically.' 'Update checks send device and version details.' `
    'Very little privacy gain.' 'Security patches would arrive late or not at all.' `
    'Turning automatic updates off leaves the PC exposed to known attacks, so BLOB does not offer a switch.'
Add-BlobPrivacyItem $g 'storeupdate' 'Automatic Microsoft Store app updates' '' 'Optional' 'Low' @('HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore|AutoDownload|2') `
    'Lets the Store update apps automatically in the background.' 'Your app list, as part of update checks.' `
    'Apps update only when you choose.' 'Automatic app fixes, including security fixes for apps.' 'Apps can fall behind on security updates; update them in the Store regularly.'

# ---- 10. Microsoft Edge Chromium -----------------------------------------------
$g = 'Microsoft Edge Chromium'
$pcEdgeItems = @(
    @('signin', 'Automatic browser sign-in', '', 'Optional', 'Medium', 'BrowserSignin|0', 'Signs Edge in with your Windows account automatically.', 'Browsing data synced to your account.', 'Edge stays signed out unless you sign in yourself.', 'Automatic sync of favourites and passwords.'),
    @('bingchat', 'Bing Chat in the new tab page', '', 'Disable', 'Low', 'NewTabPageBingChatEnabled|0', 'Shows the Copilot/Bing chat box on the new tab page.', 'What you type into it.', 'A quieter new tab page.', 'The chat box on new tabs.'),
    @('visualsearch', 'Visual search', '', 'Disable', 'Medium', 'VisualSearchEnabled|0', 'Lets you search the web with an image you hover or capture.', 'Images from pages you visit, sent to Bing.', 'Images are not sent for analysis.', 'Image hover search.'),
    @('textpred', 'Text prediction in forms', '', 'Disable', 'Medium', 'TextPredictionEnabled|0', 'Suggests words as you type in web forms.', 'What you type in text fields.', 'Your typing is not sent for predictions.', 'Inline word suggestions.'),
    @('tabsvc', 'Cloud-based tab services', '', 'Disable', 'Medium', 'TabServicesEnabled|0', 'Uses Microsoft cloud services to suggest tab groups and titles.', 'Titles and addresses of your open tabs.', 'Open tabs are not analysed in the cloud.', 'Automatic tab grouping suggestions.'),
    @('aihistory', 'AI-powered history search', '', 'Disable', 'Medium', 'HistorySearchSettings|1', 'Uses AI to search your history by meaning.', 'Your browsing history.', 'History is searched by plain text only.', 'Natural-language history search.'),
    @('shopping', 'Shopping assistant', '', 'Disable', 'Medium', 'EdgeShoppingAssistantEnabled|0', 'Shows coupons and price comparisons on shopping sites.', 'Shopping pages you visit.', 'Shopping visits are not checked against Microsoft services.', 'Coupons and price history.'),
    @('aithemes', 'AI-generated themes', '', 'Disable', 'Low', 'AIGenThemesEnabled|0', 'Creates browser themes from a text prompt.', 'Your prompts.', 'No prompts sent.', 'AI theme generation.'),
    @('aiapis', 'Built-in AI APIs for websites', '', 'Disable', 'Medium', 'BuiltInAIAPIsEnabled|0', 'Lets websites use Edge built-in AI models.', 'Page content passed to on-device AI by websites.', 'Websites cannot use the built-in AI.', 'Site features built on those APIs.'),
    @('compose', 'Inline Compose', '', 'Disable', 'Medium', 'ComposeInlineEnabled|0', 'Offers AI writing help inside text boxes.', 'Text you write.', 'Your writing is not sent to Copilot.', 'AI rewrite suggestions.'),
    @('copilotctx', 'Copilot access to page context', '', 'Disable', 'High', 'CopilotPageContext|0', 'Lets Copilot read the page you are viewing.', 'The full content of the current page.', 'Copilot cannot read your open pages.', 'Page summaries by Copilot.'),
    @('defprompt', 'Default-browser prompts', '', 'Disable', 'Low', 'DefaultBrowserSettingsCampaignEnabled|0', 'Asks you to make Edge your default browser.', 'Whether you accept.', 'No nagging.', 'Nothing.'),
    @('campaigns', 'Browser campaigns', '', 'Disable', 'Low', 'PromotionalTabsEnabled|0', 'Shows full-page promotional tabs for Microsoft offers.', 'Your interaction with promotions.', 'No promotional tabs.', 'Nothing.'),
    @('edgediag', 'Diagnostic data collection', '', 'Disable', 'Medium', 'DiagnosticData|0', 'Sends Edge usage and crash data to Microsoft.', 'Browser usage, crashes and optionally visited sites.', 'Only the required minimum is sent.', 'Nothing you will notice.'),
    @('rewards', 'Microsoft Rewards', '', 'Disable', 'Low', 'ShowMicrosoftRewards|0', 'Shows Microsoft Rewards offers in Edge.', 'Searches and activity tied to Rewards.', 'No Rewards prompts.', 'Rewards point offers in the browser.'),
    @('m365icon', 'Microsoft 365 Copilot Chat icon', '', 'Disable', 'Low', 'Microsoft365CopilotChatIconEnabled|0', 'Shows the Microsoft 365 Copilot Chat icon in the toolbar.', 'Nothing until used.', 'A cleaner toolbar.', 'The shortcut icon.'),
    @('settingsrec', 'Settings recommendations', '', 'Disable', 'Low', 'ShowRecommendationsEnabled|0', 'Shows recommendations and notifications about Edge features.', 'Feature usage.', 'No feature nags.', 'Feature tips.'),
    @('topsites', 'Default top sites', '', 'Disable', 'Low', 'NewTabPageHideDefaultTopSites|1', 'Fills the new tab page with sponsored and default sites.', 'Clicks on those tiles.', 'No sponsored tiles.', 'Default site shortcuts.'),
    @('securenet', 'Edge Secure Network', '', 'Optional', 'Medium', '', 'A free VPN-like proxy for public Wi-Fi run with Cloudflare.', 'Traffic is routed through the proxy provider when used.', 'Turn it off in Edge Settings > Privacy if you do not want traffic routed through a proxy.', 'Encrypted browsing on public Wi-Fi.'),
    @('startboost', 'Fast Startup', '', 'Disable', 'Low', 'StartupBoostEnabled|0', 'Preloads Edge at sign-in so it opens faster.', 'Nothing extra; uses memory in the background.', 'Edge does not run until you open it.', 'Edge opens a little slower.'),
    @('acrobat', 'Adobe Acrobat subscription button', '', 'Disable', 'Low', 'ShowAcrobatSubscriptionButton|0', 'Shows an Adobe Acrobat offer in the PDF viewer.', 'Clicks on the offer.', 'No upsell button.', 'Nothing.'),
    @('edgespotlight', 'Spotlight experiences and recommendations', '', 'Disable', 'Low', 'SpotlightExperiencesAndRecommendationsEnabled|0', 'Shows personalised background images and suggestions.', 'Usage for personalisation.', 'No personalised suggestions.', 'Spotlight backgrounds.'),
    @('sharewin', 'Sharing browsing data with other Windows features', 'E157', 'Disable', 'High', 'LocalBrowserDataShareEnabled|0', 'Lets Windows features (search, recommendations) use your Edge browsing data.', 'Browsing history and site activity.', 'Browsing data stays inside Edge.', 'Recent sites in Windows search and Start.'),
    @('history', 'Browser history', '', 'Optional', 'Medium', 'SavingBrowserHistoryDisabled|1', 'Saves the sites you visit.', 'Your full browsing history (local, synced if signed in).', 'No history is kept.', 'Going back to sites through history and address-bar recall.'),
    @('suggest', 'Address-bar suggestions', '', 'Optional', 'Medium', 'SearchSuggestEnabled|0', 'Sends what you type in the address bar to the search engine for suggestions.', 'Every keystroke in the address bar.', 'Typing is not sent before you press Enter.', 'Live search suggestions.'),
    @('msbing', 'Microsoft Search in Bing', '', 'Disable', 'Medium', 'AddressBarMicrosoftSearchInBingProviderEnabled|0', 'Adds work/school results from Microsoft Search to the address bar.', 'Searches matched against your organisation content.', 'No work search in the address bar.', 'Work results in the address bar.'))
foreach ($e in $pcEdgeItems) {
    $ops = if ($e[5]) { @("$pcEdge|$($e[5])") } else { @() }
    Add-BlobPrivacyItem $g $e[0] $e[1] $e[2] $e[3] $e[4] $ops $e[6] $e[7] $e[8] $e[9] `
        $(if ($e[5]) { 'None. Edge shows "Your browser is managed by your organisation" for policies.' } else { 'No dependable policy; listed for information.' })
}

# ---- 11. Microsoft Edge Legacy ---------------------------------------------------
$g = 'Microsoft Edge Legacy'
foreach ($e in @(@('legtrack', 'Web tracking'), @('legform', 'Form suggestions'), @('leghist', 'Search history'), @('legbar', 'Edge Bar'),
                  @('legpers', 'Personalised suggestions'), @('legdata', 'Browser data collection'))) {
    Add-BlobPrivacyItem $g $e[0] $e[1] '' 'N/A' 'Low' @() `
        "Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021." 'Nothing - the browser no longer exists on current Windows.' `
        'No benefit: there is nothing left to turn off.' 'Nothing.' 'Not applicable. The Chromium-based Edge settings are in the section above.'
}

# ---- 12. Microsoft Office -------------------------------------------------------
$g = 'Microsoft Office'
Add-BlobPrivacyItem $g 'offanalytics' 'Connected experiences with content analytics' '' 'Disable' 'High' @("$pcOff\common\privacy|usercontentdisabled|2") `
    'Office features that analyse your document content in the cloud (Designer, Editor, translation).' 'Content of your documents sent for analysis.' `
    'Document content is not sent to Microsoft for these features.' 'Designer, cloud spelling/grammar and translation.' 'Policies apply to Office 2016 and later.'
Add-BlobPrivacyItem $g 'offdiag' 'Office diagnostic data submission' '' 'Disable' 'Medium' @("$pcOff\common\clienttelemetry|SendTelemetry|3") `
    'Sends Office usage and diagnostic data to Microsoft.' 'How you use Office apps, errors and performance.' 'Office stops sending optional diagnostic data.' 'Nothing you will notice.' 'None.'
Add-BlobPrivacyItem $g 'offsurvey' 'Office surveys' '' 'Disable' 'Low' @("$pcOff\common\feedback|surveyenabled|0", "$pcOff\common\feedback|enabled|0") `
    'Shows satisfaction surveys and the feedback button in Office.' 'Your answers and screenshots you attach.' 'No survey pop-ups.' 'The Office feedback option.' 'None.'
Add-BlobPrivacyItem $g 'offceip' 'Office Customer Experience Improvement Program' '' 'Disable' 'Low' @("$pcOff\common|qmenable|0") `
    'Legacy Office usage statistics program.' 'Feature usage statistics.' 'Statistics are not sent.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'offmovie' 'Office first-run movie' 'F020' 'Disable' 'Low' @("$pcOff\firstrun|disablemovie|1", "$pcOff\firstrun|bootedrtm|1") `
    'Plays the introduction video the first time Office starts.' 'Nothing.' 'Office opens straight away.' 'The intro video.' 'None.'
Add-BlobPrivacyItem $g 'offsignin' 'Office sign-in' 'F021' 'Optional' 'Medium' @("$pcOff\common\signin|signinoptions|3") `
    'Lets you sign in to Office with a Microsoft or work account.' 'Your account and documents in OneDrive.' `
    'Office cannot be tied to an online account.' 'OneDrive saving, co-authoring and Microsoft 365 activation.' 'Microsoft 365 subscriptions need sign-in to activate; only use this with standalone Office.'

# ---- 13. Microsoft 365 ------------------------------------------------------------
$g = 'Microsoft 365'
Add-BlobPrivacyItem $g 'm365cloud' 'Cloud-connected Office features' '' 'Optional' 'Medium' @("$pcOff\common\privacy|controllerconnectedservicesenabled|2") `
    'Optional connected experiences such as LinkedIn features, 3D maps and online video.' 'Data these services need, for example search terms.' `
    'Optional online services are off.' 'Those optional online features.' 'None.'
Add-BlobPrivacyItem $g 'm365download' 'Connected experiences' '' 'Optional' 'Medium' @("$pcOff\common\privacy|downloadcontentdisabled|2") `
    'Experiences that download online content into Office (templates, online pictures, icons).' 'Your searches for templates and images.' `
    'Office does not fetch online content.' 'Online templates, stock images and icons.' 'None.'
Add-BlobPrivacyItem $g 'm365diag' 'Usage and diagnostic data sharing' '' 'Disable' 'Medium' @("$pcOff\common\clienttelemetry|SendTelemetry|3") `
    'Same as Office diagnostic data: usage and diagnostics from Microsoft 365 apps.' 'App usage and errors.' 'Optional data is not sent.' 'Nothing you will notice.' 'None.'
Add-BlobPrivacyItem $g 'm365promo' 'Promotional features' '' 'Disable' 'Low' @() `
    'Promotional messages and upgrade offers inside Microsoft 365 apps.' 'Interaction with offers.' `
    'Turning off connected experiences (above) removes most of them.' 'Nothing.' 'No separate documented switch; listed for information.'

# ---- 14. Windows Explorer ---------------------------------------------------------
$g = 'Windows Explorer'
Add-BlobPrivacyItem $g 'onedrive' 'OneDrive integration' '' 'Optional' 'High' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive|DisableFileSyncNGSC|1') `
    'Lets OneDrive sync files and back up Desktop, Documents and Pictures.' 'Your files, stored in the cloud.' `
    'No files are uploaded through OneDrive.' 'OneDrive sync and backup entirely.' 'Files that only exist in OneDrive stay online; download what you need first.'
Add-BlobPrivacyItem $g 'odpromo' 'OneDrive promotional content' '' 'Disable' 'Low' @("$pcAdv|ShowSyncProviderNotifications|0") `
    'Shows OneDrive and Microsoft 365 offers inside File Explorer.' 'Clicks on offers.' 'No offers in Explorer.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'odnotify' 'OneDrive notifications' '' 'Optional' 'Low' @() `
    'OneDrive app notifications about sync, memories and storage.' 'Nothing extra.' `
    'Turn them off in OneDrive Settings > Notifications.' 'OneDrive alerts.' 'Managed inside OneDrive; listed for information.'
Add-BlobPrivacyItem $g 'odprelogin' 'OneDrive network access before login' '' 'Disable' 'Low' @('HKLM:\SOFTWARE\Microsoft\OneDrive|PreventNetworkTrafficPreUserSignIn|1') `
    'Lets OneDrive contact Microsoft before anyone signs in.' 'Network traffic from the PC before sign-in.' 'No OneDrive traffic until you sign in.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'startsugg' 'Start menu app suggestions' '' 'Disable' 'Low' @("$pcCDM|SystemPaneSuggestionsEnabled|0") `
    'Shows suggested apps in Start.' 'App usage for suggestions.' 'No promoted apps in Start.' 'App suggestions.' 'None.'
Add-BlobPrivacyItem $g 'recent' 'Recently opened files' '' 'Optional' 'Medium' @("$pcAdv|Start_TrackDocs|0", 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer|ShowRecent|0') `
    'Lists recently opened files in Start and Explorer.' 'File names you opened, stored locally.' `
    'Nobody looking at your screen sees what you worked on.' 'Quick access to recent files and jump lists.' 'None.'
Add-BlobPrivacyItem $g 'officecloud' 'Office.com files in Explorer' 'P099' 'Disable' 'Medium' @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer|ShowCloudFilesInQuickAccess|0') `
    'Shows your Office.com and OneDrive files in Explorer Home.' 'Your cloud file list, loaded from Microsoft.' `
    'Explorer shows only local items.' 'Cloud files in Explorer Home.' 'None.'
Add-BlobPrivacyItem $g 'syncnotify' 'Sync-provider notifications' '' 'Disable' 'Low' @("$pcAdv|ShowSyncProviderNotifications|0") `
    'Same switch as OneDrive promotional content: banners from sync providers in Explorer.' 'Clicks.' 'No banners.' 'Nothing.' 'None.'
Add-BlobPrivacyItem $g 'explorerrec' 'Windows Explorer recommendations' '' 'Disable' 'Medium' @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer|DisableGraphRecentItems|1') `
    'Shows recommended files from your Microsoft account activity in Explorer Home.' 'Your recent cloud documents and collaborators.' `
    'Explorer Home does not load recommendations from your account.' 'The Recommended section.' 'None.'
