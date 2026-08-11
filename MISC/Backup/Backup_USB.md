# Backup USB

Reads a target hostname from a config file, then uses `rsync` to mirror the local root filesystem (`/`) to a dated folder on a locally mounted USB backup drive (`/mnt/usb/Backup/<hostname>`), with a real-time local log appended to a daily log on the same drive and a written status file on success or failure. Functionally the USB-destination counterpart to `Backup_NAS.sh`, carrying additional "v6" reliability fixes.

---

## Usage

```console
chmod +x Backup_USB.sh
sudo ./Backup_USB.sh [dry-run]
```

Run as root, with the backup USB drive already mounted at `/mnt/usb/Backup` (see `Backup_USB_Mount.sh`). Passing `dry-run` as the only argument adds rsync's `--dry-run` flag so no files are changed.

Prerequisites:

- Must be run as root (script checks `id -u -eq 0` and exits otherwise).
- `rsync`, `tee`, `sed`, `flock`, `mktemp`, `stat`, `runuser`, `cp`, `mv` must be installed — checked individually, script exits if any is missing. `stdbuf` is used if present but optional.
- A config file named `Backup.cfg` must exist next to the script or at `/etc/Backup.cfg`, containing `Hostname=<name>` (see the `Backup.cfg` in this folder). The script exits immediately with an explicit error, listing both search paths, if the file isn't found.
- `/mnt/usb/Backup` must already exist/be mounted (checked via `MOUNT_ROOT`); the hostname subfolder under it is created automatically if missing.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `SOURCE_DIR` | `/` | Root filesystem being backed up |
| `CFG_FILE` | `$SCRIPT_DIR/Backup.cfg`, falls back to `/etc/Backup.cfg` | Location of the config file that supplies `Hostname=` |
| `DEST_BASE` | `/mnt/usb/Backup/${HOSTNAME_FROM_CFG}` | Destination folder on the USB backup drive |
| `MOUNT_ROOT` | `/mnt/usb/Backup` | Sanity check that the USB backup drive is mounted |
| `EXCLUDES` | array | rsync exclude list: `/dev`, `/lost+found`, `/media`, `/mnt`, `/opt`, `/proc`, `/run`, `/snap`, `/srv`, `/sys`, `/tmp`, `/var/run`, `/var/tmp`, `/boot/*`, `/home/nenad/.cache/*`, `/snap/*.*` |
| `LOG_DIR_NFS` | `/mnt/usb/Backup/Log/${HOSTNAME_FROM_CFG}` | Daily rsync log and status file location |
| `LOG_LOCAL_DIR` | `/var/log/rsync_backup` | Local, per-run temporary log directory |

---

## What the Script Does

### Step 1 – Locate and validate config
Resolves its own directory and looks for `Backup.cfg` there, then at `/etc/Backup.cfg`. If neither exists, prints both searched paths and exits immediately. Extracts `Hostname=` (trimmed of CR/whitespace); exits with an error if still empty.

### Step 2 – Root check
Exits with an error unless running as UID 0.

### Step 3 – Dependency check
Confirms `rsync`, `tee`, `sed`, `flock`, `mktemp`, `stat`, `runuser`, `cp`, `mv` are on `PATH`; exits if any is missing. Detects optional `stdbuf`.

### Step 4 – Dry-run flag
If the first argument is `dry-run`, sets `DRY_RUN="--dry-run"` and prints a warning banner.

### Step 5 – Verify USB drive is mounted, create destination folders
Checks `/mnt/usb/Backup` (`MOUNT_ROOT`) exists, exiting with an error if not. If `$DEST_BASE` doesn't exist, creates it with `mkdir -p` and prints an info message; exits with an error if creation fails.

### Step 6 – Prepare logging and acquire a per-date lock
Computes today's date and `$DEST_PATH`, creates the log directory and local log directory, creates today's dated destination folder (exiting with an error if `mkdir -p` fails), writes the rsync exclude list to a temp file, and takes an `flock` lock (fd 9) on `/var/lock/rsync_backup_<date>.lock` to prevent overlapping runs for the same date — exits if already locked. Registers a cleanup trap to remove the temp excludes file and release the lock.

### Step 7 – Run rsync (v6 fix)
Temporarily disables `errexit`/`pipefail`. Runs `rsync -aHX --numeric-ids --delete-delay --info=progress2,stats2 --prune-empty-dirs --exclude-from=<file> "$SOURCE_DIR" "$DEST_PATH"`, piping output through a synchronous `sed -u 's/\r/\n/g' | tee -a "$LOG_LOCAL_FILE"` pipeline. The script's own comments explain this replaces an earlier `tee >(process substitution)` approach that wasn't synchronized — bash didn't wait for it to finish, so the local log could be incomplete when the append-to-shared-log step ran next. Captures rsync's exit code from `PIPESTATUS[0]`, then restores strict mode.

### Step 8 – Append the local log to the daily log
Same layered fallback as the sibling scripts: plain `cat >>` append; on failure, diagnostics (`stat`, `mount`, `dmesg`) plus an atomic merge-and-`mv`; if the daily log is missing/unreadable, a direct `cp`; if that fails, an append attempt as the log directory's owner via `runuser`; finally, copying the local log into the log directory under a unique filename as a last resort. The local temp log is removed once successfully written to the shared log.

### Step 9 – Extract stats and write a status file (v6 fix)
Pulls the log's first 11 lines and everything from `Number of files:` onward. On success, extracts `Total transferred file size:` and `Number of regular files transferred:` using anchored `grep -E` patterns and `awk '{print $(NF-1), $NF}'`, specifically to handle rsync's comma-grouped byte counts (e.g. `49,196,532,484`) robustly. Writes `$STATUS_FILE_NFS` (or a local `.status` fallback) with status, timestamps, counts, size, and log excerpt.

### Step 10 – Handle failure
On non-zero rsync exit, writes a `FAILED` status file with the same fallback logic and — unless this was a dry run — attempts `rmdir` on the (expected-empty) destination date folder before exiting `1`.

---

## Notes

- **Destructive behavior:** rsync runs with `--delete-delay`, so files removed from the local root filesystem are eventually deleted from the USB mirror to keep it in sync.
- **Idempotent/safe to re-run:** yes for a given day — the per-date `flock` prevents concurrent runs, and rsync only transfers deltas. A failed run only tries to remove its own empty destination folder.
- Requires root. Auto-creates `$DEST_BASE` and the dated destination folder if missing.
- Both the backup data and its logs live on the same `/mnt/usb/Backup` mount here, unlike `Backup_NAS.sh` where the NAS destination and the log share are two separate mounts.
- Hardcoded/environment-specific paths: `/mnt/usb/Backup` (destination and logs), `/var/log/rsync_backup`, `/var/lock`, and `/home/nenad/.cache/*` in the exclude list (hardcodes username `nenad`).
- All `echo` output and inline comments in the script are in Danish; this document is in English.
