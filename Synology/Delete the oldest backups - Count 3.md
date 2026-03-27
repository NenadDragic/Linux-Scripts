# Delete the oldest backups - Count 3

Loops through a list of backup folders and deletes all subdirectories except the **3 newest** in each.

## Folders

| Folder |
| ------ |
| `/volume1/NetBackup/Debian_Laptop/` |
| `/volume1/NetBackup/Muddi-E750/` |
| `/volume1/NetBackup/Admin/` |
| `/volume1/NetBackup/FlightRadar_24/` |
| `/volume1/NetBackup/GPS/` |
| `/volume1/NetBackup/TFA/` |

## How it works

1. Creates a temporary file to store directory paths
2. For each folder, finds the 3 newest subdirectories (by modification time)
3. Deletes any subdirectory not in the 3 newest
4. Removes the temporary file when done

## Key commands

| Command | Description |
| ------- | ----------- |
| `find ... -printf "%T@ %p\0"` | List dirs with modification timestamp (null-delimited) |
| `sort -zn` | Sort numerically by timestamp (null-delimited) |
| `tail -z -n 3` | Keep only the 3 newest entries |
| `mapfile -d ''` | Read null-delimited paths into an array |
| `grep -Fxqz` | Check if a path is in the keep list |
| `rm -rf "$dir"` | Delete the directory and all its contents |

## Usage

```bash
bash "Delete the oldest backups - Count 3.sh"
```

To add more folders, append paths to the `input_folders` array in the script.
