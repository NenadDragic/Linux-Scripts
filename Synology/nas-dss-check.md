# nas-dss-check Script

A wrapper that finds the newest DSM configuration export (`.dss`) in `~/Downloads` and runs `nas-dss-check.py` on it, comparing the scripts in the NAS's Task Scheduler with the copies in the `Devices` git repository, showing the lines that differ, and scanning that whole repository for secrets.

---

## Usage

```console
chmod +x nas-dss-check.sh
./nas-dss-check.sh                  # newest .dss in ~/Downloads
./nas-dss-check.sh file.dss         # a specific export
./nas-dss-check.sh --export /tmp/x  # extra options are passed on to nas-dss-check.py
./nas-dss-check.sh --no-diff        # without the differences
./nas-dss-check.sh --context 3      # 3 unchanged lines around each difference
```

Run it from anywhere; it locates `nas-dss-check.py` next to itself (symlinks to the script are resolved).

Prerequisites:

- `python3` — checked at startup
- `nas-dss-check.py` in the same folder as this script — see [nas-dss-check.py.md](nas-dss-check.py.md)
- `shellcheck` is optional; without it the lint step is skipped and a note is printed
- A `.dss` export downloaded from DSM (Control Panel → Update & Restore → Configuration Backup → Export)
- The `Devices` repository checked out at `~/git/Devices`
- No `sudo`: the script only reads files in the user's home directory and must run as the normal user (see Notes)

### Configuration (top of script)

| Variable | Default | Meaning |
| --- | --- | --- |
| `DOWNLOADS` | `$HOME/Downloads` | Folder searched for `.dss` exports when no file is given. |
| `GITDIR` | `$HOME/git/Devices/NAS/Synology` | Folder with the NAS scripts in git that the DSM tasks are compared against. |
| `SCANDIR` | `$HOME/git/Devices` | Folder passed to `--scan`, so the whole repository is searched for secrets. |

---

## What the Script Does

### Step 1 – Check the setup

Resolves its own folder with `readlink -f` and expects `nas-dss-check.py` there. Stops with `FEJL: ...` and exit code `2` if `python3`, `nas-dss-check.py` or `GITDIR` is missing.

### Step 2 – Pick the export

If the first argument ends in `.dss` it is used as the export (and must exist). Otherwise the script takes the most recently modified `*.dss` in `DOWNLOADS`, and prints a note when there is more than one. No `.dss` file at all is an error (exit code `2`).

### Step 3 – Report the age of the export

Prints the chosen file with its modification time and age in days. An export older than 7 days gives a note to fetch a new one if anything was changed in DSM. A missing `shellcheck` is also noted here.

### Step 4 – Run the check

Runs `python3 nas-dss-check.py "$DSS" "$GITDIR" --scan "$SCANDIR"` followed by any remaining arguments (for example `--export DIR`, `--no-diff`, `--context 3` or `--no-shellcheck`).

### Step 5 – Summarise and exit

Prints one closing line based on the Python script's exit code and exits with that same code:

| Exit code | Meaning |
| --- | --- |
| `0` | NAS and git are in sync and no secrets were found. |
| `1` | Something needs attention; see the points printed above. |
| `2` | Setup error (missing tool, script, folder or `.dss` file). |
| other | `nas-dss-check.py` stopped with an error. |

---

## Notes

- Comments and console output are in Danish.
- Read-only: the script itself changes nothing. Files are only written when `--export DIR` is passed on to `nas-dss-check.py`.
- Do not run it with `sudo`. It needs no root rights, and under `sudo` `$HOME` normally points at root's home, so `~/Downloads` and `~/git/Devices` are not found and the script stops with exit code `2`. There is no explicit root check in the script.
- The paths under `$HOME` are hardcoded at the top of the script; a different repository location means editing `GITDIR` and `SCANDIR`.
- A specific `.dss` file must be the first argument; a `.dss` path given later is passed to `nas-dss-check.py` as an extra argument and fails there.
- "Newest" is decided by file modification time, not by the date in the file name.
- Uses its own `command -v` checks instead of the shared `lib/require_tools.sh` block.
