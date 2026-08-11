# Play2 Script

A variant of `Play.sh`: for every `.JPG`/`.JPEG` file it reads the camera model and creation date via `exiftool`, then copies **every file sharing the same base filename** — across `.JPG`, `.JPEG`, `.MOV`, `.HEIC`, `.MP4`, and `.CR2` — into a `YYYY-MM-DD/CameraModel/` folder. Unlike `Play.sh`, which only copies the JPG itself, `Play2.sh` bundles a photo together with any paired video/RAW/HEIC sidecar files that share its name.

---

## Usage

```console
chmod +x Play2.sh
bash Play2.sh
```

Run it from the folder containing the JPG/JPEG photos, alongside any paired `.MOV`/`.HEIC`/`.MP4`/`.CR2` files that share the same base filename.

Prerequisites:

- `exiftool` must be installed.

---

## What the Script Does

### Step 1 – Iterate over JPG/JPEG files
`for filename in *.JPG *.JPEG`. The `shopt -s nocaseglob` line is present but **commented out**, so — unlike `Play.sh`, where it is active — this loop is case-sensitive and only matches literal `.JPG`/`.JPEG` extensions.

### Step 2 – Skip unmatched glob
`[ -e "$filename" ] || continue` skips the iteration if the glob didn't expand (e.g. no JPG/JPEG files present). `Play.sh` does not have this guard.

### Step 3 – Derive the base filename
`baseFilename=$(basename "$filename" .JPG)` then `basename "$baseFilename" .JPEG` strips a trailing `.JPG` or `.JPEG`, leaving the name with no extension.

### Step 4 – Extract camera model
`exiftool -b -n -s -M -EXIF:Model "$filename"`, stripped of whitespace with `tr -d '[:space:]'`, then sanitized with `sed 's/[^a-zA-Z1-9]/_/g'` — any character that is not a letter or the digits 1–9 becomes an underscore.

### Step 5 – Extract creation date
`exiftool -b -n -s -M -EXIF:createdate "$filename" | cut -d' ' -f1` takes just the date portion (before the first space).

### Step 6 – Skip on missing metadata
If `cameraModel` or `creationDate` is empty, prints `Warning: Could not extract metadata from $filename` and continues to the next file.

### Step 7 – Create the target directory
`targetDir="${creationDate}/${cameraModel}"`, created with `mkdir -p`.

### Step 8 – Copy every sibling file with the same base name
For each extension in `JPG JPEG MOV HEIC MP4 CR2`, if `"${baseFilename}.${ext}"` exists, it is copied (`cp`, not moved) into `$targetDir`, printing a success or error message per file.

---

## Notes

- Files are always **copied**, never moved — originals stay in place, for every one of the six extensions handled.
- **Sanitizing regex differs from `Play.sh`:** `Play.sh` uses `[^a-zA-Z0-9]` (keeps all digits, including `0`), while `Play2.sh` uses `[^a-zA-Z1-9]` — the digit `0` is **not** in the keep-set and gets replaced with `_`. This looks like it may be an unintentional typo carried over from `Play.sh`, but it is exactly what the code does.
- Adds the `[ -e "$filename" ] || continue` guard that `Play.sh` lacks, so `Play2.sh` won't error out when the directory has no matching JPG/JPEG files.
- No delete or move step — re-running the script simply re-copies matching files into the same target folders (`cp` silently overwrites), so it is safe to re-run, though not incremental.
- Does not further sort output by file type into `ORG`/`MOV`/`CR2`/etc. subfolders the way `Sort_photos_Types.sh` / `Sort_Total.sh` do — everything for a given date/camera lands together in one folder.
- Comments and output messages are in English.
