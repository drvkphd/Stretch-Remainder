# 🤸‍♂️ Windows 11 Full-Screen Dynamic Stretch Break Reminder

A lightweight, completely native Windows 11 utility designed to combat desktop fatigue and keep your posture in check. Every 30 minutes, it locks your screen with a smooth, fluid abstract screensaver for exactly 30 seconds. 

To prevent workflow disruptions during important calls or focus sessions, the utility silently checks a local text configuration file before firing. If you are inside a scheduled meeting window, the break is automatically skipped without ever interrupting you.

## ✨ Features
* **100% Native Architecture:** Built completely with native Windows Form graphics inside a PowerShell engine—zero third-party tools required.
* **Proactive Silence Engine:** Automatically reads a simple text file (`meetings.txt`) to cross-reference your schedule. If a meeting is active, it quietly exits.
* **Auto-Generating Configuration:** Creates the text configuration file automatically on its first run with built-in template instructions.
* **Flicker-Free Animation Engine:** Utilizes advanced memory double-buffering across the application canvas and user interfaces to provide smooth, anti-aliased floating circle shapes at ~25 FPS.
* **Calm Countdown Tracker:** Displays a high-visibility countdown string ("This break will close automatically in X seconds") to keep users informed and prevent panic.
* **Sleep & Wake-Up Resilient:** Optimized specifically using synchronized event delays to prevent overlapping or rapid back-to-back triggers during laptop sleep/wake transitions.

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Save the Core Script
1. Open File Explorer and create a folder named `C:\Scripts\`.
2. Save the code file from this repository as **`StretchReminder.ps1`** inside that folder.

### Step 2: Configure Task Scheduler (UI Setup)
To guarantee your timelines never clash or create duplicate trigger cycles, we set up the automation rules directly inside the Windows Task Scheduler graphical interface:

1. Search for **Task Scheduler** in your Start menu and open it.
2. In the right-hand panel, click **Create Task...**
3. Configure the following tabs:

#### 📋 General Tab
* **Name:** `StretchReminder`
* **Configure for:** Change the drop-down menu at the bottom to **Windows 10** (this ensures modern execution rules handle the script contexts properly).

#### ⚡ Triggers Tab
Click **New...** at the bottom and create these **two** separate trigger layers:

* **Trigger 1 (Startup & Interval Timer):**
  * *Begin the task:* **At log on**
  * *Advanced settings:* Check **Delay task for:** and type or select **30 minutes**.
  * *Advanced settings:* Check **Repeat task every:** and select or type **30 minutes**.
  * *for a duration of:* Change to **Indefinitely**.
  * Click **OK**.

* **Trigger 2 (Lid Open & Wake from Sleep Timer):**
  * *Begin the task:* **On workstation unlock**
  * *Advanced settings:* Check **Delay task for:** and type or select **30 minutes**.
  * Click **OK**.

#### 🛠️ Actions Tab
Click **New...** and configure a program launch:
* **Action:** `Start a program`
* **Program/script:** `powershell`
* **Add arguments (optional):** 
  ```text
  -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\StretchReminder.ps1
  ```
* Click **OK**.

#### 🔋 Conditions Tab
* Explicitly **uncheck** the box stating *"Start the task only if the computer is on AC power"*. This guarantees your stretch intervals continue tracking while your machine operates on battery power.
* Click **OK** to save the task entirely.

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
