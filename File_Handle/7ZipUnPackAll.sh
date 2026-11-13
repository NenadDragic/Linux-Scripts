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

# Adgangskoden kontrolleres ikke på forhånd - 7zz afviser selv en forkert kode for hvert arkiv.
# (Tidligere blev den sammenlignet med en MD5-sum i scriptet - en usaltet MD5 i et git-repo
#  kan gættes offline, så den er fjernet.)
read -r -s -p "Indtast adgangskode: " password
echo

if [ -z "$password" ]; then
    echo "Tom adgangskode. Scriptet afsluttes."
    exit 1
fi

echo "Starter udpakning..."

# Loop igennem alle 7z-filer i det aktuelle bibliotek
for file in *.7z; do
    # Tjek om der er 7z-filer i mappen
    if [ ! -f "$file" ]; then
        echo "Ingen .7z-filer fundet i det aktuelle bibliotek."
        exit 1
    fi

    # Opret filnavn uden .7z endelsen
    filename="${file%.7z}"

    echo "Udpakker '$file'..."

    # Opret en ny mappe for udpakningen
    mkdir -p "$filename"
    
    # Pak filen ud til den nye mappe ved hjælp af den indtastede adgangskode
    7zz x -p"$password" "$file" -o"$filename"
    
    if [ $? -eq 0 ]; then
        echo "Udpakning af '$file' er færdig."
    else
        echo "FEJL: Noget gik galt under udpakning af '$file'. Tjek om adgangskoden er korrekt."
    fi
done

echo "Alle filer er behandlet."