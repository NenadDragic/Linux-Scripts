# Rename Command: Convert Filenames to Uppercase

This script (`Rename_Extensions_To_Big_Letter.sh`) renames every file in the **current directory** by transliterating all lowercase letters in the filename to uppercase.

## What the Script Does
The active command in the script is:

```bash
rename 'y/a-z/A-Z/' *
```

* `rename` : the Perl-based rename utility.
* `'y/a-z/A-Z/'` : a transliteration expression (like `tr`) that converts every lowercase letter `a-z` anywhere in the filename to its uppercase equivalent `A-Z`.
* `*` : the shell glob that expands to every file (and directory entry) in the current working directory.

Important details about the real behavior:
* It operates only on the **current directory** — it does **not** recurse into subdirectories, despite the introductory comment in the script mentioning "and its subdirectories."
* It uppercases the **entire filename**, not just the extension. For example, `report.txt` becomes `REPORT.TXT`, and `MyFile.txt` becomes `MYFILE.TXT`.
* There is **no dry-run / preview option** — running the script renames files immediately and unconditionally (subject to whatever the `rename` command matches via `*`).

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

```bash
chmod +x Rename_Extensions_To_Big_Letter.sh
```

2. Execute the script from inside the directory whose files you want to rename:

```bash
./Rename_Extensions_To_Big_Letter.sh
```

All files in the current directory will immediately be renamed with their names fully uppercased. There is no confirmation prompt and no way to preview the changes beforehand — back up or test in a scratch directory first if you are unsure.

## Notes
* The script contains a second, commented-out line:
  ```bash
  #find . -type f -iname '*.[a-z]*' -execdir rename -n 's/\.([a-z]+)/.\U$1/' {} \;
  ```
  This more conservative alternative would recurse into subdirectories, uppercase only the file **extension** (not the whole filename), and supports a `-n` dry-run flag (preview only, remove `-n` to apply). However, this line is currently commented out with `#` and is **not active** — it has no effect when the script runs.
