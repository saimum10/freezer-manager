# IDM Freezer & Manager v2.0

Download `IDM_Freezer_Manager.cmd`, right-click and select **Run as administrator**, then click **Yes** on the UAC prompt.

---

## Menu Options

| Option | Description |
|--------|-------------|
| **[1] Activate IDM** | Registers IDM with a generated serial. If it shows a fake serial screen, use Freeze Trial instead. |
| **[2] Freeze Trial** ✅ | Freezes the 30-day trial permanently. Recommended over activation. |
| **[3] Reset** | Clears all activation and trial data. Use this before re-activating. |
| **[4] Check Status** | Shows whether IDM is registered, in trial, or frozen. |
| **[5] Backup / Restore** | Exports IDM registry settings to `IDM_Backup\` folder and restores them when needed. |
| **[6] Download IDM** | Opens the official IDM download page. |
| **[7] Check for Updates** | Checks GitHub for a newer version of this script. |
| **[8] Settings** | Toggle logging, auto-backup, and startup update check. View or clear log files. |

---

## Notes

- **Internet connection** is required for Activate and Freeze Trial.
- If IDM shows a register popup after Freeze Trial, reinstall IDM and run again.
- The script creates a `Logs\` and `IDM_Backup\` folder next to itself.
- Supports Windows 7, 8, 8.1, 10, and 11 (x86 / x64 / ARM64).

---


