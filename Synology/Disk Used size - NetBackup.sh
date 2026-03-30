#!/bin/bash
# Version:      1.0
# Date Run:     2026-03-29
# Date:         2026-03-26
# Developper:   Nenad(a)dragic(.)com

(du -ha --max-depth=2 --exclude='#recycle' --exclude='@eaDir' --exclude='Log' /volume1/NetBackup/ 2>/dev/null | grep -vE "total$|/volume1/NetBackup/$" | sort -k2); du -shc /volume1/NetBackup/ 2>/dev/null
