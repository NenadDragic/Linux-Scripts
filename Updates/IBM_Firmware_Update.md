# IBM Firmware Update

This script checks for and applies device firmware updates on a Linux system using `fwupdmgr` (fwupd's command-line manager). It must be run as root, and it only checks for/applies updates — it does not enumerate connected devices despite the script's header comment.

---

## Usage

```console
chmod +x IBM_Firmware_Update.sh
sudo bash IBM_Firmware_Update.sh
```

Run it as root on the machine whose device firmware you want to check and update. It does not depend on any input files or working directory.

Prerequisites:

- `fwupdmgr` (from the `fwupd` package) must be installed.
- Must be run as root — the script checks `whoami` and exits otherwise.

---

## What the Script Does

### Step 1 – Verify root privileges
The script compares `$(whoami)` to `root`. If the current user is not root, it prints `Please run as root.\n` and exits without doing anything.

### Step 2 – Check for available firmware updates
It runs `fwupdmgr get-updates`, which queries fwupd for any firmware updates available for devices already known to the system.

### Step 3 – Apply firmware updates
It runs `fwupdmgr update`, which downloads and applies any updates found in Step 2 to the affected devices.

---

## Notes

- **Firmware flashing is irreversible/risky**: `fwupdmgr update` can flash device firmware (e.g. BIOS/UEFI, disk controllers, peripherals). A failed or interrupted flash can render a device unusable; some updates require a reboot to take effect, which the script does not perform or prompt for.
- The script's header comment ("Get Devices Firmware Information Script") and the code disagree: the script never runs `fwupdmgr get-devices` (which would just list devices) — it runs `fwupdmgr get-updates` followed by `fwupdmgr update`, which actually checks for and installs updates.
- The `echo "Please run as root.\n"` call does not use `echo -e`, so `\n` is printed literally instead of as a newline.
- No confirmation prompt is shown before updates are applied beyond whatever `fwupdmgr update` itself asks (fwupd may prompt per-device depending on version/policy).
