#!/bin/bash

# Find all unique file extensions in the current directory and its subdirectories
find . -type f | sed -e 's/.*\.//' | sort -u
