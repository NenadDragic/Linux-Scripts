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

# Loop through all JPG and JPEG files (case insensitive)
shopt -s nocaseglob
for filename in *.JPG *.JPEG; do
    # Skip if no files are found
    [ -e "$filename" ] || continue
    
    # Extract filename, camera model, and creation date from EXIF metadata
    baseFilename=$(basename "$filename")
    cameraModel=$(exiftool -b -n -s -M -EXIF:Model "$filename" | tr -d '[:space:]' | sed 's/[^a-zA-Z0-9]/_/g')
    
    # Extract date without time and format it as YYYY-MM-DD
    creationDate=$(exiftool -b -n -s -M -EXIF:createdate "$filename" | cut -d' ' -f1)
    
    # Skip if we couldn't get the required metadata
    if [ -z "$cameraModel" ] || [ -z "$creationDate" ]; then
        echo "Warning: Could not extract metadata from $filename"
        continue
    fi
    
    # Create directory structure
    targetDir="${creationDate}/${cameraModel}"
    
    # Create directories if they don't exist
    mkdir -p "$targetDir"
    
    # Copy file to new location
    if cp "$filename" "$targetDir/$baseFilename"; then
        echo "Successfully copied $filename to $targetDir/$baseFilename"
    else
        echo "Error: Failed to copy $filename"
    fi
done

# Reset globbing settings
shopt -u nocaseglob
