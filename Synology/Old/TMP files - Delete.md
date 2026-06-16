# TMP files - Delete

This script deletes all files in the `/volume1/Dragic` directory that end with the `.tmp` extension.

## Command

```bash
find /volume1/Dragic -name "*.tmp" -type f -delete 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.tmp"` | Matches files with the `.tmp` extension |
| `-type f` | Ensures only regular files are matched, not directories |
| `-delete` | Deletes each matched file |
| `2>/dev/null` | Suppresses error messages by redirecting stderr to `/dev/null` |

## Usage

```bash
bash "TMP files - Delete.sh"
```

Replace `/volume1/Dragic` with the actual directory path if necessary.
