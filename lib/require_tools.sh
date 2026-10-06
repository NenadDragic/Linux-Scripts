#!/bin/bash
# Version:      1.0
# Date:         2026-10-06
# Test Run:
# Developper:   Nenad(a)dragic(.)com
#
# Delt dependency-checker. Sources af scripts - køres ikke selv.
#
#   source "<repo>/lib/require_tools.sh"
#   require_tools rsync "runuser:util-linux" "7zz:7zip"
#
# Hvert argument er enten "værktøj" eller "værktøj:apt-pakke" (når pakken
# hedder noget andet end kommandoen). Mangler et eller flere værktøjer,
# skrives en samlet apt-kommando, og scriptet stoppes med exit 1.
# /usr/sbin og /sbin tjekkes også, så fx cryptsetup findes for almindelige
# brugere, hvor sbin ikke er i PATH.

require_tools() {
    local spec tool pkg dir found
    local -a missing=() pkgs=()

    for spec in "$@"; do
        tool=${spec%%:*}
        pkg=${spec#*:}
        command -v "$tool" >/dev/null 2>&1 && continue
        found=0
        for dir in /usr/local/sbin /usr/sbin /sbin; do
            [ -x "$dir/$tool" ] && { found=1; break; }
        done
        (( found )) && continue
        missing+=("$tool")
        [[ " ${pkgs[*]} " == *" $pkg "* ]] || pkgs+=("$pkg")
    done

    (( ${#missing[@]} == 0 )) && return 0

    echo "FEJL: Mangler værktøj(er): ${missing[*]}" >&2
    echo "Installér med: sudo apt install ${pkgs[*]}" >&2
    exit 1
}
