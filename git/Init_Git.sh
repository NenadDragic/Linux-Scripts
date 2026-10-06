#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools git

# Clone all of NenadDragic's repositories
# https://github.com/NenadDragic

# Bash scripts
git clone git@github.com:NenadDragic/Bash.git

# bat
git clone git@github.com:NenadDragic/bat.git

# C# scripts
git clone git@github.com:NenadDragic/c-Sharp.git

# c++
git clone git@github.com:NenadDragic/cpp.git

# Cyber Security resources
git clone git@github.com:NenadDragic/Cyber-Sec.git

# Devices
git clone git@github.com:NenadDragic/Devices.git

# Docs Downloads (e-Boks, mit.dk, Jyske Bank og Nykredit netbank)
git clone git@github.com:NenadDragic/Docs_Downloads.git

# Edora
git clone git@github.com:NenadDragic/Edora.git

# JB Scripts
git clone git@github.com:NenadDragic/JB-Scripts.git

# Learning resources
git clone git@github.com:NenadDragic/Learning.git

# lib (delt dependency-checker mv., brugt af scripts i de andre repos)
git clone git@github.com:NenadDragic/lib.git

# Linux Learning
git clone git@github.com:NenadDragic/Linux_Learning.git

# Linux Scripts
git clone git@github.com:NenadDragic/Linux-Scripts.git

# PowerShell scripts
git clone git@github.com:NenadDragic/PowerShell.git

# Python scripts
git clone git@github.com:NenadDragic/Python.git

# Raspberry Pi projects
git clone git@github.com:NenadDragic/RaspberryPi.git

# Website Source (hosting)
git clone git@github.com:NenadDragic/Web_source.git

# z-os
git clone git@github.com:NenadDragic/z-os.git

# z-os JB
git clone git@github.com:NenadDragic/z-os_JB.git
