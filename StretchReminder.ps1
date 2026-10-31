Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- AUTO-CREATE MEETINGS FILE WITH SAMPLES IF MISSING ---
$meetingFile = "C:\Scripts\meetings.txt"
if (-not (Test-Path $meetingFile)) {
    $defaultContent = @(
        "# === Stretch Reminder Focus/Meeting Schedule ===",
        "# Enter your busy time blocks below using 24-hour formatting (HH:MM-HH:MM).",
        "# Lines starting with '#' are ignored by the script.",
        "#",
        "# Samples:",
        "# 09:30-10:15",
        "# 14:00-15:30",
        "#"
    )
    $defaultContent | Out-File $meetingFile -Force
}

# --- CALENDAR CHECKER LOGIC ---
$currentTime = Get-Date
$meetings = Get-Content $meetingFile
foreach ($line in $meetings) {
    $line = $line.Trim()
    # Skip empty lines or comment lines starting with #
    if ($line -like "#*" -or [string]::IsNullOrWhiteSpace($line)) { continue }
    
    # Match HH:MM-HH:MM format safely
    if ($line -match '^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$') {
        $startTimeStr = $Matches[1]
        $endTimeStr = $Matches[2]
        
        if ([DateTime]::TryParse($startTimeStr, [ref](Get-Date)) -and [DateTime]::TryParse($endTimeStr, [ref](Get-Date))) {
            $startMeeting = [DateTime]$startTimeStr
            $endMeeting = [DateTime]$endTimeStr
            
            # Handle intervals crossing midnight cleanly
            if ($endMeeting -lt $startMeeting) { $endMeeting = $endMeeting.AddDays(1) }
            
            # SILENT SILENCE: Exit immediately if current time is inside a block
            if ($currentTime -ge $startMeeting -and $currentTime -le $endMeeting) {
                exit
            }
        }
    }
}

# --- CONFIGURATION ---
$global:TimeRemaining = 30
$CircleCount = 20
$rand = New-Object System.Random

# --- FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Time to Stretch!"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.ShowInTaskbar = $false

$bindingFlags = [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
$form.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($form, $true, $null)

# Prevent closing manually
$form.Add_FormClosing({
    param($_, $e)
    if ($global:AllowClose -ne $true) { $e.Cancel = $true }
})

# --- POPULATE MOVING CIRCLES ---
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

# --- HIGH-VISIBILITY COUNTDOWN DISPLAY ---
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(420, 60)
$panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$panel.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($panel, $true, $null)

$lblCountdown = New-Object System.Windows.Forms.Label
$lblCountdown.Text = "This break will close automatically in 30 seconds."
$lblCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblCountdown.ForeColor = [System.Drawing.Color]::FromArgb(0, 210, 255)
$lblCountdown.Location = New-Object System.Drawing.Point(15, 18)
$lblCountdown.AutoSize = $true

$panel.Controls.Add($lblCountdown)
$form.Add_Load({
    $panel.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - $panel.Width - 40), ($form.ClientSize.Height - $panel.Height - 40))
})
$form.Controls.Add($panel)

# --- ANIMATION ENGINE (PAINT EVENT) ---
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

# --- CORE SYSTEMS TICK TIMER ---
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
            if ($lblCountdown.Text -ne "This break will close automatically in $($global:TimeRemaining) seconds.") {
                $lblCountdown.Text = "This break will close automatically in $($global:TimeRemaining) seconds."
            }
        }
    }
})
$masterTimer.Start()

[System.Windows.Forms.Application]::Run($form)

foreach ($c in $global:Circles) { $c.Brush.Dispose() }
