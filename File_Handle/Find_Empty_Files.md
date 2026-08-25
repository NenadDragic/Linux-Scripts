# Find Empty Files

This script searches the current directory and all of its subdirectories for regular files that are exactly zero bytes in size, and prints their paths to standard output.

---

## Usage

```console
chmod +x Find_Empty_Files.sh
bash Find_Empty_Files.sh
```

Run it from the directory tree you want to scan — the search always starts at `.` (the current working directory) and recurses into every subdirectory.

Prerequisites:

- Standard `find` (GNU findutils) — no other tools required.
- Read access to the directory tree being scanned.

---

## What the Script Does

### Step 1 – Recursive search for zero-byte files
The script runs a single command:

```bash
find . -type f -empty
```

`find` walks the current directory tree, `-type f` restricts matches to regular files (directories, symlinks, etc. are excluded), and `-empty` further restricts matches to files whose size is zero bytes. Every matching path is printed to stdout, one per line, in the order `find` encounters them.

---

## Notes

- Read-only: the script never modifies, moves, or deletes anything, so it is always safe to re-run.
- Only regular files are considered — empty directories and empty special files (sockets, devices, etc.) are not reported because of `-type f`.
- No exclude patterns are applied (e.g. `.git`, `node_modules`), so on large trees every file is visited; performance is bound by disk I/O.
- No hardcoded paths — it always operates on the current working directory.
