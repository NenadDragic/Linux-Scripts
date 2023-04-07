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
This line defines the backup directory where the image file backups will be stored. The directory is specified using a relative path to the user's home directory.

```bash
# Define the current date in the format YYYY-MM-DD
date="$(date +%Y-%m-%d)"
```

This line defines the current date in the format YYYY-MM-DD using the `date` command with the `+%Y-%m-%d` format string.

```bash
# Backup drive 1
echo "Backing up drive 1..."
drive_type=$(lsblk -no parttypename /dev/nvme0n1p1)
pv -tpreb /dev/nvme0n1p1 | dd of="$backup_dir/$drive_type $date.img" bs=4M
```

This block of code initiates the backup of the first drive by first printing a message to the console. It then uses the `lsblk` command to determine the drive type of the first drive (partition 1 of nvme0n1) and assigns the result to the `drive_type` variable. Finally, the `pv` command is used to monitor the progress of the backup and pipe the output to the `dd` command which creates an image file backup of the drive, with a name that includes the `drive_type` and `date` variables, and stores it in the `backup_dir`.

```bash
# Backup drive 2
echo "Backing up drive 2..."
drive_type=$(lsblk -no parttypename /dev/nvme0n1p2)
pv -tpreb /dev/nvme0n1p2 | dd of="$backup_dir/$drive_type $date.img" bs=4M
```

This block of code initiates the backup of the second drive in a similar fashion to the first drive.

```bash
# Backup drive 3
echo "Backing up drive 3..."
drive_type=$(lsblk -no parttypename /dev/nvme0n1p3)
pv -tpreb /dev/nvme0n1p3 | dd of="$backup_dir/$drive_type $date.img" bs=4M
```

This block of code initiates the backup of the third drive in a similar fashion to the first and second drives.

```bash
echo "Backup complete!"
```

This line prints a message to the console indicating that the backup process is complete.
