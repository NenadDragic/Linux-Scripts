# Pull Git Repositories

This document describes the process of pulling updates for all Git repositories in the `~/git` directory. The script iterates through each subdirectory, checks if it is a Git repository, and performs a `git pull` to fetch and integrate changes from the remote repository.

## Script Details

### Script Location
The script is located at:
```
/home/nenad/git/Linux-Scripts/MISC/git/Pull_Git.sh
```

### Script Content
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

## Usage

1. Ensure the script has execute permissions:
   ```bash
   chmod +x /home/nenad/git/Linux-Scripts/MISC/git/Pull_Git.sh
   ```

2. Run the script:
   ```bash
   /home/nenad/git/Linux-Scripts/MISC/git/Pull_Git.sh
   ```

The script will iterate through all subdirectories in `~/git`, check if they are Git repositories, and pull the latest changes from their respective remotes.