# IBM Hardware Serial Info - Info.sh

This script provides an interactive menu to look up the serial number of the system or baseboard via `dmidecode`, for identifying IBM/Lenovo server hardware.

## How it works

1. Checks that the script is run as root; exits with a message if not.
2. Prompts the user to choose between two options:
   - `1`: `sudo dmidecode -t system | grep Serial` — the chassis/system serial number.
   - `2`: `sudo dmidecode -t baseboard | grep Serial` — the motherboard serial number.
3. Runs the selected `dmidecode` command, or prints an error for an invalid choice.

## Usage

Run as root and follow the interactive prompt.

```shell
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
```
