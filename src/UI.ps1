# ============================================================================
#  BLOB OPTIMIZER - UI.ps1
#  Terminal UI toolkit built only on [System.Console]. No frameworks.
#
#  Text uses inline colour tags, e.g. "{Gray}OS  {White}Windows 11".
#  Supported tags: Cyan DarkCyan White Gray DarkGray Green Yellow Red
#                  DarkYellow Magenta Black
#  Source stays pure ASCII: box glyphs are built from code points.
# ============================================================================

$Blob.Ch = @{
    TL = [string][char]0x2554; TR = [string][char]0x2557; BL = [string][char]0x255A; BR = [string][char]0x255D
    H  = [string][char]0x2550; V  = [string][char]0x2551
    SL = [string][char]0x255F; SR = [string][char]0x2562; S  = [string][char]0x2500
    Block = [string][char]0x2588; Shade = [string][char]0x2591; Dot = [string][char]0x2022
    Arrow = [string][char]0x25BA; Up = [string][char]0x2191; Down = [string][char]0x2193
    On = [string][char]0x25A0; Mid = [string][char]0x00B7
}
$Blob.ColorTag = '\{(Cyan|DarkCyan|White|Gray|DarkGray|Green|Yellow|Red|DarkYellow|Magenta|Black)\}'

# ---------------------------------------------------------------------------
#  Console lifecycle
# ---------------------------------------------------------------------------
function Initialize-BlobConsole {
    $Blob.Saved = @{
        Fg = [Console]::ForegroundColor; Bg = [Console]::BackgroundColor
        Enc = [Console]::OutputEncoding; CtrlC = [Console]::TreatControlCAsInput
        Title = $Host.UI.RawUI.WindowTitle
    }
    $Blob.AltScreen = [bool]$env:WT_SESSION
    try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }
    if ($Blob.AltScreen) { [Console]::Write([char]27 + '[?1049h') }   # keep the user's scrollback intact
    try { [Console]::TreatControlCAsInput = $true } catch { }
    try { [Console]::CursorVisible = $false } catch { }
    try { $Host.UI.RawUI.WindowTitle = 'BLOB OPTIMIZER ' + $Blob.Version } catch { }
    [Console]::BackgroundColor = 'Black'
    [Console]::Clear()
    $Blob.LastSize = ''
}

function Restore-BlobConsole {
    if (-not $Blob.Saved) { return }
    try {
        [Console]::ForegroundColor = $Blob.Saved.Fg
        [Console]::BackgroundColor = $Blob.Saved.Bg
        [Console]::Clear()
        if ($Blob.AltScreen) { [Console]::Write([char]27 + '[?1049l') }
        [Console]::TreatControlCAsInput = $Blob.Saved.CtrlC
        [Console]::CursorVisible = $true
        [Console]::OutputEncoding = $Blob.Saved.Enc
        $Host.UI.RawUI.WindowTitle = $Blob.Saved.Title
    } catch { }
}

# ---------------------------------------------------------------------------
#  Low-level drawing
# ---------------------------------------------------------------------------
function Write-BlobAt {
    param([int]$X, [int]$Y, [string]$Text, [ConsoleColor]$Fg = 'White', [ConsoleColor]$Bg = 'Black')
    if ($Text.Length -eq 0) { return }
    try { [Console]::SetCursorPosition($X, $Y) } catch { return }
    [Console]::ForegroundColor = $Fg
    [Console]::BackgroundColor = $Bg
    [Console]::Write($Text)
}

function Get-BlobPlainText { param([string]$Text) return ($Text -replace $Blob.ColorTag, '') }

function Get-BlobLayout {
    while ($true) {
        $ww = [Console]::WindowWidth; $wh = [Console]::WindowHeight
        $size = "${ww}x${wh}"
        if ($size -ne $Blob.LastSize) {
            [Console]::BackgroundColor = 'Black'; [Console]::Clear(); $Blob.LastSize = $size
        }
        if ($ww -ge 64 -and $wh -ge 20) { break }
        Write-BlobAt 0 0 'BLOB OPTIMIZER needs a larger window (minimum 64 x 20).' 'Yellow'
        Write-BlobAt 0 1 ("Current size: {0} x {1}. Resize the window or press Esc to go back." -f $ww, $wh) 'Gray'
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'Escape') { throw 'BLOB_WINDOW_TOO_SMALL' }
        }
        Start-Sleep -Milliseconds 150
    }
    $w = [Math]::Min($ww - 2, 116)
    $h = $wh - 1   # never draw on the last row: it would scroll the buffer
    return @{ WW = $ww; WH = $wh; W = $w; L = [int][Math]::Floor(($ww - $w) / 2); H = $h
              Inner = $w - 4; BodyTop = 3; BodyH = $h - 6 }
}

