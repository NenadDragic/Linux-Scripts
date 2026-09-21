# Sort Photos Script

A Bash script that normalizes, converts, and sorts image and video files into a folder structure based on EXIF/QuickTime metadata. Supports the following file formats: **JPG, JPEG, PNG, MOV, HEIC, MP4, and CR2**.

---

## Requirements

| Tool | Purpose |
|------|---------|
| `exiftool` | Reads EXIF and QuickTime metadata from image and video files |
| `libheif-examples` | Converts HEIC files to JPEG (auto-installed if missing) |

Install `exiftool` manually if not already present:

```console
sudo apt-get install libimage-exiftool-perl
```

---

## Usage

**1.** Make the script executable:

```console
chmod +x Sort_photos_Dates.sh
```

**2.** Copy the script into the folder containing your image and video files and run it:

```console
bash Sort_photos_Dates.sh
```

> **Note:** The script must be run with `bash`, not `sh`, as it uses bash-specific commands (`shopt`).

The script will process all supported files in the current directory and sort them into subfolders.

---

## What the Script Does

The script runs in six steps:

### Step 1 – Check Dependencies
Checks whether `libheif-examples` is installed (via `dpkg`) and whether `exiftool` is available (via `command -v`). Any missing packages are collected and installed in a single `apt-get install` call.

### Step 2 – Normalize File Extensions to Uppercase
All supported files are renamed so their extension is uppercase (e.g. `.jpg` → `.JPG`, `.png` → `.PNG`). Only the following file types are processed — all other files in the folder are left untouched:

```
JPG  JPEG  PNG  MOV  HEIC  MP4  CR2
```

### Step 3 – Convert HEIC to JPEG
All `.HEIC` files are converted to `.JPG` at maximum quality (`-q 100`) using `heif-convert`. A second normalization pass runs afterwards, as `heif-convert` outputs lowercase `.jpg` extensions.

File numbers are often reused (e.g. `IMG_0020.HEIC` from 2024 and `IMG_0020.JPG` from 2026 are different photos), so an existing JPG/JPEG with the same name is **never overwritten**:
- same capture date → same photo, the existing JPG is reused and no conversion happens
- different capture date → the converted file gets the unique name `<name>_HEIC.JPG`

### Step 4 – Sort JPG/JPEG/PNG + Related Files into Date/Camera Folder Structure
For each `.JPG`, `.JPEG`, or `.PNG` image file:
- The camera model and capture date are read from EXIF metadata using `exiftool`
- A folder structure is created in the format `YYYY-MM-DD/CameraModel/`
- The image is moved into the new folder
- Related files sharing the same base name (MOV, HEIC, MP4, CR2, etc.) are moved along with it **only if their own capture date is the same day**. The same file number on another day is a different photo and is left for its own anchor / Step 5. Videos are compared on `Keys:CreationDate` (local time, matches a Live Photo's HEIC), falling back to `QuickTime:CreateDate` (UTC)
- `<name>_DNG` and `<name>_HEIC` anchors (created by `Sort_Total.sh` / Step 3) look for related files named `<name>`

**Example output structure:**
```
2024-03-15/
└── Canon_EOS_R5/
    ├── IMG_1234.JPG
    ├── IMG_1234.CR2
    └── IMG_1234.MOV
2024-01-08/
└── Apple_iPhone_14_Pro/
    ├── IMG_5678.JPG
    ├── IMG_5678.PNG
    └── IMG_5678.HEIC
```

### Step 5 – Sort Remaining MOV and MP4 Files
Handles every MOV/MP4 still in the folder, i.e. those that were not paired with a photo of the same capture date in Step 4 (no photo with that name, or a photo of the same number from another day). PNG files are not handled here — every PNG is already its own anchor in Step 4, since Step 4's file glob includes PNG. For each remaining MOV or MP4:
- Camera model is read from `QuickTime:Model`, with a fallback to `QuickTime:Make` if `Model` is empty. Date is read from `QuickTime:CreateDate`
- The file is moved into the same `YYYY-MM-DD/CameraModel/` folder structure

**Example:**
```
2024-03-15/
└── Apple_iPhone_14_Pro/
    └── IMG_7971.MOV
```

### Step 6 – Remove Empty Directories
Any empty directories left in the current folder are automatically deleted.

### Progress and Summary
Steps 3, 4 and 5 print a progress tag in front of each file: `[123/2805 | 00:03:12 | ETA 00:12:00]` = files handled / total, time spent in this step, and estimated time left. The ETA is based on the average speed so far. When the script finishes it prints a summary: HEIC converted/reused/failed, photos and videos sorted, files moved in total, files without metadata, not-moved files and total time.

`heif-convert`'s own `decoding image... x%` output is hidden; it is only shown if a conversion fails (counted as `failed`).

---

## Key Commands Explained

| Command | Description |
|---------|-------------|
| `dpkg -l \| grep -q libheif-examples` | Checks if a package is installed without printing output |
| `tr 'a-z' 'A-Z'` | Converts text to uppercase |
| `exiftool -b -n -s -M -EXIF:Model` | Reads the camera model from image EXIF metadata (JPG, PNG) |
| `exiftool -b -n -s -M -EXIF:createdate` | Reads the capture date from image EXIF metadata (JPG, PNG) |
| `exiftool -b -n -s -M -QuickTime:Model` | Reads the camera model from video QuickTime metadata |
| `exiftool -b -n -s -M -QuickTime:Make` | Fallback: reads the camera make from video QuickTime metadata |
| `exiftool -b -n -s -M -QuickTime:CreateDate` | Reads the capture date from video QuickTime metadata |
| `cut -d' ' -f1 \| tr ':' '-'` | Extracts the date portion and formats it as `YYYY-MM-DD` |
| `sed 's/[^a-zA-Z0-9]/_/g'` | Replaces all special characters in the camera name with `_` |
| `mkdir -p` | Creates the folder structure including any missing parent folders |
| `shopt -s nocaseglob` | Makes wildcard (`*`) matching case-insensitive |
| `find . -mindepth 1 -type d -empty -delete` | Deletes empty folders without touching the root folder |

---

## Notes

- Files that cannot be matched to a `.JPG`/`.JPEG` anchor are handled independently in Step 5, as long as their metadata contains a camera model and capture date
- If EXIF or QuickTime metadata (camera model or date) is missing from a file, the file is **skipped** with a warning
- The script uses `mv` (move), not `cp` (copy), so files are removed from the source folder once sorted. Files that are skipped (missing metadata) stay in place
- A file is never overwritten: if a file with the same name already exists in the target folder, the source file is left in place with a warning
- Pairing checks the date of every related file with an extra `exiftool` call, so large folders take longer than before
- The script must be run with `bash`, not `sh`
