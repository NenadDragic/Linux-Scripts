# Backup NAS

Reads a target hostname from a config file, then uses `rsync` to mirror the local root filesystem (`/`) to a dated folder on a NAS mount (`/mnt/NetBackup/<hostname>`), keeping a real-time local log and appending it to a daily log on a separate USB-mounted log share, with a written status file on success or failure.

---

## Usage

```console
chmod +x Backup_NAS.sh
sudo ./Backup_NAS.sh [dry-run]
```

Run as root. Passing `dry-run` as the only argument adds rsync's `--dry-run` flag so no files are changed.

Prerequisites:

- Must be run as root (script checks `id -u -eq 0` and exits otherwise).
- `rsync`, `tee`, `sed`, `flock`, `mktemp`, `stat`, `runuser`, `cp`, `mv` must be installed — the script checks each and exits if any is missing. `stdbuf` is used if present but is optional.
- A config file named `Backup.cfg` must exist next to the script (`$SCRIPT_DIR/Backup.cfg`) or at `/etc/Backup.cfg`, containing a line `Hostname=<name>` (see the `Backup.cfg` in this folder, which sets `Hostname=Debian_Laptop`).
- `/mnt/NetBackup/<hostname>` must already exist/be mounted — the script only checks for it and exits with an error if it isn't; it does not mount or create it.
- `/mnt/usb/Backup` is expected to be mounted too, since the log directory lives under it.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `SOURCE_DIR` | `/` | Root filesystem being backed up |
| `CFG_FILE` | `$SCRIPT_DIR/Backup.cfg`, falls back to `/etc/Backup.cfg` | Location of the config file that supplies `Hostname=` |
| `DEST_BASE` | `/mnt/NetBackup/${HOSTNAME_FROM_CFG}` | Base destination directory on the NAS mount |
| `EXCLUDES` | array | rsync exclude list: `/dev`, `/lost+found`, `/media`, `/mnt`, `/opt`, `/proc`, `/run`, `/snap`, `/srv`, `/sys`, `/tmp`, `/var/run`, `/var/tmp`, `/boot/*`, `/home/nenad/.cache/*`, `/snap/*.*` |
| `LOG_DIR_NFS` | `/mnt/usb/Backup/Log/${HOSTNAME_FROM_CFG}` | Daily rsync log and status file location |
| `LOG_LOCAL_DIR` | `/var/log/rsync_backup` | Local, per-run temporary log directory |

---

## What the Script Does

### Step 1 – Resolve hostname from config
Determines its own directory, looks for `Backup.cfg` there or at `/etc/Backup.cfg`, extracts the `Hostname=` value (stripped of CR/whitespace) with `grep`/`cut`/`sed`. Exits with an error if no hostname can be read.

### Step 2 – Root check
Exits with an error unless running as UID 0.

### Step 3 – Dependency check
Confirms `rsync`, `tee`, `sed`, `flock`, `mktemp`, `stat`, `runuser`, `cp`, `mv` are all on `PATH`, exiting if any is missing. Detects whether `stdbuf` is available (optional).

### Step 4 – Dry-run flag
If the first argument is `dry-run`, sets `DRY_RUN="--dry-run"` and prints a banner warning no files will change.

### Step 5 – Verify NAS destination is mounted
Checks that `$DEST_BASE` (`/mnt/NetBackup/<hostname>`) exists; exits with an error if not. Unlike the USB variants of this script, it does **not** create this directory itself.

### Step 6 – Prepare logging and acquire a per-date lock
Computes today's date and `$DEST_PATH`, creates the NFS log directory and local log directory, creates today's destination folder, writes the rsync exclude list to a temp file, and takes an `flock` lock (via file descriptor 9) on `/var/lock/rsync_backup_<date>.lock` so two runs for the same date can't overlap — exits if the lock is already held. Registers a cleanup trap that removes the temp excludes file and releases the lock on exit.

### Step 7 – Run rsync
Temporarily disables `errexit`/`pipefail` so a non-zero rsync exit code (e.g. `23`) doesn't kill the script early. Runs `rsync -aHX --numeric-ids --delete-delay --info=progress2,stats2 --prune-empty-dirs --exclude-from=<file> "$SOURCE_DIR" "$DEST_PATH"`, piping output through `tee` into a process substitution that converts `\r` to `\n` and appends to the local log. Captures rsync's exit code from `PIPESTATUS[0]`, then restores strict mode.

### Step 8 – Append the local log to the NFS/USB daily log
Tries, in order: a plain `cat >>` append; on failure, gathers diagnostics (`stat`, `mount`, `dmesg`) into the local log, then tries an atomic merge (concatenate old + new into a temp file, `mv` over the original); if the destination log is missing/unreadable, tries a direct `cp`; if that still fails, tries appending as the log directory's owning user via `runuser`; as a last resort, copies the local log into the log directory under a unique filename. The local temp log is deleted once it has been successfully written to the shared log; otherwise it's kept and a warning is logged.

### Step 9 – Extract stats and write a status file
Pulls the log's first 11 lines and everything from `Number of files:` onward. On success (`rsync_exit -eq 0`), greps `Total transferred file size` / `Number of regular files transferred` from the log and writes `$STATUS_FILE_NFS` (falling back to a local `.status` file if that write fails) containing status, timestamps, counts, size, and the log excerpt. Prints a success summary to stdout.

### Step 10 – Handle failure
On non-zero rsync exit, writes a `FAILED` status file with the same primary/fallback logic, and — unless this was a dry run — attempts `rmdir` on the (expected-empty) destination date folder before exiting `1`.

---

## Notes

- **Destructive behavior:** rsync runs with `--delete-delay`, so files removed from the source root are eventually deleted from the NAS mirror to keep it in sync — a real delete against the backup destination on every successful run.
- **Idempotent/safe to re-run:** yes for a given day — the per-date `flock` prevents two simultaneous runs from colliding, and rsync itself only transfers deltas. A failed run only tries to remove its own (empty) destination folder, not existing backup data.
- Requires root, and requires `/mnt/NetBackup/<hostname>` to already be mounted; the script errors out rather than mounting it.
- Hardcoded/environment-specific paths: `/mnt/NetBackup` (NAS mount base), `/mnt/usb/Backup/Log/...` (log location — on a *different* mount than the backup data itself), `/var/log/rsync_backup`, `/var/lock`, and `/home/nenad/.cache/*` in the exclude list (hardcodes the username `nenad`).
- Uses an older, non-synchronized `tee >(process substitution)` pattern for the local log pipeline. Per the script's own history (see Backup_USB.sh), this pattern can leave the local log incomplete at the moment it gets appended to the shared log, because bash doesn't wait for the substituted process to finish.
- The header comment describes this as a "v5" script meant to be saved as `Backup_NAS_Complete_v5.sh` and processed with `dos2unix`; the file actually present here is `Backup_NAS.sh`.
- All `echo` output and inline comments in the script are in Danish; this document is in English.
