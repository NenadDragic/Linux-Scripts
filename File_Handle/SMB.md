# SMB Mount/Unmount Script

Mounts or unmounts one of three predefined CIFS/SMB network shares (`DashCam`, `Dragic`, `NetBackup`) from a fixed remote server to a fixed local mount point under `/mnt`.

---

## Usage

```console
chmod +x SMB.sh
sudo ./SMB.sh <ShareName> <mount|umount>
```

Examples:

```console
sudo ./SMB.sh DashCam mount
sudo ./SMB.sh dragic umount
```

Prerequisites:

- Must be run as root (or via `sudo`) — the script itself does not check for root, but `mount`/`umount` will fail without sufficient privileges.
- `cifs-utils` (provides `mount.cifs`) must be installed for `mount -t cifs` to work.
- A credentials file must already exist at the hardcoded path for the chosen share (see Configuration) containing the SMB username/password.
- The remote CIFS server must be reachable at the hardcoded IP address.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `REMOTE_SERVER` | `192.168.1.50` | IP address of the SMB/CIFS server |
| `MOUNT_BASE_DIR` | `/mnt` | Parent directory under which each share is mounted |
| `LOCAL_UID` | `1000` | UID assigned to mounted files (`uid=` mount option) |
| `LOCAL_GID` | `1000` | GID assigned to mounted files (`gid=` mount option) |
| `CIFS_VERSION` | `3.0` | SMB protocol version passed as `vers=` |

Per-share settings (hardcoded in a `case` statement, not meant to be edited per run):

| Share name (case-insensitive) | `REAL_NAME` | Credentials file |
|---|---|---|
| `dashcam` | `DashCam` | `/home/nenad/.smbcredentials_DashCam` |
| `dragic` | `Dragic` | `/home/nenad/.smbcredentials_Dragic` |
| `netbackup` | `NetBackup` | `/home/nenad/.smbcredentials_NetBackup` |

---

## What the Script Does

### Step 1 – Parse arguments
Reads `SHARE_NAME` (`$1`) and `ACTION` (`$2`, lowercased via `${2,,}`). If either is empty, prints a usage message listing the available shares and exits with status 1.

### Step 2 – Resolve the share
Matches the lowercased `SHARE_NAME` against a `case` statement for `dashcam`, `dragic`, or `netbackup`, setting `REAL_NAME` and `CRED_FILE` accordingly. Any other value prints an error ("Ugyldigt share-navn") and exits with status 1.

### Step 3 – Build paths
Constructs `LOCAL_MOUNT_POINT="${MOUNT_BASE_DIR}/${REAL_NAME}"` and `REMOTE_PATH="//${REMOTE_SERVER}/${REAL_NAME}"`.

### Step 4 – Mount
If `ACTION` is `mount`: creates the mount point with `mkdir -p`, builds the mount options string (`credentials=...,uid=...,gid=...,vers=3.0`), and runs `mount -t cifs "$REMOTE_PATH" "$LOCAL_MOUNT_POINT" -o "$MOUNT_OPTIONS"`. Reports success or failure based on the exit code.

### Step 5 – Unmount
If `ACTION` is `umount` or `unmount`: runs `umount "$LOCAL_MOUNT_POINT"` and reports success or failure based on the exit code.

### Step 6 – Invalid action
Any other `ACTION` value prints "Ugyldig handling" and exits with status 1.

---

## Notes

- Not destructive to file contents: the script only mounts/unmounts a network share; it does not read, write, move, or delete files itself.
- Idempotent-ish: mounting an already-mounted share or unmounting an already-unmounted one will simply produce a `mount`/`umount` error message via the exit-code check — the script does not pre-check current mount state.
- Hardcoded paths and values: remote server IP (`192.168.1.50`), mount base (`/mnt`), UID/GID (`1000`), CIFS version (`3.0`), and per-share credential file paths under `/home/nenad/` — the username in those paths (`nenad`) is specific to the original machine. Only the file *paths* are hardcoded here; no credential contents are stored in the script itself.
- `EXTRA_OPTS` is defined per-share but is always an empty string in all three cases, so it currently has no effect (leaves a trailing comma in the constructed mount options string).
- Requires the `cifs-utils` package (`mount.cifs`) to be installed; the script does not check for or install it.
- Output messages, including emoji (checkmarks/crosses), are in Danish.
