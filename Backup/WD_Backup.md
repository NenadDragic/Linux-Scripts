# WD Backup

Copies three NAS shares (`/mnt/NetBackup`, `/mnt/Dragic`, `/mnt/DashCam`) to a LUKS-encrypted WD Elements USB drive using `rsync`. If the drive is not already mounted, the script unlocks it (`cryptsetup`) and mounts it itself. It shows overall progress with Danish thousands separators, writes a timestamped log, and prints a per-job summary at the end. By default it only adds and updates files on the drive; deleting files that no longer exist on the source requires the explicit `--spejl` option.

---

## Usage

```console
chmod +x WD_Backup.sh
sudo ./WD_Backup.sh [options]
```

Run as root (unless `--maal` is used, see below). Run it inside `tmux` for long jobs so the copy survives closing the terminal window: `tmux new -s backup`.

Options:

| Option | Meaning |
|---|---|
| `--torloeb`, `--tørløb`, `-n` | Dry run: `rsync --dry-run --itemize-changes`, so it lists what would be copied and writes nothing to the drive |
| `--spejl` | Mirror mode: adds `--delete --delete-excluded`, so files on the drive that are missing on the source (or match an exclude pattern) are deleted. Without it the script only adds and updates |
| `--kun NAME` | Run only the job whose target folder is `NAME`, e.g. `--kun DashCam` |
| `--luk` | Unmount and lock the drive when the copy finishes (only if the script itself mounted/unlocked it) |
| `--plads` | Measure the size of the sources first and compare it with the free space on the drive |
| `--maal PATH`, `--mål PATH` | Use `PATH` as the destination instead of the encrypted drive; skips unlocking/mounting and the root requirement |
| `--raatal`, `--råtal` | Show rsync's progress numbers raw, without the Danish thousands separator |
| `--hjaelp`, `--hjælp`, `-h` | Print the help text and exit |

Prerequisites:

- Must be run as root, unless `--maal` is given — unlocking, mounting and reading the NAS shares need root.
- `rsync` and `findmnt` are checked at startup; the script exits if either is missing. `cryptsetup`, `mount`/`umount`, `du`, `df`, `numfmt` and `getent` are used without being checked.
- `perl` is used to format the progress numbers; if it is missing the script warns and falls back to raw numbers (as if `--raatal` was given).
- The NAS shares should already be mounted at `/mnt/NetBackup`, `/mnt/Dragic` and `/mnt/DashCam` — the script does not mount them.
- The WD drive must be connected. If it is locked, the script either uses the key file (if present) or prompts for the passphrase.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `DISK_BYID` | `/dev/disk/by-id/usb-WD_Elements_25A3_4230315738365444-0:0` | Stable device path of the WD drive; partition 1 (`-part1`) is the LUKS container |
| `LUKS_UUID` | `f77e78ad-3189-4e36-b912-82e42359049e` | UUID of the LUKS container; used to recognise an already opened `/dev/mapper/luks-<uuid>` |
| `FS_UUID` | `8154462f-dffc-481a-b95f-37f048a3236a` | UUID of the filesystem inside the container; used to find an existing mount |
| `MAPNAME` | `wd-backup` | Device-mapper name used when the script opens the container itself |
| `KEYFILE` | `/root/wd-backup.key` | Key file used to unlock the drive if it exists and is readable; otherwise `cryptsetup` prompts for the passphrase |
| `FALLBACK_MOUNT` | `/mnt/backup` | Mount point used when the script mounts the drive itself |
| `JOBS` | `/mnt/NetBackup:NetBackup`, `/mnt/Dragic:Dragic`, `/mnt/DashCam:DashCam` | Copy jobs as `source:target-folder-on-drive` |
| `EXCLUDES` | array | rsync excludes: `#recycle/`, `@eaDir/`, `#snapshot/`, `.DS_Store`, `Thumbs.db`, `lost+found/` |

---

## What the Script Does

### Step 1 – Parse options
Reads the options listed above. An unknown option prints the help text and exits with code `2`.

### Step 2 – Set up the log
Creates `~/wd-backup-logs/wd-backup-<YYYYMMDD-HHMMSS>.log` in the home directory of the invoking user (`SUDO_USER`), falling back to `/tmp` if the directory can't be created. The log file is chowned to that user.

