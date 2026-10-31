Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- PATH DEFINITIONS ---
$meetingFile = Join-Path $PSScriptRoot "meetings.txt"
$lastRunFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "stretch_last_run.txt")
$logFile     = Join-Path $PSScriptRoot "stretch_debug.log"
$currentTime = Get-Date

function Write-DebugLog ($msg) {
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] $msg
"
    [System.IO.File]::AppendAllText($logFile, $logEntry)
}

# --- 1. COOLDOWN & PRESENCE LOGIC ---
$MinWorkMinutes = 30   # Continuous work minutes required before a break
$MaxBreakGap = 45   # If away longer than 35m, grant a fresh work session

if (Test-Path $lastRunFile) {
    $lastRunStr = [System.IO.File]::ReadAllText($lastRunFile)
    if ([DateTime]::TryParse($lastRunStr, [ref](Get-Date))) {
        $lastRunTime = [DateTime]$lastRunStr
        $minutesElapsed = ($currentTime - $lastRunTime).TotalMinutes

        if ($minutesElapsed -gt $MaxBreakGap) {
            [System.IO.File]::WriteAllText($lastRunFile, $currentTime.ToString("o"))
            Write-DebugLog "SESSION RESET: Stepped away for $([Math]::Round($minutesElapsed, 1)) mins. Timer restarted with 30m grace."
            exit
        }

        if ($minutesElapsed -lt $MinWorkMinutes) {
            Write-DebugLog "BLOCKED: Only $([Math]::Round($minutesElapsed, 1)) mins worked since last break/wake."
            exit
        }
    }
} else {
    [System.IO.File]::WriteAllText($lastRunFile, $currentTime.ToString("o"))
    Write-DebugLog "SESSION INITIALIZED: First run timestamp set. Grace period started."
    exit
}

# --- 2. CALENDAR / MEETING CHECKER ---
if (-not (Test-Path $meetingFile)) {
    $defaultContent = @(
        "# === Stretch Reminder Focus/Meeting Schedule ===",
        "# Enter busy time blocks below using 24-hour formatting (HH:MM-HH:MM).",
        "# Lines starting with '#' are ignored by the script.",
        "#",
        "# Samples:",
        "# 09:30-10:15",
        "# 14:00-15:30",
        "#"
    )
    [System.IO.File]::WriteAllLines($meetingFile, $defaultContent)
}

$meetings = [System.IO.File]::ReadAllLines($meetingFile)
foreach ($line in $meetings) {
    $line = $line.Trim()
    if ($line -like "#*" -or [string]::IsNullOrWhiteSpace($line)) { continue }
    
    if ($line -match '^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$') {
        $startTimeStr = $Matches[1]
        $endTimeStr   = $Matches[2]
        
        if ([DateTime]::TryParse($startTimeStr, [ref](Get-Date)) -and [DateTime]::TryParse($endTimeStr, [ref](Get-Date))) {
            $startMeeting = [DateTime]$startTimeStr
            $endMeeting   = [DateTime]$endTimeStr
            
            if ($endMeeting -lt $startMeeting) { $endMeeting = $endMeeting.AddDays(1) }
            
            if ($currentTime -ge $startMeeting -and $currentTime -le $endMeeting) {
                Write-DebugLog "BLOCKED by meeting window: $line"
                exit
            }
        }
    }
}

# --- 3. MARK EXECUTION TIMESTAMP ---
[System.IO.File]::WriteAllText($lastRunFile, $currentTime.ToString("o"))
Write-DebugLog "TRIGGERED break window."

# --- 4. UI & ANIMATION ENGINE ---
$global:TimeRemaining = 30
$CircleCount = 18
$rand = New-Object System.Random

$form = New-Object System.Windows.Forms.Form
$form.Text = "Time to Stretch!"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.ShowInTaskbar = $false

