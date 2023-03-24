#!/bin/bash

echo "Finding files in the current directory and its subdirectories whose names have lowercase file extensions and renaming them to have uppercase file extensions..."

find . -type f -iname '*.[a-z]*' -execdir rename -n 's/\.([a-z]+)/.\U$1/' {} \;
