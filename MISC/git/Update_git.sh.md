## Bash Script: Add, Commit, and Push Changes to a Git Repository
This bash script (`commit_changes.sh`) is designed to add, commit, and push changes to a Git repository. The script prompts the user for a commit message and uses that message in the commit.

## Usage
Make sure you have permission to execute the script. If not, run the following command to grant permission:

```console
chmod +x commit_changes.sh
```
Execute the script by running the following command:

```console
./commit_changes.sh
```

The script will prompt the user for a commit message, add all changes to the staging area, commit the changes with the provided commit message, and push the changes to the remote repository.

## Explanation

The script uses the following three Git commands to add, commit, and push changes to the repository:

* `git add -A`: This command adds all changes, including new files, modifications, and deletions, to the staging area.
* `git commit -am`: This command commits the changes with the provided commit message, using the -a option to automatically stage all changes, and the -m option to include the commit message in the same command line.
* `git push`: This command pushes the committed changes to the remote repository.

The script prompts the user for a commit message using the `read` command and stores the message in a variable. The script then uses the stored message in the `git commit -am` command.

Overall, this script is useful for users who want to quickly add, commit, and push changes to a Git repository with a customized commit message.
