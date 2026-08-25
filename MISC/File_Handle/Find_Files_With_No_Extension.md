# Find Files With No Extension

This script prints a banner and then recursively searches the current directory tree for regular files whose basename contains no dot at all, printing their paths.

---

## Usage

```console
chmod +x Find_Files_With_No_Extension.sh
bash Find_Files_With_No_Extension.sh
```

Run it from the directory tree you want to scan.

Prerequisites:

- Standard `find` (GNU findutils) — no other tools required.
- Read access to the directory tree being scanned.

---

## What the Script Does

### Step 1 – Print banner
The script echoes `Files without extensions:`.

### Step 2 – Search for dot-less filenames
It then runs:

```bash
find . -type f ! -name '*.*'
```

`find` recurses from `.`, `-type f` restricts results to regular files, and `-name '*.*'` matches any basename that contains at least one dot. The leading `!` negates that test, so only files whose basename has **zero** dots anywhere in it are printed.

---

## Notes

- `-name` only inspects the dot character, not "extension" semantics: a hidden dotfile such as `.bashrc`, or a multi-dot name such as `archive.tar.gz`, is treated as having an extension and is excluded, even though `.bashrc` has no real filename extension.
- Read-only: the script never modifies the filesystem, so it is safe to re-run at any time.
- No hardcoded paths — it always operates on the current working directory.
