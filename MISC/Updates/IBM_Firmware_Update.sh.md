# Get Devices Firmware Information Script
This script (get_devices_firmware_info.sh) retrieves and updates firmware information for devices on a Linux system using a command-line tool called `fwupdmgr`.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:

``` console
chmod +x get_devices_firmware_info.sh
```

2. Execute the script with root privileges by running the following command:

``` console
sudo ./get_devices_firmware_info.sh
```

The script will check for available firmware updates for devices on the system and then perform the updates, if any.

## Explanation

The script checks for root privileges, runs the `fwupdmgr get-updates` command to fetch available firmware updates, and then runs the `fwupdmgr update` command to perform the updates.

* `if [ $EUID -ne "0" ]`; then: This line checks if the user running the script has root privileges (user ID 0). If not, the script prints a message and exits.
* `echo -e "Please run as root.\n"`: This line prints an error message, indicating that the script should be run as root.
* `exit`: This line exits the script if the user does not have root privileges.
* `fwupdmgr get-updates`: This command fetches available firmware updates for devices on the system.
* `fwupdmgr update`: This command applies the fetched firmware updates to the devices.
