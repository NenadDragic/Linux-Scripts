#!/bin/bash

# ─────────────────────────────────────────────
# STEP 1: Check dependencies
# ─────────────────────────────────────────────
if ! dpkg -l | grep -q libheif-examples; then
    echo "libheif-examples is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y libheif-examples
fi

# ─────────────────────────────────────────────
# STEP 2: Normalize file extensions to uppercase
#         Only processes: JPG, JPEG, PNG, MOV, HEIC, MP4, CR2
# ─────────────────────────────────────────────
for f in *.jpg *.jpeg *.png *.mov *.heic *.mp4 *.cr2 \
          *.JPG *.JPEG *.PNG *.MOV *.HEIC *.MP4 *.CR2; do
    [ -e "$f" ] || continue
    ext="${f##*.}"
    base="${f%.*}"
    upper_ext=$(echo "$ext" | tr 'a-z' 'A-Z')
    if [ "$ext" != "$upper_ext" ]; then
        mv "$f" "${base}.${upper_ext}"
        echo "Renamed $f → ${base}.${upper_ext}"
    fi
done

# ─────────────────────────────────────────────
# STEP 3: Convert HEIC to JPEG
# ─────────────────────────────────────────────
for f in *.HEIC; do
    [ -e "$f" ] || continue
    heif-convert -q 100 "$f" "${f%.HEIC}.JPG"
    echo "Converted $f → ${f%.HEIC}.JPG"
done

# Normalize again – heif-convert outputs lowercase .jpg
for f in *.jpg *.jpeg; do
    [ -e "$f" ] || continue
    ext="${f##*.}"
    base="${f%.*}"
    upper_ext=$(echo "$ext" | tr 'a-z' 'A-Z')
    if [ "$ext" != "$upper_ext" ]; then
        mv "$f" "${base}.${upper_ext}"
        echo "Renamed $f → ${base}.${upper_ext}"
    fi
done

# ─────────────────────────────────────────────
# STEP 4: Sort all JPG/JPEG/PNG + related files
#         into date/camera folder structure
# ─────────────────────────────────────────────
shopt -s nocaseglob

for filename in *.JPG *.JPEG *.PNG; do
    [ -e "$filename" ] || continue

    # Strip extension to get base name
    baseFilename=$(basename "$filename" .JPG)
    baseFilename=$(basename "$baseFilename" .JPEG)
    baseFilename=$(basename "$baseFilename" .PNG)

    # Extract camera model from EXIF (replace non-alphanumeric with _)
    cameraModel=$(exiftool -b -n -s -M -EXIF:Model "$filename" \
        | tr -d '[:space:]' \
        | sed 's/[^a-zA-Z0-9]/_/g')

    # Extract creation date (YYYY-MM-DD)
    creationDate=$(exiftool -b -n -s -M -EXIF:createdate "$filename" \
        | cut -d' ' -f1 | tr ':' '-')

    if [ -z "$cameraModel" ] || [ -z "$creationDate" ]; then
        echo "Warning: Could not extract metadata from $filename – skipping"
        continue
    fi

    targetDir="${creationDate}/${cameraModel}"
    mkdir -p "$targetDir"

    # Copy JPG/JPEG/PNG + all related files with the same base name
    for ext in JPG JPEG PNG MOV HEIC MP4 CR2; do
        if [ -e "${baseFilename}.${ext}" ]; then
            if cp "${baseFilename}.${ext}" "$targetDir/"; then
                echo "Copied ${baseFilename}.${ext} → $targetDir/"
            else
                echo "Error: Failed to copy ${baseFilename}.${ext}"
            fi
        fi
    done
done

shopt -u nocaseglob

# ─────────────────────────────────────────────
# STEP 5: Sort standalone MOV, MP4 and PNG files
#         that have no matching JPG/JPEG anchor
# ─────────────────────────────────────────────
for filename in *.MOV *.MP4 *.PNG; do
    [ -e "$filename" ] || continue

    baseFilename=$(basename "$filename" .MOV)
    baseFilename=$(basename "$baseFilename" .MP4)
    baseFilename=$(basename "$baseFilename" .PNG)

    # Skip if a matching JPG/JPEG exists – already handled in Step 4
    if [ -e "${baseFilename}.JPG" ] || [ -e "${baseFilename}.JPEG" ]; then
        continue
    fi

    ext="${filename##*.}"

    if [ "$ext" = "PNG" ]; then
        # Read metadata from PNG via EXIF
        cameraModel=$(exiftool -b -n -s -M -EXIF:Model "$filename" \
            | tr -d '[:space:]' \
            | sed 's/[^a-zA-Z0-9]/_/g')
        creationDate=$(exiftool -b -n -s -M -EXIF:createdate "$filename" \
            | cut -d' ' -f1 | tr ':' '-')
    else
        # Read metadata from video via QuickTime
        cameraModel=$(exiftool -b -n -s -M -QuickTime:Model "$filename" \
            | tr -d '[:space:]' \
            | sed 's/[^a-zA-Z0-9]/_/g')

        # Fallback to Make if Model is empty
        if [ -z "$cameraModel" ]; then
            cameraModel=$(exiftool -b -n -s -M -QuickTime:Make "$filename" \
                | tr -d '[:space:]' \
                | sed 's/[^a-zA-Z0-9]/_/g')
        fi

        creationDate=$(exiftool -b -n -s -M -QuickTime:CreateDate "$filename" \
            | cut -d' ' -f1 | tr ':' '-')
    fi

    if [ -z "$cameraModel" ] || [ -z "$creationDate" ]; then
        echo "Warning: Could not extract metadata from $filename – skipping"
        continue
    fi

    targetDir="${creationDate}/${cameraModel}"
    mkdir -p "$targetDir"

    if cp "$filename" "$targetDir/"; then
        echo "Copied $filename → $targetDir/"
    else
        echo "Error: Failed to copy $filename"
    fi
done

# ─────────────────────────────────────────────
# STEP 6: Clean up empty directories
# ─────────────────────────────────────────────
find . -mindepth 1 -type d -empty -delete

echo "All tasks completed."
