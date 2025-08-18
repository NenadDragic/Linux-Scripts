#!/bin/bash

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

        exit 1

        ;;

esac
