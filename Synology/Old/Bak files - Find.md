# Bak files - Find

This script finds all files in the `/volume1/Dragic` directory that are named `*.bak`.

## Command

```bash
find /volume1/Dragic -name "*.bak" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.bak"` | Specifies the pattern to match the filenames |
| `-type f` | Ensures that only regular files (not directories) are matched |

## Usage

```bash
bash "Bak files - Find.sh"
```

Replace `/volume1/Dragic` with the actual directory path if necessary.
