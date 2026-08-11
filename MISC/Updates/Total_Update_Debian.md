# Total Update Debian Script

Runs a full system update pass on a Debian/Ubuntu-based machine: APT packages, Snap, Flatpak, firmware (fwupd), user-level Python pip packages, global npm packages, and the `locate` database — then reports whether a reboot is needed.

---

## Usage

```console
chmod +x Total_Update_Debian.sh
sudo bash Total_Update_Debian.sh
```

Must be run as root; the script checks `$EUID` itself and refuses to continue otherwise.

Prerequisites:

- Root privileges (`sudo`)
- `apt`/`apt-get` (Debian/Ubuntu base)
- Optional tools, auto-detected with `command -v` and skipped (not installed) if absent: `snap`, `flatpak`, `fwupdmgr`, `pip3`, `npm`, `updatedb` (from `mlocate`/`plocate`)
- `/etc/os-release` for OS name/version detection (optional — falls back to a generic "Linux" label if missing)

---

## What the Script Does

### Step 0 – Root check and setup
Exits with an error if `$EUID -ne 0`. Initializes `REBOOT_NEEDED=false` and `START_TIME`. Reads `/etc/os-release` (if present) for `OS_NAME`/`OS_VERSION` and prints an OS-specific hint: Ubuntu → all steps active including Snap; Debian → warns that Snap/fwupd aren't standard and will be skipped if not installed. Runs under `set -euo pipefail`, so most unguarded command failures abort the whole script.

### Step 1/8 – APT package update
`apt-get update -qq`, then `DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y` with `--force-confdef`/`--force-confold` (keeps existing config files on conflicts, no prompts), then `apt-get install -f -y -qq` to fix any broken dependencies.

### Step 2/8 – APT cleanup
`apt-get autoremove -y -qq` followed by `apt-get autoclean -qq`.

### Step 3/8 – Snap
If `snap` is present: `snap refresh` updates all snaps, then the script lists disabled snap revisions (`snap list --all | awk '/disabled/{print $1, $3}'`) and removes each with `snap remove "$snapname" --revision="$revision"`. Skipped with a warning if `snap` isn't installed.

### Step 4/8 – Flatpak
If `flatpak` is present: `flatpak update -y`, then `flatpak uninstall --unused -y` to drop unused runtimes. Skipped with a warning otherwise.

### Step 5/8 – Firmware (fwupd)
If `fwupdmgr` is present: `fwupdmgr refresh --force` refreshes metadata (non-fatal on failure), then checks `fwupdmgr get-updates` for the string "Upgrade"; if found, runs `fwupdmgr update -y` and sets `REBOOT_NEEDED=true`. Skipped with a warning if fwupd isn't installed.

### Step 6/8 – Python pip (user-level)
Resolves the real (non-root) user via `logname`. If found and `pip3` is present: upgrades pip itself for that user (`sudo -u "$REAL_USER" pip3 install --upgrade pip --quiet`), then lists outdated pip packages (`pip3 list --outdated --format=freeze`, excluding editable `-e` installs) and upgrades them via `xargs -r sudo -u "$REAL_USER" pip3 install --upgrade --quiet`.

### Step 7/8 – npm global packages
If `npm` is present: `npm install -g npm --silent` (self-update), then `npm update -g --silent`.

### Step 8/8 – updatedb
If `updatedb` is present: runs it to refresh the `locate` database; otherwise warns to install `mlocate` or `plocate`.

### Step 9 – Reboot check & summary
Checks for `/var/run/reboot-required` and sets `REBOOT_NEEDED=true` if it exists. Computes elapsed time from `START_TIME`, prints a completion summary with duration and timestamp, and — if a reboot is needed — recommends running `sudo reboot`.

---

## Notes

- Output and internal comments are in Danish ("Opdaterer", "Fjerner", "Kør: sudo reboot", etc.).
- `set -euo pipefail` is active: the core APT steps (update, full-upgrade, install -f, autoremove, autoclean) are **not** individually guarded and will halt the entire script on failure. Most of the optional steps (Snap, Flatpak, fwupd, pip, npm) are wrapped with `|| true` / `|| warn ...` so they degrade gracefully instead of aborting.
- Destructive/risky operations, all run non-interactively with `-y` (no confirmation prompt): `apt-get full-upgrade -y`, `apt-get autoremove -y` (can remove packages), `snap remove ... --revision=...`, `flatpak uninstall --unused -y`, and `fwupdmgr update -y` (flashes device firmware — can be irreversible on some hardware).
- Must be run as root; enforced explicitly at the top via an `$EUID` check.
- The on-disk filename is `Total_Update_Debian.sh`, but the script's own header comment still labels it `ubuntu-total-update.sh` / "Total system opdatering af Ubuntu Desktop" — a leftover from an Ubuntu-focused variant. The OS-detection logic does handle both Ubuntu and Debian, skipping Snap/fwupd gracefully on Debian if they aren't installed.
- Hardcoded paths: `/etc/os-release`, `/var/run/reboot-required`.
- Broadly safe to re-run: apt/snap/flatpak/pip/npm update commands are idempotent no-ops when already current, and snap revision cleanup only targets already-disabled revisions.
