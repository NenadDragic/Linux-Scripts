# Synology Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas. These are Synology NAS Task Scheduler scripts.

---

## Backup & Copy

| Script | Doc | Summary |
|---|---|---|
| `Copy GPS log files.sh` | [Copy GPS log files.md](Copy%20GPS%20log%20files.md) | Copies GPS monitor CSV logs from a remote host to the NAS, then lists the destination contents. |
| `Copy USB - Devices.sh` | [Copy USB - Devices.md](Copy%20USB%20-%20Devices.md) | Copies all files from a USB drive to `/volume1/NetBackup/`, removing source files after transfer, then cleans up empty directories and the source share. |
| `Copy USB - Log.sh` | [Copy USB - Log.md](Copy%20USB%20-%20Log.md) | Copies log files from a USB drive to `/volume1/NetBackup/Log/`, removing the source files after transfer, then deletes the source directory. |
| `Loppe files Copy.sh` | [Loppe files Copy.md](Loppe%20files%20Copy.md) | Copies the `Loppe` directory from a remote host to the NAS, then lists the destination contents. |
| `Delete the oldest backups - Count 3.sh` | [Delete the oldest backups - Count 3.md](Delete%20the%20oldest%20backups%20-%20Count%203.md) | Loops through a list of backup folders and deletes all subdirectories except the 3 newest in each. |
| `Delete FTP DashCam 30 over days.sh` | [Delete FTP DashCam 30 over days.md](Delete%20FTP%20DashCam%2030%20over%20days.md) | Deletes all files in `/volume1/DashCam` that were last modified more than 30 days ago, skipping the recycle bin. |

## DDNS

| Script | Doc | Summary |
|---|---|---|
| `DDNS - E-Studie.sh` | [DDNS - E-Studie.md](DDNS%20-%20E-Studie.md) | Triggers a DDNS update via a cPanel webcall on `dragic.com`. |

## Disk & File Counting

| Script | Doc | Summary |
|---|---|---|
| `Disk Used size - DashCam.sh` | [Disk Used size - DashCam.md](Disk%20Used%20size%20-%20DashCam.md) | Shows disk usage for `/volume1/DashCam/` up to 1 directory level deep, then prints the total. |
| `Disk Used size - Dragic.sh` | [Disk Used size - Dragic.md](Disk%20Used%20size%20-%20Dragic.md) | Shows disk usage for `/volume1/Dragic/` up to 1 directory level deep, then prints the total. |
| `Disk Used size - NetBackup.sh` | [Disk Used size - NetBackup.md](Disk%20Used%20size%20-%20NetBackup.md) | Shows disk usage for `/volume1/NetBackup/` up to 2 directory levels deep, then prints the total. |
| `FileCount - Router - DashCam.sh` | [FileCount - Router - DashCam.md](FileCount%20-%20Router%20-%20DashCam.md) | Finds all files in `/volume1/DashCam/File-Count-DashCam/` modified today and displays their contents using `more`. |
| `FileCount - Router - SD.sh` | [FileCount - Router - SD.md](FileCount%20-%20Router%20-%20SD.md) | Finds all files in `/volume1/DashCam/File-Count-SD/` modified today and displays their contents. |
| `FileCount - SFTP - DashCam.sh` | [FileCount - SFTP - DashCam.md](FileCount%20-%20SFTP%20-%20DashCam.md) | Counts the number of files in each DashCam directory and prints the results to the console. |

## Cleanup: Find/Delete pairs

