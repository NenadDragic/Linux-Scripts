# Backup Crontabs

Backs up every user's crontab into its own timestamped file, so crontabs can be restored later with a plain `crontab -u <user> <file>`. Reads the user list from NSS/passwd (`getent passwd`) unless specific users are given, optionally includes system-wide cron (`/etc/crontab` + `/etc/cron.d/*`), and can prune old backup files by age.

---

## Usage

```console
chmod +x Backup_crontabs.sh
sudo ./Backup_crontabs.sh [-d katalog] [-u bruger]... [-k dage] [-s] [-n] [-q] [-h]
```

Run as root to capture every user's crontab; without root it silently restricts itself to the invoking user's own crontab and skips system cron (see Notes). Restore a saved crontab with:

```console
crontab -u <bruger> crontab_<bruger>_<dato>.txt
```

Options:

| Flag | Meaning |
|---|---|
| `-d KATALOG` | Output directory (default `/var/backups/crontabs`) |
| `-u BRUGER` | Only back up this user; repeatable. Default: all users from `getent passwd` |
| `-k DAGE` | Delete backup files in the output directory older than this many days (`0` = no cleanup) |
| `-s` | Also save system cron (`/etc/crontab` and `/etc/cron.d/*`) |
| `-n` | Dry-run: print what would happen, write nothing |
| `-q` | Quiet: only print errors |
| `-h` | Show help |

Prerequisites:

- `crontab` command available on `PATH`.
- Root privileges to read other users' crontabs and to write system cron; running as a non-root user limits the script to that user's own crontab.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `OUTDIR` | `/var/backups/crontabs` | Directory backup files are written to (overridable with `-d`) |
| `KEEP_DAYS` | `0` | Age threshold in days for pruning old backups (`0` disables cleanup; overridable with `-k`) |
| `INCLUDE_SYSTEM` | `0` | Whether to also back up `/etc/crontab` + `/etc/cron.d/*` (overridable with `-s`) |
| `DRY_RUN` | `0` | Preview mode, writes nothing (overridable with `-n`) |
| `QUIET` | `0` | Suppress non-error output (overridable with `-q`) |

---

## What the Script Does

### Step 1 – Parse options and validate
Parses flags with `getopts`, validates `-k` is a non-negative integer, and confirms `crontab` is installed.

### Step 2 – Build the user list
If no `-u` was given, enumerates all users via `getent passwd` (covers local and NSS/LDAP/AD-backed accounts). If not running as root, overrides this to just the invoking user (`id -un`) and forces `INCLUDE_SYSTEM=0`, with a warning to stderr.

### Step 3 – Prepare the output directory
Sets `umask 077` and (unless dry-run) creates `OUTDIR` with `chmod 700`.

### Step 4 – Save each user's crontab
For each user, runs `crontab -l -u <user>`; skips users with no crontab or whose crontab is only blank lines/comments. Otherwise sanitizes the username into a safe filename (replacing anything outside `[A-Za-z0-9._@-]` with `_`) and writes `crontab_<user>_<YYYY-MM-DD>.txt` with `chmod 600` (or logs what would be written, in dry-run mode).

### Step 5 – Save system cron (optional)
If `-s` was passed, concatenates `/etc/crontab` and every file in `/etc/cron.d/`, each prefixed with a `### <path>` header, and saves it as `crontab_system_<date>.txt` via the same save routine.

### Step 6 – Prune old backups (optional)
If `-k` is greater than `0` and not in dry-run, deletes files in `OUTDIR` matching `crontab_*_YYYY-MM-DD.txt` older than `KEEP_DAYS` days, logging each deletion.

### Step 7 – Summary
Prints a final count of files written and users skipped (phrased as a dry-run preview if `-n` was used).

---

## Notes

- **Not idempotent for a given day in a destructive way, but not additive either:** re-running on the same date simply overwrites that day's file per user (`crontab_<user>_<date>.txt`), so it's safe to re-run but does not keep multiple backups per day.
- **Privilege drop is silent-ish:** running without root doesn't fail — it just quietly narrows scope to the current user and disables `-s`, only surfacing a warning to stderr. Easy to miss if stderr isn't checked.
- **`set -euo pipefail`** is used, but the per-user `crontab -l` failure (no crontab) is explicitly caught with `if ! content=...` so it doesn't abort the loop.
- Destructive behavior is opt-in only: file deletion only happens with `-k` > `0`, and only targets files already matching the script's own naming pattern in `OUTDIR`.
- Danish-language comments, usage text, and log/error/warning messages (`FEJL`, `ADVARSEL`), consistent with other scripts in this folder (e.g. `Backup_USB_Umount.sh`).
- Hardcoded default output path `/var/backups/crontabs` — override with `-d` if that path isn't writable or desired.
