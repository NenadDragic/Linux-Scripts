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
require_tools sudo wget

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
