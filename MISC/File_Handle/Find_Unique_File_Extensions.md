# Find Unique File Extensions Script
This script (find_unique_extensions.sh) is designed to find all unique file extensions in the current directory and its subdirectories.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

```bash
chmod +x find_unique_extensions.sh
```

2. Execute the script by running the following command:

```bash
./find_unique_extensions.sh
```

The script will output the unique file extensions found in the current directory and its subdirectories.

## Explanation
The script uses a combination of find, sed, and sort commands to find unique file extensions. The commands' syntax is as follows:

```bash
find . -type f | sed -e 's/.*\.//' | sort -u
```

* `find . -type f` : This command searches the current directory (.) and its subdirectories for files only (excluding directories), outputting the file paths.
* `sed -e 's/.*\.//'` : This command is a stream editor (sed) that uses a regular expression to remove the file path and keep only the file extension.
* `sort -u` : This command sorts the input lines and removes duplicates, leaving only unique file extensions.
When the script is executed, the `find` command retrieves all the files, the `sed` command extracts the file extensions, and the `sort` command filters out duplicates, printing the unique file extensions to the console.
