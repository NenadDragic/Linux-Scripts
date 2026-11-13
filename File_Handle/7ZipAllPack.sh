#!/bin/bash
# Version:      1.1
# Date:         2026-11-13
# Test Run:
# Developper:   Nenad(a)dragic(.)com

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
require_tools "7zz:7zip"

# Adgangskoden indtastes to gange, så en tastefejl ikke giver arkiver, der ikke kan åbnes igen.
# (Tidligere blev den sammenlignet med en MD5-sum i scriptet - en usaltet MD5 i et git-repo
#  kan gættes offline, så den er fjernet.)
read -r -s -p "Indtast adgangskode: " password
echo
read -r -s -p "Gentag adgangskode:  " password2
echo

if [ -z "$password" ]; then
    echo "Tom adgangskode. Scriptet afsluttes."
    exit 1
fi
if [ "$password" != "$password2" ]; then
    echo "De to adgangskoder er ikke ens. Scriptet afsluttes."
    exit 1
fi
unset password2

echo "Adgangskoder er ens. Starter komprimering..."

# Loop igennem alle undermapper i det aktuelle bibliotek
for dir in */; do
    # Fjern den afsluttende skråstreg
    folder_name="${dir%/}"
    
    echo "Komprimerer indholdet af mappen '$folder_name'..."
    
    # Skift til mappen og komprimer kun dens indhold
    (cd "$folder_name" && 7zz a -p"$password" -mhe -t7z "../$folder_name.7z" ./*)
    
    if [ $? -eq 0 ]; then
        echo "Komprimering af '$folder_name' er færdig."
    else
        echo "FEJL: Noget gik galt under komprimering af '$folder_name'."
    fi
done

echo "Alle mapper er behandlet."