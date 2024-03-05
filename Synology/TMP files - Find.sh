#!/bin/bash

# This script finds all files in the /volume1/Dragic directory that end with the .tmp extension.

# The find command is used to search for files in the specified directory.
# The -name "*.tmp" option specifies the pattern to match the filenames.
# The -type f option ensures that only regular files (not directories) are matched.

# Usage:
# Run this script to find all files in the /volume1/Dragic directory that end with the .tmp extension.
# Make sure to replace /volume1/Dragic with the actual directory path if necessary.

find /volume1/Dragic -name "*.tmp" -type f