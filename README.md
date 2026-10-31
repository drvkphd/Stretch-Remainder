# 🤸‍♂️ Windows 11 Full-Screen Dynamic Stretch Break Reminder

A lightweight, completely native Windows 11 utility designed to combat desktop fatigue and keep your posture in check. Every 30 minutes, it locks your screen with a smooth, fluid abstract screensaver for exactly 30 seconds. 

To prevent workflow disruptions during important calls or focus sessions, the utility silently checks a local text configuration file before firing. If you are inside a scheduled meeting window, the break is automatically skipped without ever interrupting you.

## ✨ Features
* **100% Native Architecture:** Built completely with native Windows Form graphics inside a PowerShell engine—zero third-party tools required.
* **Proactive Silence Engine:** Automatically reads a simple text file (`meetings.txt`) to cross-reference your schedule. If a meeting is active, it quietly exits.
* **Auto-Generating Configuration:** Creates the text configuration file automatically on its first run with built-in template instructions.
* **Flicker-Free Animation Engine:** Utilizes advanced memory double-buffering across the application canvas and user interfaces to provide smooth, anti-aliased floating circle shapes at ~25 FPS.
* **Calm Countdown Tracker:** Displays a high-visibility countdown string ("This break will close automatically in X seconds") to keep users informed and prevent panic.
* **Sleep & Wake-Up Resilient:** Optimized specifically to stay aligned during modern laptop lid closures and sleep transitions without breaking the core time interval loops.

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Save the Core Script
1. Open File Explorer and create a folder named `C:\Scripts\`.
2. Save the code file from this repository as **`StretchReminder.ps1`** inside that folder.

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

## 📅 Managing Your Meeting Schedule

The first time the utility tries to run, it will automatically generate a template file at **`C:\Scripts\meetings.txt`**. 

Open this file in Notepad at the start of your day to quickly log your busy blocks. The script skips any lines starting with a `#` sign, letting you keep the instructions intact. Simply add your meeting windows using a clean, 24-hour time range (`HH:MM-HH:MM`) on a new line:

```text
# === Stretch Reminder Focus/Meeting Schedule ===
# Enter your busy time blocks below using 24-hour formatting (HH:MM-HH:MM).
# Lines starting with '#' are ignored by the script.
#
# Samples:
# 09:30-10:15
# 14:00-15:30

11:00-11:30
13:30-14:30
16:00-17:15
```

---

## 🛠️ Usage & Verification
* **Immediate System Verification:** To test graphics rendering instantly, press `Win + R`, paste: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder.ps1`, and hit Enter. *(Note: Make sure your current time isn't blocked inside your meetings.txt file when testing!)*
* **Routine Behavior:** When starting up fresh, logging back into your workstation, or opening up your laptop lid, the script waits for an initial 30 minutes. It will never interrupt your fresh desktop sessions.
* **Manual Close Protocol:** The utility locks control interfaces to prevent accidental closure via standard system interrupt commands (`Alt + F4` / `Esc`). The screen will clear automatically after its 30-second timer finishes.
