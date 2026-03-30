#!/bin/bash
# Version       1.0
# Date:         2026-03-26
# Date Run:     2026-03-29
# Developper:   Nenad(a)dragic(.)com

find /volume1/Dragic/ -name '*  *' -exec sh -c 'mv "$1" "${1//  / }"' find-sh {} \;