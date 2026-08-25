#!/bin/bash

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

echo "Adgangskode valideret. Starter udpakning..."

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