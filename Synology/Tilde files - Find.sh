#!/bin/bash

# This script finds all files in the /volume1/Dragic directory that start with a tilde (~) and end with any extension.

# The find command is used to search for files in the specified directory.
# The -name "~*.*" option specifies the pattern to match the filenames.
# The -type f option ensures that only regular files (not directories) are matched.

# Usage:
# Run this script to find all files in the /volume1/Dragic directory that start with a tilde (~) and end with any extension.
# Make sure to replace /volume1/Dragic with the actual directory path if necessary.

find /volume1/Dragic -name "~*.*" -type f