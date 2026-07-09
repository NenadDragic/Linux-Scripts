#!/bin/bash

# Runs Sort_photos_Dates.sh (sort into YYYY-MM-DD/CameraModel/), then runs
# Sort_photos_Types.sh inside every resulting YYYY-MM-DD/CameraModel/ folder
# (sort into ORG/MOV/MP4/CR2/HEIC).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Step 1: Sorting by date and camera model ==="
bash "$SCRIPT_DIR/Sort_photos_Dates.sh"

echo "=== Step 2: Sorting file types within each date/camera folder ==="
find . -mindepth 2 -maxdepth 2 -type d -print0 | while IFS= read -r -d '' dir; do
    echo "--- $dir ---"
    (cd "$dir" && bash "$SCRIPT_DIR/Sort_photos_Types.sh")
done

echo "=== Cleaning up empty date directories ==="
find . -mindepth 1 -type d -empty -delete

echo "All tasks completed."
