# Delete Thumbs.db Files Script

This script (`delete_thumbs_files.sh`) finds and deletes all files named `Thumbs.db` in the `/volume1/Dragic` directory and any subdirectories on a Linux system using the `find` command.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

```bash
chmod +x delete_thumbs_files.sh
```

2. Execute the script by running the following command:

```bash
./delete_thumbs_files.sh
```

The script will search for and delete all files named `Thumbs.db` in the `/volume1/Dragic` directory and any subdirectories.

* `find /volume1/Dragic -name "Thumbs.db" -type f -delete 2>/dev/null`: This command finds all files named `Thumbs.db` in the `/volume1/Dragic` directory and any subdirectories and deletes them. The `2>/dev/null` part of the command redirects any error messages to the null device, effectively discarding them.
