# Space Usage Real Time

Lists every mounted drive and network share (via `df -h`, with pseudo-filesystems like `tmpfs` filtered out), lets you pick one interactively, then polls its disk usage once per interval, printing each measurement with a timestamp and appending it to a log file in your home directory — both to the screen and to the log, via `tee`.

---

## Usage

```console
chmod +x SpaceUsageRealTime.sh
./SpaceUsageRealTime.sh [--interval N]
```

Run from any working directory; no root required. Stop monitoring with `Ctrl+C` — the log file is kept, and the next run appends to it rather than overwriting it.

Options:

| Option | Meaning |
|---|---|
| `--interval N`, `-i N` | Seconds between measurements (default: `60`). Must be a positive integer. |
| `--hjaelp`, `-h` | Print the help text and exit. |

Prerequisites:

- `df` (coreutils) — checked at startup.
- A writable home directory (`$HOME`) for the log file.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `INTERVAL` | `60` | Seconds between measurements; overridable with `--interval` |
| `EXCLUDE_FS` | `tmpfs`, `devtmpfs`, `squashfs`, `overlay`, `efivarfs` | Filesystem types hidden from the drive list (pseudo-filesystems, not real storage) |

---

## What the Script Does

### Step 1 – Parse options
Reads `--interval`/`-i` (validated as a positive integer) and `--hjaelp`/`-h`. An unknown option prints the help text and exits with code `2`.

### Step 2 – List all drives
Runs `df -h --output=source,fstype,size,used,avail,pcent,target`, excluding the filesystem types in `EXCLUDE_FS`, and prints the result as a numbered table (source, type, size, used, available, use%, mount point). Exits with an error if `df` returns no rows at all.

### Step 3 – Choose a drive
Prompts for a number in range; re-prompts on anything else (non-numeric, `0`, or out of range) until a valid choice is made.

### Step 4 – Derive the log file name
Builds a filesystem-safe name from the chosen mount point's last path component (`/` itself becomes `root`), falling back to the device name if that comes out empty. The log is written to `~/<name>-usage.log`.

### Step 5 – Monitor
Prints what's being monitored, the interval, and the log path, then prints a header row (`TIDSPUNKT  BRUGT LEDIGT BRUGT%`) followed by one aligned row per measurement, forever:

```bash
read -r used avail pcent <<<"$(df -h --output=used,avail,pcent "$TARGET" | tail -1)"
printf '%-19s %6s %6s %6s\n' "$(date '+%F %T')" "$used" "$avail" "$pcent"
sleep "$INTERVAL"
```

The header and every row go to both the terminal and the log file via `tee -a`, so the header is written once at the top of each run in the log too. A trap on `Ctrl+C`/`SIGTERM` prints a "stopped" line and exits cleanly (`exit 0`) instead of just being killed mid-line.

---

## Notes

- **Runs until stopped:** there's no fixed duration or count — it's meant to be left running (e.g. in `tmux`) and interrupted with `Ctrl+C` when you're done watching.
- **Log grows indefinitely:** every run appends (`tee -a`); nothing rotates or trims old entries. For long-term monitoring, rotate `~/<name>-usage.log` yourself (e.g. `logrotate`). Each run also appends its own header row, so a log spanning several runs has one `TIDSPUNKT BRUGT LEDIGT BRUGT%` line per run, not just one at the very top.
- **Chosen by mount point, not device:** the loop queries `df` by the target mount point, not the raw device path, so it keeps working correctly even if the underlying device node changes (e.g. `/dev/sdb1` → `/dev/sdc1` after a reboot) as long as the same thing is still mounted at the same place.
- **If the mount disappears mid-run:** `df` on a mount point that's gone (drive unplugged, network share dropped) prints an error to stderr and returns nothing useful for that line; the loop keeps running and retrying every interval rather than exiting.
- **No parent-directory creation:** if `$HOME` isn't writable, `tee` fails for that run (visible as a `tee: ... No such file or directory` error) but the loop still keeps printing to the screen.
- **Name collisions across drives:** two different drives mounted with the same last path component (unusual, but possible under different parents) would log to the same file; there's no per-run disambiguation beyond the mount point's basename.
- Danish console output/comments, consistent with most other scripts in this folder.
- No dependency on any other script in the folder.