$bindingFlags = [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
$form.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($form, $true, $null)

$form.Add_FormClosing({
    param($_, $e)
    if ($global:AllowClose -ne $true) { $e.Cancel = $true }
})

# Ambient floating bubbles
$global:Circles = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt $CircleCount; $i++) {
    $r = $rand.Next(35, 100)
    $color = [System.Drawing.Color]::FromArgb($rand.Next(60, 140), $rand.Next(40, 220), $rand.Next(100, 256), $rand.Next(150, 256))
    $dx = $rand.Next(-4, 5); if ($dx -eq 0) { $dx = 2 }
    $dy = $rand.Next(-4, 5); if ($dy -eq 0) { $dy = -2 }
    $circle = [PSCustomObject]@{
        X      = $rand.Next(100, 1000)
        Y      = $rand.Next(100, 600)
        Radius = $r
        DX     = $dx
        DY     = $dy
        Brush  = New-Object System.Drawing.SolidBrush($color)
    }
    [void]$global:Circles.Add($circle)
}

# Bottom-Right Information Card (Expanded 680x185)
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(680, 185)
$panel.BackColor = [System.Drawing.Color]::FromArgb(40, 42, 46)
$panel.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($panel, $true, $null)

# 1. Countdown Header (12pt Bold)
$lblCountdown = New-Object System.Windows.Forms.Label
$lblCountdown.Text = "This break will close automatically in 30 seconds."
$lblCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblCountdown.ForeColor = [System.Drawing.Color]::FromArgb(0, 215, 255)
$lblCountdown.Location = New-Object System.Drawing.Point(18, 14)
$lblCountdown.AutoSize = $true
$panel.Controls.Add($lblCountdown)

# 2. Stretch & Water Prompt (11pt Bold)
$lblHealthMsg = New-Object System.Windows.Forms.Label
$lblHealthMsg.Text = "Please use this break to stretch and drink water."
$lblHealthMsg.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblHealthMsg.ForeColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$lblHealthMsg.Location = New-Object System.Drawing.Point(18, 42)
$lblHealthMsg.AutoSize = $true
$panel.Controls.Add($lblHealthMsg)

# 3. Meeting Schedule Notice (9.5pt Regular)
$lblMeetingMsg = New-Object System.Windows.Forms.Label
$lblMeetingMsg.Text = "Have upcoming meetings or need quiet hours? Open C:\Scripts\StretchReminder and edit meetings.txt to block interruptions."
$lblMeetingMsg.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblMeetingMsg.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$lblMeetingMsg.Location = New-Object System.Drawing.Point(18, 72)
$lblMeetingMsg.Size = New-Object System.Drawing.Size(645, 50)
$panel.Controls.Add($lblMeetingMsg)

# 4. Open-Source Attribution & Credit Line (9.0pt Italic)
$lblCredits = New-Object System.Windows.Forms.Label
$lblCredits.Text = "Engineered by Dr. S. Vishnu Kumar @ Megam Solutions (https://github.com/drvkphd/) • Open-source & free to adapt with due credit."
$lblCredits.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Italic)
$lblCredits.ForeColor = [System.Drawing.Color]::FromArgb(130, 200, 225)
$lblCredits.Location = New-Object System.Drawing.Point(18, 135)
$lblCredits.Size = New-Object System.Drawing.Size(645, 30)
$panel.Controls.Add($lblCredits)

$form.Add_Load({
    $panel.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - $panel.Width - 40), ($form.ClientSize.Height - $panel.Height - 40))
})
$form.Controls.Add($panel)

# --- VECTOR GRAPHICS TOOLS ---
$global:AnimTick = 0
$penWhite = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 5)
$penCyan  = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 220, 255), 4)
$penWhite.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$penWhite.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
$brushWater = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 170, 255))
$brushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$fontCaption = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)