# Draws one row inside the frame: "| <content padded> |"
function Write-BlobRow {
    param($Layout, [int]$Row, [string]$Text = '', [switch]$Highlight, [ConsoleColor]$Default = 'White')
    $bg = if ($Highlight) { 'DarkCyan' } else { 'Black' }
    Write-BlobAt $Layout.L $Row ($Blob.Ch.V + ' ') 'DarkCyan'
    $x = $Layout.L + 2; $remaining = $Layout.Inner
    $parts = [regex]::Split($Text, $Blob.ColorTag)
    $fg = $Default
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { $fg = [ConsoleColor]$parts[$i]; continue }
        $t = $parts[$i]
        if ($t.Length -eq 0 -or $remaining -le 0) { continue }
        if ($t.Length -gt $remaining) { $t = $t.Substring(0, [Math]::Max(0, $remaining - 1)) + '~' }
        $c = $fg
        if ($Highlight -and $c -in @('Gray', 'DarkGray', 'DarkCyan')) { $c = 'White' }
        Write-BlobAt $x $Row $t $c $bg
        $x += $t.Length; $remaining -= $t.Length
    }
    if ($remaining -gt 0) { Write-BlobAt $x $Row (' ' * $remaining) 'White' $bg }
    Write-BlobAt ($Layout.L + $Layout.W - 2) $Row (' ' + $Blob.Ch.V) 'DarkCyan'
}

function Write-BlobRule {
    param($Layout, [int]$Row, [string]$Kind = 'sep')
    $w = $Layout.W
    switch ($Kind) {
        'top'    { $s = $Blob.Ch.TL + ($Blob.Ch.H * ($w - 2)) + $Blob.Ch.TR }
        'bottom' { $s = $Blob.Ch.BL + ($Blob.Ch.H * ($w - 2)) + $Blob.Ch.BR }
        default  { $s = $Blob.Ch.SL + ($Blob.Ch.S * ($w - 2)) + $Blob.Ch.SR }
    }
    Write-BlobAt $Layout.L $Row $s 'DarkCyan'
}

function Format-BlobFooter {
    param([string[]]$Pairs)
    # Pairs are "Key|Action" strings.
    ($Pairs | ForEach-Object { $k, $a = $_ -split '\|', 2; "{Cyan}$k {Gray}$a" }) -join '{DarkGray}   '
}

# Draws the frame, title bar and footer. Returns the layout for the body.
function Write-BlobFrame {
    param([string]$Crumb = '', [string]$Footer = '')
    $L = Get-BlobLayout
    Write-BlobRule $L 0 'top'
    $title = "{Cyan}$($Blob.Ch.On) BLOB OPTIMIZER"
    if ($Crumb) { $title += " {DarkGray}$($Blob.Ch.Arrow) {White}$Crumb" }
    $flags = "{DarkGray}v$($Blob.Version)"
    if ($Blob.IsAdmin) { $flags += " {DarkGray}$($Blob.Ch.Mid) {Green}ADMIN" } else { $flags += " {DarkGray}$($Blob.Ch.Mid) {Yellow}STANDARD USER" }
    if ($Blob.DryRun)  { $flags += " {DarkGray}$($Blob.Ch.Mid) {Magenta}DRY RUN" }
    $gap = $L.Inner - (Get-BlobPlainText $title).Length - (Get-BlobPlainText $flags).Length
    Write-BlobRow $L 1 ($title + (' ' * [Math]::Max(1, $gap)) + $flags)
    Write-BlobRule $L 2
    Write-BlobRule $L ($L.H - 3)
    Write-BlobRow $L ($L.H - 2) $Footer
    Write-BlobRule $L ($L.H - 1) 'bottom'
    return $L
}

