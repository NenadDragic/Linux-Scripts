# Find Files With Big Letters In File Name Beginning

This script prints a banner and then runs `find . -type f -regex './[A-Z]*'`. Because GNU `find`'s `-regex` matches against the *entire path*, not just the basename, and the pattern contains no wildcard for a path separator, this only matches plain files sitting directly in the current directory (never inside a subdirectory) whose entire filename consists exclusively of uppercase letters `A`–`Z` — no digits, punctuation, extension, or lowercase letters anywhere in the name.

---

## Usage

```console
chmod +x Find_Files_With_Big_Letters_In_FileName_Begginig.sh
bash Find_Files_With_Big_Letters_In_FileName_Begginig.sh
```

Run it from the directory you want to inspect.

Prerequisites:

- Standard `find` (GNU findutils) — no other tools required.
- Read access to the directory being scanned.

---

## What the Script Does

### Step 1 – Print banner
The script echoes: `Finding files in the current directory and its subdirectories whose filenames begin with a capital letter...`

### Step 2 – Restricted regex search
It then runs:

```bash
find . -type f -regex './[A-Z]*'
```

`-type f` restricts results to regular files. `-regex './[A-Z]*'` requires the *whole* path string to match `./` followed by zero or more characters in `[A-Z]`. Since `find`'s regex matching is not anchored to the basename, and the pattern has no `.*` or `/` to account for subdirectories, only files whose full path is `./<UPPERCASE-ONLY-NAME>` satisfy it — i.e. top-level files whose name has no lowercase letters, digits, dots, or other characters.

---

## Notes

- The printed banner is misleading relative to the actual behavior: despite claiming to search "the current directory and its subdirectories" for names that "begin with a capital letter," the regex in fact (a) never descends into subdirectories, and (b) requires *every* character in the filename to be an uppercase letter, not just the first one. A file like `Makefile` or `Dockerfile` (starts with a capital letter but contains lowercase letters) will **not** match; a file like `LICENSE` or `README` (all uppercase, no extension) will.
- Read-only: the script never modifies the filesystem, so it is safe to re-run at any time.
- No hardcoded paths — it always operates on the current working directory.
