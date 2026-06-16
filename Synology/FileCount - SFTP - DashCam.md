# FileCount - SFTP - DashCam

Counts the number of files in each DashCam directory and prints the results to the console.

## Command

```bash
files_count=0

files_count=$(ls -l /volume1/DashCam/Photo | wc -l)
echo "Photos: $files_count"

files_count=$(ls -l /volume1/DashCam/Movie | wc -l)
echo "Movie: $files_count"

files_count=$(ls -l /volume1/DashCam/Movie/RO | wc -l)
echo "Movie RO: $files_count"

files_count=$(ls -l /volume1/DashCam/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"
```

## Usage

```bash
bash "FileCount - SFTP - DashCam.sh"
```

> **Note:** `ls -l | wc -l` includes the `total` line in the count, so the actual file count is one less than reported.
