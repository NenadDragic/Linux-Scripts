# Initialize Git Repositories

This script is used to pull the latest changes from all Git repositories in the `~/git` directory. It iterates through each subdirectory, checks if it is a Git repository, and performs a `git pull` operation.

## Script: Pull_Git.sh

```bash
#!/bin/bash

# Pull of all of NenadDragic's repositories
# https://github.com/NenadDragic

# Clear
clear

# Define the base directory
base_dir=~/git

# Iterate over all subdirectories
for dir in "$base_dir"/*; do
    # Check if it's a directory
    if [ -d "$dir" ]; then
        # Change to the directory
        cd "$dir"
        
        # Check if it's a git repository
        if [ -d ".git" ]; then
            # Run git pull
            echo "Running git pull in $dir"
            git pull
        fi
    fi
done
```

## How to Use

1. Save the script as `Pull_Git.sh` in your desired directory.
2. Make the script executable:
   ```bash
   chmod +x Pull_Git.sh
   ```
3. Run the script:
   ```bash
   ./Pull_Git.sh
   ```

## Notes
- Ensure that the `~/git` directory contains all the repositories you want to update.
- The script assumes that all subdirectories in `~/git` are Git repositories. Non-Git directories will be skipped.
- The script clears the terminal before execution for better readability.

## Example Output
```
Running git pull in /home/nenad/git/repo1
Already up to date.
Running git pull in /home/nenad/git/repo2
Updating abc123..def456
...
```