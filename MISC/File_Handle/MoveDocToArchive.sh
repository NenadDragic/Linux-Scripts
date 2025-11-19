#!/bin/bash

# Dette script flytter filer baseret på et årstal,
# der er angivet som parameter.

# --- Parametre og opsætning ---

# Tjek om både en handling ([run|find]) og et årstal er angivet.
if [[ "$1" != "run" && "$1" != "find" ]] || [[ -z "$2" ]]; then
    echo "Brug: $0 [run|find] [årstal]"
    echo "Eksempel: $0 find 2008"
    exit 1
fi

action="$1"
search_year="$2"

fra_Folder="/home/nenad/Downloads/Leg/Doc"
til_Folder="/home/nenad/Downloads/Leg/Doc Archive"
logfil="flyttede_filer_${search_year}_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$til_Folder"

# --- Håndtering af "find" funktionen ---
if [[ "$action" == "find" ]]; then
    echo "Følgende filer matcher mønsteret: $search_year"
    # find-kommandoen er nu rettet til at bruge årstallet fra parameteren.
    find "$fra_Folder" -type f -name "*\[${search_year}-??-??\]*"
    exit 0
fi

# --- Håndtering af "run" funktionen ---
if [[ "$action" == "run" ]]; then
    echo "Start flytning af filer fra år $search_year: $(date)" > "$logfil"
    
    find "$fra_Folder" -type f -name "*\[${search_year}-??-??\]*" -print0 | while IFS= read -r -d '' fil; do
        
        if [[ -n "$fil" ]]; then
            filnavn=$(basename "$fil")
            mv "$fil" "$til_Folder/"
            echo "Flyttet: $filnavn" >> "$logfil"
        fi
    done
    
    echo "Færdig: $(date)" >> "$logfil"
    echo "Flytning gennemført. Log gemt i: $logfil"
fi