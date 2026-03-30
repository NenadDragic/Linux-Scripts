#!/bin/bash
# Version:      1.0
# Date run:     2026-03-29
# Date:         2026-03-26
# Developper:   Nenad(a)dragic(.)com

(du -ha --max-depth=1 --exclude='#recycle' --exclude='@eaDir' --exclude='Log' /volume1/DashCam/ 2>/dev/null | grep -vE "total$|/volume1/DashCam/$" | sort -k2); du -shc /volume1/DashCam/ 2>/dev/null
