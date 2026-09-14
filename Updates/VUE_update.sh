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
require_tools wget sudo

# VUE Update script

# Check for root privileges
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi

# URL to download
url="https://example.com/somefile.tar.gz"

# Filename from URL
filename=$(basename "$url")

# Use wget to download the file
wget $url

# Notify user of download completion
echo "Download completed."

# Untar the downloaded file
tar -xzf $filename

# Notify user of file extraction completion
echo "File extracted."

# Copy files to necessary directories
sudo cp vuescan.svg /usr/share/icons/hicolor/scalable/apps/
sudo cp vuescan.rul /lib/udev/rules.d/60-vuescan.rules
sudo cp vuescan     /usr/bin/

# Purge packages
sudo apt purge ippusbxd
sudo apt purge ipp-usb

# Reload Udev rules
sudo udevadm control --reload-rules

echo "Script completed successfully."
