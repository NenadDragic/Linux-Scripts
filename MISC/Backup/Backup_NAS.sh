#!/bin/bash

# Check if the user is root
if [ "$(whoami)" != "root" ]; then
    echo "Please run as root."
    exit
fi

# Define the backup directory
backup_dir="../../media/nenad/2F90E98B5A2F4030/Backup - Debian Laptop"

# Backup the data
sudo rsync -av -e "ssh -l Debian_Backup" 192.168.1.50::NetBackup/BackupData/Debian_Laptop/$(date +%Y-%m-%d)

# Exit
exit
