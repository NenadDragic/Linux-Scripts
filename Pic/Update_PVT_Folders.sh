#!/bin/bash

# Check if Convert.sh exists and is executable (it lives in the same folder as this script)
CONVERT_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Convert.sh"
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