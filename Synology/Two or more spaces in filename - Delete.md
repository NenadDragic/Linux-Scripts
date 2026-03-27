# Two or more spaces in filename - Delete

> **Note:** Despite the "Delete" name, this script **renames** files — it does not delete them.

Finds all files under `/volume1/Dragic` that have two or more consecutive spaces in their names and renames them by replacing the double spaces with a single space.

## Command

```bash
find /volume1/Dragic/ -name '*  *' -exec sh -c 'mv "$1" "${1//  / }"' find-sh {} \;
```

## Options

| Option | Description |
| ------ | ----------- |
| `-name '*  *'` | Match filenames containing two consecutive spaces (single quotes prevent shell wildcard expansion) |
| `-exec sh -c '...' find-sh {} \;` | Execute a shell command on each matched file |
| `mv "$1" "${1//  / }"` | Rename the file by replacing double spaces with a single space |

## Usage

```bash
bash "Two or more spaces in filename - Delete.sh"
```

Replace `/volume1/Dragic` with the target directory path if needed.
