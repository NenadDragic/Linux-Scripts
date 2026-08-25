# Total Update

This script updates and cleans up package state on a Debian/APT-based Linux system, then rebuilds the `locate` file database. It must be run as root.

---

## Usage

```console
chmod +x Total_Update.sh
sudo bash Total_Update.sh
```

Run it as root on the Debian-based system you want to update; it does not take any arguments and does not depend on the current working directory.

Prerequisites:

- A Debian/APT-based distribution (`apt` must be available).
- `updatedb` (from the `mlocate`/`plocate` package) must be installed for the last step to succeed.
- Must be run as root — the script checks `whoami` and exits otherwise.

---

## What the Script Does

### Step 1 – Verify root privileges
The script compares `$(whoami)` to `root`. If the current user is not root, it prints `Please run as root.\n` and exits without doing anything.

### Step 2 – Update the APT package index
Runs `apt -y update` to refresh the local package index from configured repositories.

### Step 3 – Upgrade installed packages
Runs `apt -y upgrade` to upgrade all installed packages to their latest available versions without removing packages.

### Step 4 – Full/dist upgrade
Runs `apt -y dist-upgrade`, which additionally handles changed dependencies, potentially installing or removing packages as needed.

### Step 5 – Remove unneeded packages
Runs `apt autoremove` (no `-y`) to remove packages that were automatically installed as dependencies and are no longer needed.

### Step 6 – Clean the local package cache
Runs `apt autoclean` to delete cached `.deb` files for packages that can no longer be downloaded.

### Step 7 – Rebuild the locate database
Runs `updatedb` to refresh the file-path database used by the `locate` command.

---

## Notes

- **Destructive/system-wide impact**: `apt upgrade`/`dist-upgrade`/`autoremove` can install, remove, or replace packages across the entire system; `dist-upgrade` in particular may remove packages to resolve dependency changes. There is no dry-run or confirmation step (all use `-y` except `autoremove`, which will still prompt interactively if it needs confirmation since `-y` was not passed to it).
- **Possible pending reboot**: if the upgrade includes a kernel, glibc, or similar core package, the script does not detect this or prompt for/perform a reboot — a reboot may still be required afterward for changes to fully take effect.
- The `echo "\nUpdating APT packages...\n"` call does not use `echo -e`, so the `\n` sequences print literally rather than as newlines.
- No error handling: if any `apt` command fails (e.g. network issue, held package, lock held by another process), the script continues to the next command regardless.
- Assumes a Debian/Ubuntu-family distribution; will fail on non-APT systems.
