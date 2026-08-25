# Pic Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Sorting/Organizing

| Script | Doc | Summary |
|---|---|---|
| `Sort_Total.sh` | [Sort_Total.md](Sort_Total.md) | Orchestrates the full pipeline: converts DNG files to best-quality JPGs, then runs `Sort_photos_Dates.sh` to sort by date/camera model, then runs `Sort_photos_Types.sh` on each resulting folder to split files by type. |
| `Sort_photos_Dates.sh` | [Sort_photos_Dates.md](Sort_photos_Dates.md) | Normalizes file extensions to uppercase, converts HEIC to JPEG, then sorts JPG/JPEG/PNG images — plus any related MOV/HEIC/MP4/CR2 files sharing the same base name — into `YYYY-MM-DD/CameraModel/` folders using EXIF/QuickTime metadata. |
| `Sort_photos_Types.sh` | [Sort_photos_Types.md](Sort_photos_Types.md) | Organizes files in the current folder into `ORG`/`MOV`/`MP4`/`CR2`/`HEIC` subfolders by extension; HEIC-to-JPG conversion code exists but is commented out, so HEIC files are moved as-is. |
| `Play.sh` | [Play.md](Play.md) | Organizes photos into `YYYY-MM-DD/CameraModel/` folders based on EXIF creation date and camera model, copying (not moving) each JPG/JPEG so originals stay in place. |
| `Play2.sh` | [Play2.md](Play2.md) | A variant of `Play.sh` that, for each JPG/JPEG, also copies every sibling file sharing the same base filename (MOV, HEIC, MP4, CR2) into the same date/camera folder, bundling paired video/RAW/HEIC files together with the photo. |

## Format Conversion

| Script | Doc | Summary |
|---|---|---|
| `Convert.sh` | [Convert.md](Convert.md) | Renames every file and directory in the current folder to uppercase, converts any resulting `.HEIC` files to quality-100 JPEGs with `heif-convert`, then runs a second uppercase-rename pass — a general folder-normalize-and-convert utility, not limited to photos. |
| `Update_PVT_Folders.sh` | [Update_PVT_Folders.md](Update_PVT_Folders.md) | Recursively finds `*.PVT` files in the current directory tree and invokes `Convert.sh` (via a hardcoded path) once per match found. |

## Diagnostics/Maintenance

| Script | Doc | Summary |
|---|---|---|
| `Camera-Model.sh` | [Camera-Model.md](Camera-Model.md) | Reads every `.JPG`/`.JPEG` file in the current directory and prints filename, camera model, and creation date from EXIF metadata via `exiftool`; a read-only diagnostic listing that never copies, moves, renames, or deletes files. |
| `LibHEIF_Update.sh` | [LibHEIF_Update.md](LibHEIF_Update.md) | Removes any distro-packaged `libheif1`/`libheif-dev`, then builds and installs the latest tagged `libheif` release from source via `git`/`cmake`/`make`; a standalone dependency installer for HEIC support used indirectly by `Convert.sh` and `Sort_Total.sh`. |

---

## Notes

- `Sort_Total.sh` is not a standalone implementation — it calls `Sort_photos_Dates.sh` and `Sort_photos_Types.sh` directly (they must be present in the same folder), so any future change to those two scripts automatically applies to `Sort_Total.sh` as well.
- `Play2.sh` is an explicit variant of `Play.sh`: same EXIF-driven date/camera sorting, but it additionally bundles paired MOV/HEIC/MP4/CR2 files with each JPG, adds a guard for "no matching files" that `Play.sh` lacks, and uses a slightly different (and likely unintentionally different) character-sanitizing regex.
- Required external tools recur across the folder: `exiftool` (most scripts), `heif-convert`/`libheif-examples` (HEIC conversion), `darktable-cli` (DNG conversion in `Sort_Total.sh`), and the Perl `rename` utility (`Convert.sh`).
- Destructive/unsafe-by-design scripts: `Convert.sh` renames every file and subdirectory in the working directory to uppercase with no filter and no collision handling (can silently overwrite); `LibHEIF_Update.sh` purges the existing `libheif` packages before the source rebuild even starts.
- Hardcoded path: `Update_PVT_Folders.sh` points at `/home/nenad/git/Linux-Scripts/MISC/Pic/Convert.sh`, tying it to one user's home directory and clone location.
- `Convert.sh` ignores any argument passed to it — `Update_PVT_Folders.sh` passes the matched `.PVT` file path, but `Convert.sh` always processes the entire current working directory regardless.
- Comments and console output across this folder's scripts are documented as English.
