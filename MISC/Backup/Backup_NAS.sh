#!/bin/bash

# Check if the user is root
if [ "$(whoami)" != "root" ]; then
    echo "Please run as root."
    exit
fi

# Backup the data
sudo rsync -av /home/. -e "ssh -l Debian_Backup" 192.168.1.50::NetBackup/BackupData/Debian_Laptop/$(date +%Y-%m-%d)

# Exit
exit
