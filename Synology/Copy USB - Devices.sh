#!/bin/bash
# Version:      1.1
# Date:         2026-04-13
# Test Run:     2026-04-13
# Developper: Nenad(a)dragic(.)com

sudo rsync -avL --progress --remove-source-files \
  /volumeUSB1/usbshare/ \
  /volume1/NetBackup/

sudo find /volumeUSB1/usbshare/ -type d -empty -delete

sudo rm -rf /volumeUSB1/usbshare/
