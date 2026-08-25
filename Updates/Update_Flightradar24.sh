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
