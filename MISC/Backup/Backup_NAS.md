# Shell Script to Backup Data

This shell script is designed to perform a backup of data to a remote location using `rsync` and `ssh`. Make sure to run this script with root privileges.

## Prerequisites

You should have the following prerequisites installed on your system:

- `rsync`: A fast, versatile file copying tool.
- `ssh`: Secure Shell protocol for secure remote access.

## Usage

1. Make sure you have root privileges to run this script.

2. Modify the `backup_dir` variable to specify the backup directory on the remote system.

3. Run the script using the following command:

```bash
sudo bash script_name.sh

## Explanation

- The script checks if the user is running it with root privileges using the `whoami` command.

- The `backup_dir` variable is set to the directory where the backup will be stored on the remote system.

- The `rsync` command is used to perform the backup. It uses the `-av` flags for archive mode and verbose output. The `-e` flag specifies the SSH command to use for the remote connection.

- The script then exits after completing the backup.

Remember to replace placeholders like `192.168.1.50` with the actual IP address of your remote system and adjust paths as needed.

**Note:** This script assumes you have set up SSH key-based authentication between the local and remote systems to avoid manual password prompts during the backup process.
