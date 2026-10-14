# Backup Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Rsync Backup Jobs

| Script | Doc | Summary |
| --- | --- | --- |
| `Backup_USB.sh` | [Backup_USB.md](Backup_USB.md) | Mirrors the local root filesystem to a dated folder named after the machine's hostname on a locally mounted USB backup drive, carrying "v6" reliability fixes to the logging pipeline and stats extraction. |
| `WD_Backup.sh` | [WD_Backup.md](WD_Backup.md) | Copies three NAS shares (`/mnt/NetBackup`, `/mnt/Dragic`, `/mnt/DashCam`) to a LUKS-encrypted WD Elements USB drive with `rsync`, unlocking and mounting the drive and the NAS shares (via `SMB.sh`) itself if needed; adds/updates only by default, with optional dry run, mirror (`--spejl`), single-job, space-check, count-missing (`--mangler`, `--tael-foerst`) and auto-lock modes, Danish-formatted progress and a timestamped log. |
| `WD-Drive.sh` | [WD-Drive.md](WD-Drive.md) | Mounts, shows status for, and unmounts the LUKS-encrypted WD Elements drive (found by LUKS UUID) on `/mnt/backup`; `status` returns exit codes 0/1/3 for use in other scripts, and `umount --sluk` also powers off the USB drive. |
| `Backup_USB_Pack.sh` | [Backup_USB_Pack.md](Backup_USB_Pack.md) | Packs each dated backup folder on the USB drive into a `YYYY-MM-DD.gz` archive, validates the archive against the folder (content, metadata, object and xattr counts) and deletes the folder only if every check passes. |

## System Backup Jobs

| Script | Doc | Summary |
| --- | --- | --- |
| `Backup_Crontabs.sh` | [Backup_Crontabs.md](Backup_Crontabs.md) | Saves every user's crontab to its own dated file (restorable with `crontab -u`), with optional system-cron inclusion, dry-run, and age-based cleanup of old backup files. |

## USB Mount Management

| Script | Doc | Summary |
| --- | --- | --- |
| `Backup_USB_Mount.sh` | [Backup_USB_Mount.md](Backup_USB_Mount.md) | Creates the backup mount point if missing and mounts the backup USB drive (identified by partition UUID) at `/mnt/usb/Backup`, printing a confirmation on success. |
| `Backup_USB_Umount.sh` | [Backup_USB_Umount.md](Backup_USB_Umount.md) | Unmounts the backup USB drive from `/mnt/usb/Backup` and ejects it (identified by partition UUID), printing a confirmation on success. |

---

## Notes

- **Destructive behavior:** `Backup_USB_Pack.sh` deletes dated backup folders, but only after their archive has been validated. `Backup_USB.sh` runs rsync with `--delete-delay`, so files removed from the source are eventually deleted from the backup destination on every successful run. It is otherwise idempotent/safe to re-run for a given day thanks to a per-date `flock`.
- Console `echo` output and inline comments in `Backup_USB.sh` and `CreatePDF`-style scripts in this repo are in Danish; `Backup_USB_Mount.sh`'s only output string is in English, and `Backup_USB_Umount.sh`'s confirmation message is in Danish.
- Several scripts hardcode environment-specific details tied to one machine/user: the username `nenad` in exclude lists, and a specific USB partition UUID in `Backup_USB_Mount.sh` that must be updated if that physical drive is ever replaced.
- `Backup_NAS_Guide.md` is an additional reference document in this folder (auto-mounting a USB drive via udev + systemd, in Danish) that is not the doc for any single `.sh` script here — it's background/setup material related to how the backup USB drive gets mounted, complementary to `Backup_USB_Mount.sh`.
- `Old/` holds retired scripts and their docs (`Backup_NAS.sh`, `Backup_SD_USB.sh`, `Total_Backup.sh`) plus the `Backup.cfg`/`Backup_SD.cfg` files that are no longer needed, since the backup folder is now named after the machine's hostname.
