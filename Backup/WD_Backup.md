# WD Backup

Copies three NAS shares (`/mnt/NetBackup`, `/mnt/Dragic`, `/mnt/DashCam`) to a LUKS-encrypted WD Elements USB drive using `rsync`. If the drive is not already mounted, the script unlocks it (`cryptsetup`) and mounts it itself. It shows overall progress with Danish thousands separators, writes a timestamped log, and prints a per-job summary at the end. It can also count how many files and how much data are still missing on the drive, either on its own (`--mangler`) or before copying (`--tael-foerst`). By default it only adds and updates files on the drive; deleting files that no longer exist on the source requires the explicit `--spejl` option.

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
| `--mangler`, `--status` | Count only: shows per job and in total how many files and how much data are missing on the drive, without copying anything. With `--spejl` it also counts the files that would be deleted |
| `--tael-foerst`, `--tæl-først` | Like `--mangler`, then copies. Jobs where nothing is missing are skipped. Costs an extra pass over all files before copying starts |
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
- `perl` is used to format the progress numbers and to show the live status line while counting; if it is missing the script warns and falls back to raw numbers (as if `--raatal` was given). Counting still works without `perl`, but shows no live progress, and `--tael-foerst` can then not detect jobs with nothing to do.
- The NAS shares are mounted automatically via `../File_Handle/SMB.sh` (`<Share> mount`) if they are not already mounted at `/mnt/NetBackup`, `/mnt/Dragic` and `/mnt/DashCam`, and unmounted again (`<Share> umount`) when the script exits — but only the shares the script mounted itself. Shares that were already mounted are left alone. This happens whether or not the WD drive was already mounted, and respects `--kun`. If a share cannot be mounted, its job is skipped with a warning. Unmounting runs from an `EXIT` trap, so it also happens after fatal errors.
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

### Step 5 – Mount the NAS shares
For each selected job whose source is not already a mount point, runs `../File_Handle/SMB.sh <Share> mount` and checks the result with `mountpoint` (SMB.sh returns `0` even on failure). Exits if `SMB.sh` can't be found. An `EXIT` trap unmounts again only the shares the script mounted itself.

### Step 6 – Build the rsync command
Base command: `rsync -aH --partial --human-readable --info=progress2` plus the excludes. ACLs (`-A`) and extended attributes (`-X`) are left out on purpose, because the NAS shares don't expose them and rsync fails with `Permission denied (13)`. `--outbuf=N` keeps progress flowing when output is piped through `perl`. `--spejl` and `--torloeb` add their flags as described above.

### Step 7 – Optional space check (`--plads`)
Runs `du` on each selected source (skipping `#recycle` and `@eaDir`), prints the size per job, the total and the free space on the drive, and exits with an error if the total is larger than the free space.

### Step 8 – Optional count (`--mangler` / `--tael-foerst`)
For each selected job (skipping missing or empty sources, same as the copy), runs `rsync -aH --dry-run --stats --no-inc-recursive` with the same excludes (plus `--delete --delete-excluded` with `--spejl`). This compares size and mtime exactly like a real run but transfers no data. With `perl`, a status line on the terminal shows first how many files have been found on the source, then the comparison progress in percent, what is missing so far and an estimated time left.

From rsync's `--stats` it reads files and bytes to transfer, total files and bytes, and (with `--spejl`) regular files to delete, and prints a table `JOB / FILER / DATA [/ SLET]` as *missing/total*, plus a total row when more than one job ran, the time the count took, the free space on the drive and the log path. Files where only permissions or owner differ are not counted as missing. rsync code `23` gives a warning that the numbers are a minimum; other failures mark the count as failed.

With `--mangler` the script stops here (closing the drive if `--luk` was given). With `--tael-foerst` it continues to the copy, and jobs where rsync found nothing to create, update or delete are marked as having nothing to do.

### Step 9 – Run each job
For every entry in `JOBS` (or only the one matching `--kun`):

