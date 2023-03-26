# Finding Files by Extension Script

This script (find_files_by_extension.sh) is designed to search for files in the current directory and its subdirectories that have an extension consisting of at least one lowercase letter.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

```bash
chmod +x find_files_by_extension.sh
```

2. Execute the script by running the following command:

```bash
./find_files_by_extension.sh
```

The script will output the paths of all files found in the search that have an extension consisting of at least one lowercase letter.

## Explanation
The script uses the `find` command to search for files by extension. The command's syntax is as follows:

* `find` : This is the command used to search for files and directories in a directory hierarchy.
* `.` : This argument specifies the starting directory for the search. In this case, it is the current directory.
* `-type f` : This flag filters the search results, only returning files (not directories).
* `-regextype posix-extended` : This flag specifies the type of regular expression used in the search.
* `-regex '.*\.[a-z]+'` : This flag specifies the regular expression used to match the filenames, which consists of any character followed by a dot and at least one lowercase letter.
When the script is executed, the `find` command searches the current directory and its subdirectories for files with an extension consisting of at least one lowercase letter, printing the paths of the found files to the console.
