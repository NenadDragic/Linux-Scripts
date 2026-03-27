#!/bin/bash
# Version 1.0
# Date: 2026-03-26
# Developper: Nenad(a)dragic(.)com

input_folders=(
    "/volume1/NetBackup/Debian_Laptop/"
    "/volume1/NetBackup/Muddi-E750/"
    "/volume1/NetBackup/Admin/"
    "/volume1/NetBackup/FlightRadar_24/"
    "/volume1/NetBackup/GPS/"
    "/volume1/NetBackup/TFA/"
)

temp_file=$(mktemp)

for bibliotek in "${input_folders[@]}"; do
    echo "Processing folder: $bibliotek"

    find "$bibliotek" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\0" | sort -zn | tail -z -n 3 | cut -z -d' ' -f2- > "$temp_file"

    mapfile -d '' newest_dirs < "$temp_file"

    find "$bibliotek" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
        if ! printf '%s\0' "${newest_dirs[@]}" | grep -Fxqz -- "$dir"; then
            echo "Deleting: $dir"
            rm -rf "$dir"
        fi
    done
done

rm -f "$temp_file"