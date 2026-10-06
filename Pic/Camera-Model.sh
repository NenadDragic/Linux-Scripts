#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools "exiftool:libimage-exiftool-perl"

for filename in *.JPG *.JPEG; do
    # Extract filename, camera model, and creation date from EXIF metadata
    filename=$(exiftool -b -n -s -M -FileName "$filename" | cut -d ':' -f 1)
    cameraModel=$(exiftool -b -n -s -M -EXIF:Model "$filename" | cut -d ':' -f 2)
    creationDate=$(exiftool -b -n -s -M -EXIF:createdate "$filename" | cut -d ':' -f 1-6)

    # Join the extracted values into a single string
    formattedOutput="$filename $cameraModel $creationDate"

    # Print the formatted output
    echo "$formattedOutput"
done

