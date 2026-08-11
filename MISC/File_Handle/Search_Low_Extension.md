# Finding Files by Extension Script

This script (Search_Low_Extension.sh) is designed to search for files in the current directory and its subdirectories that have an extension consisting of at least one lowercase letter.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

```bash
chmod +x Search_Low_Extension.sh
```

2. Execute the script by running the following command:

```bash
./Search_Low_Extension.sh
```

The script will output the paths of all files found in the search that have an extension consisting of at least one lowercase letter.

## Explanation
The script first prints a banner, then uses the `find` command to search for files by extension, and finally prints a completion footer. Its actual output looks like this:

```
Searching for files with lowercase letter extensions in <current directory>
-----------------------------------------------------------
<matching file paths, one per line>
-----------------------------------------------------------
Search complete
```

The `find` command's syntax is as follows:

* `find` : This is the command used to search for files and directories in a directory hierarchy.
* `.` : This argument specifies the starting directory for the search. In this case, it is the current directory.
* `-type f` : This flag filters the search results, only returning files (not directories).
* `-regextype posix-extended` : This flag specifies the type of regular expression used in the search.
* `-regex '.*\.[a-z]+'` : This flag specifies the regular expression used to match the filenames, which consists of any character followed by a dot and at least one lowercase letter.
When the script is executed, it prints a banner (`Searching for files with lowercase letter extensions in $(pwd)`) and a separator line, then the `find` command searches the current directory and its subdirectories for files with an extension consisting of at least one lowercase letter, printing the paths of the found files to the console, followed by another separator line and a `Search complete` footer.
