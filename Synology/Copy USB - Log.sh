#!/bin/bash
# Version:      1.0
# Date:         2026-03-26
# Test Run:
# Developper:   Nenad(a)dragic(.)com

sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

sudo rm -rf /volumeUSB1/usbshare/Log/
