#!/bin/bash
# Version       1.0
# Date Run:     2026-03-29
# Date:         2026-03-26
# Developper:   Nenad(a)dragic(.)com

current_date=$(date '+%Y%m%d')
start_timestamp=$(date -d "$current_date" '+%Y%m%d%H%M.%S')
end_timestamp=$(date -d "$current_date + 1 day" '+%Y%m%d%H%M.%S')

touch -t "$start_timestamp" /tmp/start_marker
touch -t "$end_timestamp" /tmp/end_marker

files_modified_today=$(find /volume1/DashCam/File-Count-DashCam/ -maxdepth 1 -type f -newer /tmp/start_marker ! -newer /tmp/end_marker -exec basename {} \;)

rm -f /tmp/start_marker /tmp/end_marker

if [ -n "$files_modified_today" ]; then
    for file in $files_modified_today; do
        more "/volume1/DashCam/File-Count-DashCam/$file"
    done
else
    echo "No files modified today."
fi