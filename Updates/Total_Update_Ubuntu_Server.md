# Total Update Ubuntu Server Script

Runs a full system update pass on a headless Ubuntu Server machine: APT packages, Snap, firmware (fwupd), user-level Python pip packages, global npm packages, and the `locate` database — then reports whether a reboot is needed.

---

## Usage

```console
chmod +x Total_Update_Ubuntu_Server.sh
sudo bash Total_Update_Ubuntu_Server.sh
```

Must be run as root; the script checks `$EUID` itself and refuses to continue otherwise.

Prerequisites:

- Root privileges (`sudo`)
- `apt`/`apt-get` (Ubuntu Server base)
- Optional tools, auto-detected with `command -v` and skipped (not installed) if absent: `snap`, `fwupdmgr`, `pip3`, `npm`, `updatedb` (from `mlocate`/`plocate`)
- `/etc/os-release` for OS name/version detection (optional — falls back to a generic "Linux" label if missing)

---

## What the Script Does

### Step 0 – Root check and setup
Exits with an error if `$EUID -ne 0`. Initializes `REBOOT_NEEDED=false` and `START_TIME`. Reads `/etc/os-release` (if present) for `OS_NAME`/`OS_VERSION` and warns (non-fatal) if the detected `NAME` doesn't contain "ubuntu". Also warns (non-fatal) if it detects a graphical desktop (`Xorg` on PATH, or `$XDG_CURRENT_DESKTOP` set), suggesting [Total_Update_Ubuntu.sh](Total_Update_Ubuntu.sh) instead since that variant also handles Flatpak. Runs under `set -euo pipefail`, so most unguarded command failures abort the whole script.

### Step 1/7 – APT package update
`apt-get update -qq`, then `DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y` with `--force-confdef`/`--force-confold` (keeps existing config files on conflicts, no prompts), then `apt-get install -f -y -qq` to fix any broken dependencies.

### Step 2/7 – APT cleanup
`apt-get autoremove -y -qq` followed by `apt-get autoclean -qq`.

### Step 3/7 – Snap
If `snap` is present: `snap refresh` updates all snaps, then the script lists disabled snap revisions (`snap list --all | awk '/disabled/{print $1, $3}'`) and removes each with `snap remove "$snapname" --revision="$revision"`. Skipped with a warning if `snap` isn't installed. Ubuntu Server cloud images ship `snapd` by default (used for `lxd`, `core`, etc.), so this step is normally active.

### Step 4/7 – Firmware (fwupd)
If `fwupdmgr` is present: `fwupdmgr refresh --force` refreshes metadata (non-fatal on failure), then checks `fwupdmgr get-updates` for the string "Upgrade"; if found, runs `fwupdmgr update -y` and sets `REBOOT_NEEDED=true`. Skipped with a warning if fwupd isn't installed — the warning notes this is typical for VMs/cloud instances, where there's no real firmware to flash.

### Step 5/7 – Python pip (user-level)
Resolves the real (non-root) user via `logname`. If found and `pip3` is present: upgrades pip itself for that user (`sudo -u "$REAL_USER" pip3 install --upgrade pip --quiet`), then lists outdated pip packages (`pip3 list --outdated --format=freeze`, excluding editable `-e` installs) and upgrades them via `xargs -r sudo -u "$REAL_USER" pip3 install --upgrade --quiet`.

### Step 6/7 – npm global packages
If `npm` is present: `npm install -g npm --silent` (self-update), then `npm update -g --silent`.

### Step 7/7 – updatedb
If `updatedb` is present: runs it to refresh the `locate` database; otherwise warns to install `mlocate` or `plocate`.

### Step 8 – Reboot check & summary
Checks for `/var/run/reboot-required` and sets `REBOOT_NEEDED=true` if it exists. Computes elapsed time from `START_TIME`, prints a completion summary with duration and timestamp, and — if a reboot is needed — recommends running `sudo reboot`.

---

## Notes

- This is the headless counterpart of [Total_Update_Ubuntu.md](Total_Update_Ubuntu.md): identical except Flatpak is dropped entirely (a GUI app packaging system with no role on a server) and step numbering is 1/7–7/7 instead of 1/8–8/8. Firmware/pip/npm/Snap steps are unchanged and remain guarded with `command -v` checks, so they're harmless no-ops on systems that don't have those tools.
- Output and internal comments are in Danish ("Opdaterer", "Fjerner", "Kør: sudo reboot", etc.), matching the rest of this folder's `Total_Update_*` scripts.
- `set -euo pipefail` is active: the core APT steps (update, full-upgrade, install -f, autoremove, autoclean) are **not** individually guarded and will halt the entire script on failure. The optional steps (Snap, fwupd, pip, npm) are wrapped with `|| true` / `|| warn ...` so they degrade gracefully instead of aborting.
- Destructive/risky operations, all run non-interactively with `-y` (no confirmation prompt): `apt-get full-upgrade -y`, `apt-get autoremove -y` (can remove packages), `snap remove ... --revision=...`, and `fwupdmgr update -y` (flashes device firmware — can be irreversible on some hardware, mainly relevant to bare-metal servers).
- Must be run as root; enforced explicitly at the top via an `$EUID` check.
- Hardcoded paths: `/etc/os-release`, `/var/run/reboot-required`.
- Broadly safe to re-run: apt/snap/pip/npm update commands are idempotent no-ops when already current, and snap revision cleanup only targets already-disabled revisions.
