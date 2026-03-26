#!/bin/bash
MOUNT_POINT="/mnt/usb/Backup"
UUID="cff68436-8fe9-422f-8ce8-750206be924f"

sudo mkdir -p "$MOUNT_POINT"
sudo mount UUID="$UUID" "$MOUNT_POINT" && echo "Mounted OK: $MOUNT_POINT"
