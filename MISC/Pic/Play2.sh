#!/bin/bash

# Loop through all JPG and JPEG files (case insensitive)
#shopt -s nocaseglob
for filename in *.JPG *.JPEG; do
    # Skip if no files are found
    [ -e "$filename" ] || continue
    
    # Extract filename, camera model, and creation date from EXIF metadata
    baseFilename=$(basename "$filename" .JPG)
    baseFilename=$(basename "$baseFilename" .JPEG)
    cameraModel=$(exiftool -b -n -s -M -EXIF:Model "$filename" | tr -d '[:space:]' | sed 's/[^a-zA-Z1-9]/_/g')
    
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
    
    # Copy all files with the same base name but different extensions
    for ext in JPG JPEG MOV HEIC MP4 CR2; do
        if [ -e "${baseFilename}.${ext}" ]; then
            if cp "${baseFilename}.${ext}" "$targetDir/"; then
                echo "Successfully copied ${baseFilename}.${ext} to $targetDir/"
            else
                echo "Error: Failed to copy ${baseFilename}.${ext}"
            fi
        fi
    done
done

# Reset globbing settings
# shopt -u nocaseglob
