#!/bin/bash

# This script counts the number of files in several directories and prints the counts to the console.

# The script starts by initializing a variable to hold the file count.
# It then prints a header to the console.
# The ls -l command is used to list the files in each directory, and the wc -l command is used to count the number of lines in the output, which corresponds to the number of files.
# The file count for each directory is stored in the files_count variable and then printed to the console.
# This process is repeated for each of the specified directories.
# Finally, a footer is printed to the console.

# Usage:
# Run this script to count the number of files in the /volume1/NetBackup/DashCam/Photo, /volume1/NetBackup/DashCam/Movie, /volume1/NetBackup/DashCam/Movie/RO, and /volume1/NetBackup/DashCam/Movie/Parking directories and print the counts to the console.
# Make sure to replace the directory paths with the actual paths if necessary.

files_count=0

echo '********************************************'
echo '** NAS - NAS ** NAS - NAS ** NAS - NAS **'
echo '********************************************'
echo ""

# files_count=$(ls -l /volume1/NetBackup/DashCam/Photo | wc -l)
files_count=$(ls -l /volume1/DashCam/Photo | wc -l)
echo "Photos: $files_count"

# files_count=$(ls -l /volume1/NetBackup/DashCam/Movie | wc -l)
files_count=$(ls -l /volume1/DashCam/Movie | wc -l)
echo "Movie: $files_count"

# files_count=$(ls -l /volume1/NetBackup/DashCam/Movie/RO | wc -l)
files_count=$(ls -l /volume1/DashCam/Movie/RO | wc -l)
echo "Movie RO: $files_count" 

# files_count=$(ls -l /volume1/NetBackup/DashCam/Movie/Parking | wc -l)
files_count=$(ls -l /volume1/DashCam/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"

echo ""
echo '********************************************'
echo '** NAS - NAS ** NAS - NAS ** NAS - NAS **'
echo '********************************************'