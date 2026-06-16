# Bak files - Delete

This script deletes all files in the `/volume1/Dragic` directory that end with the `.bak` extension.

## Command

```bash
find /volume1/Dragic -name "*.bak" -type f -delete 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.bak"` | Matches files with the `.bak` extension |
| `-type f` | Ensures only regular files are matched, not directories |
| `-delete` | Deletes each matched file |
| `2>/dev/null` | Suppresses error messages by redirecting stderr to `/dev/null` |

## Usage

```bash
bash "Bak files - Delete.sh"
```

Replace `/volume1/Dragic` with the actual target directory path if necessary.
