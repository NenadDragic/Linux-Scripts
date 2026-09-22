# Total Update Raspberry Pi Script

Runs a full system update pass on a Raspberry Pi (Raspberry Pi OS / other Debian-based Pi distro): APT packages, EEPROM/bootloader firmware, Snap, user-level Python pip packages, global npm packages, and the `locate` database — then reports whether a reboot is needed.

---

## Usage

```console
chmod +x Total_Update_RaspberryPi.sh
sudo bash Total_Update_RaspberryPi.sh
```

Must be run as root; the script checks `$EUID` itself and refuses to continue otherwise.

Prerequisites:

- Root privileges (`sudo`)
- `apt`/`apt-get` (Raspberry Pi OS / Debian base)
- Optional tools, auto-detected with `command -v` and skipped (not installed) if absent: `rpi-eeprom-update`, `snap`, `pip3`, `npm`, `updatedb` (from `mlocate`/`plocate`)
- `/etc/os-release` for OS name/version detection and `/proc/device-tree/model` for Pi model detection (both optional — the script warns but continues if either is missing)

---

## What the Script Does

### Step 0 – Root check and setup
Exits with an error if `$EUID -ne 0`. Initializes `REBOOT_NEEDED=false` and `START_TIME`. Reads `/etc/os-release` (if present) for `OS_NAME`/`OS_VERSION`, and reads `/proc/device-tree/model` (if present) to print the Pi hardware model, e.g. "Raspberry Pi 4 Model B Rev 1.4". Warns (non-fatal) if `/proc/device-tree/model` is missing, since that means the script can't confirm it's actually running on a Pi. Runs under `set -euo pipefail`, so most unguarded command failures abort the whole script.

### Step 1/7 – APT package update
`apt-get update -qq`, then `DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y` with `--force-confdef`/`--force-confold` (keeps existing config files on conflicts, no prompts), then `apt-get install -f -y -qq` to fix any broken dependencies. On Raspberry Pi OS this also pulls in kernel/`raspberrypi-kernel` updates via the normal APT path.

### Step 2/7 – APT cleanup
`apt-get autoremove -y -qq` followed by `apt-get autoclean -qq`.

### Step 3/7 – Firmware (rpi-eeprom-update)
If `rpi-eeprom-update` is present: runs it to check for EEPROM/bootloader updates, looking for "UPDATE AVAILABLE" in the output; if found, runs `rpi-eeprom-update -a` to stage the update and sets `REBOOT_NEEDED=true` (EEPROM updates only take effect after a reboot). Skipped with a warning if the tool isn't installed. This replaces the `fwupd`-based firmware step used in the Ubuntu variants, since Raspberry Pi boot/EEPROM firmware is managed separately from `fwupd`/LVFS.

### Step 4/7 – Snap
If `snap` is present: `snap refresh` updates all snaps, then the script lists disabled snap revisions (`snap list --all | awk '/disabled/{print $1, $3}'`) and removes each with `snap remove "$snapname" --revision="$revision"`. Skipped with a warning if `snap` isn't installed — the warning notes this is normal, since Snap isn't part of a stock Raspberry Pi OS install.

### Step 5/7 – Python pip (user-level)
Resolves the real (non-root) user via `logname`. If found and `pip3` is present: upgrades pip itself for that user (`sudo -u "$REAL_USER" pip3 install --upgrade pip --quiet`), then lists outdated pip packages (`pip3 list --outdated --format=freeze`, excluding editable `-e` installs) and upgrades them via `xargs -r sudo -u "$REAL_USER" pip3 install --upgrade --quiet`.

### Step 6/7 – npm global packages
If `npm` is present: `npm install -g npm --silent` (self-update), then `npm update -g --silent`.

### Step 7/7 – updatedb
If `updatedb` is present: runs it to refresh the `locate` database; otherwise warns to install `mlocate` or `plocate`.

### Step 8 – Reboot check & summary
Checks for `/var/run/reboot-required` and sets `REBOOT_NEEDED=true` if it exists (in addition to any EEPROM update from step 3). Computes elapsed time from `START_TIME`, prints a completion summary with duration and timestamp, and — if a reboot is needed — recommends running `sudo reboot`.

---

## Notes

- This is the Raspberry Pi counterpart of [Total_Update_Ubuntu.md](Total_Update_Ubuntu.md) / [Total_Update_Ubuntu_Server.md](Total_Update_Ubuntu_Server.md): Flatpak is dropped (not standard on Pi), and the `fwupd` firmware step is replaced with `rpi-eeprom-update` for EEPROM/bootloader firmware, which is how firmware updates actually work on Pi hardware.
- Output and internal comments are in Danish ("Opdaterer", "Fjerner", "Kør: sudo reboot", etc.), matching the rest of this folder's `Total_Update_*` scripts.
- `set -euo pipefail` is active: the core APT steps (update, full-upgrade, install -f, autoremove, autoclean) are **not** individually guarded and will halt the entire script on failure. The optional steps (rpi-eeprom-update, Snap, pip, npm) are wrapped with `|| true` / `|| warn ...` so they degrade gracefully instead of aborting.
- Destructive/risky operations, all run non-interactively with `-y`/`-a` (no confirmation prompt): `apt-get full-upgrade -y`, `apt-get autoremove -y` (can remove packages), `snap remove ... --revision=...`, and `rpi-eeprom-update -a` (flashes bootloader/EEPROM firmware — a bad flash or power loss mid-update can require re-flashing via `rpiboot`/a second Pi).
- Must be run as root; enforced explicitly at the top via an `$EUID` check.
- Hardcoded paths: `/etc/os-release`, `/proc/device-tree/model`, `/var/run/reboot-required`.
- Broadly safe to re-run: apt/snap/pip/npm update commands are idempotent no-ops when already current, snap revision cleanup only targets already-disabled revisions, and `rpi-eeprom-update` only stages a new image when one is actually available.
