#!/bin/bash
MOUNT_POINT="/mnt/usb/Backup"
UUID="6b0f406c-bf48-4ecc-9673-d963dc278d9c"

sudo umount "$MOUNT_POINT" && \
sudo eject "/dev/disk/by-uuid/$UUID" && \
echo "USB sikkert fjernet"
