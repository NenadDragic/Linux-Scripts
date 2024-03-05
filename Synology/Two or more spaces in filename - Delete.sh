#!/bin/bash

# This script finds all files in the /volume1/Dragic directory that have two or more spaces in their names and renames them by replacing the double spaces with a single space.

# The find command is used to search for files in the specified directory.
# The -name '*  *' option specifies the pattern to match the filenames. It looks for filenames containing two consecutive spaces.
# The -exec option is used to execute a command on each matched file.
# The command 'sh -c 'mv "$1" "${1//  / }"' find-sh {} \;' renames each matched file by replacing the double spaces with a single space.
# Note: The pattern uses single quotes to prevent the shell from expanding the wildcard characters.

# Usage:
# Run this script to find all files in the /volume1/Dragic directory that have two or more spaces in their names and rename them by replacing the double spaces with a single space.
# Make sure to replace /volume1/Dragic with the actual directory path if necessary.

find /volume1/Dragic/ -name '*  *' -exec sh -c 'mv "$1" "${1//  / }"' find-sh {} \;