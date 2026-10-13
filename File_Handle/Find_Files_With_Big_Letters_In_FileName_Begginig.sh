#!/bin/bash
# Version:      1.0
# Date:         2023-03-24
# Test Run:
# Developper:   Nenad(a)dragic(.)com

echo "Finding files in the current directory and its subdirectories whose filenames begin with a capital letter..."
find . -type f -regex './[A-Z]*'
