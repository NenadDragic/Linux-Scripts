# Update PVT Folders Script

Recursively searches the current directory tree for `*.PVT` files and, for each one it finds, invokes `Convert.sh` from a hardcoded absolute path.

---

## Usage

```console
chmod +x Update_PVT_Folders.sh
bash Update_PVT_Folders.sh
```

Run it from the top of a directory tree you want to scan for `.PVT` files.

Prerequisites:

- `Convert.sh` must exist and be executable at the hardcoded path below — the script exits with an error if it is missing or not executable.
- All prerequisites of `Convert.sh` itself (`heif-convert`, the `rename` utility — see `Convert.md`), since `Convert.sh` is what actually does the work.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `CONVERT_SCRIPT` | `/home/nenad/git/Linux-Scripts/MISC/Pic/Convert.sh` | Hardcoded absolute path to the `Convert.sh` script to invoke |

---

## What the Script Does

### Step 1 – Verify Convert.sh is available
Checks `[ -x "$CONVERT_SCRIPT" ]`; if `Convert.sh` doesn't exist or isn't executable at that exact path, prints an error and exits with status `1`.

### Step 2 – Find all .PVT files
Runs `find . -name "*.PVT" -type f`, recursively from the current directory, piping the results line-by-line into a `while IFS= read -r file` loop.

### Step 3 – Process each match
For every `.PVT` file found, echoes `Processing file: $file`, then runs `"$CONVERT_SCRIPT" "$file"`.

---

## Notes

- **Hardcoded path:** `CONVERT_SCRIPT` points to `/home/nenad/git/Linux-Scripts/MISC/Pic/Convert.sh`, tying this script to one user's home directory and clone location. It will fail the existence check on any other machine or path layout.
- **The `$file` argument passed to `Convert.sh` has no effect.** `Convert.sh`'s own logic (`for f in *`, `for f in *.HEIC`) never reads its positional parameters — it always processes every entry of whatever directory is current when it runs, not the folder containing the matched `.PVT` file, and not scoped to any single file.
- Neither this script nor `Convert.sh` ever `cd`s into the `.PVT` file's directory, so every invocation of `Convert.sh` acts on the same top-level working directory. If multiple `.PVT` files are found (including in subdirectories), `Convert.sh`'s uppercase-rename/HEIC-convert pass over that top-level directory is effectively repeated once per `.PVT` file found, rather than once per subdirectory containing one.
- Inherits all of `Convert.sh`'s destructive behavior — it renames every entry in the working directory to uppercase and converts `.HEIC` files to `.JPG` without deleting the source (see `Convert.md`).
- Safe/idempotent only to the extent `Convert.sh` is; re-running just re-triggers those effects once per matched `.PVT` file again.
- Comments and output messages are in English.
