#!/bin/bash

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

