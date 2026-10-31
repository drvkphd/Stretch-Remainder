Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CHECK FOR SNOOZE ACTIVE ---
$snoozeFile = "$env:TEMP\stretch_snooze.txt"
if (Test-Path $snoozeFile) {
    $snoozeUntilStr = Get-Content $snoozeFile -Raw
    if ([DateTime]::TryParse($snoozeUntilStr, [ref](Get-Date))) {
        $snoozeUntil = [DateTime]$snoozeUntilStr
        if ((Get-Date) -lt $snoozeUntil) {
            exit # Quietly exit if the snooze period is still active
        } else {
            Remove-Item $snoozeFile -ErrorAction SilentlyContinue
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

# Explicit binding flags to prevent reflection ambiguity errors
$bindingFlags = [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
$form.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($form, $true, $null)

# Prevent manual closing
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

# --- UI CONTROLS (SNOOZE & COUNTDOWN) ---
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(420, 130)
$panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$panel.GetType().GetProperty("DoubleBuffered", $bindingFlags).SetValue($panel, $true, $null)

# Countdown Text Display
$lblCountdown = New-Object System.Windows.Forms.Label
$lblCountdown.Text = "This break will close automatically in 30 seconds."
$lblCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblCountdown.ForeColor = [System.Drawing.Color]::FromArgb(0, 210, 255) # Bright cyan
$lblCountdown.Location = New-Object System.Drawing.Point(15, 12)
$lblCountdown.AutoSize = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Meeting scheduled at? (HH:MM / e.g. 14:30):"
$label.ForeColor = [System.Drawing.Color]::White
$label.Location = New-Object System.Drawing.Point(15, 48)
$label.AutoSize = $true

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(15, 75)
$textBox.Size = New-Object System.Drawing.Size(120, 25)

$btnSnooze = New-Object System.Windows.Forms.Button
$btnSnooze.Text = "Snooze Breaks"
$btnSnooze.Location = New-Object System.Drawing.Point(145, 73)
$btnSnooze.Size = New-Object System.Drawing.Size(130, 26)
$btnSnooze.ForeColor = [System.Drawing.Color]::Black
$btnSnooze.BackColor = [System.Drawing.Color]::LightGray

$btnSnooze.Add_Click({
    $inputTime = $textBox.Text
    if ([DateTime]::TryParse($inputTime, [ref](Get-Date))) {
        $targetTime = [DateTime]$inputTime
        if ($targetTime -lt (Get-Date)) { $targetTime = $targetTime.AddDays(1) }
        $targetTime.ToString("o") | Out-File $snoozeFile -Force
        
        $global:AllowClose = $true
        $form.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Invalid time format. Please use HH:MM (24-hour style).")
    }
})

$panel.Controls.Add($lblCountdown)
$panel.Controls.Add($label)
$panel.Controls.Add($textBox)
$panel.Controls.Add($btnSnooze)

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
$masterTimer.Interval = 40 # Optimized 25 FPS
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

# Display form
[System.Windows.Forms.Application]::Run($form)

# Clean memory vectors
foreach ($c in $global:Circles) { $c.Brush.Dispose() }
