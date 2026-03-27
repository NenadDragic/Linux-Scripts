# FileDelete - Router - DashCam

Finds all files in `/volume1/DashCam/File-Delete/` modified today and displays their contents using `more`.

## How it works

1. Gets today's date in `YYYYMMDD` format
2. Creates temporary marker files at start and end of the day in `/tmp/`
3. Uses `find` to locate files modified within today's time range
4. Removes the temporary marker files
5. Displays each matched file with `more`, or prints a message if none are found

## Command

```bash
current_date=$(date '+%Y%m%d')
start_timestamp=$(date -d "$current_date" '+%Y%m%d%H%M.%S')
end_timestamp=$(date -d "$current_date + 1 day" '+%Y%m%d%H%M.%S')

touch -t "$start_timestamp" /tmp/start_marker
touch -t "$end_timestamp" /tmp/end_marker

files_modified_today=$(find /volume1/DashCam/File-Delete/ -maxdepth 1 -type f -newer /tmp/start_marker ! -newer /tmp/end_marker -exec basename {} \;)

rm -f /tmp/start_marker /tmp/end_marker
```

## Options

| Option/Variable | Description |
| --------------- | ----------- |
| `-maxdepth 1` | Search only the specified directory, not subdirectories |
| `-type f` | Match regular files only (excludes directories) |
| `-newer /tmp/start_marker` | Match files modified after start of today |
| `! -newer /tmp/end_marker` | Match files modified before end of today |
| `-exec basename {} \;` | Extract the base filename of each match |

## Usage

```bash
bash "FileDelete - Router - DashCam.sh"
```

Replace `/volume1/DashCam/File-Delete/` with the target directory path if needed.
