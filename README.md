# 🤸‍♂️ Windows 11 Full-Screen Dynamic Stretch Break Reminder

A lightweight, 100% native Windows 11 utility designed to combat desktop fatigue and posture strain. 

Every 30 minutes of continuous desk work, it displays a fluid, screensaver-style full-screen overlay for 30 seconds. To prevent unwanted interruptions, it automatically detects when you step away, resets your work timer when unlocking after a break, and silently bypasses scheduled meetings via a simple text configuration file.

## ✨ Features

* **100% Native Architecture:** Built completely with native Windows Form graphics inside a PowerShell engine—zero third-party dependencies or background daemons.
* **Smart Desk-Presence Logic:**
  * **Absence Detection:** If you step away or close your laptop lid for more than 35 minutes (e.g., lunch, coffee break), unlocking automatically grants you a fresh 30-minute block of quiet focus time.
  * **Short-Lock Suppression:** If you briefly lock your screen (under 25 minutes), it suppresses duplicate triggers.
  * **Zero Lockout on Return:** You are never locked out immediately after logging in or unlocking your PC.
* **Proactive Meeting Bypass (`meetings.txt`):** Silently checks a local schedule file before executing. If you are inside a scheduled meeting or focus block, the reminder quietly skips.
* **Flicker-Free Animation Engine:** Utilizes advanced memory double-buffering across the application canvas and notification panel to render smooth floating circles at ~25 FPS.
* **Calm Countdown Interface:** Displays a high-visibility ticking countdown alongside health reminders to ensure users remain calm and informed.
* **Trace Diagnostics (`stretch_debug.log`):** Logs every execution attempt, cooldown block, and meeting suppression for transparent visibility.

---

## 📂 Project Directory Structure

```text
C:\Scripts\StretchReminder\
├── StretchReminder.ps1      # Core application logic
├── meetings.txt             # (Auto-generated) Meeting & focus schedule
├── stretch_debug.log        # (Auto-generated) Activity & trace log
└── README.md                # Documentation & setup guide
```

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Save the Core Script

1. Open File Explorer and create the folder:
   ```text
   C:\Scripts\StretchReminder\
   ```
2. Save the `StretchReminder.ps1` file from this repository inside that folder.

### Step 2: Register the Unified Scheduled Task

To ensure seamless coordination without conflicting timers, register the single unified task using **PowerShell (Administrator)**:

```powershell
# 1. Clean out any previous task registrations
Unregister-ScheduledTask -TaskName "StretchReminder" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "StretchReminder-Reset" -Confirm:$false -ErrorAction SilentlyContinue

# 2. Define action pointing to the script
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder\StretchReminder.ps1"

# 3. Trigger 1: Log on with 30-minute repeat
$TriggerLogon = New-ScheduledTaskTrigger -AtLogOn
$TriggerLogon.RepetitionInterval = (New-TimeSpan -Minutes 30)

# 4. Trigger 2: Workstation unlock
$TriggerUnlock = Get-CimClass -Namespace Root/Microsoft/Windows/TaskScheduler -ClassName MSFT_TaskSessionStateChangeTrigger | New-CimInstance -ClientOnly -Property @{
    StateChange = [UInt16]8
    UserId = "$env:USERDOMAIN\$env:USERNAME"
}

# 5. Task settings: allow battery execution and prevent duplicate instances
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$Settings.MultipleInstances = "IgnoreNew"

# 6. Register unified task
Register-ScheduledTask -TaskName "StretchReminder" -Action $Action -Trigger @($TriggerLogon, $TriggerUnlock) -Settings $Settings -Description "Runs full-screen stretch break after 30 mins of active work." -Force
```

---

## 📅 Managing Your Meeting Schedule

On its first run, the script automatically generates a template file at:
`C:\Scripts\StretchReminder\meetings.txt`

Open this file in Notepad to enter your busy blocks in **24-hour format (`HH:MM-HH:MM`)**, one per line. Lines starting with `#` are ignored:

```text
# === Stretch Reminder Focus/Meeting Schedule ===
# Enter busy time blocks below using 24-hour formatting (HH:MM-HH:MM).
# Lines starting with '#' are ignored by the script.
#
# Samples:
# 09:30-10:15
# 14:00-15:30
11:00-12:00
14:30-15:30
16:00-17:15
```

---

## ⚙️ How the Session Logic Works

| Scenario | Script Action | User Experience |
| :--- | :--- | :--- |
| **Morning Boot / First Login** | Gap $> 35$ min detected | Timestamp set to now; exits silently. **No pop-up**. |
| **30 Minutes Continuous Work** | Gap $= 30$ min reached | **Full-screen 30-second stretch break runs**. |
| **Lunch / Stepped Away (>35 min)** | Gap $> 35$ min detected | Resets timestamp on unlock. **No pop-up**; grants 30 min focus. |
| **Quick Screen Lock (<25 min)** | Gap $< 25$ min detected | Exits silently under cooldown. **No pop-up**. |
| **Active Meeting Window** | Matches `meetings.txt` range | Exits silently. **No pop-up**. |

---

## 🧪 Testing & Verification

* **Visual Test (Bypass Cooldown):**
  ```powershell
  Remove-Item "$env:TEMP\stretch_last_run.txt" -ErrorAction SilentlyContinue; powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder\StretchReminder.ps1
  ```
* **View Activity Log:**
  ```powershell
  Get-Content "C:\Scripts\StretchReminder\stretch_debug.log" -Tail 5
  ```

---

## 🗑️ Uninstallation

To completely remove the utility from your system, run in PowerShell (Administrator):

```powershell
Unregister-ScheduledTask -TaskName "StretchReminder" -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\Scripts\StretchReminder" -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\stretch_last_run.txt" -ErrorAction SilentlyContinue
```
