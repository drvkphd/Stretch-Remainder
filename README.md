# 🤸‍♂️ Windows 11 Full-Screen Dynamic Stretch & Hydration Reminder

A lightweight, zero-bloat, native Windows utility designed to combat desktop fatigue, promote healthy posture, and keep hydration on track. Every 30 minutes of continuous desk work, it gently takes over the screen for exactly 30 seconds with a fluid GDI+ vector animation (a swaying stick figure stretching overhead and an animated glass tumbler with sloshing water) and ambient floating bubbles[cite: 8, 10].

To prevent workflow disruptions during calls or focus sessions, the utility cross-references a local schedule file (`meetings.txt`). If a meeting or quiet focus hour is active, the break is silently bypassed.

---

## ✨ Features
* **100% Native Architecture:** Built purely with Windows Forms and GDI+ vector drawing inside native PowerShell—zero third-party dependencies, Node.js, or Electron overhead[cite: 8].
* **Smart Presence Awareness:** Distinguishes between active desk work and absences. Stepping away for longer than 45 minutes (such as lunch or walking away) automatically restarts your work timer with a full 30-minute grace window upon return, rather than interrupting you the moment you sit back down.
* **Dual Vector Animations:** Smooth, programmatic sine-wave vector animations depicting a stick figure stretching overhead and a glass tumbler with sloshing water[cite: 8, 10].
* **Proactive Meeting Suppression:** Automatically bypasses scheduled interruptions when the current time falls within active blocks in `meetings.txt`[cite: 8].
* **Zero System Footprint:** Windows Task Scheduler handles triggers; the script consumes 0% background CPU while you work[cite: 8].

---

## 📂 Repository Structure

```text
C:\Scripts\StretchReminder\
│
├── StretchReminder.ps1      # Core standalone PowerShell utility & UI engine
├── meetings.txt             # User-defined meeting/focus quiet windows (auto-generated)
├── stretch_debug.log        # Activity trace log (timestamps, resets, suppresses)
└── README.md                # Documentation & deployment guide
```[cite: 8]

---

## 🚀 Quick Setup & Deployment

### Step 1: Place the Script
Create the directory `C:\Scripts\StretchReminder\` and save `StretchReminder.ps1` inside it[cite: 8].

### Step 2: Register the Unified Scheduled Task
Open **PowerShell as Administrator** and execute:

```powershell
# Remove any legacy task instances
Unregister-ScheduledTask -TaskName "StretchReminder" -Confirm:$false -ErrorAction SilentlyContinue

# Configure action pointing to standalone script
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder\StretchReminder.ps1"

# Trigger 1: Logon with 30-minute repetition
$TriggerLogon = New-ScheduledTaskTrigger -AtLogOn
$TriggerLogon.RepetitionInterval = (New-TimeSpan -Minutes 30)

# Trigger 2: Workstation unlock
$TriggerUnlock = Get-CimClass -Namespace Root/Microsoft/Windows/TaskScheduler -ClassName MSFT_TaskSessionStateChangeTrigger | New-CimInstance -ClientOnly -Property @{
    StateChange = [UInt16]8
    UserId = "$env:USERDOMAIN\$env:USERNAME"
}

# Settings: Battery friendly + drop overlapping instances
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$Settings.MultipleInstances = "IgnoreNew"

# Register the single unified task
Register-ScheduledTask -TaskName "StretchReminder" -Action $Action -Trigger @($TriggerLogon, $TriggerUnlock) -Settings $Settings -Description "Runs full-screen stretch and hydration break after 30 mins of continuous work." -Force
```[cite: 8]

---

## 📅 Managing Meeting Windows (`meetings.txt`)

On its initial run, the script creates `meetings.txt` in the script directory[cite: 8]. Add busy time intervals using 24-hour format (`HH:MM-HH:MM`):

```text
# === Stretch Reminder Focus/Meeting Schedule ===
# Enter busy time blocks below using 24-hour formatting (HH:MM-HH:MM).
# Lines starting with '#' are ignored by the script.

09:30-10:15
14:00-15:30
16:00-17:00
```[cite: 8]

---

## 🔍 Instant Verification & Testing

To preview the full-screen animation immediately without waiting for the 30-minute timer, run this command in PowerShell:

```powershell
[System.IO.File]::WriteAllText("$([System.IO.Path]::GetTempPath())stretch_last_run.txt", (Get-Date).AddMinutes(-31).ToString("o")); powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\StretchReminder\StretchReminder.ps1"
