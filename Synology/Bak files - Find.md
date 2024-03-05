# Bak files - Find.sh

This script finds all files in the `/volume1/Dragic` directory that are named `*.bak`.

## How it works

The `find` command is used to search for files in the specified directory.

- The `-name "*.bak"` option specifies the pattern to match the filenames.
- The `-type f` option ensures that only regular files (not directories) are matched.

## Usage

Run this script to find all files in the `/volume1/Dragic` directory that are named `*.bak`.

Make sure to replace `/volume1/Dragic` with the actual directory path if necessary.

```shellscript
find /volume1/Dragic -name "*.bak" -type f