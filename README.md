# Cursor AI IDE Installer for Ubuntu 24.04

This is a guideline and script for installing or updating Cursor on Ubuntu 24.04.

## 🚀 Quick Start (One-Line Installation)

Run this command to install/update Cursor directly without cloning the repository:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hieutt192/Cursor-ubuntu/Cursor-ubuntu24.04/manage_cursor.sh)"
```

> **Note:** For Ubuntu 22.04 installation, please switch to the `main` branch or visit: [Link](https://github.com/hieutt192/Cursor-ubuntu/tree/main)

---

## 🎨 Script Interface

When you run the script, you'll see a user-friendly menu interface:

```
   ______                              ___    ____   ________  ______
  / ____/_  ________________  _____   /   |  /  _/  /  _/ __ \/ ____/
 / /   / / / / ___/ ___/ __ \/ ___/  / /| |  / /    / // / / / __/   
/ /___/ /_/ / /  (__  ) /_/ / /     / ___ |_/ /   _/ // /_/ / /___   
\____/\__,_/_/  /____/\____/_/     /_/  |_/___/  /___/_____/_____/   
                                                                     
For Ubuntu 24.04
-------------------------------------------------
  /\_/\
 ( o.o )
  > ^ <
------------------------
1. 💿 Install Cursor
2. 🆙 Update Cursor
3. 🎨 Restore Icons
4. 🗑️ Uninstall Cursor
Note: If the menu reappears after choosing an option, check any error message above.
------------------------
Please choose an option (1, 2, 3, or 4): 
```

---

## ✨ Features
- 🚀 **One-line Installation:** Install directly from GitHub without cloning
- 📦 **Auto-download:** Automatically fetches latest Cursor AppImage 
- 🔄 **Easy Update:** Update to newest version with single command
- 🎨 **Icon Restore:** Change your icon selection after installation
- 🗑️ **Complete Uninstall:** Remove Cursor and all related files
- 🖥️ **Desktop Integration:** Automatic menu entry creation

---

## ⚙️ Prerequisites
- 🐧 Ubuntu 24.04 or compatible Linux distribution
- 🌐 Internet connection
- 🔑 `sudo` privileges
- 📦 `curl` (auto-installed if missing)

---


## 🎨 Available Icons
- <img src="images/cursor-icon.png" alt="Cursor Icon" width="24"/> `cursor-icon.png` – Standard Cursor logo with blue background  
- <img src="images/cursor-black-icon.png" alt="Cursor Black Icon" width="24"/> `cursor-black-icon.png` – Cursor logo with dark background

---

## ⚠️ Important Notes
- **Ubuntu 24.04:** This script is specifically designed for Ubuntu 24.04
- **Do NOT install libfuse2:** Unlike Ubuntu 22.04, libfuse2 is not needed and can cause issues
- **Restart recommended:** For best experience, restart after installation
- **Sudo required:** Script needs admin privileges for system-wide installation

---

## 🧩 Troubleshooting
If you encounter any issues:
1. **Permission errors:** Ensure you have `sudo` privileges and active internet connection
2. **Script fails to download:** Check your network connection and try again
3. **Cursor won't start:** Run from terminal to see error messages: `/opt/Cursor/AppRun --no-sandbox`
4. **Desktop entry missing:** Log out and log back in, or restart your computer

---

## ❌ Uninstallation

The script includes a built-in uninstall option. Simply run the script and choose option 4:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hieutt192/Cursor-ubuntu/Cursor-ubuntu24.04/manage_cursor.sh)"
```

Or if you have the script locally:
```bash
./manage_cursor.sh
```

Select **4. 🗑️ Uninstall Cursor** from the menu for complete removal.

---

## 🆕 New Feature Release

### Latest Features (Current Version)
**Enhanced Script Interface and User Experience:**
- **🚀 One-line Installation:** Direct installation via curl command without cloning repository
- **🗑️ Uninstall Option:** Complete removal functionality built into main menu
- **🎨 Icon Restore:** Change your icon selection after installation with dedicated option
- **📦 Smart Auto-download:** Intelligent download with automatic fallback to manual input
- **🖥️ Desktop Integration:** Automatic menu entry creation and proper permissions
- **💻 Ubuntu 24.04 Optimized:** Specifically designed for Ubuntu 24.04 without libfuse2 dependency
- **🎭 Beautiful UI:** ASCII art banner with figlet and friendly cat mascot
- **🔧 Comprehensive Management:** Install, Update, Restore Icons, and Uninstall all in one script