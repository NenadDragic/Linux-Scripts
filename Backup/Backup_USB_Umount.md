# Backup USB Umount

Safely unmounts the backup USB drive and then ejects it, identified by partition UUID, from `/mnt/usb/Backup`. This is the counterpart to `Backup_USB_Mount.sh`, which performs the reverse operation.

---

## Usage

```console
chmod +x Backup_USB_Umount.sh
./Backup_USB_Umount.sh
```

The script calls `sudo` internally for both `umount` and `eject`, so it can be invoked without prefixing `sudo` as long as the running user has sudo rights (expect a password prompt). Run it before physically disconnecting the backup USB drive, once any backup jobs writing to it (`Backup_USB.sh`, `Backup_SD_USB.sh`) have finished.

Prerequisites:

- Sudo privileges for the invoking user (for `umount` and `eject`).
- The backup USB partition (matched by hardcoded UUID) must currently be mounted at `MOUNT_POINT`.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `MOUNT_POINT` | `/mnt/usb/Backup` | Directory the drive is mounted at and will be unmounted from |
| `UUID` | a hardcoded partition UUID (see script) | Identifies the specific backup USB partition to eject, independent of its `/dev/sdX` device name |

---

## What the Script Does

### Step 1 – Unmount the Drive
Runs `sudo umount "$MOUNT_POINT"`.

### Step 2 – Eject the Drive
Only if the unmount succeeded (chained with `&&`), runs `sudo eject "/dev/disk/by-uuid/$UUID"` to spin down/release the device.

### Step 3 – Confirm
Only if both prior steps succeeded, prints `USB sikkert fjernet` ("USB safely removed").

---

## Notes

- **No explicit error handling:** if `umount` fails (drive busy, already unmounted, wrong mount point) or `eject` fails, the script relies entirely on that command's own stderr output — there is no custom error message, exit code check, or retry logic, and the confirmation message is simply skipped since every step is chained with `&&`.
- **Not idempotent in a harmless way:** running it again after the drive is already unmounted will just cause `umount` to fail with its own "not mounted" message and the chain stops there (no eject attempted) — this is safe, just a no-op.
- Hardcoded values: the mount point path and a specific USB partition UUID tied to one physical drive — the UUID must be kept in sync with `Backup_USB_Mount.sh` and updated in both scripts if that drive is ever replaced.
- The confirmation message (`"USB sikkert fjernet"`) is in Danish, unlike `Backup_USB_Mount.sh`'s English `Mounted OK: ...` message — inconsistent language between the two counterpart scripts.
- **History note:** this script was empty (0 bytes) earlier in this repo's history and has since been filled in with the logic described above, along with a UUID update — if you're comparing against an older checkout or cached copy of this doc, disregard any version describing it as non-functional.
