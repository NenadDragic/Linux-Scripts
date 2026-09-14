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
require_tools fzf "ssh:openssh-client"

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
