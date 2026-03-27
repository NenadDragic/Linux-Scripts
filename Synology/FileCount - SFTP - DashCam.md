# FileCount - SFTP - DashCam

Counts the number of files in each DashCam directory and prints the results to the console.

## Directories

| Label | Path |
| ----- | ---- |
| Photos | `/volume1/DashCam/Photo` |
| Movie | `/volume1/DashCam/Movie` |
| Movie RO | `/volume1/DashCam/Movie/RO` |
| Movie Parking | `/volume1/DashCam/Movie/Parking` |

## How it works

Uses `ls -l | wc -l` for each directory to count entries, then prints the count with a labeled header and footer.

> **Note:** `ls -l | wc -l` includes the `total` line in the count, so the actual file count is one less than reported.

## Usage

```bash
bash "FileCount - SFTP - DashCam.sh"
```

Replace directory paths with the actual paths if needed.