# Waits for a key. Returns $null when the window was resized (caller redraws).
function Read-BlobKey {
    $size = $Blob.LastSize
    while (-not [Console]::KeyAvailable) {
        Start-Sleep -Milliseconds 35
        if ("$([Console]::WindowWidth)x$([Console]::WindowHeight)" -ne $size) { return $null }
    }
    $k = [Console]::ReadKey($true)
    # Ctrl+C behaves like Escape so the tool can always clean up properly.
    if ($k.Key -eq 'C' -and ($k.Modifiers -band [ConsoleModifiers]::Control)) {
        return New-Object ConsoleKeyInfo ([char]27), ([ConsoleKey]::Escape), $false, $false, $false
    }
    return $k
}

# Word-wraps plain text into lines of at most $Width characters.
function Split-BlobText {
    param([string]$Text, [int]$Width = 96)
    $out = New-Object System.Collections.ArrayList
    $line = ''
    foreach ($word in ($Text -split '\s+')) {
        if ($line.Length -gt 0 -and ($line.Length + 1 + $word.Length) -gt $Width) { [void]$out.Add($line); $line = $word }
        elseif ($line.Length -gt 0) { $line += ' ' + $word }
        else { $line = $word }
    }
    if ($line) { [void]$out.Add($line) }
    return $out.ToArray()
}

function Format-BlobPad {
    param([string]$Text, [int]$Width)
    $plain = Get-BlobPlainText $Text
    if ($plain.Length -ge $Width) { return $Text }
    return $Text + (' ' * ($Width - $plain.Length))
}

