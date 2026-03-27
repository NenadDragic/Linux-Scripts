# Tilde files - Find

Finds all files under `/volume1/Dragic` that start with a tilde (`~`) and have any extension.

## Command

```bash
find /volume1/Dragic -name "~*.*" -type f
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name "~*.*"` | Match filenames starting with `~` and containing an extension |
| `-type f` | Match regular files only (excludes directories) |

## Usage

```bash
bash "Tilde files - Find.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
