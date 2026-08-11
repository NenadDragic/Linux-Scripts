# Update and Maintenance Script
This script (Total_Update.sh) is designed to update and maintain a Debian-based Linux system. It checks for root privileges, updates the APT packages, and updates the file location database.

## Usage
1. Make sure you have permission to execute the script. If not, run the following command to grant permission:
```bash
chmod +x Total_Update.sh
```

2. Execute the script by running the following command:
```bash
sudo ./Total_Update.sh
```

The script will update APT packages and the file location database on your Debian-based Linux system.

## Explanation
The script uses a combination of `if` statement, APT package management commands, and the `updatedb` command to perform the update and maintenance tasks.

* `if [ "$(whoami)" != "root" ]; then`: This line checks if the current username is not "root".

`echo "Please run as root.\n"`: If the user is not root, the script displays a message asking to run the script as root. Note there is no `-e` flag, so the `\n` is printed literally rather than as a newline.

`exit`: If the user is not root, the script exits.

`fi`: This closes the if statement.

`apt -y update`: This command updates the package list from the repositories.

`apt -y upgrade`: This command upgrades all installed packages to their latest available versions.

`apt -y dist-upgrade`: This command performs an intelligent upgrade, handling changes in package dependencies, and installing new packages if necessary.

`apt autoremove`: This command removes any unnecessary packages that were automatically installed to satisfy dependencies and are no longer needed.

`apt autoclean`: This command cleans up the local repository, removing package files that can no longer be downloaded and are virtually useless.

`updatedb`: This command updates the file location database, which is used by the locate command to quickly find files on the system.

When the script is executed, it checks for root privileges, updates the APT packages, and updates the file location database, automating the process of updating and maintaining a Debian-based Linux system.
