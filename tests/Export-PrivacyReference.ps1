<#
.SYNOPSIS
    Writes docs\PRIVACY-SETTINGS.md from the privacy catalogue in src\, so the
    document always matches what the app shows.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Export-PrivacyReference.ps1
#>
$root = Split-Path $PSScriptRoot -Parent
$srcDir = Join-Path $root 'src'
$out = Join-Path $root 'docs\PRIVACY-SETTINGS.md'

& {
    param($srcDir, $out)
    foreach ($m in 'Core', 'UI', 'Engine', 'TweakDetails', 'PrivacyCenter', 'PrivacyData1', 'PrivacyData2', 'PrivacyData3') { . (Join-Path $srcDir "$m.ps1") }
    $items = @(Get-BlobPrivacyItems)
    $recWord = @{ Disable = 'DISABLE'; Optional = 'OPTIONAL'; Keep = 'KEEP ENABLED' }
    $sb = New-Object System.Text.StringBuilder
    $nl = "`n"
    [void]$sb.Append("# Privacy settings reference$nl$nl")
    [void]$sb.Append("Generated from the BLOB OPTIMIZER privacy catalogue ($($items.Count) settings in $($Blob.PrivacyGroups.Count) sections). ")
    [void]$sb.Append("Every entry answers the same questions: what it does, what can be collected, the benefit of turning it off, what you lose, possible problems, a recommendation and a privacy impact rating.$nl$nl")
    [void]$sb.Append("**Recommendations:** DISABLE = good privacy benefit with minimal disadvantages. OPTIONAL = depends on how you use the PC. KEEP ENABLED = important for security, stability or everyday use.$nl$nl")
    [void]$sb.Append("**How BLOB changes them:** only documented Windows, Edge and Office policy or settings values (shown under *Change*). Every setting listed here can be switched in BLOB; every original value is saved first and can be restored. Microsoft Defender, security updates and Windows activation are never changed. O&O ShutUp10++ IDs are given where known; none are guessed.$nl$nl")
    $counts = $items | Group-Object { $_.Privacy.Rec } | ForEach-Object { "$($recWord[$_.Name]): $($_.Count)" }
    [void]$sb.Append("Totals - $($counts -join ', ').$nl$nl## Sections$nl$nl")
    for ($i = 0; $i -lt $Blob.PrivacyGroups.Count; $i++) {
        $g = $Blob.PrivacyGroups[$i]
        $anchor = (($i + 1).ToString() + '-' + ($g.ToLower() -replace '[^a-z0-9 ]', '' -replace ' ', '-'))
        [void]$sb.Append("$($i + 1). [$g](#$anchor) ($(@($items | Where-Object Group -eq $g).Count))$nl")
    }
    for ($i = 0; $i -lt $Blob.PrivacyGroups.Count; $i++) {
        $g = $Blob.PrivacyGroups[$i]
        [void]$sb.Append("$nl## $($i + 1). $g$nl")
        foreach ($t in @($items | Where-Object Group -eq $g)) {
            $p = $t.Privacy
            $title = $t.Name + $(if ($p.Oo) { " (O&O $($p.Oo))" } else { '' })
            [void]$sb.Append("$nl### $title$nl$nl")
            [void]$sb.Append("**$($recWord[$p.Rec])** - privacy impact **$($p.Impact)**$(if ($t.Admin -and -not $t.InfoOnly) { ' - needs administrator' })$nl$nl")
            [void]$sb.Append("- **What it does:** $($p.Does)$nl")
            [void]$sb.Append("- **What can be collected:** $($p.Data)$nl")
            [void]$sb.Append("- **Benefit of turning it off:** $($p.Benefit)$nl")
            [void]$sb.Append("- **What you lose:** $($p.Lose)$nl")
            [void]$sb.Append("- **Possible problems:** $($p.Issues)$nl")
            $chg = @($t.Registry | ForEach-Object { '`' + (Format-BlobRegPath $_.Path $_.Name) + ' = ' + $_.Value + '`' }) + @($t.Services | ForEach-Object { "service ``$($_.Name)`` startup = $($_.Startup)" })
            [void]$sb.Append("- **Change:** $($chg -join ', ')$nl")
        }
    }
    [IO.File]::WriteAllText($out, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
    "Wrote $out ($($items.Count) settings)"
} $srcDir $out
