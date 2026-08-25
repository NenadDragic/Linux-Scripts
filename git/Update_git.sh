#!/bin/bash

# Prompt user for commit message
read -p "Enter commit message: " message

# Add all changes to the staging area
git add -A

# Commit changes with the provided commit message
git commit -am "$message"

# Push changes to the remote repository
git push
