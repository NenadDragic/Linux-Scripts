#!/bin/bash

# Define an array of input folders
input_folders=(
    "/volume1/NetBackup/Debian_Laptop/"
    "/volume1/NetBackup/Muddi-E750/"
    "/volume1/NetBackup/Admin/"
    "/volume1/NetBackup/FlightRadar_24/"
    "/volume1/NetBackup/GPS/"
    "/volume1/NetBackup/TFA/"

    #"/path/to/another/folder/"
    #"/path/to/yet/another/folder/"
)

# Temporary file to store the list of newest directories
temp_file=$(mktemp)

# Loop through each input folder
for bibliotek in "${input_folders[@]}"; do
    echo "Processing folder: $bibliotek"

    # Find the 3 newest directories and store their paths
    find "$bibliotek" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\0" | sort -zn | tail -z -n 3 | cut -z -d' ' -f2- > "$temp_file"

    # Read the newest directories into an array
    mapfile -d '' newest_dirs < "$temp_file"

    # Delete all directories except the 2 newest
    find "$bibliotek" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
        if ! printf '%s\0' "${newest_dirs[@]}" | grep -Fxqz -- "$dir"; then
            echo "Deleting: $dir"
            rm -rf "$dir"
        fi
    done
done

# Clean up the temporary file
rm -f "$temp_file"