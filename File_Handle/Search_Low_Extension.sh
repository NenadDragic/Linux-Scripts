#!/bin/bash
# Version:      1.0
# Date:         2023-03-21
# Test Run:
# Developper:   Nenad(a)dragic(.)com

echo "Searching for files with lowercase letter extensions in $(pwd)"
echo "-----------------------------------------------------------"

find . -type f -regextype posix-extended -regex '.*\.[a-z]+'

echo "-----------------------------------------------------------"
echo "Search complete"
