# Find Empty Files Script
This script (find_empty_files.sh) is designed to find all empty files in the current directory and its subdirectories.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

```console
chmod +x find_empty_files.sh
```

2. Execute the script by running the following command:
```console
./find_empty_files.sh
```
The script will output the paths of all empty files in the current directory and its subdirectories.

## Explanation
 
The script uses the find command to search for empty files. The command's syntax is as follows:
```console
find . -type f -empty
```
* `find` : This is the command used to search for files and directories in a directory hierarchy.
* `.´ : This argument specifies the starting directory for the search. In this case, it is the current directory.
* `-type f´ : This flag filters the search results, only returning files (not directories).
* `-empty´ : This flag further filters the search results, only returning empty files.
When the script is executed, the find command searches the current directory and its subdirectories for empty files, printing the paths of the found files to the console.
