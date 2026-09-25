# Backup Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Rsync Backup Jobs

| Script | Doc | Summary |
|---|---|---|
| `Backup_NAS.sh` | [Backup_NAS.md](Backup_NAS.md) | Reads a hostname from a config file and uses `rsync` to mirror the local root filesystem to a dated folder on a NAS mount, logging locally and to a separate USB-mounted log share, with a status file written on success or failure. |
| `Backup_SD_USB.sh` | [Backup_SD_USB.md](Backup_SD_USB.md) | Same rsync/logging/status-file pattern as `Backup_NAS.sh`, but mirrors an already-mounted SD card's root filesystem to a dated folder on a locally mounted USB backup drive. |
| `Backup_USB.sh` | [Backup_USB.md](Backup_USB.md) | The USB-destination counterpart to `Backup_NAS.sh` — mirrors the local root filesystem to a dated folder on a locally mounted USB backup drive, carrying additional "v6" reliability fixes to the logging pipeline and stats extraction. |
| `WD_Backup.sh` | [WD_Backup.md](WD_Backup.md) | Copies three NAS shares (`/mnt/NetBackup`, `/mnt/Dragic`, `/mnt/DashCam`) to a LUKS-encrypted WD Elements USB drive with `rsync`, unlocking and mounting the drive itself if needed; adds/updates only by default, with optional dry run, mirror (`--spejl`), single-job, space-check and auto-lock modes, Danish-formatted progress and a timestamped log. |
| `WD-Drive.sh` | [WD-Drive.md](WD-Drive.md) | Mounts, shows status for, and unmounts the LUKS-encrypted WD Elements drive (found by LUKS UUID) on `/mnt/backup`; `status` returns exit codes 0/1/3 for use in other scripts, and `umount --sluk` also powers off the USB drive. |
| `Total_Backup.sh` | [Total_Backup.md](Total_Backup.md) | Backs up three drives (`nvme0n1p1`/`p2`/`p3`) as raw `dd` disk images, named by drive type and date, into a backup directory; requires root. |

## System Backup Jobs

| Script | Doc | Summary |
|---|---|---|
| `Backup_Crontabs.sh` | [Backup_Crontabs.md](Backup_Crontabs.md) | Saves every user's crontab to its own dated file (restorable with `crontab -u`), with optional system-cron inclusion, dry-run, and age-based cleanup of old backup files. |

## USB Mount Management

| Script | Doc | Summary |
|---|---|---|
| `Backup_USB_Mount.sh` | [Backup_USB_Mount.md](Backup_USB_Mount.md) | Creates the backup mount point if missing and mounts the backup USB drive (identified by partition UUID) at `/mnt/usb/Backup`, printing a confirmation on success. |
| `Backup_USB_Umount.sh` | [Backup_USB_Umount.md](Backup_USB_Umount.md) | **Currently empty (0 bytes) and non-functional.** Intended to safely unmount and eject the backup USB drive, but the file contains no code, so running it has no effect. |

---

## Notes

- **Non-functional script:** `Backup_USB_Umount.sh` is an empty file — its own doc states this is likely an accidental empty commit or an unfinished work-in-progress, and that the intended unmount/eject logic needs to be reinstated before the documentation can describe real behavior.
- **Destructive behavior:** the three rsync-based scripts (`Backup_NAS.sh`, `Backup_SD_USB.sh`, `Backup_USB.sh`) all run rsync with `--delete-delay`, so files removed from the source are eventually deleted from the backup destination on every successful run. They are otherwise idempotent/safe to re-run for a given day thanks to a per-date `flock`.
- Console `echo` output and inline comments in `Backup_NAS.sh`, `Backup_SD_USB.sh`, `Backup_USB.sh`, and `CreatePDF`-style scripts in this repo are in Danish; `Backup_USB_Mount.sh`'s only output string is in English, and `Backup_USB_Umount.md` itself is written in Danish.
- Several scripts hardcode environment-specific details tied to one machine/user: the username `nenad` in exclude lists and SD mount paths, and a specific USB partition UUID in `Backup_USB_Mount.sh` that must be updated if that physical drive is ever replaced.
- `Backup_NAS_Guide.md` is an additional reference document in this folder (auto-mounting a USB drive via udev + systemd, in Danish) that is not the doc for any single `.sh` script here — it's background/setup material related to how the backup USB drive gets mounted, complementary to `Backup_USB_Mount.sh`.
