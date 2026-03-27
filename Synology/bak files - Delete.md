# bak files - Delete

Deletes all `.bak` files under `/volume1/Dragic`.

## Command

```bash
find /volume1/Dragic -name "*.bak" -type f -delete 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.bak"` | Match filenames ending with `.bak` |
| `-type f` | Match regular files only (excludes directories) |
| `-delete` | Delete each matched file |
| `2>/dev/null` | Suppress error messages |

## Usage

```bash
bash "bak files - Delete.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
