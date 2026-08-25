# Backup SD USB

Reads a target hostname from a config file, then uses `rsync` to mirror an already-mounted SD card's root filesystem (`/media/nenad/rootfs/`) to a dated folder on a locally mounted USB backup drive (`/mnt/usb/Backup/<hostname>`), with a real-time local log appended to a daily log on the same USB drive and a written status file on success or failure.

---

## Usage

```console
chmod +x Backup_SD_USB.sh
sudo ./Backup_SD_USB.sh [dry-run]
```

Run as root, with the SD card already mounted at `/media/nenad/rootfs/` (e.g. via a card reader) and the backup USB drive already mounted at `/mnt/usb/Backup` (see `Backup_USB_Mount.sh`). Passing `dry-run` as the only argument adds rsync's `--dry-run` flag so no files are changed.

Prerequisites:

- Must be run as root (script checks `id -u -eq 0` and exits otherwise).
- `rsync`, `tee`, `sed`, `flock`, `mktemp`, `stat`, `runuser`, `cp`, `mv` must be installed — checked individually, script exits if any is missing. `stdbuf` is used if present but optional.
- A config file named `Backup_SD.cfg` must exist next to the script or at `/etc/Backup_SD.cfg`, containing a line `Hostname=<name>` (see the `Backup_SD.cfg` in this folder, which sets `Hostname=FlightRadar_24`). The script exits immediately with an explicit error if this file isn't found in either location.
- `/mnt/usb/Backup` must already exist/be mounted (checked via `MOUNT_ROOT`); the hostname subfolder under it is created automatically if missing.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `SOURCE_DIR` | `/media/nenad/rootfs/` | Mounted SD card root filesystem to back up |
| `CFG_FILE` | `$SCRIPT_DIR/Backup_SD.cfg`, falls back to `/etc/Backup_SD.cfg` | Location of the config file that supplies `Hostname=` |
| `DEST_BASE` | `/mnt/usb/Backup/${HOSTNAME_FROM_CFG}` | Destination folder on the USB backup drive |
| `MOUNT_ROOT` | `/mnt/usb/Backup` | Sanity check that the USB backup drive is mounted |
| `EXCLUDES` | array | rsync exclude list: `/dev`, `/lost+found`, `/media`, `/mnt`, `/opt`, `/proc`, `/run`, `/snap`, `/srv`, `/sys`, `/tmp`, `/var/run`, `/var/tmp`, `/boot/*`, `/home/nenad/.cache/*`, `/snap/*.*` |
| `LOG_DIR_NFS` | `/mnt/usb/Backup/Log/${HOSTNAME_FROM_CFG}` | Daily rsync log and status file location |
| `LOG_LOCAL_DIR` | `/var/log/rsync_backup` | Local, per-run temporary log directory |

---

## What the Script Does

### Step 1 – Locate and validate config
Resolves its own directory and looks for `Backup_SD.cfg` there, then at `/etc/Backup_SD.cfg`. If neither exists, prints both searched paths and exits immediately. Extracts `Hostname=` (trimmed of CR/whitespace); exits with an error if it's still empty.

### Step 2 – Root check
Exits with an error unless running as UID 0.

### Step 3 – Dependency check
Confirms `rsync`, `tee`, `sed`, `flock`, `mktemp`, `stat`, `runuser`, `cp`, `mv` are on `PATH`; exits if any is missing. Detects optional `stdbuf`.

### Step 4 – Dry-run flag
If the first argument is `dry-run`, sets `DRY_RUN="--dry-run"` and prints a warning banner.

### Step 5 – Verify USB drive is mounted, create destination folders
Checks `/mnt/usb/Backup` (`MOUNT_ROOT`) exists, exiting with an error if not. If `$DEST_BASE` (the hostname subfolder) doesn't exist, creates it with `mkdir -p`, printing an info message; exits with an error if creation fails.

### Step 6 – Prepare logging and acquire a per-date lock
Computes today's date and `$DEST_PATH`, creates the NFS-style log directory and local log directory, creates today's dated destination folder (exiting with an error if that `mkdir -p` fails), writes the rsync exclude list to a temp file, and takes an `flock` lock (fd 9) on `/var/lock/rsync_backup_<date>.lock` to prevent two runs for the same date overlapping — exits if already locked. Registers a cleanup trap to remove the temp excludes file and release the lock.

### Step 7 – Run rsync
Temporarily disables `errexit`/`pipefail`. Runs `rsync -aHX --numeric-ids --delete-delay --info=progress2,stats2 --prune-empty-dirs --exclude-from=<file> "$SOURCE_DIR" "$DEST_PATH"`, piping output through a synchronous `sed -u 's/\r/\n/g' | tee -a "$LOG_LOCAL_FILE"` pipeline (rather than a process substitution) so the local log is guaranteed complete before the next step runs. Captures rsync's exit code from `PIPESTATUS[0]`, then restores strict mode.

### Step 8 – Append the local log to the daily log
Same layered fallback as the sibling scripts: plain `cat >>` append; on failure, diagnostics (`stat`, `mount`, `dmesg`) plus an atomic merge-and-`mv`; if the daily log is missing/unreadable, a direct `cp`; if that fails, an append attempt as the log directory's owner via `runuser`; and finally, copying the local log into the log directory under a unique filename as a last resort. The local temp log is removed once successfully written to the shared log.

### Step 9 – Extract stats and write a status file
Pulls the log's first 11 lines and everything from `Number of files:` onward. On success, extracts `Total transferred file size:` and `Number of regular files transferred:` using anchored `grep -E` patterns and `awk` (handling comma-grouped byte counts), then writes `$STATUS_FILE_NFS` (or a local `.status` fallback) with status, timestamps, counts, size, and log excerpt.

### Step 10 – Handle failure
On non-zero rsync exit, writes a `FAILED` status file with the same fallback logic and — unless this was a dry run — attempts `rmdir` on the (expected-empty) destination date folder before exiting `1`.

---

## Notes

- **Destructive behavior:** rsync runs with `--delete-delay`, so files removed from the SD card source are eventually deleted from the corresponding folder on the USB backup drive.
- **Idempotent/safe to re-run:** yes for a given day — the per-date `flock` prevents concurrent runs, and rsync only transfers deltas. A failed run only tries to remove its own empty destination folder.
- Requires root. Auto-creates `$DEST_BASE` and the dated destination folder if missing (unlike Backup_NAS.sh, which requires its NAS destination to pre-exist).
- Fixes a race condition present in the older `tee >(process substitution)` pattern (see Backup_NAS.sh) by using a synchronous `sed | tee -a` pipeline, so the local log file is fully written before it's merged into the shared daily log.
- Hardcoded/environment-specific paths: `SOURCE_DIR=/media/nenad/rootfs/` (assumes the SD card is mounted under user `nenad`'s auto-mount path), `/mnt/usb/Backup` for both destination and logs, `/var/log/rsync_backup`, `/var/lock`, and `/home/nenad/.cache/*` in the exclude list.
- All `echo` output and inline comments in the script are in Danish; this document is in English.
