Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- PATH DEFINITIONS ---
$meetingFile = Join-Path $PSScriptRoot "meetings.txt"
$lastRunFile = "$env:TEMP\stretch_last_run.txt"
$logFile     = Join-Path $PSScriptRoot "stretch_debug.log"
$currentTime = Get-Date

function Write-DebugLog ($msg) {
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] $msg`r`n"
    [System.IO.File]::AppendAllText($logFile, $logEntry)
}

# --- 1. SMART SESSION & COOLDOWN LOGIC ---
$MinWorkMinutes = 25   # Minimum continuous desk work required before a break
$MaxBreakGap    = 35   # If away longer than this, treat as stepping away from desk

if (Test-Path $lastRunFile) {
    $lastRunStr = Get-Content $lastRunFile -Raw
    if ([DateTime]::TryParse($lastRunStr, [ref](Get-Date))) {
        $lastRunTime = [DateTime]$lastRunStr
        $minutesElapsed = ($currentTime - $lastRunTime).TotalMinutes

        # CASE A: Stepped away / fresh wake-up (e.g., laptop was closed for hours or lunch)
        if ($minutesElapsed -gt $MaxBreakGap) {
            Set-Content -Path $lastRunFile -Value $currentTime.ToString("o") -Force
            Write-DebugLog "SESSION RESET: Stepped away for $([Math]::Round($minutesElapsed, 1)) mins. Timer restarted with 30m grace."
            exit
        }

        # CASE B: Too soon since last break or session start
        if ($minutesElapsed -lt $MinWorkMinutes) {
            Write-DebugLog "BLOCKED: Only $([Math]::Round($minutesElapsed, 1)) mins worked since last break/wake."
            exit
        }
    }
} else {
    # First-time run: Initialize baseline timestamp and exit silently
    Set-Content -Path $lastRunFile -Value $currentTime.ToString("o") -Force
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
    Set-Content -Path $meetingFile -Value $defaultContent -Force
}

$meetings = Get-Content $meetingFile
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

# --- 3. MARK BREAK EXECUTION TIMESTAMP ---
Set-Content -Path $lastRunFile -Value $currentTime.ToString("o") -Force
Write-DebugLog "TRIGGERED break window."

# --- 4. UI & ANIMATION ENGINE ---
$global:TimeRemaining = 30
$CircleCount = 20
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

# Generate floating circles
$global:Circles = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt $CircleCount; $i++) {
    $r = $rand.Next(40, 120)
    $color = [System.Drawing.Color]::FromArgb($rand.Next(120, 220), $rand.Next(50, 256), $rand.Next(50, 256), $rand.Next(50, 256))
    $dx = $rand.Next(-5, 6); if ($dx -eq 0) { $dx = 3 }
    $dy = $rand.Next(-5, 6); if ($dy -eq 0) { $dy = -3 }
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

# Bottom-Right Notification Panel
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(560, 125)
$panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$panel.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($panel, $true, $null)

# 1. Countdown Header
$lblCountdown = New-Object System.Windows.Forms.Label
$lblCountdown.Text = "This break will close automatically in 30 seconds."
$lblCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblCountdown.ForeColor = [System.Drawing.Color]::FromArgb(0, 210, 255)
$lblCountdown.Location = New-Object System.Drawing.Point(15, 12)
$lblCountdown.AutoSize = $true
$panel.Controls.Add($lblCountdown)

# 2. Stretch & Hydration Prompt
$lblHealthMsg = New-Object System.Windows.Forms.Label
$lblHealthMsg.Text = "Please use this break to stretch and drink water."
$lblHealthMsg.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblHealthMsg.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$lblHealthMsg.Location = New-Object System.Drawing.Point(15, 38)
$lblHealthMsg.AutoSize = $true
$panel.Controls.Add($lblHealthMsg)

# 3. Meeting Schedule Notice
$lblMeetingMsg = New-Object System.Windows.Forms.Label
$lblMeetingMsg.Text = "Have upcoming meetings or need quiet hours? Open C:\Scripts\StretchReminder and edit the meetings.txt file to block interruptions."
$lblMeetingMsg.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblMeetingMsg.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$lblMeetingMsg.Location = New-Object System.Drawing.Point(15, 66)
$lblMeetingMsg.Size = New-Object System.Drawing.Size(530, 45)
$panel.Controls.Add($lblMeetingMsg)

$form.Add_Load({
    $panel.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - $panel.Width - 40), ($form.ClientSize.Height - $panel.Height - 40))
})
$form.Controls.Add($panel)

# Animation Render Loop
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
})

# Tick Timer (~25 FPS)
$global:AllowClose = $false
$masterTimer = New-Object System.Windows.Forms.Timer
$masterTimer.Interval = 40 
$startTime = [System.Diagnostics.Stopwatch]::StartNew()
$lastSecondCheck = 0

$masterTimer.Add_Tick({
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

foreach ($c in $global:Circles) { $c.Brush.Dispose() }
