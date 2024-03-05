#!/bin/bash
files_count=0

echo '********************************************'
echo '** NAS - NAS ** NAS - NAS ** NAS - NAS **'
echo '********************************************'
echo ""
files_count=$(ls -l /volume1/Ftp/DashCam/Photo | wc -l)
echo "Photos: $files_count"

files_count=$(ls -l /volume1/Ftp/DashCam/Movie | wc -l)
echo "Movie: $files_count"

files_count=$(ls -l /volume1/Ftp/DashCam/Movie/RO | wc -l)
echo "Movie RO: $files_count" 

files_count=$(ls -l /volume1/Ftp/DashCam/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"
echo ""
echo '********************************************'
echo '** NAS - NAS ** NAS - NAS ** NAS - NAS **'
echo '********************************************'