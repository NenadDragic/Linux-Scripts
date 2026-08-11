# Camera Model Script

Reads every `.JPG`/`.JPEG` file in the current directory and prints a line showing its filename, camera model, and creation date, all pulled from EXIF metadata via `exiftool`. It is a read-only diagnostic listing — no files are copied, moved, renamed, or deleted.

---

## Usage

```console
chmod +x Camera-Model.sh
bash Camera-Model.sh
```

Run it from the folder containing the JPG/JPEG photos you want to inspect.

Prerequisites:

- `exiftool` must be installed.
- No write access is required — the script only reads files and prints to stdout.

---

## What the Script Does

### Step 1 – Iterate over JPG/JPEG files
Loops with `for filename in *.JPG *.JPEG`. `nocaseglob` is not enabled, so the glob is case-sensitive and only matches files whose extension is literally `.JPG` or `.JPEG` (lowercase `.jpg`/`.jpeg` are ignored).

### Step 2 – Extract metadata per file
For each match, runs three `exiftool -b -n -s -M …` calls and pipes each through `cut`:

- `-FileName` → `cut -d ':' -f 1` for the filename
- `-EXIF:Model` → `cut -d ':' -f 2` for the camera model
- `-EXIF:createdate` → `cut -d ':' -f 1-6` for the creation date/time

Because `-b` already strips the tag label from exiftool's output, these `cut` filters mostly pass the raw values straight through unchanged — they only trim something if the value itself happens to contain a colon.

### Step 3 – Print the result
Joins the three extracted values into `"$filename $cameraModel $creationDate"` and echoes one line per file.

---

## Notes

- Purely informational: this script never writes, moves, or deletes anything, so it is always safe to re-run.
- Only uppercase-extension files (`.JPG`, `.JPEG`) are matched, since `nocaseglob` is not set. `nullglob` is not set either, so if no matching files exist in the directory, the literal unexpanded patterns `*.JPG` / `*.JPEG` are passed straight to `exiftool`, which will report an error for a nonexistent file.
- There is no metadata validation or skip logic (unlike `Play.sh`/`Play2.sh`): if a matched file has no EXIF model or date, the corresponding field is simply printed blank.
- Comments and script logic are in English.
