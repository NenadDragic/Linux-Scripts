# Search Low Extension

This script prints a banner naming the current working directory, recursively searches for files whose extension consists entirely of lowercase letters, and prints a completion footer.

---

## Usage

```console
chmod +x Search_Low_Extension.sh
bash Search_Low_Extension.sh
```

Run it from the directory tree you want to search — the banner reports `$(pwd)`, and the search itself is always rooted at `.`.

Prerequisites:

- Standard `find` (GNU findutils) with POSIX-extended regex support (`-regextype posix-extended`).
- Read access to the directory tree being scanned.

---

## What the Script Does

### Step 1 – Print opening banner
Echoes `Searching for files with lowercase letter extensions in $(pwd)` followed by a separator line of dashes.

### Step 2 – Regex search for lowercase-only extensions
Runs:

```bash
find . -type f -regextype posix-extended -regex '.*\.[a-z]+'
```

`-type f` restricts results to regular files. `-regex '.*\.[a-z]+'` requires the *entire* path to match: any characters (`.*`, which also absorbs directory separators, so subdirectories are included), followed by a dot, followed by one or more lowercase letters `a`–`z` and nothing after them. This effectively matches on the file's final extension, including multi-dot names (e.g. `archive.tar.gz` matches because it ends in `.gz`).

### Step 3 – Print completion footer
Prints a separator line and `Search complete`.

---

## Notes

- The extension must consist *only* of lowercase letters `a`–`z` — digits are not in the character class, so common extensions containing numbers (e.g. `.mp3`, `.h264`) do **not** match.
- Mixed-case or uppercase extensions (e.g. `.JPG`, `.Txt`) also do not match.
- Unlike `Find_Files_With_Big_Letters_In_FileName_Begginig.sh`, this script's regex correctly covers subdirectories, because `.*` absorbs path separators.
- Read-only: the script never modifies the filesystem, so it is safe to re-run at any time.
- No hardcoded paths — it always operates on the current working directory.
