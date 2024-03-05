#!/bin/bash

# This script finds all files in the /volume1/Dragic directory that have two or more spaces in their names.

# The find command is used to search for files in the specified directory.
# The -name '*  *' option specifies the pattern to match the filenames. It looks for filenames containing two consecutive spaces.
# Note: The pattern uses single quotes to prevent the shell from expanding the wildcard characters.

# Usage:
# Run this script to find all files in the /volume1/Dragic directory that have two or more spaces in their names.
# Make sure to replace /volume1/Dragic with the actual directory path if necessary.

find /volume1/Dragic/ -name '*  *'