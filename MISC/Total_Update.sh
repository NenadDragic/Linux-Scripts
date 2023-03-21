#!/bin/bash
# Update script

# Check for root privileges
if [ $EUID -ne "0" ]; then
  echo -e "Please run as root.\n"
  exit
fi

# Update APT packages
echo -e "\nUpdating APT packages...\n"
apt -y update
apt -y upgrade
apt -y dist-upgrade
apt autoremove
apt autoclean

# Update file location database
echo -e "\nUpdating file location database...\n"
updatedb 
