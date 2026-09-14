#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools sudo git make

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
