#!/bin/bash
# Version:      1.0
# Date:         2026-03-26
# Test Run:     2026-03-29
# Developper: Nenad(a)dragic(.)com

find /volume1/DashCam -path "/volume1/DashCam/#recycle" -prune -o -type f -mtime +30 -print0 | xargs -0 rm -f
