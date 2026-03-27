# Tilde files - Delete

Deletes all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension.

## Command

```bash
find /volume1/Dragic -name "~*.*" -type f -delete 2>/dev/null
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "~*.*"` | Match filenames starting with `~` and containing an extension |
| `-type f` | Match regular files only (excludes directories) |
| `-delete` | Delete each matched file |
| `2>/dev/null` | Suppress error messages |

## Usage

```bash
bash "Tilde files - Delete.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
