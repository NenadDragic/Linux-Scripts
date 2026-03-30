#!/bin/bash
# Version:      1.0
# Date Run:     2026-03-29
# Date:         2026-03-26
# Developper:   Nenad(a)dragic(.)com

files_count=0

echo '********************************************'
echo '** NAS - NAS ** NAS - NAS ** NAS - NAS **'
echo '********************************************'
echo ""

files_count=$(ls -l /volume1/DashCam/Photo | wc -l)
echo "Photos: $files_count"

files_count=$(ls -l /volume1/DashCam/Movie | wc -l)
echo "Movie: $files_count"

files_count=$(ls -l /volume1/DashCam/Movie/RO | wc -l)
echo "Movie RO: $files_count"

files_count=$(ls -l /volume1/DashCam/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"

echo ""
echo '********************************************'
echo '** NAS - NAS ** NAS - NAS ** NAS - NAS **'
echo '********************************************'