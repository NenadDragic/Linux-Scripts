# TMP files - Find

This script finds all files in the `/volume1/Dragic` directory that end with the `.tmp` extension.

## Command

```bash
find /volume1/Dragic -name "*.tmp" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.tmp"` | Matches files with the `.tmp` extension |
| `-type f` | Ensures only regular files are matched, not directories |

## Usage

```bash
bash "TMP files - Find.sh"
```

Replace `/volume1/Dragic` with the actual directory path if necessary.
