#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools git

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
