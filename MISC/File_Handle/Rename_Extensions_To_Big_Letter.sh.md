# Find and Rename Command: Find Files with Lowercase Extensions and Rename to Uppercase

This command `(find . -type f -iname '*.[a-z]*' -execdir rename 's/\.([a-z]+)/.\U$1/' {} \;)` is designed to find all files in the current directory and its subdirectories whose names have lowercase file extensions and rename them to have uppercase file extensions.

## Explanation
The command uses the `find` command to search for files in the directory hierarchy. The command's syntax is as follows:

```console
find . -type f -iname '*.[a-z]*' -execdir rename -n 's/\.([a-z]+)/.\U$1/' {} \;
```
__To apply the changes, remove the -n flag from the rename command:__

Here's an explanation of each element of the command:

* `find`: This is the command used to search for files and directories in a directory hierarchy.
* `.`: This argument specifies the starting directory for the search. In this case, it is the current directory.
* `-type f`: This flag filters the search results, only returning files (not directories).
* `-iname '*.[a-z]*'`: This option specifies a case-insensitive match for filenames that end with a lowercase file extension.
* `-execdir rename 's/\.([a-z]+)/.\U$1/' {} \;`: This option executes the rename command in the directory where each file is located. The `rename` command uses a regular expression to match and convert the lowercase file extension to uppercase.

When the command is executed, the `find` command searches the current directory and its subdirectories for files whose names have lowercase file extensions, and renames them to have uppercase file extensions.

Overall, this command is useful for users who want to quickly find and rename files in a directory and its subdirectories with lowercase file extensions to have uppercase file extensions.
