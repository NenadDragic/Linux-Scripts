# Get info for an IBM Lenovo

## Usage
To use the script, follow these steps:

1. Make sure you have permission to execute the script. If not, run the following command to grant permission:
console

```bash
chmod +x Info.sh
```

2. Execute the script by running the following command:

```bash
sudo ./Info.sh
```

## Explanation

```bash
#!/bin/bash
```
This line indicates that the script should be run using the Bash shell.

```bash
# Check if the user has root privileges
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi
```

This block of code checks whether the user has root privileges by comparing the output of the `whoami` command to the string "root". If the user is not root, the script will print an error message asking the user to run the script with root privileges, and then exit.

```bash
echo "Which command would you like to run?"
echo "1. sudo dmidecode -t system | grep Serial"
echo "2. sudo dmidecode -t baseboard | grep Serial"
read choice
```

These lines prompt the user to choose one of two commands by displaying a menu with two options. The `read` command reads the user's input into the `choice` variable.

```bash
case $choice in
  1) sudo dmidecode -t system | grep Serial ;;
  2) sudo dmidecode -t baseboard | grep Serial ;;
  *) echo "Invalid choice. Please choose 1 or 2." ;;
esac
```

This `case` statement executes the command corresponding to the value of `choice`. If the user selects option 1, the script runs `sudo dmidecode -t system | grep Serial`, which retrieves the system serial number. If the user selects option 2, the script runs `sudo dmidecode -t baseboard | grep Serial`, which retrieves the serial number of the baseboard. If the user enters an invalid choice, the script prints an error message asking the user to choose 1 or 2.

Overall, this script allows a user to select one of two commands using a menu and then executes the chosen command. The script is useful in situations where a user needs to retrieve hardware information using the `dmidecode` utility.
