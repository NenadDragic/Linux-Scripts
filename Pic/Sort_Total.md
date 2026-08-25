# Sort Total Script

Combines `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` into one run: first converts any DNG files to best-quality JPGs, then sorts photos/videos by date and camera model, and finally sorts each resulting folder's files by type.

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
| `JPEG_KVALITET` | `97` | JPEG quality for DNG conversion (95–97 is visually lossless) |
| `SLET_DNG_EFTER` | `0` | Set to `1` to delete the DNG original after a successful conversion instead of keeping it |

---

## What the Script Does

### Step 0 – Convert DNG to JPG (best quality)
For every `.dng`/`.DNG` file in the current folder:

- Checks that `darktable-cli` and `exiftool` are installed, and installs them via `apt` if missing (`darktable` and `libimage-exiftool-perl`). Skipped entirely when no DNG files are present.
- Performs a full RAW development with `darktable-cli` at full resolution and quality `JPEG_KVALITET`. `--library ':memory:'` is used so your normal darktable database is never touched.
- Copies all EXIF metadata (date, camera model, GPS, …) from the DNG into the JPG so the date sorting in Step 1 works on the converted files, and sets the file's modification time to `DateTimeOriginal`.
- Re-runs are safe: if a matching JPG already exists, conversion is skipped.

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
Each kept DNG original is moved into a `DNG/` subfolder next to the JPG it was converted to. The script locates the sorted JPG by filename, so the DNG always lands in the exact same `YYYY-MM-DD/CameraModel/` folder regardless of how `Sort_photos_Dates.sh` names its folders. If the sorted JPG cannot be found (e.g. conversion failed), the DNG is left in place with a warning.

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

---

## Notes

- Reuses `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` as-is — any future changes to those scripts apply automatically to `Sort_Total.sh`. The DNG handling lives entirely in `Sort_Total.sh`.
- `Sort_photos_Types.sh` checks/installs `libheif-examples` on every folder it processes; harmless once installed, but noisy on the first run across many folders.
- Same copy/move behaviour as the two source scripts: JPG/JPEG are copied (not moved) to `ORG`; MOV/MP4/CR2/HEIC are moved. Converted DNG→JPGs are treated as normal JPGs.
- If two shoots contain files with the same base name (e.g. two different `IMG_0001.DNG`), Step 1b places the DNG next to the first matching JPG it finds — rare with camera numbering, but worth knowing.
- **Qubes/template note:** if this runs in an AppVM, apt installs do not persist across reboots. Install `darktable` and `libimage-exiftool-perl` once in the `debian-13-xfce` template; the script will then skip the install step.
- If `Sort_photos_Dates.sh` is later extended to handle DNG itself, Step 1b will simply skip files that have already been moved.
