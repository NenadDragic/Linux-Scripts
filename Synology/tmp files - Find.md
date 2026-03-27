# tmp files - Find

Finds all `.tmp` files under `/volume1/Dragic`.

## Command

```bash
find /volume1/Dragic -name "*.tmp" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.tmp"` | Match filenames ending with `.tmp` |
| `-type f` | Match regular files only (excludes directories) |

## Usage

```bash
bash "tmp files - Find.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