# ---------------------------------------------------------------------------
#  Menu component
#  Items: hashtables with Label, Right (status markup), Detail (markup),
#         Header ($true = non-selectable group title), Checked, Hot (hotkey)
#  Returns @{ Action = 'Select' | 'Back' | <custom key action>; Index = n }
# ---------------------------------------------------------------------------
function Show-BlobMenu {
    param([string]$Crumb, [array]$Items, [string[]]$Intro = @(), [switch]$MultiSelect,
          [hashtable]$Keys = @{}, [int]$Start = -1, [string[]]$FooterPairs)

    if (-not $FooterPairs) {
        $FooterPairs = @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Navigate", 'Enter|Select')
        if ($MultiSelect) { $FooterPairs += 'Space|Toggle' }
        if (@($Items | Where-Object { $_.Header }).Count -gt 1) { $FooterPairs += 'Tab|Next group' }
        $FooterPairs += 'Esc|Back'
    }
    $selectable = @(for ($i = 0; $i -lt $Items.Count; $i++) { if (-not $Items[$i].Header) { $i } })
    if ($selectable.Count -eq 0) { return @{ Action = 'Back'; Index = -1 } }
    $cur = if ($Start -in $selectable) { $Start } else { $selectable[0] }
    $scroll = 0
    $hasDetail = @($Items | Where-Object { $_.Detail }).Count -gt 0

    while ($true) {
        $L = Write-BlobFrame -Crumb $Crumb -Footer (Format-BlobFooter $FooterPairs)
        $row = $L.BodyTop
        foreach ($line in $Intro) { Write-BlobRow $L $row $line; $row++ }
        if ($Intro.Count -gt 0) { Write-BlobRow $L $row ''; $row++ }
        $detailRows = if ($hasDetail) { 3 } else { 0 }
        $listH = [Math]::Max(3, $L.BodyTop + $L.BodyH - $row - $detailRows)

        if ($cur -lt $scroll) { $scroll = $cur }
        if ($cur -ge $scroll + $listH) { $scroll = $cur - $listH + 1 }
        if ($scroll -gt 0 -and $Items[$scroll - 1].Header -and $cur -eq $scroll) { $scroll-- }

        $rightW = 0
        foreach ($it in $Items) { if ($it.Right) { $rightW = [Math]::Max($rightW, (Get-BlobPlainText $it.Right).Length) } }
        for ($r = 0; $r -lt $listH; $r++) {
            $idx = $scroll + $r
            if ($idx -ge $Items.Count) { Write-BlobRow $L ($row + $r) ''; continue }
            $it = $Items[$idx]
            if ($it.Header) {
                $h = " $($it.Label) "
                $fill = $L.Inner - $h.Length - 2
                Write-BlobRow $L ($row + $r) ("{DarkCyan}$($Blob.Ch.S)$($Blob.Ch.S){Cyan}$h{DarkCyan}" + ($Blob.Ch.S * [Math]::Max(0, $fill)))
                continue
            }
            $sel = ($idx -eq $cur)
            $mark = if ($sel) { "{White}$($Blob.Ch.Arrow) " } else { '  ' }
            $box = ''
            if ($MultiSelect) { $box = if ($it.Checked) { "{Green}[$($Blob.Ch.On)] " } else { '{DarkGray}[ ] ' } }
            $hot = if ($it.Hot) { "{Cyan}[$($it.Hot)] " } else { '' }
            $labelColor = if ($it.Disabled) { '{DarkGray}' } else { '{White}' }
            $left = "$mark$box$hot$labelColor$($it.Label)"
            $right = if ($it.Right) { $it.Right } else { '' }
            $space = $L.Inner - (Get-BlobPlainText $left).Length - $rightW - 1
            if ($space -lt 1) { $space = 1 }
            $text = $left + (' ' * $space) + (Format-BlobPad $right $rightW)
            Write-BlobRow $L ($row + $r) $text -Highlight:$sel
        }
        if ($hasDetail) {
            $dr = $L.BodyTop + $L.BodyH - 3
            Write-BlobRow $L $dr ("{DarkCyan}" + ($Blob.Ch.S * $L.Inner))
            $detail = @($Items[$cur].Detail)
            Write-BlobRow $L ($dr + 1) $(if ($detail.Count -gt 0) { "{Gray}" + $detail[0] } else { '' })
            Write-BlobRow $L ($dr + 2) $(if ($detail.Count -gt 1) { "{Gray}" + $detail[1] } else { '' })
        }

        $k = Read-BlobKey
        if (-not $k) { continue }
        $pos = [array]::IndexOf($selectable, $cur)
        switch ($k.Key) {
            'UpArrow'   { if ($pos -gt 0) { $cur = $selectable[$pos - 1] } else { $cur = $selectable[-1] } continue }
            'DownArrow' { if ($pos -lt $selectable.Count - 1) { $cur = $selectable[$pos + 1] } else { $cur = $selectable[0] } continue }
            'PageUp'    { $cur = $selectable[[Math]::Max(0, $pos - $listH)]; continue }
            'PageDown'  { $cur = $selectable[[Math]::Min($selectable.Count - 1, $pos + $listH)]; continue }
            'Home'      { $cur = $selectable[0]; continue }
            'End'       { $cur = $selectable[-1]; continue }
            'Tab' {
                $next = $null
                for ($i = $cur + 1; $i -lt $Items.Count; $i++) { if ($Items[$i].Header -and ($i + 1) -lt $Items.Count) { $next = $i + 1; break } }
                if ($null -eq $next) { $next = $selectable[0] }
                if ($next -in $selectable) { $cur = $next }
                continue
            }
            'Spacebar'  { if ($MultiSelect -and -not $Items[$cur].Disabled) { $Items[$cur].Checked = -not $Items[$cur].Checked }; continue }
            'Enter'     { return @{ Action = 'Select'; Index = $cur } }
            'Escape'    { return @{ Action = 'Back'; Index = $cur } }
            'Backspace' { return @{ Action = 'Back'; Index = $cur } }
        }
        if ([int]$k.KeyChar -le 32) { continue }   # navigation keys were handled above
        $ch = ([string]$k.KeyChar).ToUpperInvariant()
        if ($Keys.ContainsKey($ch)) { return @{ Action = $Keys[$ch]; Index = $cur } }
        for ($i = 0; $i -lt $Items.Count; $i++) {
            if ($Items[$i].Hot -and ([string]$Items[$i].Hot).ToUpperInvariant() -eq $ch) { return @{ Action = 'Select'; Index = $i } }
        }
    }
}