| Script | Doc | Summary |
|---|---|---|
| `Thumbs.db files - Find.sh` | [Thumbs.db files - Find.md](Thumbs.db%20files%20-%20Find.md) | Finds all `Thumbs.db` files under `/volume1/Dragic` (Windows thumbnail cache files often left behind on network shares). |
| `Thumbs.db files - Delete.sh` | [Thumbs.db files - Delete.md](Thumbs.db%20files%20-%20Delete.md) | Deletes all `Thumbs.db` files under `/volume1/Dragic`. |
| `Tilde files - Find.sh` | [Tilde files - Find.md](Tilde%20files%20-%20Find.md) | Finds all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension. |
| `Tilde files - Delete.sh` | [Tilde files - Delete.md](Tilde%20files%20-%20Delete.md) | Deletes all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension. |
| `Two or more spaces in filename - Find.sh` | [Two or more spaces in filename - Find.md](Two%20or%20more%20spaces%20in%20filename%20-%20Find.md) | Finds all files under `/volume1/Dragic` that have two or more consecutive spaces in their names. |
| `Two or more spaces in filename - Delete.sh` | [Two or more spaces in filename - Delete.md](Two%20or%20more%20spaces%20in%20filename%20-%20Delete.md) | Finds files with two or more consecutive spaces in their names and renames them to collapse the double spaces to one — despite the "Delete" name, it renames rather than deletes. |
| `bak files - Find.sh` | [bak files - Find.md](bak%20files%20-%20Find.md) | Finds all `.bak` files under `/volume1/Dragic`. |
| `bak files - Delete.sh` | [bak files - Delete.md](bak%20files%20-%20Delete.md) | Deletes all `.bak` files under `/volume1/Dragic`. |
| `tmp files - Find.sh` | [tmp files - Find.md](tmp%20files%20-%20Find.md) | Finds all `.tmp` files under `/volume1/Dragic`. |
| `tmp files - Delete.sh` | [tmp files - Delete.md](tmp%20files%20-%20Delete.md) | Deletes all `.tmp` files under `/volume2/Dragic` — note the different volume than the Find script above (see Notes). |
| `FileDelete - Router - DashCam.sh` | [FileDelete - Router - DashCam.md](FileDelete%20-%20Router%20-%20DashCam.md) | Finds all files in `/volume1/DashCam/File-Delete/` modified today and displays their contents using `more` — despite the name, it does not delete anything. |

## Integrity Checks

| Script | Doc | Summary |
|---|---|---|
| `Find Corrup files.sh` | [Find Corrup files.md](Find%20Corrup%20files.md) | Finds all files under `/volume1/Dragic` that contain `CORRUPT` in their filename. |
| `Find Invalid files.sh` | [Find Invalid files.md](Find%20Invalid%20files.md) | Finds all files under `/volume1/Dragic` that contain `INVALID` in their filename. |

## Status/Monitoring

| Script | Doc | Summary |
|---|---|---|
| `Loppe Status.sh` | [Loppe Status.md](Loppe%20Status.md) | Prints the contents of the Loppe status file to the terminal. |

## System

| Script | Doc | Summary |
|---|---|---|
| `Reboot.sh` | [Reboot.md](Reboot.md) | Immediately reboots the NAS via `shutdown -r now` — irreversible, with no confirmation prompt, forcibly terminating all running processes, scheduled tasks, and active file transfer/SFTP/SCP sessions. |

---

## Notes

- **Destructive/irreversible scripts:** `Reboot.sh` (immediate, irreversible reboot with no confirmation); the `-delete` find operations (`Thumbs.db files - Delete.sh`, `Tilde files - Delete.sh`, `bak files - Delete.sh`, `tmp files - Delete.sh`); `Delete the oldest backups - Count 3.sh` and `Delete FTP DashCam 30 over days.sh` (prune files/folders based on age or retention count); and `Copy USB - Devices.sh` / `Copy USB - Log.sh`, which remove the source files/directory after copying. Note that `Two or more spaces in filename - Delete.sh` actually renames files rather than deleting them, and `FileDelete - Router - DashCam.sh` despite its name only displays matching files' contents and does not delete anything.
- **Volume mismatch:** `tmp files - Find.sh` targets `/volume1/Dragic` while `tmp files - Delete.sh` targets `/volume2/Dragic` — a different volume than its Find counterpart. This looks like a likely copy/paste bug rather than an intentional design choice, and is worth verifying before relying on the Delete script to clean up what the Find script reports.
- A `Synology/Old/` subfolder exists containing near-duplicate/deprecated-looking versions of some of these scripts. It is indexed separately in its own Overview.md and is not covered here.
