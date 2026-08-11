# Backup USB Mount

Creates the backup mount point (if missing) and mounts the backup USB drive, identified by partition UUID, at `/mnt/usb/Backup`, printing a confirmation message on success. This is the counterpart to `Backup_USB_Umount.sh`, which reverses the operation.

---

## Usage

```console
chmod +x Backup_USB_Mount.sh
./Backup_USB_Mount.sh
```

The script calls `sudo` internally for both `mkdir` and `mount`, so it can be invoked without prefixing `sudo` as long as the running user has sudo rights (expect a password prompt). Run it whenever the physical backup USB drive has been connected but not yet mounted — for example, before running `Backup_USB.sh` or `Backup_SD_USB.sh`.

Prerequisites:

- Sudo privileges for the invoking user (for `mkdir` and `mount`).
- The specific backup USB partition (matched by hardcoded UUID) must be physically connected.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `MOUNT_POINT` | `/mnt/usb/Backup` | Directory the drive is mounted onto |
| `UUID` | a hardcoded partition UUID (see script) | Identifies the specific backup USB partition to mount, independent of its `/dev/sdX` device name |

---

## What the Script Does

### Step 1 – Ensure the mount point exists
Runs `sudo mkdir -p "$MOUNT_POINT"` to create `/mnt/usb/Backup` if it doesn't already exist.

### Step 2 – Mount the drive by UUID
Runs `sudo mount UUID="$UUID" "$MOUNT_POINT"`. Only if that succeeds (the two commands are chained with `&&`) does it print `Mounted OK: /mnt/usb/Backup`.

---

## Notes

- **No explicit error handling:** if `mount` fails (drive not connected, already mounted, wrong UUID, filesystem error), the script relies entirely on `mount`'s own stderr output — there is no custom error message, exit code check, or retry logic, and the success message is simply skipped.
- **Idempotent/safe to re-run:** running it again while the drive is already mounted will just cause `mount` to fail with its own "already mounted" message; no data is affected either way. Mounting itself is not destructive to the drive's contents.
- Hardcoded values: the mount point path and a specific USB partition UUID tied to one physical drive — the UUID must be updated in the script if that drive is ever replaced.
- Unlike the rsync backup scripts in this folder, this script has no Danish comments — its only output string, `Mounted OK: ...`, is in English.