### Step 3 – Check prerequisites
Exits if `rsync` or `findmnt` is missing. Warns and switches to raw numbers if `perl` is missing. Exits unless running as root (or `--maal` was given).

### Step 4 – Find or mount the drive
Unless `--maal` was given:

1. If a filesystem with `FS_UUID` is already mounted, that mount point is used and left alone.
2. Otherwise, exits if `<DISK_BYID>-part1` does not exist (drive not connected).
3. Uses an already opened mapper (`/dev/mapper/luks-<LUKS_UUID>`, e.g. opened by the desktop, or `/dev/mapper/wd-backup`) if there is one; otherwise runs `cryptsetup open`, with `KEYFILE` if readable, else asking for the passphrase.
4. Mounts the mapper on `FALLBACK_MOUNT`.

With `--maal`, the given directory must exist and is used as the destination, with a warning.

### Step 5 – Build the rsync command
Base command: `rsync -aH --partial --human-readable --info=progress2` plus the excludes. ACLs (`-A`) and extended attributes (`-X`) are left out on purpose, because the NAS shares don't expose them and rsync fails with `Permission denied (13)`. `--outbuf=N` keeps progress flowing when output is piped through `perl`. `--spejl` and `--torloeb` add their flags as described above.

### Step 6 – Optional space check (`--plads`)
Runs `du` on each selected source (skipping `#recycle` and `@eaDir`), prints the size per job, the total and the free space on the drive, and exits with an error if the total is larger than the free space.

### Step 7 – Run each job
For every entry in `JOBS` (or only the one matching `--kun`):

- Skips the job if the source directory does not exist, or if it is empty (so an empty or unmounted source can never empty the drive in mirror mode).
- Warns if the source is not a mount point (a hint that the NAS share may have dropped off), but continues.
- Creates the target folder on the drive (not in dry-run mode).
- Runs rsync `source/` → `<drive>/<target>/`. The progress output goes through a `perl` filter that adds Danish thousands separators, e.g. `(xfr#23262, ir-chk=6513/151321)` becomes `(xfr#23.262, ir-chk=6.513/151.321)`, without touching file names. Completed lines are also written to the log.
- Maps rsync's exit code (read from `PIPESTATUS[0]`): `0` and `24` (files vanished during the run) → OK; `23` → partial transfer; `20` → interrupted by the user, and the remaining jobs are skipped; anything else → failed.

### Step 8 – Summary
Prints a table of job / status / time, the total time, the free space on the drive and the log path. Each result is also written to the log.

### Step 9 – Optional close (`--luk`)
If the script mounted the drive itself, it syncs, unmounts it, and locks it again if it was the one that opened the LUKS container. A drive that was already mounted before the run is left mounted, with a warning.

### Step 10 – Exit code
Exits `1` (with a warning) if no job ran, or if any job's status was not `OK`; otherwise exits `0`.

---

## Notes

- **Exit code.** `0` only if at least one job ran and every job that ran finished `OK`. `1` if any job was partial, failed, interrupted or skipped, or if no job ran at all (e.g. `--kun` with a name that matches no job). Fatal errors (missing drive, missing prerequisites, not enough space) also exit `1`, and an unknown option exits `2`. This makes the script usable from cron or another script.
- **`--spejl` deletes data.** In mirror mode `--delete --delete-excluded` also removes anything on the drive that matches an exclude pattern (e.g. an existing `#recycle/` folder). Run with `--torloeb --spejl` first to see what would be removed.
- **`--plads` is conservative.** It compares the *full* size of the sources with the free space, not just what's new, so on a drive that already holds most of the data it can abort a run that would in fact fit.
- **No cleanup after fatal errors.** Errors go through `doed`, which exits immediately without a trap. If the script fails after unlocking/mounting the drive (or is interrupted with Ctrl-C), the drive stays unlocked and mounted until you close it manually.
- **Dry run still unlocks the drive.** `--torloeb` only prevents rsync from writing; the drive is still unlocked and mounted so the comparison can be made.
- **`--maal` and `--luk`.** With `--maal` the script never mounts anything, so `--luk` only prints the "was already mounted" warning.
- **Hardcoded, machine-specific values.** The device path, both UUIDs, the key file path and the NAS mount points are tied to one specific drive and machine (`Debian-Laptop`); update them at the top of the script if the drive is replaced.
- **Language.** Console output, log lines and comments are in Danish.
- No dependency on any other script in the folder.
