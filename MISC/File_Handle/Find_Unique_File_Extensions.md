# Find Unique File Extensions

This script recursively lists every file under the current directory, strips each path down to the text after the last dot using `sed`, and prints the sorted, deduplicated list of resulting values.

---

## Usage

```console
chmod +x Find_Unique_File_Extensions.sh
bash Find_Unique_File_Extensions.sh
```

Run it from the directory tree you want to scan.

Prerequisites:

- Standard `find`, `sed`, and `sort` — all part of a normal Linux base install (findutils, GNU sed, GNU coreutils).
- Read access to the directory tree being scanned.

---

## What the Script Does

### Step 1 – Enumerate all files
`find . -type f` recursively lists every regular file under the current directory as a full relative path (e.g. `./photos/img.JPG`).

### Step 2 – Strip everything up to the last dot
Each path is piped through `sed -e 's/.*\.//'`. The greedy pattern `.*\.` consumes everything up to and including the *last* dot on the line, leaving only the text after it (in the typical case, the file extension).

### Step 3 – Sort and deduplicate
`sort -u` sorts the remaining lines alphabetically and removes duplicates, so the final output is the set of unique values found in Step 2, printed to stdout.

---

## Notes

- For a file path that contains **no dot at all**, the `sed` substitution has nothing to match, so the entire original path is passed through unchanged and appears mixed into the "extensions" list — the script does not filter these out.
- The substitution operates on the whole path string, not just the basename, so a dot inside a *directory* name (e.g. `./v1.2-backup/notes`) can also be picked up as the "extension" if it happens to be the last dot in the line, even though the file itself has none.
- Extensions are compared case-sensitively, so `jpg` and `JPG` are reported as two distinct entries.
- Read-only: the script never modifies the filesystem, so it is safe to re-run at any time.
- No hardcoded paths — it always operates on the current working directory.
