#!/bin/bash

echo "Searching for files with lowercase letter extensions in $(pwd)"
echo "-----------------------------------------------------------"

find . -type f -regextype posix-extended -regex '.*\.[a-z]+'

echo "-----------------------------------------------------------"
echo "Search complete"
