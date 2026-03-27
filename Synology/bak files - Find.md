# bak files - Find

Finds all `.bak` files under `/volume1/Dragic`.

## Command

```bash
find /volume1/Dragic -name "*.bak" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*.bak"` | Match filenames ending with `.bak` |
| `-type f` | Match regular files only (excludes directories) |

## Usage

```bash
bash "bak files - Find.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
