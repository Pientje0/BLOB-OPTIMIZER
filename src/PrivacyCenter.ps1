# ============================================================================
#  BLOB OPTIMIZER - PrivacyCenter.ps1
#  The privacy catalogue: every item explained with
#    what it does / what is collected / benefit of turning it off /
#    what you lose / possible issues / recommendation / privacy impact.
#  Every item has a real switch that uses a documented policy or settings
#  value. Things BLOB cannot or will not change (Defender, security updates,
#  activation, settings without a reliable switch) are not listed.
#  O&O ShutUp10++ IDs are shown where they were provided; none are invented.
# ============================================================================

$Blob.PrivacyGroups = @(
    'Privacy', 'Telemetry and User Behavior', 'App Privacy', 'Cortana and Input Personalisation', 'Location Services', 'Search',
    'Synchronisation of Windows Settings', 'Security', 'Windows Update', 'Microsoft Edge Chromium',
    'Microsoft Office', 'Microsoft 365', 'Windows Explorer', 'Lock Screen', 'Taskbar', 'Activity History and Clipboard',
    'Microsoft Copilot and Windows AI', 'Mobile Devices', 'Miscellaneous', 'Gaming')

# Ops are compact strings:  'HKLM:\path|ValueName|Value[|Type]'  or  'svc:ServiceName=Disabled'
function Add-BlobPrivacyItem {
    param([string]$Group, [string]$Id, [string]$Name, [string]$Oo,
          [ValidateSet('Disable', 'Optional', 'Keep')][string]$Rec, [ValidateSet('Low', 'Medium', 'High')][string]$Impact,
          [Parameter(Mandatory)][string[]]$Ops, [string]$Does, [string]$Data, [string]$Benefit, [string]$Lose, [string]$Issues)
    $reg = @(); $svc = @()
    foreach ($o in $Ops) {
        if (-not $o) { continue }
        if ($o -like 'svc:*') { $n, $v = $o.Substring(4) -split '=', 2; $svc += @{ Name = $n; Startup = $v }; continue }
        $p = $o -split '\|'
        $val = $p[2]
        $type = if ($p.Count -gt 3) { $p[3] } elseif ($val -match '^-?\d+$') { 'DWord' } else { 'String' }
        if ($type -eq 'DWord') { $val = [int64]$val }
        $reg += @{ Path = $p[0]; Name = $p[1]; Value = $val; Type = $type }
    }
    # Risk of turning the feature OFF follows the recommendation.
    $risk = switch ($Rec) { 'Disable' { 'Minimal' } 'Optional' { 'Standard' } default { 'Advanced' } }
    Register-BlobTweak @{
        Id = "pc.$Id"; Section = 'PrivacyCenter'; Group = $Group; Category = $Group; Risk = $risk
        Name = $Name; Description = $Does; Registry = $reg; Services = $svc
        InfoOnly = (($reg.Count + $svc.Count) -eq 0)
        Privacy = @{ Rec = $Rec; Impact = $Impact; Oo = $Oo; Does = $Does; Data = $Data; Benefit = $Benefit; Lose = $Lose; Issues = $Issues }
    }
    $ooText = if ($Oo) { " O&O ShutUp10++ ID: $Oo." } else { '' }
    $Blob.TweakDetails["pc.$Id"] = "$Does What is collected: $Data Turning it off: $Benefit You lose: $Lose Possible issues: $Issues Recommendation: $($Rec.ToUpper()). Privacy impact: $Impact.$ooText"
}

function Get-BlobPrivacyItems { return @($Blob.Tweaks | Where-Object { $_.Section -eq 'PrivacyCenter' }) }
function Get-BlobCoreTweaks { return @($Blob.Tweaks | Where-Object { $_.Section -ne 'PrivacyCenter' }) }

# Shared registry locations used by the catalogue files.
$pcDC   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
$pcCDM  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$pcCS   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore'
$pcEdge = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$pcOff  = 'HKCU:\Software\Policies\Microsoft\office\16.0'
$pcWS   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
$pcSync = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync'
$pcWU   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$pcLoc  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'
$pcCC   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
$pcCCU  = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
$pcSys  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$pcAdv  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$pcSS   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
