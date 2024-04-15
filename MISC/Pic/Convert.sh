#!/bin/bash


# Big letters in extension
rename 'y/a-z/A-Z/' *

# Convert HEIC files to JPEG and rename them
for f in *.HEIC; do
    heif-convert -q 100 "$f" "${f%.HEIC}.JPG"
done