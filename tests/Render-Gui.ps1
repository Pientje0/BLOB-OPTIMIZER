<#
.SYNOPSIS
    Renders every page of the BLOB OPTIMIZER window to PNG files (dry run,
    nothing is changed) and checks that navigation clicks work.
    Loads src\ inside one script block, exactly like the release does.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Render-Gui.ps1 -OutDir .\screens
#>
param([string]$OutDir = (Join-Path ([IO.Path]::GetTempPath()) 'blob-screens'))

$srcDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'src'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

& {
    param($srcDir, $OutDir)
    foreach ($m in 'Core', 'UI', 'Engine', 'Performance', 'Gaming', 'Tweaks', 'Privacy', 'Services', 'Startup',
                   'Cleanup', 'Network', 'Power', 'Restore', 'TweakDetails', 'ExternalTools', 'Apps', 'Prefetch', 'Dashboard', 'GuiXaml', 'Gui', 'GuiPages', 'GuiSystem', 'GuiApps', 'Main') {
        . (Join-Path $srcDir "$m.ps1")
    }
    $Blob.SourceRoot = Split-Path $srcDir -Parent
    Initialize-BlobState -DryRun $true
    $Blob.SysInfo = Get-BlobSystemSummary
    $why = Test-BlobGuiSupported
    if ($why) { Write-Host "Window UI unavailable: $why" -ForegroundColor Yellow; return }

    Initialize-BlobGuiWindow
    $w = $Blob.Gui.Window
    $w.WindowStartupLocation = 'Manual'; $w.Left = -20000; $w.Top = -20000; $w.ShowActivated = $false; $w.ShowInTaskbar = $false
    $w.Show()
    $fail = 0
    foreach ($p in $Blob.Gui.Pages) {
        # Navigate through the real button so the click handler path is exercised.
        $btn = $Blob.Gui.Nav[$p.Key]
        $btn.RaiseEvent((New-Object Windows.RoutedEventArgs ([Windows.Controls.Button]::ClickEvent)))
        Update-BlobGui
        if ($Blob.Gui.Current -ne $p.Key) { Write-Host "  [FAIL] click on '$($p.Label)' did not navigate" -ForegroundColor Red; $fail++; continue }
        $content = $Blob.Gui.PageHost.Content
        $w.UpdateLayout(); Update-BlobGui
        $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap ([int]$w.ActualWidth), ([int]$w.ActualHeight), 96, 96, ([Windows.Media.PixelFormats]::Pbgra32)
        $bmp.Render($w)
        $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
        $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bmp))
        $file = Join-Path $OutDir ("{0:D2}-{1}.png" -f ([array]::IndexOf($Blob.Gui.Pages, $p) + 1), $p.Key)
        $fs = [IO.File]::Create($file); $enc.Save($fs); $fs.Close()
        $errCard = ($content -is [Windows.Controls.Border]) -and ($Blob.Gui.PageHost.Content.Child -is [Windows.Controls.StackPanel]) -and
                   (@($Blob.Gui.PageHost.Content.Child.Children | Where-Object { "$($_.Text)" -like '*could not be loaded*' }).Count -gt 0)
        if ($errCard) { Write-Host "  [FAIL] $($p.Label) shows a load error" -ForegroundColor Red; $fail++ }
        else { Write-Host "  [ OK ] $($p.Label) -> $file" -ForegroundColor Green }
    }
    # Exercise a log write and the button handler wrapper.
    Add-BlobGuiLog '{Green}Render test log line.'
    $w.Close()
    if ($fail) { Write-Host "$fail page(s) failed" -ForegroundColor Red } else { Write-Host 'All pages rendered' -ForegroundColor Green }
} $srcDir $OutDir
