#!/bin/bash
MOUNT_POINT="/mnt/usb/Backup"
UUID="6b0f406c-bf48-4ecc-9673-d963dc278d9c"

sudo mkdir -p "$MOUNT_POINT"
sudo mount UUID="$UUID" "$MOUNT_POINT" && echo "Mounted OK: $MOUNT_POINT"
