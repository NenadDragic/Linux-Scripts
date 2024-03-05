# Delete FTP DashCam 30 over days.sh

This script finds and deletes all files in the `/volume1/Ftp/DashCam` directory that were last modified more than 30 days ago.

## How it works

The `find` command is used to search for files in the specified directory.

- The `-type f` option ensures that only regular files (not directories) are matched.
- The `-mtime +30` option specifies that only files that were last modified more than 30 days ago should be matched.
- The matched files are then piped to the `xargs` command, which uses the `rm -f` command to delete each file.

## Usage

Run these commands to find and delete all files in the `/volume1/Ftp/DashCam` directory that were last modified more than 30 days ago. Make sure to replace `/volume1/Ftp/DashCam` with the actual directory path if necessary.

```shellscript
find /volume1/Ftp/DashCam -type f -mtime +30
find /volume1/Ftp/DashCam -type f -mtime +30  | xargs rm -f