#!/bin/bash

# Check if Convert.sh exists and is executable
CONVERT_SCRIPT="/home/nenad/git/Linux-Scripts/MISC/Pic/Convert.sh"
if [ ! -x "$CONVERT_SCRIPT" ]; then
    echo "Error: Convert.sh not found or not executable at $CONVERT_SCRIPT"
    exit 1
fi

# Find all .PVT files and process them
find . -name "*.PVT" -type f | while IFS= read -r file; do
    echo "Processing file: $file"
    
    # Run the Convert.sh script with the file as argument
    "$CONVERT_SCRIPT" "$file"
done