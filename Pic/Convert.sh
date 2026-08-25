#!/bin/bash

# Big letters in extension (using tr)
for f in *; do
    new_name=$(echo "$f" | tr 'a-z' 'A-Z')
    mv "$f" "$new_name"
done

# Convert HEIC files to JPEG and rename them
for f in *.HEIC; do
    heif-convert -q 100 "$f" "${f%.HEIC}.JPG"
done

# Big letters in extension
rename 'y/a-z/A-Z/' *
