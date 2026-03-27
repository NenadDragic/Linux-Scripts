# tmp files - Delete

Deletes all `.tmp` files under `/volume1/Dragic`.

## Command

```bash
find /volume1/Dragic -name "*.tmp" -type f -delete 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.tmp"` | Match filenames ending with `.tmp` |
| `-type f` | Match regular files only (excludes directories) |
| `-delete` | Delete each matched file |
| `2>/dev/null` | Suppress error messages |

## Usage

```bash
bash "tmp files - Delete.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
