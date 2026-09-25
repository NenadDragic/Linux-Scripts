# WD Drive

Mounts, shows the status of, and unmounts the LUKS-encrypted WD Elements USB backup drive (the same drive `WD_Backup.sh` writes to). The drive is found by its LUKS UUID, so it does not matter whether it shows up as `sdb` or `sdc`, or whether the desktop or the script unlocked it. It covers this one drive only.

---

## Usage

```console
chmod +x WD-Drive.sh
sudo ./WD-Drive.sh mount              # unlock and mount on /mnt/backup
     ./WD-Drive.sh status             # show state (more detail with sudo)
sudo ./WD-Drive.sh umount [--sluk]    # unmount and lock; --sluk also powers off the USB drive
```

Commands:

| Command | Meaning |
|---|---|
| `mount`, `monter`, `montér` | Unlock the LUKS container (if needed) and mount the filesystem on `MOUNTPOINT`. Needs root |
| `status` | Show whether the drive is connected, unlocked and mounted, plus free space. With root it also lists processes using the drive and the SMART health status |
| `umount`, `unmount`, `afmonter`, `afmontér` | Unmount every mount of the drive, then lock it. Needs root |
| `-h`, `--hjaelp`, `--hjælp`, `help` | Print the help text (no command also prints it, but exits `1`) |

Option (for `umount` only):

| Option | Meaning |
|---|---|
| `--sluk`, `--power-off` | After locking, power the drive off with `udisksctl power-off` so it can be unplugged right away |

Prerequisites:

- `cryptsetup`, `mount`/`umount`, `lsblk`, `findmnt` and `df` are used without being checked.
- `fuser` (package `psmisc`) is optional — used to show which processes keep the drive busy.
- `smartctl` (`smartmontools`) is optional — used by `status` when run as root.
- `udisksctl` (`udisks2`) is only needed for `--sluk`; if missing the script warns and the drive is still locked and safe to remove.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `LUKS_UUID` | `f77e78ad-3189-4e36-b912-82e42359049e` | UUID of the LUKS partition; used to find the drive via `/dev/disk/by-uuid/` |
| `FS_UUID` | `8154462f-dffc-481a-b95f-37f048a3236a` | UUID of the filesystem inside the container; used to find all existing mounts |
| `MAPNAME` | `wd-backup` | Device-mapper name used when the script unlocks the drive itself |
| `KEYFILE` | `/root/wd-backup.key` | Key file used if it exists and is readable; otherwise `cryptsetup` asks for the passphrase |
| `MOUNTPOINT` | `/mnt/backup` | Where `mount` mounts the drive |
| `MOUNT_OPTS` | `noatime` | Mount options |

---

## What the Script Does

### `mount`
1. Requires root and a connected drive (`/dev/disk/by-uuid/<LUKS_UUID>` must exist).
2. If the filesystem is already mounted anywhere (e.g. under `/media/...` by the desktop), reports that and stops.
3. Uses an already open LUKS mapping if there is one (desktop's `luks-<uuid>` or `wd-backup`); otherwise runs `cryptsetup open` with the key file, or with a passphrase prompt.
4. Creates `MOUNTPOINT` and mounts the mapper there. If the mount point is already occupied, or the mount fails, a container the script opened itself is closed again, so the drive is not left half open.
5. Prints size, used, available and percentage.

### `status`
Prints a small table: connected (with device and size), unlocked (with mapper), mounted (every mount point, filesystem type, rw/ro), and space used. As root it adds the processes using the mount and the SMART health result (`smartctl -d sat`, which may not be readable through the USB bridge). Without root it only hints that sudo gives more.

Exit codes for `status`, usable from other scripts:

| Code | Meaning |
|---|---|
| `0` | Mounted |
| `1` | Connected, but not mounted (locked, or unlocked without a mount) |
| `3` | Not connected |

### `umount`
1. Requires root. If the drive is not connected, reports that and exits `0`.
2. Runs `sync`, then unmounts every mount of the filesystem, last-mounted first. If one cannot be unmounted, it lists the processes using it (via `fuser`) and exits `1`.
3. Closes the LUKS mapping, whatever it is called.
4. With `--sluk`, powers the drive off via `udisksctl`.

---

## Notes

- **Exit codes.** `mount`/`umount` exit `0` on success (or nothing to do) and `1` on errors; an unknown command or option exits `2`. `status` uses the codes above.
- **Doesn't touch data.** The script never writes to the drive; it only unlocks, mounts, unmounts and locks.
- **Same drive as `WD_Backup.sh`.** Both scripts use the same UUIDs, mapper name and key file, so one can be used after the other. `WD_Backup.sh` can unlock and mount the drive by itself; use this script when you want to inspect or work on the drive manually.
- **Hardcoded, machine-specific values.** Both UUIDs and the key file path belong to one specific drive and machine (`Debian-Laptop`); update them at the top of the script if the drive is replaced.
- **Language.** Console output and comments are in Danish.
- No dependency on any other script in the folder.
