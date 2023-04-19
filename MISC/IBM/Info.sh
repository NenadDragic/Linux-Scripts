#!/bin/bash

# Check if the user has root privileges
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi

echo "Which command would you like to run?"
echo "1. sudo dmidecode -t system | grep Serial"
echo "2. sudo dmidecode -t baseboard | grep Serial"
read choice

case $choice in
  1) sudo dmidecode -t system | grep Serial ;;
  2) sudo dmidecode -t baseboard | grep Serial ;;
  *) echo "Invalid choice. Please choose 1 or 2." ;;
esac
