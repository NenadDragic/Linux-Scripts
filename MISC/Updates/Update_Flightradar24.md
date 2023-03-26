# Bash script for updating the Flightradar24 software on a Raspberry Pi

This Bash script updates the Flightradar24 software on a Raspberry Pi. It stops the Flightradar24 service, removes the old software, downloads and installs the latest software package from the official repository, and restarts the service.

## Usage

To use this script, simply run it in a Bash terminal. The script will automatically stop the Flightradar24 service, remove the old software, download and install the latest software package, and restart the service.

## Script

```bash
#!/bin/bash

# Stop the Flightradar24 service
sudo systemctl stop fr24feed

# Remove the old Flightradar24 software
sudo dpkg -r fr24feed

# Download the latest Flightradar24 software package
wget https://repo-feed.flightradar24.com/linux_x86_64_binaries/fr24feed_1.0.28-1_amd64.deb

# Install the latest Flightradar24 software package
sudo dpkg -i fr24feed_1.0.28-1_amd64.deb

# Start the Flightradar24 service
sudo systemctl start fr24feed
```

## Explanation

The script consists of five parts:

1. Stop the Flightradar24 service:

   ```bash
   sudo systemctl stop fr24feed
   ```

   This command stops the Flightradar24 service to prevent any conflicts during the update process.

2. Remove the old Flightradar24 software:

   ```bash
   sudo dpkg -r fr24feed
   ```

   This command removes the old Flightradar24 software from the system.

3. Download the latest Flightradar24 software package:

   ```bash
   wget https://repo-feed.flightradar24.com/linux_x86_64_binaries/fr24feed_1.0.28-1_amd64.deb
   ```

   This command downloads the latest Flightradar24 software package from the official repository. The version number in the URL may need to be updated to match the latest version of the software.

4. Install the latest Flightradar24 software package:

   ```bash
   sudo dpkg -i fr24feed_1.0.28-1_amd64.deb
   ```

   This command installs the latest Flightradar24 software package on the system. The version number in the filename may need to be updated to match the latest version of the software.

5. Start the Flightradar24 service:

   ```bash
   sudo systemctl start fr24feed
   ```

   This command starts the Flightradar24 service to resume normal operation.

## Note

This script requires sudo privileges to execute, so the user may be prompted to enter their password. The version number in the `wget` and `dpkg` commands may need to be updated to match the latest version of the Flightradar24 software. You can check the latest version on the official Flightradar24 website.
