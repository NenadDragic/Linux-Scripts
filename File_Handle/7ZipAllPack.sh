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
require_tools "7zz:7zip"

# MD5-summen for den korrekte adgangskode
EXPECTED_MD5="e0baa6edf1482789a19a5e1380bb4132"

# Spørg brugeren om adgangskoden
read -s -p "Indtast adgangskode: " password
echo

# Valider adgangskoden ved at sammenligne MD5-summen
if [ "$(echo -n "$password" | md5sum | awk '{print $1}')" != "$EXPECTED_MD5" ]; then
    echo "Forkert adgangskode. Scriptet afsluttes."
    exit 1
fi

echo "Adgangskode valideret. Starter komprimering..."

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