- Skips the job if the source directory does not exist, or if it is empty (so an empty or unmounted source can never empty the drive in mirror mode).
- Warns if the source is not a mount point (a hint that the NAS share may have dropped off), but continues.
- With `--tael-foerst`, skips jobs the count found nothing to do for (status `INTET NYT`), and prints the counted missing amount before each job that runs.
- Creates the target folder on the drive (not in dry-run mode).
- Runs rsync `source/` → `<drive>/<target>/`. The progress output goes through a `perl` filter that adds Danish thousands separators, e.g. `(xfr#23262, ir-chk=6513/151321)` becomes `(xfr#23.262, ir-chk=6.513/151.321)`, without touching file names. If the progress line is wider than the terminal (e.g. tmux on a phone), it is shortened on screen — extra spaces first, then speed and time, finally cut — so it keeps overwriting itself instead of scrolling. Completed lines are written in full to the log.
- Maps rsync's exit code (read from `PIPESTATUS[0]`): `0` and `24` (files vanished during the run) → OK; `23` → partial transfer; `20` → interrupted by the user, and the remaining jobs are skipped; anything else → failed.

### Step 10 – Summary
Prints a table of job / status / time — with `--tael-foerst` also the amount the count found missing — the total time, the free space on the drive and the log path. Each result is also written to the log.

### Step 11 – Optional close (`--luk`)
If the script mounted the drive itself, it syncs, unmounts it, and locks it again if it was the one that opened the LUKS container. A drive that was already mounted before the run is left mounted, with a warning.

### Step 12 – Exit code
Exits `1` (with a warning) if no job ran, or if any job's status was not `OK` or `INTET NYT`; otherwise exits `0`. The EXIT trap then unmounts the shares the script mounted.

---

## Notes

- **Exit code.** `0` only if at least one job ran and every job that ran finished `OK` (or `INTET NYT` with `--tael-foerst`). With `--mangler` alone, `0` if every count succeeded, `1` if any failed. `1` if any job was partial, failed, interrupted or skipped, or if no job ran at all (e.g. `--kun` with a name that matches no job). Fatal errors (missing drive, missing prerequisites, not enough space) also exit `1`, and an unknown option exits `2`. This makes the script usable from cron or another script.
- **`--spejl` deletes data.** In mirror mode `--delete --delete-excluded` also removes anything on the drive that matches an exclude pattern (e.g. an existing `#recycle/` folder). Run with `--torloeb --spejl` first to see what would be removed.
- **`--plads` is conservative.** It compares the *full* size of the sources with the free space, not just what's new, so on a drive that already holds most of the data it can abort a run that would in fact fit.
- **Only partial cleanup after fatal errors.** Errors go through `doed`, which exits immediately. The `EXIT` trap still unmounts the NAS shares the script mounted, but if the script fails after unlocking/mounting the WD drive (or is interrupted with Ctrl-C), the drive stays unlocked and mounted until you close it manually.
- **Counting is not free.** `--mangler`/`--tael-foerst` walk every file on both sides over the network, and `--no-inc-recursive` keeps the whole file list in memory (roughly 100 bytes per file). The counted numbers are a snapshot; files changing on a live share can make the real copy differ slightly.
- **Dry run still unlocks the drive.** `--torloeb` only prevents rsync from writing; the drive is still unlocked and mounted so the comparison can be made.
- **`--maal` and `--luk`.** With `--maal` the script never mounts anything, so `--luk` only prints the "was already mounted" warning.
- **Hardcoded, machine-specific values.** The device path, both UUIDs, the key file path and the NAS mount points are tied to one specific drive and machine (`Debian-Laptop`); update them at the top of the script if the drive is replaced.
- **Language.** Console output, log lines and comments are in Danish.
- **Depends on `../File_Handle/SMB.sh`** for mounting the NAS shares; the script exits if it's missing.
