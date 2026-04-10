#!/bin/bash
# Version:      1.0
# Date:         2026-03-26
# Test Run:     2026-03-29
# Developper: Nenad(a)dragic(.)com

rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

rm -rf /volumeUSB1/usbshare/Log/
