#!/bin/bash
# Version         1.2
# Date run:       2026-04-13
# Date:           2026-04-13  
# Developper:     Nenad(a)dragic(.)com

sudo rsync -avL --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

sudo find /volumeUSB1/usbshare/ -type d -empty -delete

sudo rm -rf /volumeUSB1/usbshare/Log/
