# Thumbs.db files - Find

Finds all `Thumbs.db` files under `/volume1/Dragic`. These are Windows thumbnail cache files often left behind on network shares.

## Command

```bash
find /volume1/Dragic -name "Thumbs.db" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "Thumbs.db"` | Match files with the exact name `Thumbs.db` |
| `-type f` | Match regular files only (excludes directories) |

## Usage

```bash
bash "Thumbs.db files - Find.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
