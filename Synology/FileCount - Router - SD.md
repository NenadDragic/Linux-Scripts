# FileCount - Router - SD

Finds all files in `/volume1/DashCam/File-Count-SD/` modified today and displays their contents using `more`.

## How it works

1. Gets today's date in `YYYYMMDD` format
2. Creates temporary marker files at start and end of the day in `/tmp/`
3. Uses `find` to locate files modified within today's time range
4. Removes the temporary marker files
5. Displays each matched file with `more`, or prints a message if none are found

## Command

```bash
find /volume1/DashCam/File-Count-SD/ -maxdepth 1 -type f -newer /tmp/start_marker ! -newer /tmp/end_marker -exec basename {} \;
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
bash "FileCount - Router - SD.sh"
```

Replace `/volume1/DashCam/File-Count-SD/` with the target directory path if needed.
