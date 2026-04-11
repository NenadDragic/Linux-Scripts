#!/bin/bash
# Version         1.1
# Date run:       2026-04-11
# Date:           2026-04-11
# Developper:     Nenad(a)dragic(.)com

sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

sudo rm -rf /volumeUSB1/usbshare/Log/
