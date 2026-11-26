# Backup USB

Uses the machine's own short hostname (`hostname -s`), then uses `rsync` to mirror the local root filesystem (`/`) to a dated folder on a locally mounted USB backup drive (`/mnt/usb/Backup/<hostname>`), with a real-time local log appended to a daily log on the same drive and a written status file on success or failure. Functionally the USB-destination counterpart to the retired `Old/Backup_NAS.sh`, carrying additional "v6" reliability fixes.

---

## Usage

```console
chmod +x Backup_USB.sh
sudo ./Backup_USB.sh [dry-run]
```

Run as root, with the backup USB drive already mounted at `/mnt/usb/Backup` (see `Backup_USB_Mount.sh`). Passing `dry-run` as the only argument adds rsync's `--dry-run` flag so no files are changed.

Prerequisites:

- Must be run as root (script checks `id -u -eq 0` and exits otherwise).
- `rsync`, `sed`, `awk`, `flock`, `find`, `mktemp`, `stat`, `runuser`, `cp`, `mv` must be installed; only `rsync` and `runuser` are checked (see the dependency check below). `stdbuf` is used if present but optional.
- No config file is needed: the destination folder is named after the machine's hostname (`hostname -s`).
- `/mnt/usb/Backup` must be a real mount point (checked with `mountpoint -q` on `MOUNT_ROOT`; an existing but unmounted folder aborts the script, so a backup can never land on the root filesystem); the hostname subfolder under it is created automatically if missing.
- Dependency check: the script starts by sourcing the shared `lib/require_tools.sh` (found by walking up from the script's own folder) and stops with an `apt install` hint if any of these are missing: `rsync`, `runuser`

### Configuration (top of script)

| Variable | Default | Meaning |
| --- | --- | --- |
| `SOURCE_DIR` | `/` | Root filesystem being backed up |
| `HOSTNAME_FROM_CFG` | `hostname -s` (falls back to `/etc/hostname`) | Machine name used for the destination and log folders |
| `DEST_BASE` | `/mnt/usb/Backup/${HOSTNAME_FROM_CFG}` | Destination folder on the USB backup drive |
| `MOUNT_ROOT` | `/mnt/usb/Backup` | Sanity check that the USB backup drive is mounted |
| `EXCLUDES` | array | rsync exclude list: `/lost+found`, `/opt`, `/snap`, `/srv` (whole folder); `/dev/*`, `/media/*`, `/mnt/*`, `/proc/*`, `/run/*`, `/sys/*`, `/tmp/*`, `/var/tmp/*` (contents only, the empty folder is kept for restores); `/swap.img`, `/swapfile`; `/var/cache/*`, `/root/.cache/*`, `/home/*/.cache/*`; browser and Electron app caches under `/home/*/.config/` (`Cache`, `Code Cache`, `GPUCache`, `CacheStorage`, `ScriptCache`, `CachedData`, `*ShaderCache`, `*Dawn*Cache`, `Safe Browsing`) |
| `LOG_DIR_NFS` | `/mnt/usb/Backup/Log/${HOSTNAME_FROM_CFG}` | Daily rsync log and status file location |
| `LOG_LOCAL_DIR` | `/var/log/rsync_backup` | Local, per-run temporary log directory |

---

## What the Script Does

### Step 1 – Locate and validate config

Reads the machine's short hostname with `hostname -s` (falling back to `/etc/hostname`), stripped of whitespace. Exits with an error if it is empty.

### Step 2 – Root check

Exits with an error unless running as UID 0.

### Step 3 – Dependency check

Runs first, before everything else: `require_tools rsync runuser` (via `lib/require_tools.sh`) stops the script with an `apt install` hint if either is missing. The other tools are not checked. Later, the script detects optional `stdbuf`.

### Step 4 – Dry-run flag

If the first argument is `dry-run`, sets `DRY_RUN="--dry-run"` and prints a warning banner.

### Step 5 – Verify USB drive is mounted, create destination folders

Checks `/mnt/usb/Backup` (`MOUNT_ROOT`) exists and — via `mountpoint -q` — that a filesystem is actually mounted there, exiting with an error if either check fails. If `$DEST_BASE` doesn't exist, creates it with `mkdir -p` and prints an info message; exits with an error if creation fails.

### Step 6 – Prepare logging and acquire a lock

Computes today's date and `$DEST_PATH`, creates the log directory and local log directory, creates today's dated destination folder (exiting with an error if `mkdir -p` fails), writes the rsync exclude list to a temp file, and takes an `flock` lock (fd 9) on `/var/lock/rsync_backup.lock` to prevent overlapping runs (a fixed name, so runs either side of midnight cannot overlap) — exits if already locked. Deletes local logs and exclude files in `/var/log/rsync_backup` older than 30 days. Registers a cleanup trap that removes the temp excludes file, releases the lock, and removes the local log once it has been written to the daily log.

### Step 7 – Run rsync

Temporarily disables `errexit`/`pipefail`. Runs `rsync -aHX --numeric-ids --delete-delay --info=stats2 --itemize-changes --exclude-from=<file> "$SOURCE_DIR" "$DEST_PATH"`; when the script runs in a terminal (`[ -t 1 ]`) it uses `--info=progress2,stats2` instead. Output goes through a synchronous `sed -u 's/\r/\n/g' | awk` pipeline (not process substitution, which bash does not wait for). The `awk` step sorts the lines:

- progress lines → terminal only, redrawn on one line; never written to the log
- itemized changes (`>f+++++++++ path`, `*deleting path`, …) → log only
- everything else (errors, warnings, statistics) → terminal and log

The log therefore lists every file that was changed or deleted instead of thousands of progress lines. Captures rsync's exit code from `PIPESTATUS[0]`, then restores strict mode.

### Step 8 – Append the local log to the daily log

Same layered fallback as the sibling scripts: plain `cat >>` append; on failure, diagnostics (`stat`, `mount`, `dmesg`) plus an atomic merge-and-`mv`; if the daily log is missing/unreadable, a direct `cp`; if that fails, an append attempt as the log directory's owner via `runuser`; finally, copying the local log into the log directory under a unique filename as a last resort. The local temp log is removed by the cleanup trap once successfully written to the shared log (after the status file is written).

### Step 9 – Extract stats and write a status file

Reads this run's local log (not the daily log, which can contain several runs) and pulls its first 11 lines, any rsync warnings/errors (`rsync:`, `rsync warning`, `file has vanished`, at most 50 lines) and everything from `Number of files:` onward. Exit code 0 counts as success; exit code 24 ("some files vanished before they could be transferred", e.g. browser or database files changing during the run) counts as success with a warning and is written as `SUCCESS (ADVARSEL: …)` with the exit code. On success, extracts `Total transferred file size:` and `Number of regular files transferred:` using anchored `grep -E` patterns and `awk '{print $(NF-1), $NF}'`, specifically to handle rsync's comma-grouped byte counts (e.g. `49,196,532,484`) robustly. Writes `$STATUS_FILE_NFS` (or a local `.status` fallback) with status, rsync exit code, timestamps, counts, size, warnings and log excerpt.

### Step 10 – Handle failure

On any other non-zero rsync exit, writes a `FAILED` status file with the same fallback logic and — unless this was a dry run — attempts `rmdir` on the (expected-empty) destination date folder before exiting `1`.

---

## Notes

- **Destructive behavior:** rsync runs with `--delete-delay`, so files removed from the local root filesystem are eventually deleted from the USB mirror to keep it in sync.
- **Idempotent/safe to re-run:** yes for a given day — the `flock` lock prevents concurrent runs, and rsync only transfers deltas. A failed run only tries to remove its own empty destination folder.
- Requires root. Auto-creates `$DEST_BASE` and the dated destination folder if missing.
- Both the backup data and its logs live on the same `/mnt/usb/Backup` mount here, unlike the retired `Old/Backup_NAS.sh` where the NAS destination and the log share are two separate mounts.
- Hardcoded/environment-specific paths: `/mnt/usb/Backup` (destination and logs), `/var/log/rsync_backup`, `/var/lock`.
- `/boot` is backed up (kernel, initrd and GRUB config). Mount points such as `/proc`, `/sys`, `/dev`, `/run`, `/tmp`, `/mnt`, `/media` are kept as empty folders, and other empty folders are kept too (no `--prune-empty-dirs`), so a restored system has the folders services expect.
- `/var/run` is a symlink to `/run` and is copied as a symlink.
- Browser and app caches (Chrome, Chromium, VS Code, Claude, Discord, …) are excluded with `**` patterns, so every app and browser profile is covered. They are rebuilt automatically and change constantly, which otherwise causes `file has vanished` warnings (exit 24). Sessions, IndexedDB, Local Storage and other real data are still backed up.
- Messages and the status file say "USB"; variable names ending in `_NFS` (`LOG_FILE_NFS`, `LOG_DIR_NFS`, `STATUS_FILE_NFS`) are left over from the NAS version and point to the USB drive.
- All `echo` output and inline comments in the script are in Danish; this document is in English.
- Since v1.2 the log holds itemized changes instead of progress lines, the status file only describes the current run, rsync exit 24 is reported as success with a warning, `/boot` and empty folders are kept, swap files and browser/app caches are excluded, and messages say "USB" instead of "NFS".
- Since v1.1 the script refuses to run when `/mnt/usb/Backup` exists but nothing is mounted there. `Backup_USB_Mount.sh` creates that folder itself, so before this check a run without the USB drive wrote the whole backup to the system disk.