$form.Add_Paint({
    param($_, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    foreach ($c in $global:Circles) {
        $c.X += $c.DX
        $c.Y += $c.DY
        if ($c.X -le 0 -or ($c.X + ($c.Radius * 2)) -ge $form.ClientSize.Width) { $c.DX = -$c.DX }
        if ($c.Y -le 0 -or ($c.Y + ($c.Radius * 2)) -ge $form.ClientSize.Height) { $c.DY = -$c.DY }
        $g.FillEllipse($c.Brush, $c.X, $c.Y, $c.Radius * 2, $c.Radius * 2)
    }

    $sine = [Math]::Sin($global:AnimTick * 0.12)

    # 1. ANIMATED STRETCHING FIGURE (Center-Left)
    $figX = [int]($form.ClientSize.Width * 0.35)
    $figY = [int]($form.ClientSize.Height * 0.45)
    $swayX = [int]($sine * 14)
    $headY = $figY - 80 + [int]($sine * 4)

    $g.DrawEllipse($penWhite, ($figX + $swayX - 16), $headY, 32, 32)
    $g.DrawLine($penWhite, ($figX + $swayX), ($headY + 32), $figX, ($figY + 40))
    
    $armSpread = [int](30 + ($sine * 10))
    $armReachY = $headY - 25 - [int]($sine * 15)
    $g.DrawLine($penWhite, ($figX + $swayX), ($headY + 45), ($figX + $swayX - $armSpread), $armReachY)
    $g.DrawLine($penWhite, ($figX + $swayX), ($headY + 45), ($figX + $swayX + $armSpread), $armReachY)
    
    $g.DrawLine($penWhite, $figX, ($figY + 40), ($figX - 25), ($figY + 110))
    $g.DrawLine($penWhite, $figX, ($figY + 40), ($figX + 25), ($figY + 110))
    $g.DrawString("STRETCH", $fontCaption, $brushWhite, ($figX - 45), ($figY + 130))

    # 2. ANIMATED DRINKING GLASS (Center-Right)
    $cupX = [int]($form.ClientSize.Width * 0.60)
    $cupY = [int]($form.ClientSize.Height * 0.45)

    $state = $g.Save()
    $tiltAngle = [float]($sine * 18)
    $g.TranslateTransform($cupX + 35, $cupY + 60)
    $g.RotateTransform($tiltAngle)

    $g.DrawLine($penCyan, -30, -50, -20, 50)
    $g.DrawLine($penCyan, -20, 50, 20, 50)
    $g.DrawLine($penCyan, 20, 50, 30, -50)

    $waterLevel = [int](-10 + ($sine * 12))
    $waterPoints = @(
        (New-Object System.Drawing.Point(-22, $waterLevel)),
        (New-Object System.Drawing.Point(22, $waterLevel)),
        (New-Object System.Drawing.Point(18, 48)),
        (New-Object System.Drawing.Point(-18, 48))
    )
    $g.FillPolygon($brushWater, $waterPoints)
    $g.DrawLine($penWhite, 0, 30, 25, -70)
    $g.Restore($state)

    $g.DrawString("DRINK WATER", $fontCaption, $brushWhite, ($cupX - 20), ($cupY + 130))
})

# Tick timer
$global:AllowClose = $false
$masterTimer = New-Object System.Windows.Forms.Timer
$masterTimer.Interval = 40 
$startTime = [System.Diagnostics.Stopwatch]::StartNew()
$lastSecondCheck = 0

$masterTimer.Add_Tick({
    $global:AnimTick++
    $form.Invalidate()

    $elapsedSeconds = [Math]::Floor($startTime.Elapsed.TotalSeconds)
    if ($elapsedSeconds -gt $lastSecondCheck) {
        $lastSecondCheck = $elapsedSeconds
        $global:TimeRemaining = 30 - $elapsedSeconds
        
        if ($global:TimeRemaining -le 0) {
            $global:AllowClose = $true
            $masterTimer.Stop()
            $form.Close()
        } else {
            $lblCountdown.Text = "This break will close automatically in $($global:TimeRemaining) seconds."
        }
    }
})

$masterTimer.Start()
[System.Windows.Forms.Application]::Run($form)

# Cleanup
$penWhite.Dispose()
$penCyan.Dispose()
$brushWater.Dispose()
$brushWhite.Dispose()
$fontCaption.Dispose()
foreach ($c in $global:Circles) { $c.Brush.Dispose() }
