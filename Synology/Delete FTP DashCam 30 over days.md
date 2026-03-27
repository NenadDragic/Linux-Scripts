# Delete FTP DashCam 30 over days

Deletes all files in `/volume1/DashCam` that were last modified more than 30 days ago, skipping the recycle bin.

## Command

```bash
find /volume1/DashCam -path "/volume1/DashCam/#recycle" -prune -o -type f -mtime +30 -print0 | xargs -0 rm -f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-path "/volume1/DashCam/#recycle" -prune` | Skip the Synology recycle bin directory |
| `-type f` | Match regular files only (excludes directories) |
| `-mtime +30` | Match files last modified more than 30 days ago |
| `-print0` | Output filenames null-delimited (safe for filenames with spaces) |
| `xargs -0 rm -f` | Delete each matched file (null-delimited input) |

## Usage

```bash
bash "Delete FTP DashCam 30 over days.sh"
```

Replace `/volume1/DashCam` with the target directory path if needed.
