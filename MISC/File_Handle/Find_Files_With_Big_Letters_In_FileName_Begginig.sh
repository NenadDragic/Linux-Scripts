#!/bin/bash

echo "Finding files in the current directory and its subdirectories whose filenames begin with a capital letter..."
find . -type f -regex './[A-Z]*'
