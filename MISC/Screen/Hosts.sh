#!/bin/bash

# 1. Hent alle hosts, sorter dem, og lad brugeren vælge med fzf
# fzf åbner en interaktiv søgeboks
target=$(grep -i "^Host " ~/.ssh/config | grep -v "*" | awk '{print $2}' | sort -f | fzf --height 40% --reverse --border --header="Vælg SSH host:")

# 2. Hvis brugeren valgte en host (og ikke trykkede ESC), så forbind
if [ -n "$target" ]; then
    echo "Forbinder til $target..."
    ssh "$target"
else
    echo "Ingen host valgt."

fi
