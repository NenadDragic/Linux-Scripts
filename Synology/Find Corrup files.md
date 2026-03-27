# Find Corrupt files

Finds all files under `/volume1/Dragic` that contain `CORRUPT` in their filename.

## Command

```bash
find /volume1/Dragic -name "*CORRUPT*.*" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "*CORRUPT*.*"` | Match filenames containing `CORRUPT` and having an extension |
| `-type f` | Match regular files only (excludes directories) |

## Usage

```bash
bash "Find Corrup files.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
