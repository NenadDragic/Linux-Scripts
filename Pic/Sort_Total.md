# Sort Total Script

Combines `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` into one run: first converts any DNG files to JPGs (by extracting the embedded full-size preview), then sorts photos/videos by date and camera model, and finally sorts each resulting folder's files by type.

---

## Usage

```console
chmod +x Sort_Total.sh
bash Sort_Total.sh
```

Run it from the folder containing your image and video files, with `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` present in the same folder as `Sort_Total.sh`.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `SLET_DNG_EFTER` | `0` | Set to `1` to delete the DNG original after a successful conversion instead of keeping it |

---

## What the Script Does

### Step 0 – Convert DNG to JPG (embedded preview)
For every `.dng`/`.DNG` file in the current folder:

- Checks that `exiftool` is installed, and installs it via `apt` if missing (`libimage-exiftool-perl`).
- Extracts the full-size JPEG preview embedded in the DNG with `exiftool -b -PreviewImage` into `<name>_DNG.jpg` (e.g. `IMG_0020_DNG.jpg`). The unique name matters because file numbers are reused across phones/years, so `IMG_0020.DNG` must not become — or overwrite — a different photo's `IMG_0020.JPG`. For Apple ProRAW files from an iPhone this is a full-resolution JPEG (e.g. 8064x6048, Display P3) that already carries date, camera model and GPS, so the date sorting in Step 1 works on it. The file's modification time is set to `DateTimeOriginal`.
- This replaces the earlier `darktable-cli` development: darktable 4.2 (Debian 12) cannot decode ProRAW (`Unsupported predictor mode: 7`), and `darktable-cli` also holds a database lock (`data.db.lock`) that made concurrent or stuck runs fail.
- A DNG without an embedded preview is reported and left untouched.
- Re-runs are safe: if `<name>_DNG.jpg` already exists, conversion is skipped.

### Step 1 – Sort by Date and Camera Model
Runs `Sort_photos_Dates.sh` unchanged. Produces a folder structure:

```
YYYY-MM-DD/
└── CameraModel/
    ├── IMG_1234.JPG
    ├── IMG_1234.CR2
    └── IMG_1234.MOV
```

### Step 1b – Place DNG Originals
Each kept DNG original is moved into a `DNG/` subfolder next to the JPG it was converted to. The script locates the sorted `<name>_DNG.JPG` by filename, so the DNG always lands in the exact same `YYYY-MM-DD/CameraModel/` folder regardless of how `Sort_photos_Dates.sh` names its folders. If the sorted JPG cannot be found (e.g. conversion failed), the DNG is left in place with a warning.

### Step 1c – Remove the Temporary Suffix
Now that every file is in its final `YYYY-MM-DD/CameraModel/` folder, the temporary unique names are shortened again: `IMG_0020_DNG.JPG` → `IMG_0020.JPG` (and `IMG_0020_HEIC.JPG` → `IMG_0020.JPG`). This runs before Step 2, so the copy in `ORG/` gets the clean name too. If `IMG_0020.JPG` already exists in that folder (e.g. a JPG of the same shot), nothing is overwritten: the suffixed name is kept and a warning is printed.

### Step 2 – Sort Each Folder by File Type
For every `YYYY-MM-DD/CameraModel/` folder created in Step 1, runs `Sort_photos_Types.sh` inside it, producing:

```
YYYY-MM-DD/
└── CameraModel/
    ├── ORG/
    │   ├── IMG_1234.JPG
    │   └── IMG_5678.JPG   <- converted from DNG
    ├── DNG/
    │   └── IMG_5678.DNG   <- original
    ├── CR2/
    │   └── IMG_1234.CR2
    └── MOV/
        └── IMG_1234.MOV
```

### Step 3 – Clean Up
Deletes any empty `YYYY-MM-DD` or `CameraModel` directories left behind.

### Progress, Timing and Summary
Step 0 and Step 2 print `[done/total | elapsed | ETA]` for every DNG file / date-camera folder, every step prints `Step N done in HH:MM:SS`, and `Sort_photos_Dates.sh` prints its own progress and summary (see `Sort_photos_Dates.md`). At the very end a summary shows: DNG converted/skipped/failed, DNG originals placed, JPG suffixes removed, folders sorted by type and the total run time.

---

## Notes

- Reuses `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` as-is — any future changes to those scripts apply automatically to `Sort_Total.sh`. The DNG handling lives entirely in `Sort_Total.sh`.
- `Sort_photos_Types.sh` checks/installs `libheif-examples` on every folder it processes; harmless once installed, but noisy on the first run across many folders.
- Files are paired by base name **and** capture date, and are never overwritten — see `Sort_photos_Dates.md`. Different photos that share a file number end up in their own date folders, and the temporary `_DNG`/`_HEIC` suffix is removed again in Step 1c (it only stays when the clean name is already taken in that folder).
- Same copy/move behaviour as the two source scripts: Step 1 moves the JPG/JPEG/PNG and all related files (MOV/MP4/CR2/HEIC) into the date/camera folder; Step 2 then copies (not moves) JPG/JPEG into `ORG` as a backup of the originals and moves MOV/MP4/CR2/HEIC into their type folders. Converted DNG→JPGs are treated as normal JPGs.
- If two shoots contain files with the same base name (e.g. two different `IMG_0001.DNG`), Step 1b places the DNG next to the first matching JPG it finds — rare with camera numbering, but worth knowing.
- **Qubes/template note:** if this runs in an AppVM, apt installs do not persist across reboots. Install `libimage-exiftool-perl` once in the `debian-13-xfce` template; the script will then skip the install step.
- If `Sort_photos_Dates.sh` is later extended to handle DNG itself, Step 1b will simply skip files that have already been moved.
