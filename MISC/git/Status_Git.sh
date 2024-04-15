#!/bin/bash

# Validate status of all of NenadDragic's repositories
# https://github.com/NenadDragic

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
            # Run git status
            echo "Running git status in $dir"
            git status
        fi
    fi
done