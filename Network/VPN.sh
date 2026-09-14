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
require_tools sudo "wg-quick:wireguard-tools" "wg:wireguard-tools"

# Tjek om der er nok argumenter

if [ "$#" -lt 2 ]; then

    echo "Brug: $0  "

    exit 1

fi

COMMAND=$1

INTERFACE=$2

case "$COMMAND" in

    up)

        sudo wg-quick up "$INTERFACE"

        ;;

    show)

        sudo wg show "$INTERFACE"

        ;;

    down)

        sudo wg-quick down "$INTERFACE"

        ;;

    *)

        echo "Ugyldig kommando: $COMMAND"

        echo "Gyldige kommandoer er: up, show, down"

    	echo "fx. sudo sh VPN.sh up Dragic"
        
        exit 1

        ;;

esac
