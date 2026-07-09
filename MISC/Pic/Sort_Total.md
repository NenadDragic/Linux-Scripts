# Sort Total Script

Combines `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` into one run: first sorts photos/videos by date and camera model, then sorts each resulting folder's files by type.

---

## Usage

```console
chmod +x Sort_Total.sh
bash Sort_Total.sh
```

Run it from the folder containing your image and video files, with `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` present in the same folder as `Sort_Total.sh`.

---

## What the Script Does

### Step 1 – Sort by Date and Camera Model
Runs `Sort_photos_Dates.sh` unchanged. Produces a folder structure:

```
YYYY-MM-DD/
└── CameraModel/
    ├── IMG_1234.JPG
    ├── IMG_1234.CR2
    └── IMG_1234.MOV
```

### Step 2 – Sort Each Folder by File Type
For every `YYYY-MM-DD/CameraModel/` folder created in Step 1, runs `Sort_photos_Types.sh` inside it, producing:

```
YYYY-MM-DD/
└── CameraModel/
    ├── ORG/
    │   └── IMG_1234.JPG
    ├── CR2/
    │   └── IMG_1234.CR2
    └── MOV/
        └── IMG_1234.MOV
```

### Step 3 – Clean Up
Deletes any empty `YYYY-MM-DD` or `CameraModel` directories left behind.

---

## Notes

- Reuses `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` as-is — any future changes to those scripts apply automatically to `Sort_Total.sh`.
- `Sort_photos_Types.sh` checks/installs `libheif-examples` on every folder it processes; harmless once installed, but noisy on the first run across many folders.
- Same copy/move behaviour as the two source scripts: JPG/JPEG are copied (not moved) to `ORG`; MOV/MP4/CR2/HEIC are moved.
