# Move Doc To Archive

This script finds files whose names contain a 2008-dated pattern (`2008-??-??`) in a source folder and moves them into an archive folder, with three modes: preview matches (`find`), simulate the whole run without touching anything (`dryrun`), or actually move the files and write a timestamped log (`run`). All of the script's own messages (echo output and log entries) are written in Danish.

---

## Usage

```console
chmod +x MoveDocToArchive.sh
bash MoveDocToArchive.sh [find|dryrun|run]
```

Run it after editing the `fra_folder` (source) and `til_folder` (destination) variables at the top of the script — the working directory it's launched from doesn't matter since both paths are absolute. It must be called with exactly one of `find`, `dryrun`, or `run`; any other argument (including none) prints a usage message and exits with status 1.

Prerequisites:

- Bash (the script uses `mapfile` and `[[ ]]`, so it is not POSIX-`sh` portable).
- Standard coreutils/findutils: `find`, `stat`, `sha256sum`, `mv`, `mkdir`, `date`, `awk`, `basename`.
- Write access to `til_folder` (to create it, write the log, and receive moved files) and read/write access to `fra_folder` (files are moved out of it).

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `fra_folder` | `/sti/til/fra_folder` (placeholder) | Source directory scanned non-recursively (`-maxdepth 1`) for files matching `*2008-??-??*` |
| `til_folder` | `/sti/til/til_folder` (placeholder) | Destination directory files are moved into; created with `mkdir -p` in `dryrun` and `run` modes if missing |
| `logfil` | `$til_folder/flyttede_filer_<timestamp>.log` | Path of the log file written during `run`, timestamped per invocation |

Both `fra_folder` and `til_folder` are shipped as obvious placeholder paths and must be edited before the script is usable.

---

## What the Script Does

### Step 1 – Validate the argument
If `$1` is not `run`, `find`, or `dryrun`, it prints a usage line (`Brug: <script> [run|find|dryrun]`) and exits with status 1.

### Step 2 – Verify the source folder exists
If `fra_folder` is not a directory, it prints an error and exits with status 1.

### Step 3 – Collect matching files
`mapfile -d '' filer < <(find "$fra_folder" -maxdepth 1 -type f -name "*2008-??-??*" -print0)` gathers, non-recursively, every regular file directly inside `fra_folder` whose name contains the literal substring `2008-` followed by two digits, a dash, and two more digits.

### Step 4 – `find` mode: preview
If no files matched, it prints that nothing matches; otherwise it prints each matching path. No files are touched, and the script exits 0.

### Step 5 – `dryrun` mode: simulate
Creates `til_folder` with `mkdir -p` if it doesn't exist (this is a real side effect even though the mode is called "dry"). It compares the device IDs of `fra_folder` and `til_folder` (`stat -c %d`) to report whether checksum validation would be used, then loops over the matched files reporting, for each, whether it would be skipped (a same-named file already exists at the destination) or moved — printing running counts of both. No files are actually moved or copied.

### Step 6 – `run` mode: perform the move
Creates `til_folder` if missing, determines whether source and destination are on the same filesystem (skip checksums) or different filesystems (use checksums), and opens `logfil` with a header. For each matched file: if a same-named file already exists at the destination it is skipped and logged; otherwise, if checksumming is active, a SHA-256 checksum is taken before the move. The file is moved with `mv`; on success, if checksumming is active, a new SHA-256 checksum is taken after the move and compared to the pre-move checksum, logging `OK` or `CHECKSUM FEJL` accordingly (with no rollback on mismatch — the file has already been moved either way); if `mv` itself fails, a `FEJL ved flytning` line is logged. After the loop, a summary line and completion timestamp are appended to the log, and a matching summary is printed to the console along with the log's path.

---

## Notes

- Destructive: `run` mode **moves** (not copies) matching files out of `fra_folder`. A checksum mismatch is logged as an error but the file is not moved back — there is no rollback.
- Files that already exist under the same name at the destination are skipped rather than overwritten, in both `dryrun` and `run` — so re-running after a partial run will not re-move already-moved files. A different file that happens to share the same name would still be silently skipped rather than merged or renamed.
- `dryrun` still has a side effect: it creates `til_folder` via `mkdir -p` if absent, despite the mode's name and its own "no files were touched" message.
- Checksum verification only happens when `fra_folder` and `til_folder` are on different filesystems (per `stat -c %d`); on the same filesystem the script relies solely on `mv`'s atomic rename and skips checksumming.
- The match pattern is hardcoded to the literal year `2008` (`*2008-??-??*`); a different year requires editing the script.
- The search is non-recursive (`-maxdepth 1`) — files in subfolders of `fra_folder` are never considered.
- All echo and log output is in Danish (e.g. "Fejl", "Ingen filer matcher mønsteret", "Flytning gennemført", "SPRING OVER").
- `fra_folder` and `til_folder` are hardcoded placeholder paths (`/sti/til/...`) that must be edited before first use.
