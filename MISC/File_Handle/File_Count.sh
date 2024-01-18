#!/bin/bash

# Specify the folder path
folder_path=$(pwd)

# Check if the folder exists
if [ ! -d "$folder_path" ]; then
    echo "Error: Folder not found!"
    exit 1
fi

# Use find to get a list of all files in the folder
files=$(find "$folder_path" -type f)

# Use awk to extract and count file extensions, then sort them
extension_count=$(echo "$files" | awk -F'.' '{print $NF}' | sort | uniq -c | sort -n)

# Display the result
echo "File Extensions Count:"
echo "$extension_count"