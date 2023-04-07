# Backup Script
This script (Total_Backup.sh) is designed to backup data from three different drives to a backup directory.

´´´bash
#!/bin/bash
´´´

This is the shebang line that specifies the interpreter to be used for running the script. In this case, it is the bash shell.

```bash
# Check if user is root
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi
```

This block of code checks if the script is being run as the root user by comparing the output of the `whoami` command with the string "root". If the user is not root, an error message is printed and the script exits using the `exit` command.

```bash
# Define the backup directory
backup_dir="../../media/nenad/2F90E98B5A2F4030/Backup - Debian Laptop"
```
