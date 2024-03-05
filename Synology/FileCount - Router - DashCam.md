# FileCount - Router - DashCam.sh

This script finds all files in the `/volume1/Ftp/DashCam/File-Count-DashCam/` directory that were modified today and opens them with the default text editor.

## How it works

The current date is obtained in the format YYYYMMDD. Temporary marker files with specific timestamps are created to represent the start and end of the day. The `find` command is used to search for files in the specified directory that were modified between the timestamps of the start and end marker files.

- The `-maxdepth 1` option ensures that only the specified directory (not subdirectories) is searched.
- The `-type f` option ensures that only regular files (not directories) are matched.
- The `-newer /tmp/start_marker ! -newer /tmp/end_marker` options specify the time range for file modification times.
- The `-exec basename {} \;` command extracts the base name of each matched file.

The temporary marker files are then removed. If any files were modified today, they are opened with the `more` command (the default text editor in many Unix-like systems). If no files were modified today, a message is printed to the console.

## Usage

Run this script to find all files in the `/volume1/Ftp/DashCam/File-Count-DashCam/` directory that were modified today and open them with the default text editor. Make sure to replace `/volume1/Ftp/DashCam/File-Count-DashCam/` with the actual directory path if necessary.

```shellscript
current_date=$(date '+%Y%m%d')
start_timestamp=$(date -d "$current_date" '+%Y%m%d%H%M.%S')
end_timestamp=$(date -d "$current_date + 1 day" '+%Y%m%d%H%M.%S')

touch -t "$start_timestamp" /tmp/start_marker
touch -t "$end_timestamp" /tmp/end_marker

files_modified_today=$(find /volume1/Ftp/DashCam/File-Count-DashCam/ -maxdepth 1 -type f -newer /tmp/start_marker ! -newer /tmp/end_marker -exec basename {} \;)

rm -f /tmp/start_marker /tmp/end_marker

if [ -n "$files_modified_today" ]; then
    for file in $files_modified_today; do
        more "/volume1/Ftp/DashCam/File-Count-DashCam/$file"  
    done
else
    echo "No files modified today."
fi