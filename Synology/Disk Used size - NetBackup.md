# Disk Used size - NetBackup

Shows disk usage for `/volume1/NetBackup/` up to 2 directory levels deep, then prints the total.

## Command

```bash
(du -ha --max-depth=2 --exclude='#recycle' --exclude='@eaDir' --exclude='Log' /volume1/NetBackup/ 2>/dev/null | grep -vE "total$|/volume1/NetBackup/$" | sort -k2); du -shc /volume1/NetBackup/ 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-h` | Human-readable sizes (KB, MB, GB) |
| `-a` | Show size for all files, not just directories |
| `--max-depth=2` | Limit output to 2 directory levels |
| `--exclude='#recycle'` | Skip Synology recycle bin |
| `--exclude='@eaDir'` | Skip Synology extended attributes directory |
| `--exclude='Log'` | Skip Log directory |
| `2>/dev/null` | Suppress error messages |
| `grep -vE "total$|/volume1/NetBackup/$"` | Remove the summary total and root path lines |
| `sort -k2` | Sort output by path (second column) |
| `-shc` (second `du`) | Print a grand total summary |

## Usage

```bash
bash "Disk Used size - NetBackup.sh"
```

Replace `/volume1/NetBackup/` with the target directory path if needed.
