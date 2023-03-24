#!/bin/bash

# Update package lists and upgrade existing packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# Install necessary packages
sudo apt-get install -y dkms git realtek-rtl88xxau-dkms

# Clone repository and navigate to directory
git clone https://github.com/aircrack-ng/rtl8812au.git
cd rtl8812au

# Make and install the driver
make
sudo make install

echo "sudo ip link set wlan1 down"
echo "sudo iw dev wlan1 set type monitor"
echo "sudo ip link set wlan1 up"
echo "https://hackernoon.com/configuring-the-alpha-awus036ach-wi-fi-adapter-on-kali-linux"
