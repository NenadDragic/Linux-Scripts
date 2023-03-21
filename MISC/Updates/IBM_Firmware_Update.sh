#!/bin/bash
# Get Devices Firmware Information Script

# Check if the user has root privileges
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi

# Execute fwupdmgr get-devices command
fwupdmgr get-updates

# Execute fwupdmgr update command
fwupdmgr update
