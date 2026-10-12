# USB_Copy_Clean_Delete Script

Runs on the Synology NAS as one DSM scheduled task that handles the USB backup disk from start to finish. It moves all backup folders from the USB disk to `NetBackup`, keeps the newest backups in each folder and deletes the rest, optionally deletes old log files, and finishes with a disk usage report. It replaces the three older DSM tasks "Backup USB Disk", "Delete the oldest backups - Count 3" and "Disk Used size - NetBackup".

---

## Usage

The script is stored as a file on the NAS and called from a DSM task (Control Panel → Task Scheduler → User-defined script) that runs as `root` and sets the parameters:

```bash
export MODE=Dryrun      # Dryrun = only show what would happen | Run = do it
export KEEP=3           # backups to keep per folder
export LOG_DAYS=0       # delete log files older than N days (0 = off)
export NOPRUNE=""       # folders without cleanup, space-separated, e.g. "Ubuntu_Learning Ubuntu_MISC"
bash /volume1/root-scripts/USB_Copy_Clean_Delete.sh
```

Any parameter that is not set gets the default from the table below. `MODE` defaults to `Dryrun`, so nothing is changed until the task explicitly sets `MODE=Run`.

To follow a run while it is going, open an SSH session on the NAS:

```bash
tail -f /tmp/USB_Copy_Clean_Delete.log
```

Prerequisites:

- Must run under `bash` as `root`. Both are checked at startup (exit code `2`).
- The USB disk must be mounted at `USB` and have the marker file `USB_MARKER` in its root (see Notes).
- `rsync`, `flock` and GNU `find`, which are all included in DSM.
- `synoacltool` (included in DSM) to restore the inherited ACLs. If it is missing, the ACL step is skipped with a note.
- `unzip` or `7z` to test `.zip` backups. Without either one, a `.zip` only has to be non-empty to pass. `.gz` files are always tested with `gzip -t`.

### Parameters (environment variables)

| Variable | Default | Meaning |
| --- | --- | --- |
| `MODE` | `Dryrun` | `Dryrun` shows what would happen without changing anything. `Run` does it. Case-insensitive. |
| `KEEP` | `3` | Number of backups to keep in each `NetBackup` folder. Must be at least `1`. |
| `LOG_DAYS` | `0` | Delete files in `NetBackup/Log` older than this many days. `0` turns log cleanup off. |
| `NOPRUNE` | empty | Space-separated folder names in `NetBackup` that are never cleaned up in step 2. |
| `USB_MARKER` | `.netbackup-usb` | Marker file that must exist in the root of the USB disk. An empty string turns the check off. |
| `USB` | `/volumeUSB1/usbshare` | Mount point of the USB disk. |
| `DST` | `/volume1/NetBackup` | Destination share for the backups. |

The header comment and the example DSM task only mention the first four. `USB_MARKER`, `USB` and `DST` can be overridden the same way.

---

## What the Script Does

### Step 0 – Check the setup

