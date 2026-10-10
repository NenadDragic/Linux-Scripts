# Sort_photos_Types

This script sorts mixed media files in the current directory into type-specific subfolders (`ORG`, `MOV`, `MP4`, `CR2`, `HEIC`), then removes any resulting empty directories.

---

## Usage

```console
chmod +x Sort_photos_Types.sh
bash Sort_photos_Types.sh
```

Run it from the folder containing the mixed media files you want to sort.

Prerequisites:

- Only standard tools (`mkdir`, `mv`, `cp`, `find`); nothing is installed and there is no dependency check.
- No `sudo`: run it as the user who owns the files.
- Write access to the current directory (to create subfolders and move/copy files).

---

## What the Script Does

### Step 1 – Create destination folders

`mkdir -p ORG MOV MP4 CR2 HEIC` creates all five destination folders in the current directory (no error if they already exist).

### Step 2 – (Disabled) uppercase renaming and HEIC conversion

The script contains commented-out lines for renaming all filenames to uppercase (`rename 'y/a-z/A-Z/' *`) and converting `.HEIC` files to `.JPG` via `heif-convert`. Neither runs — they are left in the file as inactive reference code.

### Step 3 – Move video/RAW/HEIC files into their folders

`mv -t MOV *.MOV`, `mv -t MP4 *.MP4`, `mv -t CR2 *.CR2`, and `mv -t HEIC *.HEIC` move matching files out of the current directory and into their respective subfolders. Matching is case-sensitive and only matches the exact uppercase extension shown.

### Step 4 – Copy JPEG files into `ORG`

`cp -t ORG *.JPG *.JPEG` copies (does not move) matching files into the `ORG` folder; the originals remain in the current directory.

### Step 5 – Delete empty directories

`find . -type d -empty -delete` removes any directory under the current path that ended up empty — including any of the five folders just created if no matching files existed for that type.

### Step 6 – Print completion message

The script prints `All tasks completed.` once all the above steps have run.

---

## Notes

- Destructive for videos/RAW/HEIC: `.MOV`, `.MP4`, `.CR2`, and `.HEIC` files are **moved** out of the current directory (originals no longer exist there). JPG/JPEG files are only **copied** into `ORG`, so their originals remain in the current directory (not moved into any folder).
- Matching is case-sensitive and only covers the exact extensions `*.MOV`, `*.MP4`, `*.CR2`, `*.HEIC`, `*.JPG`, `*.JPEG` — lowercase variants (e.g. `.mov`, `.jpg`) will not be matched or moved/copied.
- The earlier `libheif-examples` install step has been removed from the script. The HEIC-to-JPG conversion via `heif-convert` that it supported is still present only as commented-out code.
- No `set -e` is used, so if a glob like `*.MOV` matches nothing, bash passes the literal string `*.MOV` to `mv`, which will print its own "No such file or directory" error and the script continues regardless.
- Because folders are created up front with `mkdir -p` and then swept for emptiness at the end, any of the five folders (including `ORG`) will be deleted again if no files of that type existed in the source directory.
- `mv -t` and `cp -t` are GNU coreutils options.