# ---------------------------------------------------------------------------
#  Scrollable text view. Returns 'Back' or a custom key action.
# ---------------------------------------------------------------------------
function Show-BlobText {
    param([string]$Crumb, [string[]]$Lines, [hashtable]$Keys = @{}, [string[]]$FooterPairs)
    if (-not $FooterPairs) { $FooterPairs = @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Scroll", 'PgUp/PgDn|Page', 'Esc|Back') }
    $top = 0
    while ($true) {
        $L = Write-BlobFrame -Crumb $Crumb -Footer (Format-BlobFooter $FooterPairs)
        $maxTop = [Math]::Max(0, $Lines.Count - $L.BodyH)
        $top = [Math]::Min([Math]::Max(0, $top), $maxTop)
        for ($r = 0; $r -lt $L.BodyH; $r++) {
            $i = $top + $r
            $t = if ($i -lt $Lines.Count) { $Lines[$i] } else { '' }
            if ($r -eq $L.BodyH - 1 -and $top -lt $maxTop) { $t = "{DarkGray}  $($Blob.Ch.Down) more below ($($Lines.Count - $top - $L.BodyH + 1) lines)" }
            Write-BlobRow $L ($L.BodyTop + $r) $t
        }
        $k = Read-BlobKey
        if (-not $k) { continue }
        switch ($k.Key) {
            'UpArrow'   { $top--; continue }
            'DownArrow' { $top++; continue }
            'PageUp'    { $top -= $L.BodyH - 1; continue }
            'PageDown'  { $top += $L.BodyH - 1; continue }
            'Home'      { $top = 0; continue }
            'End'       { $top = $maxTop; continue }
            'Escape'    { return 'Back' }
            'Backspace' { return 'Back' }
            'Enter'     { if (-not $Keys.ContainsKey('ENTER')) { return 'Back' } else { return $Keys['ENTER'] } }
        }
        if ([int]$k.KeyChar -le 32) { continue }
        $ch = ([string]$k.KeyChar).ToUpperInvariant()
        if ($Keys.ContainsKey($ch)) { return $Keys[$ch] }
    }
}

# Full-screen confirmation. Shows exactly what will happen; Y confirms.
function Confirm-BlobAction {
    param([string]$Crumb, [string]$Question, [string[]]$Lines, [switch]$Danger)
    $head = @()
    if ($Danger) { $head += "{Red}$($Blob.Ch.On) WARNING {White}$Question" } else { $head += "{Cyan}$($Blob.Ch.On) {White}$Question" }
    if ($Blob.DryRun) { $head += '{Magenta}DRY RUN is active: nothing will actually be changed.' }
    $head += ''
    $r = Show-BlobText -Crumb $Crumb -Lines ($head + $Lines) -Keys @{ Y = 'Yes'; N = 'No'; ENTER = 'Noop' } `
        -FooterPairs @('Y|Confirm', 'N / Esc|Cancel', "$($Blob.Ch.Up)$($Blob.Ch.Down)|Scroll")
    while ($r -eq 'Noop') {
        $r = Show-BlobText -Crumb $Crumb -Lines ($head + $Lines) -Keys @{ Y = 'Yes'; N = 'No'; ENTER = 'Noop' } `
            -FooterPairs @('Y|Confirm', 'N / Esc|Cancel', "$($Blob.Ch.Up)$($Blob.Ch.Down)|Scroll")
    }
    return ($r -eq 'Yes')
}

function Show-BlobNotice {
    param([string]$Crumb, [string]$Title, [string[]]$Lines = @(), [ValidateSet('Info', 'Success', 'Warning', 'Error')][string]$Kind = 'Info')
    $color = @{ Info = 'Cyan'; Success = 'Green'; Warning = 'Yellow'; Error = 'Red' }[$Kind]
    $null = Show-BlobText -Crumb $Crumb -Lines (@("{$color}$($Blob.Ch.On) $Title", '') + $Lines) -FooterPairs @('Enter / Esc|Continue')
}

# Single-line text input. Validate returns an error message or $null.
function Read-BlobInput {
    param([string]$Crumb, [string[]]$Prompt, [string]$Default = '', [scriptblock]$Validate)
    $buf = $Default; $err = ''
    try { [Console]::CursorVisible = $true } catch { }
    try {
        while ($true) {
            $L = Write-BlobFrame -Crumb $Crumb -Footer (Format-BlobFooter @('Enter|Accept', 'Esc|Cancel', 'Backspace|Delete'))
            $row = $L.BodyTop
            foreach ($p in $Prompt) { Write-BlobRow $L $row $p; $row++ }
            Write-BlobRow $L $row ''; $row++
            $fieldW = $L.Inner - 4
            $shown = if ($buf.Length -gt $fieldW) { $buf.Substring($buf.Length - $fieldW) } else { $buf }
            Write-BlobRow $L $row ("{Cyan}> {White}" + $shown)
            Write-BlobRow $L ($row + 1) $(if ($err) { "{Red}$err" } else { '' })
            for ($r = $row + 2; $r -lt $L.BodyTop + $L.BodyH; $r++) { Write-BlobRow $L $r '' }
            try { [Console]::SetCursorPosition($L.L + 4 + $shown.Length, $row) } catch { }
            $k = Read-BlobKey
            if (-not $k) { continue }
            switch ($k.Key) {
                'Escape'    { return $null }
                'Backspace' { if ($buf.Length -gt 0) { $buf = $buf.Substring(0, $buf.Length - 1) }; $err = ''; continue }
                'Enter' {
                    $v = $buf.Trim()
                    if ($Validate) { $e = & $Validate $v; if ($e) { $err = $e; continue } }
                    return $v
                }
            }
            if ($k.KeyChar -and [int]$k.KeyChar -ge 32 -and $buf.Length -lt 260) { $buf += $k.KeyChar; $err = '' }
        }
    } finally { try { [Console]::CursorVisible = $false } catch { } }
}

