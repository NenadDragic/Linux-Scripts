# Get the current date in the format YYYYMMDD
current_date=$(date '+%Y%m%d')

# Create temporary marker files with specific timestamps
start_timestamp=$(date -d "$current_date" '+%Y%m%d%H%M.%S')
end_timestamp=$(date -d "$current_date + 1 day" '+%Y%m%d%H%M.%S')

touch -t "$start_timestamp" /tmp/start_marker
touch -t "$end_timestamp" /tmp/end_marker

# List files modified today in the specified directory
files_modified_today=$(find /volume1/Ftp/DashCam/File-Count-SD/ -maxdepth 1 -type f -newer /tmp/start_marker ! -newer /tmp/end_marker -exec basename {} \;)

# Remove temporary marker files
rm -f /tmp/start_marker /tmp/end_marker

# Check if any files were modified today
if [ -n "$files_modified_today" ]; then
    for file in $files_modified_today; do
        # Open each file with the default text editor
        more "/volume1/Ftp/DashCam/File-Count-SD/$file"  
    done
else
    echo "No files modified today."
fi