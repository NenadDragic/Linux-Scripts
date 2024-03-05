#!/bin/bash

# This script finds all files named "Thumbs.db" in the /volume1/Dragic directory.

# The find command is used to search for files in the specified directory.
# The -name "Thumbs.db" option specifies the exact filename to match.
# The -type f option ensures that only regular files (not directories) are matched.

# Usage:
# Run this script to find all files named "Thumbs.db" in the /volume1/Dragic directory.
# Make sure to replace /volume1/Dragic with the actual directory path if necessary.

find /volume1/Dragic -name "Thumbs.db" -type f