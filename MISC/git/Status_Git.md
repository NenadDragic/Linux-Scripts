## Bash Script: Validate Status for Git Repositories

This bash script (`Status_Git.sh`) is designed to validate the status of all Git repositories in a user-defined directory. 
The script iterates through subdirectories in the directory and checks if they contain a Git repository (.git directory). 
If a Git repository is found, it runs git status to show the status of the repository.

## Usage

Make sure you have permission to execute the script. If not, run the following command to grant permission:

```bash
chmod +x validate_git_status.sh
```

Run the script with the following command:

```bash
./Status_Git.sh
```
The script will check all subdirectories in the defined base directory, and for Git repositories, it will show the output of git status.

## Explanation

The script uses the following structure to iterate through directories and check for Git repositories:

base_dir=~/git  # Defines the base directory to search for Git repositories. Change this to your own directory if you store Git projects elsewhere.

for dir in "$base_dir"/*; do
  if [ -d "$dir" ]; then
    cd "$dir"
    if [ -d ".git" ]; then
      echo "Running git status in $dir"
      git status
    fi
  fi
done

This script is useful for getting a quick overview of the status of Git repositories in a specific directory. You can easily change the base_dir to the directory that contains your Git projects.