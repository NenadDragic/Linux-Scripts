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
require_tools sudo eject

MOUNT_POINT="/mnt/usb/Backup"
UUID="6b0f406c-bf48-4ecc-9673-d963dc278d9c"

sudo umount "$MOUNT_POINT" && \
sudo eject "/dev/disk/by-uuid/$UUID" && \
echo "USB sikkert fjernet"
