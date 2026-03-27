# Disk Used size - Dragic

Shows disk usage for `/volume1/Dragic/` up to 1 directory level deep, then prints the total.

## Command

```bash
(du -ha --max-depth=1 --exclude='#recycle' --exclude='@eaDir' --exclude='Log' /volume1/Dragic/ 2>/dev/null | grep -vE "total$|/volume1/Dragic/$" | sort -k2); du -shc /volume1/Dragic/ 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-h` | Human-readable sizes (KB, MB, GB) |
| `-a` | Show size for all files, not just directories |
| `--max-depth=1` | Limit output to 1 directory level |
| `--exclude='#recycle'` | Skip Synology recycle bin |
| `--exclude='@eaDir'` | Skip Synology extended attributes directory |
| `--exclude='Log'` | Skip Log directory |
| `2>/dev/null` | Suppress error messages |
| `grep -vE "total$|/volume1/Dragic/$"` | Remove the summary total and root path lines |
| `sort -k2` | Sort output by path (second column) |
| `-shc` (second `du`) | Print a grand total summary |

## Usage

```bash
bash "Disk Used size - Dragic.sh"
```

Replace `/volume1/Dragic/` with the target directory path if needed.