Validates `MODE`, `KEEP` and `LOG_DAYS`, checks that it runs as `root` and that `DST` exists. It then takes a lock on `/tmp/USB_Copy_Clean_Delete.lock` so two runs cannot overlap. From that point on, all output goes both to DSM (and so to the task's e-mail) and to `/tmp/USB_Copy_Clean_Delete.log`. The log is overwritten on each run.

### Step 1 – Move folders from the USB disk

Skips the step if the USB disk is not mounted at `USB`. Fails without moving anything if the marker file is missing. Every folder in the root of the USB disk is moved to `NetBackup/<folder>/`, except names starting with `@` or `.` and the system folders `#recycle`, `System Volume Information`, `$RECYCLE.BIN` and `lost+found`.

The move is done in two passes so nothing is deleted from the USB disk before everything is copied:

1. **Copy** each folder with `rsync -rlt -u`. The step stops at the first folder that fails, and nothing is deleted from the USB disk.
2. **Delete** from the USB disk with `rsync --remove-source-files`, which only removes files that now match in `NetBackup` (same size and modification time). Empty subfolders are removed afterwards, but the top-level folders on the USB disk are kept.

After each folder, the script restores the inherited DSM ACL on new files and folders in `NetBackup` with `synoacltool -enforce-inherit`, because files created by `rsync` otherwise end up readable by `root` only.

Finally it checks that no files are left in the moved folders on the USB disk. Leftover files make the step fail. Loose files in the root of the USB disk are listed, but they are not moved and do not count as an error.

In `Dryrun`, the step only runs `rsync -n -i` to list what would be copied and counts how many files and folders in `NetBackup` are missing their ACL.

### Step 2 – Clean up old backups

For each folder in `NetBackup` (except `Log`, folders starting with `@`, `#` or `.`, and folders in `NOPRUNE`), the script finds backup files directly in the folder whose names start with a date and end in `.zip` or `.gz` (`YYYY-MM-DD*.zip`, `YYYY-MM-DD*.gz`). They are sorted by name, which is chronological because of the date prefix.

If there are more than `KEEP` backups, the newest one is integrity-tested first. Only if it passes are the oldest backups deleted, so that `KEEP` remain. If the test fails, nothing is deleted in that folder and the step is marked as failed. Files that do not match the backup name pattern are never touched.

### Step 3 – Delete old log files

If `LOG_DAYS` is greater than `0`, deletes files in `NetBackup/Log` (including subfolders) whose modification time is more than `LOG_DAYS` days old. `@eaDir` folders are skipped. In `Dryrun` it only lists them.

### Step 4 – Report disk usage

Prints `du -h` for `NetBackup` two levels deep (without `@eaDir` and `@tmp`), sorted by path so the total for `NetBackup` comes first, followed by `df -h` for the volume.

### Exit codes

All steps run even if an earlier step fails. The exit code reflects the whole run:

| Exit code | Meaning |
| --- | --- |
| `0` | `Run` finished without errors. |
| `1` | One or more steps failed, `DST` is missing, or another run already holds the lock. |
| `2` | Setup error: wrong `MODE`, `KEEP` or `LOG_DAYS`, not `root`, or not `bash`. |
| `3` | `Dryrun` finished. DSM treats this as a failure and sends the result by e-mail, so a task that was accidentally left on `Dryrun` does not go unnoticed. |

---

## Notes

- **Create the marker file on the USB disk before the first run.** With the default `USB_MARKER`, step 1 fails until `.netbackup-usb` exists in the root of the USB disk (for example `touch /volumeUSB1/usbshare/.netbackup-usb`). The check prevents the script from emptying a different disk that happens to be mounted at the same place.
- **Only the newest backup is tested.** The older backups that are kept are not tested, so a damaged older backup can still be one of the `KEEP` that remain.
- **In `Dryrun`, step 2 does not include the files on the USB disk.** Nothing is copied in `Dryrun`, so the cleanup counts only what is already in `NetBackup`. A `Run` can therefore delete more than the `Dryrun` showed.
- **`rsync -u` never overwrites a newer file in `NetBackup`.** If a file on the USB disk is older than the one in `NetBackup`, it stays on the USB disk, and step 1 reports it as left over and fails.
- **`rsync` uses `-rlt` instead of `-a`** so it never changes owner, group or permissions in `NetBackup`; a `chmod` would remove DSM's ACL. `-t` is needed because the delete pass compares size and modification time.
- **It is safe to run all steps after a failure.** `rsync` writes to a hidden temporary file and only renames it once it is complete, so a half-copied file never counts as a backup in step 2.
- **Errors before the lock is taken are not in the log file.** Setup errors, a missing `DST` and a held lock are only shown in DSM and the task e-mail, not in `/tmp/USB_Copy_Clean_Delete.log`.
- The mount check looks for `USB` as an exact mount point in `/proc/mounts`. A disk mounted elsewhere counts as not mounted, and step 1 is skipped without an error.
- Backups are only searched for directly inside each `NetBackup` folder, not in subfolders.
- Comments and console output are in Danish.
