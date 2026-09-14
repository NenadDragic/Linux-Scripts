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
require_tools pv

# Check if user is root
if [ "$(whoami)" != "root" ]
  then
    echo "Please run as root.\n"
    exit
fi

# Define the backup directory
backup_dir="../../media/nenad/3CA79D5F2053D934"

# Define the current date in the format YYYY-MM-DD
date="$(date +%Y-%m-%d)"

# Backup drive 1
echo "Backing up drive 1..."
drive_type=$(lsblk -no parttypename /dev/nvme0n1p1)
pv -tpreb /dev/nvme0n1p1 | dd of="$backup_dir/$drive_type $date.img" bs=4M
dd if=/dev/nvme0n1p1 of="$backup_dir/$drive_type $date.img" bs=4M status=progress

# Backup drive 2
echo "Backing up drive 2..."
drive_type=$(lsblk -no parttypename /dev/nvme0n1p2)
pv -tpreb /dev/nvme0n1p2 | dd of="$backup_dir/$drive_type $date.img" bs=4M
dd if=/dev/nvme0n1p2 of="$backup_dir/$drive_type $date.img" bs=4M status=progress

# Backup drive 3
echo "Backing up drive 3..."
drive_type=$(lsblk -no parttypename /dev/nvme0n1p3)
pv -tpreb /dev/nvme0n1p3 | dd of="$backup_dir/$drive_type $date.img" bs=4M
dd if=/dev/nvme0n1p3 of="$backup_dir/$drive_type $date.img" bs=4M status=progress

#echo "Backing up drive"
#drive_type=$(lsblk -no parttypename /dev/nvme0n1p3)
#pv -tpreb /dev/nvme0n1p3 | dd of="$backup_dir/$drive_type $date.img" bs=4M
#dd if=/dev/nvme0n1p3 of="$backup_dir/$drive_type $date.img" bs=4M status=progress

echo "Backup complete!"
