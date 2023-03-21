# Delete .bak Files Script
This script (delete_bak_files.sh) finds and deletes all files with the ".bak" extension in the "/volume1/Dragic" directory and any subdirectories on a Linux system using the `find` command.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:
``` console
chmod +x delete_bak_files.sh
```

2. Execute the script by running the following command:
``` console
./delete_bak_files.sh
```

The script will search for and delete all files with the ".bak" extension in the "/volume1/Dragic" directory and any subdirectories.

## Explanation

The script uses the `find` command to search for files with the ".bak" extension in the "/volume1/Dragic" directory and any subdirectories, and then deletes them.

* `find /volume1/Dragic -name "*.bak" -type f -delete 2>/dev/null`: This command finds all files with the ".bak" extension in the "/volume1/Dragic" directory and any subdirectories and deletes them. The 2>/dev/null part of the command redirects any error messages to the null device, effectively discarding them.
