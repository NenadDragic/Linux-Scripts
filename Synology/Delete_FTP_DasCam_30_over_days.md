# Auto-Delete Old DashCam Files Script

This script (`auto_delete_old_files.sh`) finds and deletes files older than 30 days in the "/volume1/Ftp/DashCam" directory and its subdirectories on a Linux system using the `find` command.

## Usage

1. Ensure you have permission to execute the script. If not, grant permission by running:
```bash
   chmod +x Delete_FTP_DasCam_30_over_days.sh
```

## Execute the script by running:
./Delete_FTP_DasCam_30_over_days.sh
The script will search for and delete files older than 30 days in the "/volume1/Ftp/DashCam" directory and its subdirectories.

## Explanation
The script utilizes the find command to identify files older than 30 days in the "/volume1/Ftp/DashCam" directory and its subdirectories and then removes them.

```bash
find /volume1/Ftp/DashCam -type f -mtime +30 | xargs rm -f
```

This command finds files older than 30 days in the specified directory and its subdirectories and forcefully deletes them using `xargs` and `rm -f`.