# ---------------------------------------------------------------------------
#  Live work log for running operations
# ---------------------------------------------------------------------------
function Start-BlobWork {
    param([string]$Crumb)
    $Blob.Work = @{ Crumb = $Crumb; Lines = New-Object System.Collections.ArrayList }
    Update-BlobWork
}

function Write-BlobWork {
    param([string]$Text)
    [void]$Blob.Work.Lines.Add($Text)
    Update-BlobWork
}

function Update-BlobWork {
    $L = Write-BlobFrame -Crumb $Blob.Work.Crumb -Footer '{Yellow}Working... please wait'
    $lines = $Blob.Work.Lines
    $start = [Math]::Max(0, $lines.Count - $L.BodyH)
    for ($r = 0; $r -lt $L.BodyH; $r++) {
        $i = $start + $r
        Write-BlobRow $L ($L.BodyTop + $r) $(if ($i -lt $lines.Count) { $lines[$i] } else { '' })
    }
}

function Complete-BlobWork {
    param([string]$Summary = 'Finished.')
    [void]$Blob.Work.Lines.Add('')
    [void]$Blob.Work.Lines.Add("{Cyan}$($Blob.Ch.On) {White}$Summary")
    while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }   # drop keys pressed while working
    $null = Show-BlobText -Crumb $Blob.Work.Crumb -Lines $Blob.Work.Lines.ToArray() -FooterPairs @("$($Blob.Ch.Up)$($Blob.Ch.Down)|Scroll", 'Enter / Esc|Continue')
}

function Format-BlobResult {
    param($Result)
    $tag = switch ($Result.Status) {
        'Applied'   { '{Green} OK   ' }
        'Restored'  { '{Green} OK   ' }
        'Unchanged' { '{DarkGray} SAME ' }
        'DryRun'    { '{Magenta} DRY  ' }
        'Skipped'   { '{Yellow} SKIP ' }
        default     { '{Red} FAIL ' }
    }
    $line = "$tag{White}$($Result.Target)"
    if ($Result.Old -or $Result.New) { $line += "  {DarkGray}$($Result.Old) -> $($Result.New)" }
    if ($Result.Status -in @('Skipped', 'Failed')) { $line += "  {Gray}($($Result.Message))" }
    return $line
}

function Format-BlobBar {
    param([double]$Fraction, [int]$Width = 20)
    $Fraction = [Math]::Min(1, [Math]::Max(0, $Fraction))
    $n = [int][Math]::Round($Fraction * $Width)
    $c = if ($Fraction -ge 0.9) { 'Red' } elseif ($Fraction -ge 0.75) { 'Yellow' } else { 'Green' }
    return "{$c}" + ($Blob.Ch.Block * $n) + '{DarkGray}' + ($Blob.Ch.Shade * ($Width - $n))
}

function Format-BlobSize {
    param([double]$Bytes)
    if ($Bytes -ge 1TB) { return '{0:N1} TB' -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return '{0:N1} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N1} MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N0} KB' -f ($Bytes / 1KB) }
    return '{0:N0} B' -f $Bytes
}

# Standard explanation shown when an admin-only action is chosen without rights.
function Show-BlobAdminRequired {
    param([string]$Crumb, [string]$Why)
    Show-BlobNotice -Crumb $Crumb -Kind Warning -Title 'Administrator rights required' -Lines @(
        "{White}$Why", '',
        '{Gray}BLOB OPTIMIZER never elevates itself silently. To use this feature:',
        '{Gray}  1. Close BLOB OPTIMIZER (Esc on the dashboard).',
        '{Gray}  2. Right-click Windows Terminal and choose "Run as administrator".',
        '{Gray}  3. Run the launch command again.',
        '', '{DarkGray}Read-only features keep working without administrator rights.')
}
