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
chmod +x sort_photos.sh
```

**2.** Copy the script into the folder containing your image and video files and run it:

```console
bash sort_photos.sh
```

> **Note:** The script must be run with `bash`, not `sh`, as it uses bash-specific commands (`shopt`).

The script will process all supported files in the current directory and sort them into subfolders.

---

## What the Script Does

The script runs in six steps:

### Step 1 – Check Dependencies
Checks whether `libheif-examples` is installed. If not, it is installed automatically via `apt-get`.

### Step 2 – Normalize File Extensions to Uppercase
All supported files are renamed so their extension is uppercase (e.g. `.jpg` → `.JPG`, `.png` → `.PNG`). Only the following file types are processed — all other files in the folder are left untouched:

```
JPG  JPEG  PNG  MOV  HEIC  MP4  CR2
```

### Step 3 – Convert HEIC to JPEG
All `.HEIC` files are converted to `.JPG` at maximum quality (`-q 100`) using `heif-convert`. A second normalization pass runs afterwards, as `heif-convert` outputs lowercase `.jpg` extensions.

### Step 4 – Sort JPG/JPEG/PNG + Related Files into Date/Camera Folder Structure
For each `.JPG`, `.JPEG`, or `.PNG` image file:
- The camera model and capture date are read from EXIF metadata using `exiftool`
- A folder structure is created in the format `YYYY-MM-DD/CameraModel/`
- The image and all related files sharing the same base name (MOV, HEIC, MP4, CR2, etc.) are copied into the new folder

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

### Step 5 – Sort Standalone MOV, MP4, and PNG Files
Handles files that have no matching `.JPG`/`.JPEG` anchor. For each standalone MOV, MP4, or PNG:
- Files already handled in Step 4 are skipped
- **PNG files** – camera model and date are read from EXIF metadata (`EXIF:Model`, `EXIF:createdate`)
- **MOV/MP4 files** – camera model is read from `QuickTime:Model`, with a fallback to `QuickTime:Make` if `Model` is empty. Date is read from `QuickTime:CreateDate`
- The file is copied into the same `YYYY-MM-DD/CameraModel/` folder structure

**Example:**
```
2024-03-15/
└── Apple_iPhone_14_Pro/
    ├── IMG_7971.MOV
    └── IMG_7972.PNG
```

### Step 6 – Remove Empty Directories
Any empty directories left in the current folder are automatically deleted.

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
- The script uses `cp` (copy), not `mv` (move), so original files remain in place until you choose to delete them
- The script must be run with `bash`, not `sh`
