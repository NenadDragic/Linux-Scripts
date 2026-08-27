# Web Stat DL

Downloads the Web-Status HTML reports from the NAS to a local `Documents` folder via `rsync`.

---

## Usage

```console
chmod +x Web_Stat_DL.sh
bash Web_Stat_DL.sh
```

Run it from any working directory — source and destination paths are absolute.

Prerequisites:

- SSH access (key-based, since the script is non-interactive) to `ElBosso@192.168.1.50`.
- `rsync` installed locally and on the remote host.
- The parent of `/home/nenad/Documents/Web-Status` must exist — `rsync` creates the destination directory itself if it's missing, as long as its parent path is already there.

---

## What the Script Does

### Step 1 – Sync reports down
Runs a single command:

```bash
rsync -av ElBosso@192.168.1.50:/volume1/Dragic/Rap/Web_Status/ /home/nenad/Documents/Web-Status
```

`-a` (archive mode) preserves permissions, timestamps, and symlinks and recurses into subdirectories; `-v` prints each file transferred. The trailing slash on the source path means the *contents* of the remote `Web_Status/` folder are copied into the destination, not a nested `Web_Status` subfolder inside it.

---

## Notes

- Not destructive: in this default mode `rsync` only adds/updates files at the destination; it never deletes anything, either locally or remotely (no `--delete` flag is used).
- Safe to re-run: `rsync`'s delta-transfer only copies files that are new or have changed since the last run.
- Second hop of a two-stage pipeline: `Web-Stat.sh` in the `Devices` repo (`NAS/Synology/`) copies these same reports from a remote host down to the NAS at `/volume1/Dragic/Rap/Web_Status/`; this script then pulls them from the NAS down to this machine.
- Hardcoded values: remote user (`ElBosso` — a different user than the `admina` account used by the NAS-side scripts), remote host IP (`192.168.1.50`, the same Synology NAS referenced by `SMB.sh` in this folder), and the local destination path (`/home/nenad/Documents/Web-Status`).
