# Privacy settings reference

Generated from the BLOB OPTIMIZER privacy catalogue (179 settings in 22 sections). Every entry answers the same questions: what it does, what can be collected, the benefit of turning it off, what you lose, possible problems, a recommendation and a privacy impact rating.

**Recommendations:** DISABLE = good privacy benefit with minimal disadvantages. OPTIONAL = depends on how you use the PC. KEEP ENABLED = important for security, stability or everyday use. NOT APPLICABLE = the feature no longer exists on current Windows.

**How BLOB changes them:** only documented Windows, Edge and Office policy or settings values (shown under *Change*). Every original value is saved first and can be restored. Items marked *information only* have no switch, either because no reliable switch exists or because turning them off would weaken security (Microsoft Defender, security updates, activation). O&O ShutUp10++ IDs are given where known; none are guessed.

Totals - DISABLE: 103, OPTIONAL: 61, KEEP ENABLED: 9, NOT APPLICABLE: 6.

## Sections

1. [Privacy](#1-privacy) (6)
2. [Telemetry and User Behavior](#2-telemetry-and-user-behavior) (9)
3. [App Privacy](#3-app-privacy) (26)
4. [Cortana and Input Personalisation](#4-cortana-and-input-personalisation) (5)
5. [Location Services](#5-location-services) (10)
6. [Search](#6-search) (5)
7. [Synchronisation of Windows Settings](#7-synchronisation-of-windows-settings) (5)
8. [Security](#8-security) (9)
9. [Windows Update](#9-windows-update) (8)
10. [Microsoft Edge Chromium](#10-microsoft-edge-chromium) (26)
11. [Microsoft Edge Legacy](#11-microsoft-edge-legacy) (6)
12. [Microsoft Office](#12-microsoft-office) (6)
13. [Microsoft 365](#13-microsoft-365) (4)
14. [Windows Explorer](#14-windows-explorer) (9)
15. [Lock Screen](#15-lock-screen) (5)
16. [Taskbar](#16-taskbar) (5)
17. [Activity History and Clipboard](#17-activity-history-and-clipboard) (6)
18. [Microsoft Defender and SpyNet](#18-microsoft-defender-and-spynet) (5)
19. [Microsoft Copilot and Windows AI](#19-microsoft-copilot-and-windows-ai) (9)
20. [Mobile Devices](#20-mobile-devices) (5)
21. [Miscellaneous](#21-miscellaneous) (6)
22. [Gaming](#22-gaming) (4)

## 1. Privacy

### Windows Error Reporting

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Sends a report to Microsoft whenever a program or Windows itself crashes or hangs.
- **What can be collected:** Crash details, the program and module names, memory snapshots that can contain fragments of open documents, and hardware details.
- **Benefit of turning it off:** Crash reports and the memory contents they may include stay on your PC.
- **What you lose:** Microsoft no longer receives your crashes, so you will not get the rare "solution available" messages.
- **Possible problems:** None for normal use. Some vendors ask for crash reports when you contact their support.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Disabled = 1`, `HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Disabled = 1`

### Tips, tricks and suggestions

**DISABLE** - privacy impact **Low**

- **What it does:** Shows pop-up tips about Windows features while you use the PC.
- **What can be collected:** Which features you use, so the tips can be targeted.
- **Benefit of turning it off:** Fewer interruptions and less usage tracking for tip targeting.
- **What you lose:** You no longer see occasional hints about new features.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent-338389Enabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled = 0`

### Suggested content in Settings

**DISABLE** - privacy impact **Low**

- **What it does:** Shows suggested apps, services and articles inside the Settings app.
- **What can be collected:** Your settings activity and account type, used to choose suggestions.
- **Benefit of turning it off:** Settings shows only settings, not promotions.
- **What you lose:** Promotional cards in Settings disappear.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent-338393Enabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent-353694Enabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent-353696Enabled = 0`

### Timeline suggestions

**DISABLE** - privacy impact **Low**

- **What it does:** Shows suggested apps and activities in Task View and the old Timeline.
- **What can be collected:** Your activity history, used to suggest what to open next.
- **Benefit of turning it off:** No suggestions built from your activity.
- **What you lose:** Suggestions in Task View.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent-353698Enabled = 0`

### App notifications

**OPTIONAL** - privacy impact **Low**

- **What it does:** Lets apps and Windows show notification pop-ups (toasts).
- **What can be collected:** Notification content passes through the Windows notification service; some apps use cloud push channels.
- **Benefit of turning it off:** No pop-ups that can show private content (messages, mail previews) on screen.
- **What you lose:** All app notifications, including messages, reminders and download-complete alerts.
- **Possible problems:** You may miss alarms, calendar reminders or security notices from apps.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications\ToastEnabled = 0`

### Advertising and promotional content

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Gives every user an advertising ID that apps can read to personalise ads and measure them across apps.
- **What can be collected:** A unique ID linked to your app usage and ad interactions.
- **Benefit of turning it off:** Apps can no longer link your activity across apps for advertising.
- **What you lose:** Ads in apps become generic instead of personalised.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled = 0`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo\DisabledByGroupPolicy = 1`

## 2. Telemetry and User Behavior

### Application Telemetry

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** The Application Impact Telemetry agent records how programs use Windows components.
- **What can be collected:** Which programs you run and which system parts they use.
- **Benefit of turning it off:** Program usage is no longer reported for compatibility analysis.
- **What you lose:** Microsoft gets less data to fix compatibility problems.
- **Possible problems:** None for normal use.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\AITEnable = 0`

### Diagnostic data personalisation

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Lets Microsoft use your diagnostic data to personalise tips, ads and recommendations.
- **What can be collected:** Your diagnostic data, combined with your account.
- **Benefit of turning it off:** Diagnostic data is not used to target you.
- **What you lose:** Personalised tips and recommendations.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\CloudContent\DisableTailoredExperiencesWithDiagnosticData = 1`, `HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy\TailoredExperiencesWithDiagnosticDataEnabled = 0`

### Diagnostic log collection

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Allows Microsoft to collect extra diagnostic logs and memory dumps on request.
- **What can be collected:** Detailed logs and crash dumps that can contain personal data.
- **Benefit of turning it off:** Only basic diagnostic data is sent, no extra logs or full dumps.
- **What you lose:** Microsoft has less data to diagnose rare problems.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\LimitDiagnosticLogCollection = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\LimitDumpCollection = 1`

### OneSettings configuration downloads

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Downloads configuration from Microsoft that controls what diagnostic data is collected.
- **What can be collected:** Your device ID is sent to fetch the configuration.
- **Benefit of turning it off:** Microsoft cannot change data collection on your PC remotely.
- **What you lose:** Some remotely delivered diagnostic fixes are not received.
- **Possible problems:** Rarely, a Microsoft-pushed workaround for a bug may not arrive.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DisableOneSettingsDownloads = 1`

### Diagnostic data level

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Sets how much diagnostic data Windows sends. This sets it to Required, the minimum Home and Pro allow.
- **What can be collected:** Required: device and update health. Optional: also browsing in Edge, app usage and inking data.
- **Benefit of turning it off:** Optional diagnostic data (app usage, browsing, inking) is no longer sent.
- **What you lose:** Windows Insider builds need Optional data; some feedback features stop.
- **Possible problems:** None for normal use. Settings will say the option is managed by your organisation.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\MaxTelemetryAllowed = 1`

### Feedback requests

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Windows periodically asks you to rate features or answer surveys.
- **What can be collected:** Your answers and the context they were asked in.
- **Benefit of turning it off:** No more survey pop-ups.
- **What you lose:** You can still send feedback with Feedback Hub.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod = 0`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DoNotShowFeedbackNotifications = 1`

### Diagnostic Data Viewer collection

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** The Diagnostic Data Viewer keeps a local copy of the data Windows sends so you can inspect it.
- **What can be collected:** Nothing extra is sent; it stores a local copy (up to 1 GB) on your PC.
- **Benefit of turning it off:** Removes the local copy and the viewer. It does not reduce what is sent.
- **What you lose:** You can no longer see what Windows sends.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DisableDiagnosticDataViewer = 1`

### Windows Error Reporting

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Same switch as Windows Error Reporting in the Privacy section: crash and hang reports to Microsoft.
- **What can be collected:** Crash details and memory snapshots.
- **Benefit of turning it off:** Crash data stays on your PC.
- **What you lose:** Microsoft solution messages after crashes.
- **Possible problems:** None for normal use.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Disabled = 1`, `HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Disabled = 1`

### Device name in diagnostic data (O&O U008)

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Includes your computer name in the diagnostic data Windows sends.
- **What can be collected:** Your device name, which often contains your own name (for example "Johns-Laptop").
- **Benefit of turning it off:** Diagnostic data no longer carries a name that can identify you.
- **What you lose:** Nothing you will notice.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowDeviceNameInTelemetry = 0`

## 3. App Privacy

### Account information access

**DISABLE** - privacy impact **Medium**

- **What it does:** Controls whether apps may use your name, picture and account details. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your name, picture and account details.
- **Benefit of turning it off:** No app can access your name, picture and account details until you allow it again in Settings.
- **What you lose:** Features of apps that show your profile picture or name.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation\Value = Deny`

### Calendar access

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Controls whether apps may use your appointments and meeting details. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your appointments and meeting details.
- **Benefit of turning it off:** No app can access your appointments and meeting details until you allow it again in Settings.
- **What you lose:** Features of calendar and mail apps that show your schedule.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments\Value = Deny`

### Camera access

**OPTIONAL** - privacy impact **High**

- **What it does:** Controls whether apps may use live video from your camera. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read live video from your camera.
- **Benefit of turning it off:** No app can access live video from your camera until you allow it again in Settings.
- **What you lose:** Features of video calls, Windows Hello face sign-in in apps, and camera apps.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\Value = Deny`

### Microphone access

**OPTIONAL** - privacy impact **High**

- **What it does:** Controls whether apps may use audio from your microphone. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read audio from your microphone.
- **Benefit of turning it off:** No app can access audio from your microphone until you allow it again in Settings.
- **What you lose:** Features of voice and video calls, dictation and voice recorder.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\Value = Deny`

### Contacts access

**DISABLE** - privacy impact **Medium**

- **What it does:** Controls whether apps may use names, numbers and addresses of your contacts. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read names, numbers and addresses of your contacts.
- **Benefit of turning it off:** No app can access names, numbers and addresses of your contacts until you allow it again in Settings.
- **What you lose:** Features of apps that pick contacts from your address book.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts\Value = Deny`

### Call history access

**DISABLE** - privacy impact **Medium**

- **What it does:** Controls whether apps may use who you called and when. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read who you called and when.
- **Benefit of turning it off:** No app can access who you called and when until you allow it again in Settings.
- **What you lose:** Features of phone apps that show call history.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory\Value = Deny`

### Email access

**DISABLE** - privacy impact **High**

- **What it does:** Controls whether apps may use your email messages. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your email messages.
- **Benefit of turning it off:** No app can access your email messages until you allow it again in Settings.
- **What you lose:** Features of apps other than your mail app that read mail.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email\Value = Deny`

### Messages access

**DISABLE** - privacy impact **High**

- **What it does:** Controls whether apps may use your SMS/MMS messages. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your SMS/MMS messages.
- **Benefit of turning it off:** No app can access your SMS/MMS messages until you allow it again in Settings.
- **What you lose:** Features of apps that read or send text messages.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat\Value = Deny`

### Notifications access

**DISABLE** - privacy impact **Medium**

- **What it does:** Controls whether apps may use the content of every notification you receive. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read the content of every notification you receive.
- **Benefit of turning it off:** No app can access the content of every notification you receive until you allow it again in Settings.
- **What you lose:** Features of apps that mirror or manage notifications (for example smartwatch apps).
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener\Value = Deny`

### Pictures access

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Controls whether apps may use your Pictures folder. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your Pictures folder.
- **Benefit of turning it off:** No app can access your Pictures folder until you allow it again in Settings.
- **What you lose:** Features of photo viewers and editors from the Store.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary\Value = Deny`

### Videos access

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Controls whether apps may use your Videos folder. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your Videos folder.
- **Benefit of turning it off:** No app can access your Videos folder until you allow it again in Settings.
- **What you lose:** Features of video players and editors from the Store.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary\Value = Deny`

### Documents and files access

**OPTIONAL** - privacy impact **High**

- **What it does:** Controls whether apps may use your Documents folder. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your Documents folder.
- **Benefit of turning it off:** No app can access your Documents folder until you allow it again in Settings.
- **What you lose:** Features of Store apps that open documents directly.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary\Value = Deny`

### Location access

**OPTIONAL** - privacy impact **High**

- **What it does:** Controls whether apps may use your precise location. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read your precise location.
- **Benefit of turning it off:** No app can access your precise location until you allow it again in Settings.
- **What you lose:** Features of maps, weather, find-my-device and automatic time zone in apps.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\Value = Deny`

### Generative AI access

**DISABLE** - privacy impact **Medium**

- **What it does:** Controls whether apps may use the on-device AI models and what you feed them. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read the on-device AI models and what you feed them.
- **Benefit of turning it off:** No app can access the on-device AI models and what you feed them until you allow it again in Settings.
- **What you lose:** Features of apps that use Windows AI features.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels\Value = Deny`

### Presence detection

**OPTIONAL** - privacy impact **Low**

- **What it does:** Controls whether apps may use whether someone is in front of the screen (presence sensor). This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read whether someone is in front of the screen (presence sensor).
- **Benefit of turning it off:** No app can access whether someone is in front of the screen (presence sensor) until you allow it again in Settings.
- **What you lose:** Features of apps that wake or lock based on presence.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\humanPresence\Value = Deny`

### Passkeys

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Controls whether apps may use use of your saved passkeys to sign in. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read use of your saved passkeys to sign in.
- **Benefit of turning it off:** No app can access use of your saved passkeys to sign in until you allow it again in Settings.
- **What you lose:** Features of passwordless passkey sign-in in apps - a security feature.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\passkeys\Value = Deny`

### Bluetooth devices

**OPTIONAL** - privacy impact **Low**

- **What it does:** Controls whether apps may use communication with paired Bluetooth devices. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read communication with paired Bluetooth devices.
- **Benefit of turning it off:** No app can access communication with paired Bluetooth devices until you allow it again in Settings.
- **What you lose:** Features of apps that sync with Bluetooth devices.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync\Value = Deny`

### Input devices (HID)

**OPTIONAL** - privacy impact **Low**

- **What it does:** Controls whether apps may use direct access to keyboards, game controllers and other HID devices. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read direct access to keyboards, game controllers and other HID devices.
- **Benefit of turning it off:** No app can access direct access to keyboards, game controllers and other HID devices until you allow it again in Settings.
- **What you lose:** Features of apps that configure controllers or special keyboards.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\humanInterfaceDevice\Value = Deny`

### Saved passkey lists

**DISABLE** - privacy impact **Low**

- **What it does:** Controls whether apps may use the list of passkeys saved on this PC. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read the list of passkeys saved on this PC.
- **Benefit of turning it off:** No app can access the list of passkeys saved on this PC until you allow it again in Settings.
- **What you lose:** Features of apps that list or manage your passkeys.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\passkeysEnumeration\Value = Deny`

### Custom sensors

**DISABLE** - privacy impact **Low**

- **What it does:** Controls whether apps may use readings from extra sensors on the device. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read readings from extra sensors on the device.
- **Benefit of turning it off:** No app can access readings from extra sensors on the device until you allow it again in Settings.
- **What you lose:** Features of apps that read special sensors.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\sensors.custom\Value = Deny`

### Serial ports

**OPTIONAL** - privacy impact **Low**

- **What it does:** Controls whether apps may use devices connected to serial ports. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read devices connected to serial ports.
- **Benefit of turning it off:** No app can access devices connected to serial ports until you allow it again in Settings.
- **What you lose:** Features of apps that talk to serial devices (for example microcontrollers).
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\serialCommunication\Value = Deny`

### USB devices

**OPTIONAL** - privacy impact **Low**

- **What it does:** Controls whether apps may use direct access to USB devices. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read direct access to USB devices.
- **Benefit of turning it off:** No app can access direct access to USB devices until you allow it again in Settings.
- **What you lose:** Features of apps that talk to special USB hardware.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\usb\Value = Deny`

### Wi-Fi information

**DISABLE** - privacy impact **Medium**

- **What it does:** Controls whether apps may use nearby Wi-Fi networks, which can reveal your location. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read nearby Wi-Fi networks, which can reveal your location.
- **Benefit of turning it off:** No app can access nearby Wi-Fi networks, which can reveal your location until you allow it again in Settings.
- **What you lose:** Features of apps that scan for Wi-Fi networks.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\wifiData\Value = Deny`

### Wi-Fi Direct

**OPTIONAL** - privacy impact **Low**

- **What it does:** Controls whether apps may use direct Wi-Fi connections to other devices. This is the same switch as in Settings > Privacy & security.
- **What can be collected:** Apps that are allowed can read direct Wi-Fi connections to other devices.
- **Benefit of turning it off:** No app can access direct Wi-Fi connections to other devices until you allow it again in Settings.
- **What you lose:** Features of apps that connect to printers or screens over Wi-Fi Direct.
- **Possible problems:** Apps that need this show an error or ask you to enable access; Windows itself keeps working.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\wiFiDirect\Value = Deny`

### Voice activation

**DISABLE** - privacy impact **Medium**

- **What it does:** Lets voice assistants listen for a wake word.
- **What can be collected:** Audio is analysed locally for the keyword; after it, your voice goes to the assistant service.
- **Benefit of turning it off:** The microphone is not kept listening for wake words.
- **What you lose:** Hands-free "Hey ..." activation of voice assistants.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps\AgentActivationEnabled = 0`

### Voice activation when locked

**DISABLE** - privacy impact **Medium**

- **What it does:** Lets voice assistants respond to the wake word while the PC is locked.
- **What can be collected:** Voice commands from anyone near the locked PC.
- **Benefit of turning it off:** Nobody can talk to the assistant on your locked PC.
- **What you lose:** Voice use while locked.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps\AgentActivationOnLockScreenEnabled = 0`

## 4. Cortana and Input Personalisation

### Cortana

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Microsoft voice assistant. It was retired on current Windows; this policy blocks it where it still exists.
- **What can be collected:** Voice queries, contacts, calendar and location when Cortana is used.
- **Benefit of turning it off:** Cortana cannot run.
- **What you lose:** Cortana (already retired on Windows 11).
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\AllowCortana = 0`

### Input personalisation

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Learns from what you type and write to build a personal dictionary.
- **What can be collected:** Typing history, handwriting samples and contact names.
- **Benefit of turning it off:** Your typing and handwriting are not collected.
- **What you lose:** Personalised word suggestions.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitInkCollection = 1`, `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitTextCollection = 1`, `HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts = 0`, `HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization\AllowInputPersonalization = 0`

### Web search in Cortana

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Sends what you type in Windows Search to Bing to show web results.
- **What can be collected:** Every search term you type.
- **Benefit of turning it off:** Your local searches stay local.
- **What you lose:** Web results in Windows Search.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\ConnectedSearchUseWeb = 0`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\DisableWebSearch = 1`

### Search highlights

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows trending searches, illustrations and news in the search box.
- **What can be collected:** Your region and search usage.
- **Benefit of turning it off:** A cleaner search box, no trending content.
- **What you lose:** Daily illustrations and trending topics.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\EnableDynamicContentInWSB = 0`

### Voice activation

**DISABLE** - privacy impact **Medium**

- **What it does:** Same switch as Voice activation in App Privacy: listening for an assistant wake word.
- **What can be collected:** Audio after the wake word.
- **Benefit of turning it off:** No always-listening microphone.
- **What you lose:** Hands-free activation.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps\AgentActivationEnabled = 0`

## 5. Location Services

### App access to location

**OPTIONAL** - privacy impact **High**

- **What it does:** Controls whether apps may read your location.
- **What can be collected:** Your precise position from GPS, Wi-Fi and IP.
- **Benefit of turning it off:** Apps cannot track where you are.
- **What you lose:** Location in maps, weather and similar apps.
- **Possible problems:** Apps that need it ask you to turn it back on.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\Value = Deny`

### Windows location functionality

**OPTIONAL** - privacy impact **High** - needs administrator

- **What it does:** Turns off the Windows location platform completely (policy).
- **What can be collected:** Your location for Windows and all apps.
- **Benefit of turning it off:** Nothing on the PC can determine your location.
- **What you lose:** Location in every app, Find My Device, automatic time zone and local weather.
- **Possible problems:** Automatic time zone stops working; set the time zone manually.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableLocation = 1`

### Windows Geolocation Service (O&O L005)

**OPTIONAL** - privacy impact **High** - needs administrator

- **What it does:** The service that provides location to Windows and apps.
- **What can be collected:** Your location while the service runs.
- **Benefit of turning it off:** The location provider cannot start.
- **What you lose:** All location features.
- **Possible problems:** Same effect as turning Windows location off; reversible from Restore.
- **Change:** service `lfsvc` startup = Disabled

### Location history

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Windows keeps the last 24 hours of device location so apps with permission can read it.
- **What can be collected:** Recent positions of the device.
- **Benefit of turning it off:** Turning Windows location off (above) stops the history. You can clear it any time in Settings > Privacy & security > Location.
- **What you lose:** Nothing beyond location itself.
- **Possible problems:** No separate switch exists on current Windows, so BLOB lists this for information.
- **Change:** information only, no switch

### Location sensors

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Turns off sensors (like GPS and ambient sensors) used for location.
- **What can be collected:** Sensor readings that can reveal position and movement.
- **Benefit of turning it off:** Sensor-based tracking stops.
- **What you lose:** Auto-rotate and brightness may stop on devices that use these sensors.
- **Possible problems:** Screen auto-rotation can stop working on tablets.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableSensors = 1`

### Location scripting

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Lets scripts query your location through the Windows location API.
- **What can be collected:** Your location, to scripts running on the PC.
- **Benefit of turning it off:** Scripts cannot read your location.
- **What you lose:** Nothing for normal use.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableLocationScripting = 1`

### Geofencing

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Lets apps trigger actions when you enter or leave an area.
- **What can be collected:** Your movements in and out of defined areas.
- **Benefit of turning it off:** Covered by turning off app location access or Windows location above.
- **What you lose:** Location-based reminders.
- **Possible problems:** No separate switch on current Windows; listed for information.
- **Change:** information only, no switch

### Location-based advertising

**DISABLE** - privacy impact **Medium**

- **What it does:** Ads chosen using where you are.
- **What can be collected:** Location combined with your advertising ID.
- **Benefit of turning it off:** Covered by turning off the advertising ID (Privacy section) and app location access.
- **What you lose:** Local ads.
- **Possible problems:** No separate switch; listed for information.
- **Change:** information only, no switch

### Find My Device (O&O L008)

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Periodically sends the location of the PC to your Microsoft account so you can find it if it is lost.
- **What can be collected:** Device location, linked to your account.
- **Benefit of turning it off:** Your location is no longer stored with Microsoft.
- **What you lose:** You cannot locate or lock the PC remotely if it is lost or stolen.
- **Possible problems:** Weakens theft recovery; keep it on for laptops you carry around.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice\AllowFindMyDevice = 0`

### Location override (O&O P098)

**OPTIONAL** - privacy impact **Low**

- **What it does:** Lets you set a default location that apps use when the real one is unavailable.
- **What can be collected:** A location you choose.
- **Benefit of turning it off:** Set or clear it in Settings > Privacy & security > Location > Default location.
- **What you lose:** Nothing.
- **Possible problems:** No documented switch; listed for information.
- **Change:** information only, no switch

## 6. Search

### Web search in Start

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Sends what you type in Start to Bing and shows web suggestions.
- **What can be collected:** Every search term typed in Start.
- **Benefit of turning it off:** Start search becomes local only, and faster.
- **What you lose:** Web results and suggestions in Start.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions = 1`, `HKCU\Software\Microsoft\Windows\CurrentVersion\Search\BingSearchEnabled = 0`

### Microsoft account cloud search (O&O M029)

**DISABLE** - privacy impact **Medium**

- **What it does:** Includes results from OneDrive, Outlook and Bing for your Microsoft account in Windows Search.
- **What can be collected:** Your searches, matched against your cloud content.
- **Benefit of turning it off:** Searches do not query your Microsoft cloud content.
- **What you lose:** Cloud files and mail in search results.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings\IsMSACloudSearchEnabled = 0`

### Work or school cloud search (O&O M030)

**DISABLE** - privacy impact **Medium**

- **What it does:** Includes results from your work or school account (SharePoint, OneDrive for Business) in Windows Search.
- **What can be collected:** Your searches, matched against work content.
- **Benefit of turning it off:** Searches do not query work cloud content.
- **What you lose:** Work files in search results.
- **Possible problems:** Your organisation may manage this setting anyway.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings\IsAADCloudSearchEnabled = 0`

### Device search history (O&O M031)

**DISABLE** - privacy impact **Low**

- **What it does:** Keeps a history of your searches on this PC to improve suggestions.
- **What can be collected:** Your past searches, stored locally.
- **Benefit of turning it off:** No search history is kept.
- **What you lose:** Suggestions based on earlier searches.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings\IsDeviceSearchHistoryEnabled = 0`

### Windows Search Bing extension (O&O M103)

**DISABLE** - privacy impact **Medium**

- **What it does:** The Bing integration that powers web results inside Windows Search.
- **What can be collected:** Search terms sent to Bing.
- **Benefit of turning it off:** Windows Search does not contact Bing.
- **What you lose:** Web answers in Windows Search.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Search\BingSearchEnabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\Search\CortanaConsent = 0`

## 7. Synchronisation of Windows Settings

### Synchronisation of all settings

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Syncs your Windows settings to your Microsoft account and other PCs.
- **What can be collected:** Your preferences, themes, language and some passwords, stored in your account.
- **Benefit of turning it off:** Your settings stay on this PC only.
- **What you lose:** Settings no longer follow you to other PCs.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableSettingSyncUserOverride = 1`

### Password synchronisation

**OPTIONAL** - privacy impact **High** - needs administrator

- **What it does:** Syncs saved Wi-Fi and website passwords through your Microsoft account.
- **What can be collected:** Encrypted credentials stored in the cloud.
- **Benefit of turning it off:** Passwords never leave this PC through Windows sync.
- **What you lose:** Passwords do not appear on your other PCs.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableCredentialsSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableCredentialsSettingSyncUserOverride = 1`

### Language synchronisation

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Syncs language, keyboard and dictionary preferences.
- **What can be collected:** Your languages and custom dictionary words.
- **Benefit of turning it off:** Language data stays local.
- **What you lose:** Language settings do not follow you.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableLanguageSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableLanguageSettingSyncUserOverride = 1`

### Theme synchronisation

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Syncs wallpaper, colours and theme.
- **What can be collected:** Your wallpaper image and colour choices.
- **Benefit of turning it off:** Theme data stays local.
- **What you lose:** The same look on all your PCs.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableDesktopThemeSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableDesktopThemeSettingSyncUserOverride = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisablePersonalizationSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisablePersonalizationSettingSyncUserOverride = 1`

### Other Windows settings synchronisation

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Syncs app settings and other Windows settings (like mouse and accessibility).
- **What can be collected:** Assorted preferences.
- **Benefit of turning it off:** These settings stay local.
- **What you lose:** They do not follow you to other PCs.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableApplicationSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableApplicationSettingSyncUserOverride = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableWindowsSettingSync = 2`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\DisableWindowsSettingSyncUserOverride = 1`

## 8. Security

### Wi-Fi Sense

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Old Windows 10 feature that connected automatically to open hotspots and networks shared by contacts.
- **What can be collected:** Networks you connect to and hotspot quality data.
- **Benefit of turning it off:** The PC never joins suggested open hotspots on its own.
- **What you lose:** Automatic hotspot connections (feature already removed in newer Windows).
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config\AutoConnectAllowedOEM = 0`

### User Steps Recorder

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Steps Recorder captures screenshots and clicks to document a problem.
- **What can be collected:** Screenshots and actions while recording.
- **Benefit of turning it off:** The recorder cannot run.
- **What you lose:** Recording problem steps for support (the tool is deprecated).
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableUAR = 1`

### Windows Media DRM internet access

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Lets the old Windows Media DRM system get licences from the internet.
- **What can be collected:** Licence requests that identify the content and device.
- **Benefit of turning it off:** No DRM licence lookups online.
- **What you lose:** Playing protected WMA/WMV files that still need online licences.
- **Possible problems:** Old protected media may refuse to play.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\WMDRM\DisableOnline = 1`

### Customer Experience Improvement Program

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Legacy program that sends usage statistics to Microsoft.
- **What can be collected:** How you use Windows features.
- **Benefit of turning it off:** Usage statistics are not sent.
- **What you lose:** Nothing you will notice.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows\CEIPEnable = 0`

### NFC

**OPTIONAL** - privacy impact **Low**

- **What it does:** Lets apps turn radios such as NFC and Bluetooth on or off (radio control permission).
- **What can be collected:** Nothing is sent; apps gain control of your radios.
- **Benefit of turning it off:** Apps cannot switch your radios on behind your back.
- **What you lose:** Apps that toggle NFC or Bluetooth for you; use Settings instead.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios\Value = Deny`

### Wireless Display

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Lets other devices project (Miracast) their screen to this PC.
- **What can be collected:** Nothing is sent; nearby devices can discover the PC.
- **Benefit of turning it off:** The PC is not discoverable as a wireless display.
- **What you lose:** Projecting a phone or laptop to this PC.
- **Possible problems:** Projecting FROM this PC still works.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect\AllowProjectionToPC = 0`

### Cellular broadband

**OPTIONAL** - privacy impact **Low**

- **What it does:** Lets apps use mobile data on PCs with a SIM or eSIM.
- **What can be collected:** App traffic over your mobile connection.
- **Benefit of turning it off:** Apps cannot use mobile data.
- **What you lose:** Mobile data for apps on LTE/5G laptops.
- **Possible problems:** None on PCs without a SIM.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\cellularData\Value = Deny`

### Wi-Fi Direct

**OPTIONAL** - privacy impact **Low**

- **What it does:** Same switch as Wi-Fi Direct in App Privacy: direct Wi-Fi connections from apps to other devices.
- **What can be collected:** Device discovery data.
- **Benefit of turning it off:** Apps cannot open Wi-Fi Direct connections.
- **What you lose:** Wi-Fi Direct printing and casting from apps.
- **Possible problems:** None for most users.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\wiFiDirect\Value = Deny`

### Bluetooth pairing

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Pairing lets keyboards, mice, headsets and controllers connect to the PC.
- **What can be collected:** Device names and addresses of paired devices, stored locally.
- **Benefit of turning it off:** Little privacy gain; turn Bluetooth off in Settings when you do not use it.
- **What you lose:** All Bluetooth devices would stop working.
- **Possible problems:** Disabling pairing breaks wireless peripherals, so BLOB does not offer a switch.
- **Change:** information only, no switch

## 9. Windows Update

### Peer-to-peer update sharing

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Delivery Optimization uploads Windows updates from your PC to other PCs.
- **What can be collected:** Your IP address is visible to peers; upload bandwidth is used.
- **Benefit of turning it off:** Updates come only from Microsoft; your connection is not used to serve others.
- **What you lose:** Slightly slower updates in homes with several PCs.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode = 0`

### Update sharing restricted to local networks

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Allows update sharing only between PCs on your own network. Use this OR the switch above, not both.
- **What can be collected:** Peers on your local network only.
- **Benefit of turning it off:** No sharing with internet strangers, but home PCs still help each other.
- **What you lose:** Internet peers.
- **Possible problems:** Choose one of the two Delivery Optimization switches; the last one applied wins.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode = 1`

### Automatic driver updates (O&O W010)

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Lets Windows Update install hardware drivers automatically.
- **What can be collected:** Your hardware IDs, as with any update check.
- **Benefit of turning it off:** Windows Update will not replace drivers you installed yourself (for example a GPU driver).
- **What you lose:** Automatic driver fixes; you must update drivers yourself.
- **Possible problems:** New devices may need a manual driver download.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\ExcludeWUDriversInQualityUpdate = 1`

### Optional updates

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Lets Windows install optional non-security updates and feature switches early.
- **What can be collected:** Nothing extra.
- **Benefit of turning it off:** Only regular monthly updates are installed.
- **What you lose:** New features arrive later.
- **Possible problems:** None; security updates are not affected.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AllowOptionalContent = 0`

### Preview updates

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Allows Windows Insider preview builds on this PC.
- **What can be collected:** Preview builds require optional diagnostic data.
- **Benefit of turning it off:** The PC stays on stable releases.
- **What you lose:** Access to preview builds.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\ManagePreviewBuilds = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\ManagePreviewBuildsPolicyValue = 0`

### Feature upgrade delays

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Delays big yearly feature upgrades by 180 days (security updates still arrive).
- **What can be collected:** Nothing extra.
- **Benefit of turning it off:** You get feature upgrades after early problems are fixed.
- **What you lose:** New features arrive six months later.
- **Possible problems:** Windows Home may ignore this policy.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\DeferFeatureUpdates = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\DeferFeatureUpdatesPeriodInDays = 180`

### Automatic update behaviour

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Windows downloads and installs security updates automatically.
- **What can be collected:** Update checks send device and version details.
- **Benefit of turning it off:** Very little privacy gain.
- **What you lose:** Security patches would arrive late or not at all.
- **Possible problems:** Turning automatic updates off leaves the PC exposed to known attacks, so BLOB does not offer a switch.
- **Change:** information only, no switch

### Automatic Microsoft Store app updates

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Lets the Store update apps automatically in the background.
- **What can be collected:** Your app list, as part of update checks.
- **Benefit of turning it off:** Apps update only when you choose.
- **What you lose:** Automatic app fixes, including security fixes for apps.
- **Possible problems:** Apps can fall behind on security updates; update them in the Store regularly.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\WindowsStore\AutoDownload = 2`

## 10. Microsoft Edge Chromium

### Automatic browser sign-in

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Signs Edge in with your Windows account automatically.
- **What can be collected:** Browsing data synced to your account.
- **Benefit of turning it off:** Edge stays signed out unless you sign in yourself.
- **What you lose:** Automatic sync of favourites and passwords.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\BrowserSignin = 0`

### Bing Chat in the new tab page

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows the Copilot/Bing chat box on the new tab page.
- **What can be collected:** What you type into it.
- **Benefit of turning it off:** A quieter new tab page.
- **What you lose:** The chat box on new tabs.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\NewTabPageBingChatEnabled = 0`

### Visual search

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Lets you search the web with an image you hover or capture.
- **What can be collected:** Images from pages you visit, sent to Bing.
- **Benefit of turning it off:** Images are not sent for analysis.
- **What you lose:** Image hover search.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\VisualSearchEnabled = 0`

### Text prediction in forms

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Suggests words as you type in web forms.
- **What can be collected:** What you type in text fields.
- **Benefit of turning it off:** Your typing is not sent for predictions.
- **What you lose:** Inline word suggestions.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\TextPredictionEnabled = 0`

### Cloud-based tab services

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Uses Microsoft cloud services to suggest tab groups and titles.
- **What can be collected:** Titles and addresses of your open tabs.
- **Benefit of turning it off:** Open tabs are not analysed in the cloud.
- **What you lose:** Automatic tab grouping suggestions.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\TabServicesEnabled = 0`

### AI-powered history search

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Uses AI to search your history by meaning.
- **What can be collected:** Your browsing history.
- **Benefit of turning it off:** History is searched by plain text only.
- **What you lose:** Natural-language history search.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\HistorySearchSettings = 1`

### Shopping assistant

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Shows coupons and price comparisons on shopping sites.
- **What can be collected:** Shopping pages you visit.
- **Benefit of turning it off:** Shopping visits are not checked against Microsoft services.
- **What you lose:** Coupons and price history.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\EdgeShoppingAssistantEnabled = 0`

### AI-generated themes

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Creates browser themes from a text prompt.
- **What can be collected:** Your prompts.
- **Benefit of turning it off:** No prompts sent.
- **What you lose:** AI theme generation.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\AIGenThemesEnabled = 0`

### Built-in AI APIs for websites

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Lets websites use Edge built-in AI models.
- **What can be collected:** Page content passed to on-device AI by websites.
- **Benefit of turning it off:** Websites cannot use the built-in AI.
- **What you lose:** Site features built on those APIs.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\BuiltInAIAPIsEnabled = 0`

### Inline Compose

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Offers AI writing help inside text boxes.
- **What can be collected:** Text you write.
- **Benefit of turning it off:** Your writing is not sent to Copilot.
- **What you lose:** AI rewrite suggestions.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\ComposeInlineEnabled = 0`

### Copilot access to page context

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Lets Copilot read the page you are viewing.
- **What can be collected:** The full content of the current page.
- **Benefit of turning it off:** Copilot cannot read your open pages.
- **What you lose:** Page summaries by Copilot.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\CopilotPageContext = 0`

### Default-browser prompts

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Asks you to make Edge your default browser.
- **What can be collected:** Whether you accept.
- **Benefit of turning it off:** No nagging.
- **What you lose:** Nothing.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\DefaultBrowserSettingsCampaignEnabled = 0`

### Browser campaigns

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows full-page promotional tabs for Microsoft offers.
- **What can be collected:** Your interaction with promotions.
- **Benefit of turning it off:** No promotional tabs.
- **What you lose:** Nothing.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\PromotionalTabsEnabled = 0`

### Diagnostic data collection

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Sends Edge usage and crash data to Microsoft.
- **What can be collected:** Browser usage, crashes and optionally visited sites.
- **Benefit of turning it off:** Only the required minimum is sent.
- **What you lose:** Nothing you will notice.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\DiagnosticData = 0`

### Microsoft Rewards

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows Microsoft Rewards offers in Edge.
- **What can be collected:** Searches and activity tied to Rewards.
- **Benefit of turning it off:** No Rewards prompts.
- **What you lose:** Rewards point offers in the browser.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\ShowMicrosoftRewards = 0`

### Microsoft 365 Copilot Chat icon

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows the Microsoft 365 Copilot Chat icon in the toolbar.
- **What can be collected:** Nothing until used.
- **Benefit of turning it off:** A cleaner toolbar.
- **What you lose:** The shortcut icon.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\Microsoft365CopilotChatIconEnabled = 0`

### Settings recommendations

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows recommendations and notifications about Edge features.
- **What can be collected:** Feature usage.
- **Benefit of turning it off:** No feature nags.
- **What you lose:** Feature tips.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\ShowRecommendationsEnabled = 0`

### Default top sites

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Fills the new tab page with sponsored and default sites.
- **What can be collected:** Clicks on those tiles.
- **Benefit of turning it off:** No sponsored tiles.
- **What you lose:** Default site shortcuts.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\NewTabPageHideDefaultTopSites = 1`

### Edge Secure Network

**OPTIONAL** - privacy impact **Medium**

- **What it does:** A free VPN-like proxy for public Wi-Fi run with Cloudflare.
- **What can be collected:** Traffic is routed through the proxy provider when used.
- **Benefit of turning it off:** Turn it off in Edge Settings > Privacy if you do not want traffic routed through a proxy.
- **What you lose:** Encrypted browsing on public Wi-Fi.
- **Possible problems:** No dependable policy; listed for information.
- **Change:** information only, no switch

### Fast Startup

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Preloads Edge at sign-in so it opens faster.
- **What can be collected:** Nothing extra; uses memory in the background.
- **Benefit of turning it off:** Edge does not run until you open it.
- **What you lose:** Edge opens a little slower.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\StartupBoostEnabled = 0`

### Adobe Acrobat subscription button

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows an Adobe Acrobat offer in the PDF viewer.
- **What can be collected:** Clicks on the offer.
- **Benefit of turning it off:** No upsell button.
- **What you lose:** Nothing.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\ShowAcrobatSubscriptionButton = 0`

### Spotlight experiences and recommendations

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows personalised background images and suggestions.
- **What can be collected:** Usage for personalisation.
- **Benefit of turning it off:** No personalised suggestions.
- **What you lose:** Spotlight backgrounds.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\SpotlightExperiencesAndRecommendationsEnabled = 0`

### Sharing browsing data with other Windows features (O&O E157)

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Lets Windows features (search, recommendations) use your Edge browsing data.
- **What can be collected:** Browsing history and site activity.
- **Benefit of turning it off:** Browsing data stays inside Edge.
- **What you lose:** Recent sites in Windows search and Start.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\LocalBrowserDataShareEnabled = 0`

### Browser history

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Saves the sites you visit.
- **What can be collected:** Your full browsing history (local, synced if signed in).
- **Benefit of turning it off:** No history is kept.
- **What you lose:** Going back to sites through history and address-bar recall.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\SavingBrowserHistoryDisabled = 1`

### Address-bar suggestions

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Sends what you type in the address bar to the search engine for suggestions.
- **What can be collected:** Every keystroke in the address bar.
- **Benefit of turning it off:** Typing is not sent before you press Enter.
- **What you lose:** Live search suggestions.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\SearchSuggestEnabled = 0`

### Microsoft Search in Bing

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Adds work/school results from Microsoft Search to the address bar.
- **What can be collected:** Searches matched against your organisation content.
- **Benefit of turning it off:** No work search in the address bar.
- **What you lose:** Work results in the address bar.
- **Possible problems:** None. Edge shows "Your browser is managed by your organisation" for policies.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\AddressBarMicrosoftSearchInBingProviderEnabled = 0`

## 11. Microsoft Edge Legacy

### Web tracking

**NOT APPLICABLE** - privacy impact **Low**

- **What it does:** Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021.
- **What can be collected:** Nothing - the browser no longer exists on current Windows.
- **Benefit of turning it off:** No benefit: there is nothing left to turn off.
- **What you lose:** Nothing.
- **Possible problems:** Not applicable. The Chromium-based Edge settings are in the section above.
- **Change:** information only, no switch

### Form suggestions

**NOT APPLICABLE** - privacy impact **Low**

- **What it does:** Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021.
- **What can be collected:** Nothing - the browser no longer exists on current Windows.
- **Benefit of turning it off:** No benefit: there is nothing left to turn off.
- **What you lose:** Nothing.
- **Possible problems:** Not applicable. The Chromium-based Edge settings are in the section above.
- **Change:** information only, no switch

### Search history

**NOT APPLICABLE** - privacy impact **Low**

- **What it does:** Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021.
- **What can be collected:** Nothing - the browser no longer exists on current Windows.
- **Benefit of turning it off:** No benefit: there is nothing left to turn off.
- **What you lose:** Nothing.
- **Possible problems:** Not applicable. The Chromium-based Edge settings are in the section above.
- **Change:** information only, no switch

### Edge Bar

**NOT APPLICABLE** - privacy impact **Low**

- **What it does:** Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021.
- **What can be collected:** Nothing - the browser no longer exists on current Windows.
- **Benefit of turning it off:** No benefit: there is nothing left to turn off.
- **What you lose:** Nothing.
- **Possible problems:** Not applicable. The Chromium-based Edge settings are in the section above.
- **Change:** information only, no switch

### Personalised suggestions

**NOT APPLICABLE** - privacy impact **Low**

- **What it does:** Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021.
- **What can be collected:** Nothing - the browser no longer exists on current Windows.
- **Benefit of turning it off:** No benefit: there is nothing left to turn off.
- **What you lose:** Nothing.
- **Possible problems:** Not applicable. The Chromium-based Edge settings are in the section above.
- **Change:** information only, no switch

### Browser data collection

**NOT APPLICABLE** - privacy impact **Low**

- **What it does:** Setting of the old Microsoft Edge (EdgeHTML), which Microsoft removed from Windows in 2021.
- **What can be collected:** Nothing - the browser no longer exists on current Windows.
- **Benefit of turning it off:** No benefit: there is nothing left to turn off.
- **What you lose:** Nothing.
- **Possible problems:** Not applicable. The Chromium-based Edge settings are in the section above.
- **Change:** information only, no switch

## 12. Microsoft Office

### Connected experiences with content analytics

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Office features that analyse your document content in the cloud (Designer, Editor, translation).
- **What can be collected:** Content of your documents sent for analysis.
- **Benefit of turning it off:** Document content is not sent to Microsoft for these features.
- **What you lose:** Designer, cloud spelling/grammar and translation.
- **Possible problems:** Policies apply to Office 2016 and later.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\privacy\usercontentdisabled = 2`

### Office diagnostic data submission

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Sends Office usage and diagnostic data to Microsoft.
- **What can be collected:** How you use Office apps, errors and performance.
- **Benefit of turning it off:** Office stops sending optional diagnostic data.
- **What you lose:** Nothing you will notice.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\clienttelemetry\SendTelemetry = 3`

### Office surveys

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Shows satisfaction surveys and the feedback button in Office.
- **What can be collected:** Your answers and screenshots you attach.
- **Benefit of turning it off:** No survey pop-ups.
- **What you lose:** The Office feedback option.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\feedback\surveyenabled = 0`, `HKCU\Software\Policies\Microsoft\office\16.0\common\feedback\enabled = 0`

### Office Customer Experience Improvement Program

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Legacy Office usage statistics program.
- **What can be collected:** Feature usage statistics.
- **Benefit of turning it off:** Statistics are not sent.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\qmenable = 0`

### Office first-run movie (O&O F020)

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Plays the introduction video the first time Office starts.
- **What can be collected:** Nothing.
- **Benefit of turning it off:** Office opens straight away.
- **What you lose:** The intro video.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\firstrun\disablemovie = 1`, `HKCU\Software\Policies\Microsoft\office\16.0\firstrun\bootedrtm = 1`

### Office sign-in (O&O F021)

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Lets you sign in to Office with a Microsoft or work account.
- **What can be collected:** Your account and documents in OneDrive.
- **Benefit of turning it off:** Office cannot be tied to an online account.
- **What you lose:** OneDrive saving, co-authoring and Microsoft 365 activation.
- **Possible problems:** Microsoft 365 subscriptions need sign-in to activate; only use this with standalone Office.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\signin\signinoptions = 3`

## 13. Microsoft 365

### Cloud-connected Office features

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Optional connected experiences such as LinkedIn features, 3D maps and online video.
- **What can be collected:** Data these services need, for example search terms.
- **Benefit of turning it off:** Optional online services are off.
- **What you lose:** Those optional online features.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\privacy\controllerconnectedservicesenabled = 2`

### Connected experiences

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Experiences that download online content into Office (templates, online pictures, icons).
- **What can be collected:** Your searches for templates and images.
- **Benefit of turning it off:** Office does not fetch online content.
- **What you lose:** Online templates, stock images and icons.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\privacy\downloadcontentdisabled = 2`

### Usage and diagnostic data sharing

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Same as Office diagnostic data: usage and diagnostics from Microsoft 365 apps.
- **What can be collected:** App usage and errors.
- **Benefit of turning it off:** Optional data is not sent.
- **What you lose:** Nothing you will notice.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\office\16.0\common\clienttelemetry\SendTelemetry = 3`

### Promotional features

**DISABLE** - privacy impact **Low**

- **What it does:** Promotional messages and upgrade offers inside Microsoft 365 apps.
- **What can be collected:** Interaction with offers.
- **Benefit of turning it off:** Turning off connected experiences (above) removes most of them.
- **What you lose:** Nothing.
- **Possible problems:** No separate documented switch; listed for information.
- **Change:** information only, no switch

## 14. Windows Explorer

### OneDrive integration

**OPTIONAL** - privacy impact **High** - needs administrator

- **What it does:** Lets OneDrive sync files and back up Desktop, Documents and Pictures.
- **What can be collected:** Your files, stored in the cloud.
- **Benefit of turning it off:** No files are uploaded through OneDrive.
- **What you lose:** OneDrive sync and backup entirely.
- **Possible problems:** Files that only exist in OneDrive stay online; download what you need first.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC = 1`

### OneDrive promotional content

**DISABLE** - privacy impact **Low**

- **What it does:** Shows OneDrive and Microsoft 365 offers inside File Explorer.
- **What can be collected:** Clicks on offers.
- **Benefit of turning it off:** No offers in Explorer.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowSyncProviderNotifications = 0`

### OneDrive notifications

**OPTIONAL** - privacy impact **Low**

- **What it does:** OneDrive app notifications about sync, memories and storage.
- **What can be collected:** Nothing extra.
- **Benefit of turning it off:** Turn them off in OneDrive Settings > Notifications.
- **What you lose:** OneDrive alerts.
- **Possible problems:** Managed inside OneDrive; listed for information.
- **Change:** information only, no switch

### OneDrive network access before login

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Lets OneDrive contact Microsoft before anyone signs in.
- **What can be collected:** Network traffic from the PC before sign-in.
- **Benefit of turning it off:** No OneDrive traffic until you sign in.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Microsoft\OneDrive\PreventNetworkTrafficPreUserSignIn = 1`

### Start menu app suggestions

**DISABLE** - privacy impact **Low**

- **What it does:** Shows suggested apps in Start.
- **What can be collected:** App usage for suggestions.
- **Benefit of turning it off:** No promoted apps in Start.
- **What you lose:** App suggestions.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled = 0`

### Recently opened files

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Lists recently opened files in Start and Explorer.
- **What can be collected:** File names you opened, stored locally.
- **Benefit of turning it off:** Nobody looking at your screen sees what you worked on.
- **What you lose:** Quick access to recent files and jump lists.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackDocs = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ShowRecent = 0`

### Office.com files in Explorer (O&O P099)

**DISABLE** - privacy impact **Medium**

- **What it does:** Shows your Office.com and OneDrive files in Explorer Home.
- **What can be collected:** Your cloud file list, loaded from Microsoft.
- **Benefit of turning it off:** Explorer shows only local items.
- **What you lose:** Cloud files in Explorer Home.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ShowCloudFilesInQuickAccess = 0`

### Sync-provider notifications

**DISABLE** - privacy impact **Low**

- **What it does:** Same switch as OneDrive promotional content: banners from sync providers in Explorer.
- **What can be collected:** Clicks.
- **Benefit of turning it off:** No banners.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowSyncProviderNotifications = 0`

### Windows Explorer recommendations

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Shows recommended files from your Microsoft account activity in Explorer Home.
- **What can be collected:** Your recent cloud documents and collaborators.
- **Benefit of turning it off:** Explorer Home does not load recommendations from your account.
- **What you lose:** The Recommended section.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableGraphRecentItems = 1`

## 15. Lock Screen

### Windows Spotlight

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Downloads daily background pictures and facts from Bing for the lock screen and desktop.
- **What can be collected:** Your region and how you react to the images.
- **Benefit of turning it off:** No Bing content is fetched for your backgrounds.
- **What you lose:** Changing Spotlight images; you pick your own picture instead.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\CloudContent\DisableWindowsSpotlightFeatures = 1`

### Lock-screen advertisements

**DISABLE** - privacy impact **Low**

- **What it does:** Shows promotional overlays on the lock screen.
- **What can be collected:** Interaction with the ads.
- **Benefit of turning it off:** No ads before you sign in.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenOverlayEnabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenEnabled = 0`

### Fun facts and tips

**DISABLE** - privacy impact **Low**

- **What it does:** Shows "fun facts, tips, tricks and more" on the lock screen.
- **What can be collected:** Interaction with the tips.
- **Benefit of turning it off:** A clean lock screen.
- **What you lose:** Lock-screen trivia.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent-338387Enabled = 0`

### Lock-screen notifications

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Shows notifications on the lock screen.
- **What can be collected:** Nothing is sent, but message previews are visible to anyone near the PC.
- **Benefit of turning it off:** Private messages are not shown on a locked PC.
- **What you lose:** Seeing notifications without unlocking.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK = 0`

### Promotional recommendations

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Lets Windows show suggestions from third-party publishers in Spotlight and other places.
- **What can be collected:** Interaction with suggestions.
- **Benefit of turning it off:** No third-party promotions.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\CloudContent\DisableThirdPartySuggestions = 1`

## 16. Taskbar

### Windows Widgets

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** The Widgets board with news, weather and stocks.
- **What can be collected:** Your interests, location for weather, and what you read.
- **Benefit of turning it off:** No news feed tracking and no background loading.
- **What you lose:** Widgets board and its taskbar button.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Dsh\AllowNewsAndInterests = 0`

### Search box

**OPTIONAL** - privacy impact **Low**

- **What it does:** Shows the search box or icon on the taskbar (this hides it).
- **What can be collected:** Nothing extra; search itself is covered in the Search section.
- **Benefit of turning it off:** Less temptation to send searches to the web.
- **What you lose:** One-click search on the taskbar; the Windows key still opens search.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Search\SearchboxTaskbarMode = 0`

### News and interests

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Windows 10 taskbar weather and news feed.
- **What can be collected:** Interests and location for weather.
- **Benefit of turning it off:** No feed tracking.
- **What you lose:** Weather on the taskbar.
- **Possible problems:** Applies to Windows 10.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds\EnableFeeds = 0`

### People icon

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Windows 10 People bar for pinned contacts.
- **What can be collected:** Contacts you pin.
- **Benefit of turning it off:** No contact bar.
- **What you lose:** Pinned contacts.
- **Possible problems:** Applies to Windows 10.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\Explorer\HidePeopleBar = 1`

### Taskbar recommendations

**DISABLE** - privacy impact **Low**

- **What it does:** Shows account notifications and promoted recommendations in Start and the taskbar.
- **What can be collected:** Account status and usage.
- **Benefit of turning it off:** No account nags or promotions.
- **What you lose:** Backup and account reminders.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_AccountNotifications = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_IrisRecommendations = 0`

## 17. Activity History and Clipboard

### Sending activity history to Microsoft

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Uploads the list of apps, files and sites you used to your Microsoft account.
- **What can be collected:** Detailed activity history.
- **Benefit of turning it off:** Your activity stays on this PC.
- **What you lose:** Continuing activities on other devices.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\UploadUserActivities = 0`

### Storing activity history

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Records what you do on this PC for Timeline-style features.
- **What can be collected:** App, file and site usage stored locally.
- **Benefit of turning it off:** No activity log is kept.
- **What you lose:** Resume suggestions.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\PublishUserActivities = 0`

### Timeline

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** The Timeline view of past activities (Windows 10).
- **What can be collected:** Your activity history.
- **Benefit of turning it off:** No activity feed.
- **What you lose:** Timeline in Task View.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\EnableActivityFeed = 0`

### Clipboard history

**OPTIONAL** - privacy impact **Medium** - needs administrator

- **What it does:** Keeps a list of things you copied (Win+V).
- **What can be collected:** Everything you copy, including passwords, stored locally.
- **Benefit of turning it off:** Copied passwords and texts do not pile up in a history.
- **What you lose:** Win+V clipboard history.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\AllowClipboardHistory = 0`

### Clipboard cloud synchronisation

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Syncs your clipboard across devices through your Microsoft account.
- **What can be collected:** Everything you copy, uploaded to Microsoft.
- **Benefit of turning it off:** Copied content never leaves the PC.
- **What you lose:** Copy on one PC, paste on another.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\AllowCrossDeviceClipboard = 0`

### Sharing clipboard data across devices

**DISABLE** - privacy impact **High**

- **What it does:** Your personal switch for clipboard sync (Settings > System > Clipboard).
- **What can be collected:** Copied content uploaded for sync.
- **Benefit of turning it off:** Clipboard sync off for your account.
- **What you lose:** Cross-device paste.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Clipboard\EnableCloudClipboard = 0`

## 18. Microsoft Defender and SpyNet

### Automatic file sample submissions

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Sends suspicious files to Microsoft for analysis.
- **What can be collected:** Copies of suspicious files; Defender asks before sending files likely to contain personal data.
- **Benefit of turning it off:** Small: the data is technical and used to protect you and everyone else.
- **What you lose:** New and fast-spreading malware is caught much later, sometimes not at all.
- **Possible problems:** Turning this off weakens Microsoft Defender. BLOB never changes Defender settings; you can review them in Windows Security.
- **Change:** information only, no switch

### Microsoft SpyNet participation

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Cloud-delivered protection (formerly SpyNet/MAPS): Defender asks the cloud about unknown files.
- **What can be collected:** File hashes, file names and detection details.
- **Benefit of turning it off:** Small: the data is technical and used to protect you and everyone else.
- **What you lose:** New and fast-spreading malware is caught much later, sometimes not at all.
- **Possible problems:** Turning this off weakens Microsoft Defender. BLOB never changes Defender settings; you can review them in Windows Security.
- **Change:** information only, no switch

### Malware infection reporting

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Reports detected malware to Microsoft.
- **What can be collected:** Detection names and affected file paths.
- **Benefit of turning it off:** Small: the data is technical and used to protect you and everyone else.
- **What you lose:** New and fast-spreading malware is caught much later, sometimes not at all.
- **Possible problems:** Turning this off weakens Microsoft Defender. BLOB never changes Defender settings; you can review them in Windows Security.
- **Change:** information only, no switch

### Cloud-based Defender information sharing

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Shares threat information with Microsoft to block new threats within seconds.
- **What can be collected:** Threat metadata from your PC.
- **Benefit of turning it off:** Small: the data is technical and used to protect you and everyone else.
- **What you lose:** New and fast-spreading malware is caught much later, sometimes not at all.
- **Possible problems:** Turning this off weakens Microsoft Defender. BLOB never changes Defender settings; you can review them in Windows Security.
- **Change:** information only, no switch

### Automatic sample submission

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Same as automatic file sample submissions.
- **What can be collected:** Copies of suspicious files.
- **Benefit of turning it off:** Small: the data is technical and used to protect you and everyone else.
- **What you lose:** New and fast-spreading malware is caught much later, sometimes not at all.
- **Possible problems:** Turning this off weakens Microsoft Defender. BLOB never changes Defender settings; you can review them in Windows Security.
- **Change:** information only, no switch

## 19. Microsoft Copilot and Windows AI

### Windows Copilot

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** The Copilot assistant built into Windows.
- **What can be collected:** Your prompts, and screen or file content you share with it.
- **Benefit of turning it off:** Copilot cannot run from Windows.
- **What you lose:** Copilot in Windows (newer Copilot app versions may ignore the policy).
- **Possible problems:** The separate Copilot app can still be uninstalled from the Apps page.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot\TurnOffWindowsCopilot = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot\TurnOffWindowsCopilot = 1`

### Copilot taskbar button

**DISABLE** - privacy impact **Low**

- **What it does:** Shows the Copilot button on the taskbar.
- **What can be collected:** Nothing until used.
- **Benefit of turning it off:** No accidental Copilot launches.
- **What you lose:** The taskbar button.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowCopilotButton = 0`

### Copilot keyboard key

**OPTIONAL** - privacy impact **Low**

- **What it does:** The Copilot key on new keyboards opens Copilot.
- **What can be collected:** Nothing until used.
- **Benefit of turning it off:** Remap it in Settings > Personalization > Text input > "Customize Copilot key".
- **What you lose:** One-press Copilot.
- **Possible problems:** Remapping is a personal setting; listed for information.
- **Change:** information only, no switch

### Image Creator in Microsoft Paint

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Creates images in Paint from a text prompt using a cloud service.
- **What can be collected:** Your prompts, linked to your account.
- **Benefit of turning it off:** Prompts are not sent.
- **What you lose:** AI image creation in Paint.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint\DisableImageCreator = 1`

### AI image filling in Paint

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Generative fill and erase in Paint.
- **What can be collected:** Image content and prompts.
- **Benefit of turning it off:** Images are not processed by the AI service.
- **What you lose:** Generative fill and erase.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint\DisableGenerativeFill = 1`, `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint\DisableGenerativeErase = 1`

### Click to Do (O&O C208)

**DISABLE** - privacy impact **High** - needs administrator

- **What it does:** Analyses what is on your screen to suggest actions (Copilot+ PCs).
- **What can be collected:** Screenshots of your screen, analysed on the device.
- **Benefit of turning it off:** Your screen is not analysed.
- **What you lose:** Context actions from Click to Do.
- **Possible problems:** Only exists on Copilot+ PCs.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\WindowsAI\DisableClickToDo = 1`

### Settings Agent (O&O C209)

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** An AI agent in Settings that changes settings from a typed request.
- **What can be collected:** What you type into Settings search.
- **Benefit of turning it off:** Settings search works without the agent.
- **What you lose:** Natural-language changes in Settings.
- **Possible problems:** Only on supported devices.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\DisableSettingsAgent = 1`

### AI features in Notepad (O&O C210)

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Rewrite, summarise and write features in Notepad.
- **What can be collected:** Text you select, sent to the AI service.
- **Benefit of turning it off:** Your notes are not sent anywhere.
- **What you lose:** AI writing help in Notepad.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\WindowsNotepad\DisableAIFeatures = 1`

### AI actions in File Explorer (O&O C211)

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** AI actions in the right-click menu of files (for example blur background, summarise).
- **What can be collected:** Files you run actions on.
- **Benefit of turning it off:** Files are not sent to AI features from Explorer.
- **What you lose:** AI actions in the context menu.
- **Possible problems:** Applies on builds that support it.
- **Change:** `HKCU\Software\Policies\Microsoft\Windows\Explorer\HideAIActionsMenu = 1`

## 20. Mobile Devices

### Phone Link

**OPTIONAL** - privacy impact **High** - needs administrator

- **What it does:** Links an Android or iPhone to the PC for messages, calls, photos and notifications.
- **What can be collected:** Messages, contacts, photos and notifications from your phone.
- **Benefit of turning it off:** Your phone data is not mirrored to the PC.
- **What you lose:** Texting, calls and photos from the PC.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\EnableMmx = 0`

### Connecting PC to mobile devices

**OPTIONAL** - privacy impact **High** - needs administrator

- **What it does:** Same policy as Phone Link: allows pairing the PC with phones.
- **What can be collected:** Phone data.
- **Benefit of turning it off:** No phone pairing.
- **What you lose:** Phone integration.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\EnableMmx = 0`

### Mobile device access

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Lets Windows use a linked phone in Explorer and Start (for example recent phone photos).
- **What can be collected:** Phone content shown on the PC.
- **Benefit of turning it off:** The phone does not appear in Windows features.
- **What you lose:** Phone access from Explorer and Start.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility\CrossDeviceEnabled = 0`

### Suggestions for connecting mobile devices

**DISABLE** - privacy impact **Low**

- **What it does:** Suggests linking your phone in Settings and notifications.
- **What can be collected:** Nothing extra.
- **Benefit of turning it off:** No phone-linking nags.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility\OptedIn = 0`

### Mobile-device notifications

**OPTIONAL** - privacy impact **Medium**

- **What it does:** Shows your phone notifications on the PC through Phone Link.
- **What can be collected:** Phone notifications.
- **Benefit of turning it off:** Turning Phone Link off (above) stops it; or change it in the Phone Link app.
- **What you lose:** Phone notifications on the PC.
- **Possible problems:** Managed in Phone Link; listed for information.
- **Change:** information only, no switch

## 21. Miscellaneous

### Feedback reminders

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Same as Feedback requests: Windows asking for your opinion.
- **What can be collected:** Your answers.
- **Benefit of turning it off:** No reminders.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod = 0`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DoNotShowFeedbackNotifications = 1`

### Automatic installation of recommended Store apps

**DISABLE** - privacy impact **Medium**

- **What it does:** Windows silently installs promoted apps and games.
- **What can be collected:** Your region and account, used to choose apps.
- **Benefit of turning it off:** No apps appear without your consent.
- **What you lose:** Nothing.
- **Possible problems:** Apps already installed stay; remove them on the Apps page.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\PreInstalledAppsEnabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\OemPreInstalledAppsEnabled = 0`, `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\ContentDeliveryAllowed = 0`

### Windows tips and suggestions

**DISABLE** - privacy impact **Low** - needs administrator

- **What it does:** Policy that turns off Windows tips everywhere.
- **What can be collected:** Feature usage for targeting.
- **Benefit of turning it off:** No tips.
- **What you lose:** Hints about new features.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableSoftLanding = 1`

### Activation checks

**KEEP ENABLED** - privacy impact **Low**

- **What it does:** Windows checks that its licence is valid.
- **What can be collected:** Your product key or digital licence and hardware ID.
- **Benefit of turning it off:** None worth the risk.
- **What you lose:** Windows would show as not activated and lose personalisation.
- **Possible problems:** Blocking activation is a licensing violation and can break updates. BLOB does not offer a switch.
- **Change:** information only, no switch

### Promotional Windows features

**DISABLE** - privacy impact **Low**

- **What it does:** Full-screen "finish setting up your device" prompts promoting Microsoft services.
- **What can be collected:** Which offers you accept.
- **Benefit of turning it off:** No setup nags.
- **What you lose:** Nothing.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement\ScoobeSystemSettingEnabled = 0`

### Consumer experience features

**DISABLE** - privacy impact **Medium** - needs administrator

- **What it does:** Microsoft consumer experiences: suggested apps, account promotions and third-party offers.
- **What can be collected:** Usage and account state.
- **Benefit of turning it off:** Fewer promotions everywhere.
- **What you lose:** Nothing.
- **Possible problems:** Fully honoured on Enterprise/Education; partly on Home and Pro.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures = 1`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableConsumerAccountStateContent = 1`

## 22. Gaming

### Xbox Game Bar

**OPTIONAL** - privacy impact **Low**

- **What it does:** The Win+G overlay with widgets, chat and performance stats.
- **What can be collected:** Game and party chat data when used.
- **Benefit of turning it off:** Game Bar no longer pops up from the controller or on game start.
- **What you lose:** Quick access with the Xbox button (Win+G still works).
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\GameBar\UseNexusForGameBarEnabled = 0`, `HKCU\Software\Microsoft\GameBar\ShowStartupPanel = 0`

### Game DVR

**OPTIONAL** - privacy impact **Low** - needs administrator

- **What it does:** Policy that allows game recording and broadcasting.
- **What can be collected:** Recorded clips stay local unless you share them.
- **Benefit of turning it off:** Recording is turned off system-wide.
- **What you lose:** All Game Bar recording and screenshots.
- **Possible problems:** None.
- **Change:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR\AllowGameDVR = 0`

### Game recording

**OPTIONAL** - privacy impact **Low**

- **What it does:** Lets you record game clips with Game Bar.
- **What can be collected:** Clips stored locally.
- **Benefit of turning it off:** No captures.
- **What you lose:** Recording clips.
- **Possible problems:** None.
- **Change:** `HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR\AppCaptureEnabled = 0`

### Game capture functionality

**OPTIONAL** - privacy impact **Low**

- **What it does:** Background recording of the last minutes of gameplay.
- **What can be collected:** Gameplay video kept in memory.
- **Benefit of turning it off:** No background recording.
- **What you lose:** "Record what happened".
- **Possible problems:** None.
- **Change:** `HKCU\System\GameConfigStore\GameDVR_Enabled = 0`
