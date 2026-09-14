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
require_tools sudo dmidecode

# Check if the user has root privileges
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi

echo "Which command would you like to run?"
echo "1. sudo dmidecode -t system | grep Serial"
echo "2. sudo dmidecode -t baseboard | grep Serial"
read choice

case $choice in
  1) sudo dmidecode -t system | grep Serial ;;
  2) sudo dmidecode -t baseboard | grep Serial ;;
  *) echo "Invalid choice. Please choose 1 or 2." ;;
esac
