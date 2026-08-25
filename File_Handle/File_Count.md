# File Count Script

Counts how many files of each extension exist in the current directory tree and prints a sorted tally, from least to most common.

---

## Usage

```console
chmod +x File_Count.sh
bash File_Count.sh
```

Run it from the directory whose file extensions you want to count; the script always operates on the current working directory (`$(pwd)`) and takes no arguments.

Prerequisites:

- Standard `find`, `awk`, `sort`, and `uniq` utilities (present on virtually any Linux system).
- Read access to the current directory and its subdirectories.

---

## What the Script Does

### Step 1 – Resolve and validate the target folder
Sets `folder_path` to the current directory (`$(pwd)`) and checks with `[ ! -d "$folder_path" ]` that it exists, printing "Error: Folder not found!" and exiting with status 1 if not (in practice this check can never fail, since `pwd` always returns an existing directory).

### Step 2 – List all files recursively
Runs `find "$folder_path" -type f` to gather every regular file under the current directory into `files`.

### Step 3 – Extract and count extensions
Pipes the file list through `awk -F'.' '{print $NF}'` to take the text after the last dot in each full path, then `sort | uniq -c | sort -n` to count occurrences of each extension and sort the counts ascending (least common first).

### Step 4 – Print the result
Prints "File Extensions Count:" followed by the sorted count table.

---

## Notes

- Read-only/non-destructive: the script only reads file names, it never modifies, moves, or deletes anything. Safe to re-run at any time.
- Extension extraction is naive: because `awk -F'.'` splits on every `.` in the full path (not just the filename), files or directories with no `.` in their name produce the entire path as the "extension" rather than being grouped as extensionless. A path containing a `.` earlier (e.g. in a directory name) but not in the filename can also throw off the count.
- No filtering of hidden files/directories — `find` includes dotfiles and anything under hidden subdirectories.
- Output is in English.
- No configurable variables; the target directory is always the current one.
