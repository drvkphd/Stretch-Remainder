markdown
# 🤸‍♂️ Windows 11 Full-Screen Dynamic Stretch Break Reminder

A lightweight, completely native Windows 11 utility designed to combat desktop fatigue and keep your posture in check. Every 30 minutes, it locks your screen with a smooth, fluid abstract screensaver for exactly 30 seconds. To prevent workflow disruptions during calls, it features an interactive control panel to snooze reminders until scheduled meetings have finished.

## ✨ Features
* **100% Native Architecture:** Built completely with native Windows Form graphics inside a PowerShell engine—zero third-party tools required.
* **Flicker-Free Animation Engine:** Utilizes advanced memory double-buffering across the application canvas and user interfaces to provide smooth, anti-aliased floating circle shapes at ~25 FPS.
* **Calm Countdown Tracker:** Displays a high-visibility countdown string ("This break will close automatically in X seconds") to keep users informed and prevent panic.
* **Smart Meeting Snooze Control:** Includes an integrated text box interface to input an upcoming meeting time (e.g., `14:30`), writing a micro-token to your volatile system data to completely silence breaks until your appointment concludes.
* **Sleep & Wake-Up Resilient:** Optimized specifically to stay aligned during modern laptop lid closures and sleep transitions without breaking the core time interval loops.

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Save the Core Script
1. Open File Explorer and create a folder named `C:\Scripts\`.
2. Save the `StretchReminder.ps1` file from this repository inside that folder.

### Step 2: Initialize Automation Engine
To securely bypass registry limitations and handle automated execution loops across reboots, initialize the baseline schedule container using your terminal.

1. Right-click the Windows Start menu button and select **Terminal (Admin)** or **PowerShell (Admin)**.
2. Paste the following snippet and hit **Enter**:

```powershell
schtasks.exe /Create /TN "StretchReminder" /TR "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder.ps1" /SC MINUTE /MO 30 /F
```

### Step 3: Add Lid Wake-Up Triggers via GUI
Because modern devices rely on Sleep modes instead of full shutdowns, modify the task parameters using the graphical manager to configure smooth wake-up delay cycles:

1. Search for **Task Scheduler** in your Start menu and open it.
2. Select **Task Scheduler Library** in the left navigation sidebar.
3. Locate **StretchReminder** in the center window panel and double-click to open its properties.
4. On the **General Tab**, go down to **Configure for:** and change it to **Windows 10**.
5. Switch to the **Triggers Tab**, click on your **On workstation unlock** trigger, and click **Edit...** (If it's missing, simply click **New...** and choose *On workstation unlock* from the dropdown).
6. Under *Advanced settings*, check the box for **Delay task for:** and set it to **30 minutes**. Click **OK**.
7. Switch to the **Conditions Tab** and explicitly **uncheck** the box stating *"Start the task only if the computer is on AC power"*. This guarantees your stretch intervals continue running while your machine operates on battery power.
8. Click **OK** to commit all setting changes.

---

## 🛠️ Usage & Verification
* **Immediate System Verification:** To test graphics rendering instantly, press `Win + R`, paste: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder.ps1`, and hit Enter.
* **Routine Behavior:** When starting up fresh, logging back into your workstation, or opening up your laptop lid, the script waits for an initial 30 minutes. It will not interrupt your startup sessions instantly.
* **Manual Close Protocol:** The utility locks layout context controls to prevent accidental closure via standard system interrupt commands (`Alt + F4` / `Esc`). You must allow the 30-second timer to run out naturally or submit a valid 24-hour style format into the Snooze form control.
