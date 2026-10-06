# Backup USB Pack Script

Packs every dated backup folder (`/mnt/usb/Backup/<Hostname>/YYYY-MM-DD/`) made by the rsync backup scripts into a single `YYYY-MM-DD.gz` archive (tar + gzip) next to it, validates the archive against the folder, and deletes the folder only when every validation check has passed.

---

## Usage

```console
chmod +x Backup_USB_Pack.sh
sudo ./Backup_USB_Pack.sh [dry-run|-n] [-y]
```

| Argument | Meaning |
|---|---|
| `dry-run`, `-n`, `--dry-run` | Show the plan only — nothing is changed |
| `-y`, `--yes` | Do not ask for confirmation |
| `-h`, `--help` | Show help |

Restore an archive with:

```console
sudo tar -xpf YYYY-MM-DD.gz --numeric-owner --xattrs --xattrs-include='*' -C <target folder>
```

Without `--xattrs-include='*'` tar restores only `user.*` xattrs, so capabilities (`security.capability`) are lost.

Prerequisites:

- Must run as root — the script checks this and exits with status `1` otherwise.
- `tar`, `gzip`, `find`, `awk`, `flock`/`findmnt` (util-linux) and `getfattr` (`attr`), checked via the shared `lib/require_tools.sh`.
- `pigz` is optional; if installed it is used instead of `gzip` (same format, much faster).
- The USB backup drive must be mounted on `/mnt/usb/Backup` — the script stops if that path is on the root filesystem.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `BACKUP_ROOT` | `/mnt/usb/Backup` | Backup root; can be overridden from the environment |
| `ARCHIVE_SUFFIX` | `.gz` | Archive name: `YYYY-MM-DD.gz` |
| `LOG_DIR` | `$BACKUP_ROOT/Log/archive` | Where the run log is written |
| `BACKUP_LOCK_DIR` | `/var/lock` | Lock folder shared with the backup script (`rsync_backup_<DATE>.lock`) |
| `SELF_LOCK` | `/var/lock/backup_archive.lock` | Prevents two runs of this script at the same time |

---

## What the Script Does

### Step 1 – Pre-flight
Checks root, that `BACKUP_ROOT` is an absolute path that exists, and that it is on a separately mounted disk (`findmnt`), not the root filesystem.

### Step 2 – Find dated folders
Looks for `<root>/<host>/YYYY-MM-DD/` folders with a valid date, skipping `Log`, `lost+found` and symlinks.

### Step 3 – Show the plan and confirm
Prints each folder with its backup status and what will happen to it: skipped because a backup is running right now, skipped because it is empty, an existing archive is validated, or the folder is packed. In `dry-run` mode it stops here. Without `-y` it asks `[j/N]`, and refuses to run without a terminal.

### Step 4 – Pack, validate, delete
For each folder (holding the backup script's lock for that date):

1. Packs the folder with `tar` (`--numeric-owner --xattrs`) into `YYYY-MM-DD.gz`. An existing archive is never overwritten — it is validated instead.
2. Flushes the archive to disk and drops it from the page cache, so validation reads what is really on the USB drive.
3. `tar --list` reads the whole archive (gzip CRC and tar structure), and every member must be under `YYYY-MM-DD/`.
4. `tar --compare` compares every member byte for byte with the folder, plus permissions, owner, mtime, size, symlink targets, hardlinks and device numbers.
5. Completeness: the number of objects in the archive must match the folder (minus sockets), and the count and total size of xattrs must match.
6. Only if all checks pass is the folder deleted. Otherwise the folder is kept and the unfinished archive is removed.

### Step 5 – Summary
Logs how many folders were archived, skipped and failed, plus free space. Exits `1` if any folder failed.

---

## Notes

- **Destructive:** deletes the backup folders, but only after their archive has been validated. Ctrl-C removes the unfinished archive and leaves the folder untouched.
- Never touches a date the backup script is working on right now, because it shares that script's lock file.
- The script's comments and help text still call it `Backup_Archive_v1.sh` and refer to the backup script as `Backup_NAS_Complete_v6.sh`; in this repo the files are `Backup_USB_Pack.sh` and `Backup_USB.sh`/`Backup_NAS.sh`.
- Comments and console output are in Danish.
