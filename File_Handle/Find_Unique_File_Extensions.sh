#!/bin/bash
# Version:      1.0
# Date:         2023-03-21
# Test Run:
# Developper:   Nenad(a)dragic(.)com

# Find all unique file extensions in the current directory and its subdirectories
find . -type f | sed -e 's/.*\.//' | sort -u
