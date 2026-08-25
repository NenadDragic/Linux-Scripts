# Play

This script organizes JPG/JPEG photos in the current directory into a `YYYY-MM-DD/CameraModel` folder structure, reading the creation date and camera model from each photo's EXIF metadata.

---

## Usage

```console
chmod +x Play.sh
bash Play.sh
```

Run it from the folder containing the JPG/JPEG photos you want to organize.

Prerequisites:

- `exiftool` must already be installed — the script does not check for or install it.
- Write access to the current directory (to create the date/camera-model subfolders and copy files into them).

---

## What the Script Does

### Step 1 – Enable case-insensitive matching and find candidate files

`shopt -s nocaseglob` is set so that `*.JPG` and `*.JPEG` match regardless of case (e.g. `.jpg`, `.Jpeg`). The script then loops over every matching file, skipping the loop body entirely if no files are found (`[ -e "$filename" ] || continue`).

### Step 2 – Extract EXIF metadata

For each file, the script runs `exiftool` twice: once to read `EXIF:Model` (the camera model) and once to read `EXIF:createdate`. The camera model is stripped of whitespace and any non-alphanumeric character is replaced with an underscore. The creation date/time string is cut down to just the date portion (`YYYY-MM-DD`) using `cut -d' ' -f1`.

### Step 3 – Skip files with missing metadata

If either the camera model or the creation date came back empty, the script prints `Warning: Could not extract metadata from $filename` and moves on to the next file without copying anything.

### Step 4 – Build and create the target directory

The target path is assembled as `${creationDate}/${cameraModel}` (e.g. `2024-01-15/Canon_EOS_R6`) and created with `mkdir -p`, so nested and pre-existing directories are handled without error.

### Step 5 – Copy the file into place

The file is copied (not moved) into the target directory under its original filename via `cp`. On success the script prints `Successfully copied ... to ...`; on failure it prints `Error: Failed to copy $filename`. The source file is left untouched in the original directory either way.

### Step 6 – Restore shell globbing behavior

After the loop finishes, `shopt -u nocaseglob` resets case-insensitive globbing back to bash's default so it doesn't affect anything run afterward in the same shell.

---

## Notes

- Non-destructive: files are copied, never moved or deleted, so the originals always remain in the source folder.
- Only `*.JPG` and `*.JPEG` files are considered; other image formats (PNG, HEIC, CR2, etc.) are ignored entirely.
- Files without a readable `EXIF:Model` or `EXIF:createdate` tag are silently skipped (aside from the printed warning) — no fallback naming is used.
- Re-running the script will simply re-copy files into the same date/camera-model folders, overwriting any file already there with the same name (default `cp` behavior).
- The camera-model folder name is derived purely from EXIF data with non-alphanumeric characters collapsed to underscores, so two different camera models that sanitize to the same string would land in the same folder.
- All paths are relative to the current working directory — the script must be run from inside the folder containing the photos.
