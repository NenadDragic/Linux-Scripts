#!/bin/bash
# Update script

# Check for root privileges
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi

# Update APT packages
echo "\nUpdating APT packages...\n"
apt -y update
apt -y upgrade
apt -y dist-upgrade
apt autoremove
apt autoclean

# Update file location database
echo "Updating file location database..."
updatedb
