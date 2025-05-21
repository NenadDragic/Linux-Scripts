#!/bin/bash

# Check if libheif-examples package is installed
if ! dpkg -l | grep -q libheif-examples; then
    echo "libheif-examples package is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y libheif-examples
fi

# Create the folders
mkdir -p ORG MOV MP4 CR2 HEIC

# Big letters in extension
rename 'y/a-z/A-Z/' *

# Convert HEIC files to JPEG and rename them
for f in *.HEIC; do
    heif-convert -q 100 "$f" "${f%.HEIC}.JPG"
done

# Big letters in extension
rename 'y/a-z/A-Z/' *

# Move files to the corresponding folders
mv -t MOV *.MOV
mv -t MP4 *.MP4
mv -t CR2 *.CR2
mv -t HEIC *.HEIC

# Copy JPEG files to ORG
cp -t ORG *.JPG *.JPEG

# Delete empty directories
find . -type d -empty -delete

echo All tasks completed.
