#!/bin/bash

# ============================================================
#  MoveDocToArchive.sh
#  Finder og flytter filer med 2008-dato i filnavnet.
#
#  Brug:
#    ./MoveDocToArchive.sh find     → Preview af matchende filer
#    ./MoveDocToArchive.sh dryrun   → Simuler flytning uden at røre filer
#    ./MoveDocToArchive.sh run      → Udfør flytning
# ============================================================

# --- Validér argument ---
if [[ "$1" != "run" && "$1" != "find" && "$1" != "dryrun" ]]; then
    echo "Brug: $(basename "$0") [run|find|dryrun]"
    exit 1
fi

# --- Konfiguration ---
fra_folder="/sti/til/fra_folder"
til_folder="/sti/til/til_folder"
logfil="$til_folder/flyttede_filer_$(date +%Y%m%d_%H%M%S).log"

# --- Tjek at kildemappen eksisterer ---
if [[ ! -d "$fra_folder" ]]; then
    echo "Fejl: Kildemappen findes ikke: $fra_folder"
    exit 1
fi

# --- Find matchende filer ---
mapfile -d '' filer < <(find "$fra_folder" -maxdepth 1 -type f -name "*2008-??-??*" -print0)

# --- Find-tilstand: preview og afslut ---
if [[ "$1" == "find" ]]; then
    if [[ ${#filer[@]} -eq 0 ]]; then
        echo "Ingen filer matcher mønsteret."
    else
        echo "Følgende filer matcher mønsteret:"
        printf '%s\n' "${filer[@]}"
    fi
    exit 0
fi

# --- Dryrun-tilstand: simuler uden at røre filer ---
if [[ "$1" == "dryrun" ]]; then
    if [[ ${#filer[@]} -eq 0 ]]; then
        echo "Ingen filer matcher mønsteret."
        exit 0
    fi

    mkdir -p "$til_folder"

    device_fra=$(stat -c %d "$fra_folder")
    device_til=$(stat -c %d "$til_folder")

    if [[ "$device_fra" == "$device_til" ]]; then
        echo "[DRYRUN] Samme filsystem — checksum ville blive sprunget over."
    else
        echo "[DRYRUN] Forskellige filsystemer — checksum ville blive aktiveret."
    fi

    echo ""
    echo "Følgende handlinger ville blive udført:"
    echo "---"

    antal_ville_flyttes=0
    antal_ville_springes_over=0

    for fil in "${filer[@]}"; do
        filnavn=$(basename "$fil")
        if [[ -e "$til_folder/$filnavn" ]]; then
            echo "  ⊘ SPRING OVER (findes allerede): $filnavn"
            ((antal_ville_springes_over++))
        else
            echo "  → FLYTTES: $filnavn"
            echo "       Fra: $fil"
            echo "       Til: $til_folder/$filnavn"
            ((antal_ville_flyttes++))
        fi
    done

    echo "---"
    echo "Opsummering: $antal_ville_flyttes ville blive flyttet, $antal_ville_springes_over ville blive sprunget over."
    echo "[DRYRUN] Ingen filer blev rørt."
    exit 0
fi

# --- Run-tilstand ---

# Opret målmappen hvis den ikke findes
mkdir -p "$til_folder"

# Detektér om kilde og mål er på samme filsystem
device_fra=$(stat -c %d "$fra_folder")
device_til=$(stat -c %d "$til_folder")

if [[ "$device_fra" == "$device_til" ]]; then
    brug_checksum=false
else
    brug_checksum=true
fi

# --- Initialiser tællere og log ---
antal_ok=0
antal_fejl=0
antal_checksum_fejl=0
antal_sprunget_over=0

echo "Start flytning: $(date)" > "$logfil"

if [[ "$brug_checksum" == true ]]; then
    echo "Filsystem: kilde og mål er forskellige — checksum-validering aktiveret." >> "$logfil"
else
    echo "Filsystem: kilde og mål er ens — checksum-validering sprunget over." >> "$logfil"
fi

echo "---" >> "$logfil"

# --- Løkke over filer ---
for fil in "${filer[@]}"; do
    filnavn=$(basename "$fil")

    # Spring over hvis filen allerede findes i målet
    if [[ -e "$til_folder/$filnavn" ]]; then
        echo "SPRING OVER (findes allerede): $filnavn" >> "$logfil"
        ((antal_sprunget_over++))
        continue
    fi

    # Beregn checksum før flytning hvis nødvendigt
    if [[ "$brug_checksum" == true ]]; then
        checksum_før=$(sha256sum "$fil" | awk '{print $1}')
    fi

    # Flyt filen
    if mv "$fil" "$til_folder/"; then
        if [[ "$brug_checksum" == true ]]; then
            checksum_efter=$(sha256sum "$til_folder/$filnavn" | awk '{print $1}')
            if [[ "$checksum_før" == "$checksum_efter" ]]; then
                echo "OK:            $filnavn  [$checksum_efter]" >> "$logfil"
                ((antal_ok++))
            else
                echo "CHECKSUM FEJL: $filnavn" >> "$logfil"
                echo "  Før:   $checksum_før" >> "$logfil"
                echo "  Efter: $checksum_efter" >> "$logfil"
                ((antal_checksum_fejl++))
            fi
        else
            echo "Flyttet: $filnavn" >> "$logfil"
            ((antal_ok++))
        fi
    else
        echo "FEJL ved flytning: $filnavn" >> "$logfil"
        ((antal_fejl++))
    fi
done

# --- Opsummering ---
echo "---" >> "$logfil"
echo "Resultat: $antal_ok OK, $antal_fejl mv-fejl, $antal_checksum_fejl checksum-fejl, $antal_sprunget_over sprunget over." >> "$logfil"
echo "Færdig: $(date)" >> "$logfil"

echo ""
echo "Flytning gennemført:"
echo "  ✔ Flyttet:          $antal_ok"
echo "  ✘ mv-fejl:          $antal_fejl"
echo "  ✘ Checksum-fejl:    $antal_checksum_fejl"
echo "  ⊘ Sprunget over:    $antal_sprunget_over"
echo ""
echo "Log gemt i: $logfil"
